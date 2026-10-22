//! `complain`: lets agents log friction they hit while working (broken
//! tools, missing permissions, confusing docs) so a human can sweep the
//! log later and fix everything.
//!
//! Complaints are JSON Lines, one record per line, stored at `--file`
//! (`$COMPLAIN_FILE`), else `$XDG_DATA_HOME/complain/complaints.jsonl`,
//! else `$HOME/.local/share/complain/complaints.jsonl`. `clear` moves
//! resolved records to `complaints.archive.jsonl` in the same directory.

use std::{
    env,
    ffi::OsString,
    fs::{self, OpenOptions},
    io::{self, Write},
    path::{Path, PathBuf},
    process::ExitCode,
};

use anyhow::{Context, ensure};
use chrono::{DateTime, SecondsFormat, Utc};
use clap::{Args, Parser, Subcommand};
use serde::{Deserialize, Serialize};

fn main() -> ExitCode {
    let args = ComplainArgs::parse();
    match args.run(&mut io::stdout().lock()) {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("Error: {err:#}");
            ExitCode::FAILURE
        }
    }
}

/// Log friction hit while working, for a human to fix later.
#[derive(Parser)]
#[command(name = "complain", version, subcommand_negates_reqs = true)]
struct ComplainArgs {
    /// What went wrong
    #[arg(required = true)]
    message: Option<String>,
    /// Kind of complaint, e.g. tool-failure, permissions, docs
    #[arg(short, long)]
    category: Option<String>,
    /// The complaints file [default: $XDG_DATA_HOME/complain/complaints.jsonl]
    #[arg(long, env = "COMPLAIN_FILE", global = true)]
    file: Option<PathBuf>,
    #[command(subcommand)]
    cmd: Option<ComplainCommand>,
}

#[derive(Subcommand)]
enum ComplainCommand {
    /// List complaints (unresolved only by default)
    List(ListArgs),
    /// Mark complaints as resolved
    Resolve(ResolveArgs),
    /// Move resolved complaints to the archive
    Clear(ClearArgs),
}

#[derive(Args)]
struct ListArgs {
    /// Include resolved complaints
    #[arg(long)]
    all: bool,
    /// Only complaints filed in this repo
    #[arg(long)]
    repo: Option<String>,
    /// Print the raw JSON Lines records
    #[arg(long)]
    json: bool,
}

#[derive(Args)]
struct ResolveArgs {
    #[arg(required = true)]
    ids: Vec<u64>,
}

#[derive(Args)]
struct ClearArgs {}

/// One record in the log.
#[derive(Serialize, Deserialize)]
struct Complaint {
    id: u64,
    time: String,
    cwd: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    repo: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    branch: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    agent: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    category: Option<String>,
    message: String,
    resolved: bool,
}

/// The complaints file, with its archive alongside.
struct Log {
    path: PathBuf,
}

// --- impl ComplainArgs --- //

impl ComplainArgs {
    fn run(self, out: &mut impl Write) -> anyhow::Result<()> {
        let log = match self.file {
            Some(path) => Log { path },
            None => Log::default_location()?,
        };
        match self.cmd {
            Some(ComplainCommand::List(args)) => args.run(&log, out),
            Some(ComplainCommand::Resolve(args)) => args.run(&log, out),
            Some(ComplainCommand::Clear(args)) => args.run(&log, out),
            None => {
                let message = self.message.expect("clap requires MESSAGE");
                Self::file(&log, &message, self.category, out)
            }
        }
    }

    /// Files a new complaint, the default command.
    fn file(
        log: &Log,
        message: &str,
        category: Option<String>,
        out: &mut impl Write,
    ) -> anyhow::Result<()> {
        let message = message.trim();
        ensure!(!message.is_empty(), "Complaint message is empty");

        let max_id = log
            .read()?
            .into_iter()
            .chain(log.read_archive()?)
            .map(|r| r.id)
            .max();
        let id = max_id.unwrap_or(0) + 1;

        let complaint = Complaint::new(id, message.to_owned(), category)?;
        log.append(&[complaint])?;
        writeln!(out, "Filed complaint #{id}")?;
        Ok(())
    }
}

impl ListArgs {
    fn run(self, log: &Log, out: &mut impl Write) -> anyhow::Result<()> {
        let repo = self.repo.as_deref();
        let shown = log
            .read()?
            .into_iter()
            .filter(|r| self.all || !r.resolved)
            .filter(|r| repo.is_none_or(|name| r.repo.as_deref() == Some(name)))
            .collect::<Vec<_>>();

        if self.json {
            out.write_all(Complaint::encode_lines(&shown)?.as_bytes())?;
            return Ok(());
        }
        if shown.is_empty() {
            writeln!(out, "No complaints.")?;
            return Ok(());
        }
        for complaint in &shown {
            complaint.write_human(out)?;
        }
        Ok(())
    }
}

impl ResolveArgs {
    fn run(self, log: &Log, out: &mut impl Write) -> anyhow::Result<()> {
        let mut ids = self.ids;
        ids.sort_unstable();
        ids.dedup();

        let mut records = log.read()?;
        let unknown = ids
            .iter()
            .copied()
            .filter(|id| !records.iter().any(|r| r.id == *id))
            .collect::<Vec<_>>();
        ensure!(
            unknown.is_empty(),
            "Unknown complaint id(s): {}",
            helpers::fmt_ids(&unknown)
        );

        for r in &mut records {
            r.resolved |= ids.contains(&r.id);
        }
        log.rewrite(&records)?;
        writeln!(out, "Resolved {}.", helpers::fmt_ids(&ids))?;
        Ok(())
    }
}

impl ClearArgs {
    fn run(self, log: &Log, out: &mut impl Write) -> anyhow::Result<()> {
        let (resolved, kept): (Vec<_>, Vec<_>) =
            log.read()?.into_iter().partition(|r| r.resolved);
        if resolved.is_empty() {
            writeln!(out, "Nothing to archive.")?;
            return Ok(());
        }

        // Archive first, so a failure in between duplicates rather than loses.
        log.append_archive(&resolved)?;
        log.rewrite(&kept)?;
        writeln!(out, "Archived {} resolved complaint(s).", resolved.len())?;
        Ok(())
    }
}

// --- impl Complaint --- //

impl Complaint {
    /// A new unresolved complaint, located in the current directory.
    fn new(
        id: u64,
        message: String,
        category: Option<String>,
    ) -> anyhow::Result<Self> {
        let cwd = env::current_dir().context("Failed to get current dir")?;
        Ok(Self {
            id,
            time: Utc::now().to_rfc3339_opts(SecondsFormat::Secs, true),
            cwd: cwd.to_string_lossy().into_owned(),
            repo: git::repo_name(&cwd),
            branch: git::branch(&cwd).or_else(|| git::jj_bookmark(&cwd)),
            agent: helpers::detect_agent(),
            category,
            message,
            resolved: false,
        })
    }

    /// Writes a header line, then the message indented beneath it.
    fn write_human(&self, out: &mut impl Write) -> io::Result<()> {
        let time = match DateTime::parse_from_rfc3339(&self.time) {
            Ok(time) => time.format("%Y-%m-%d %H:%MZ").to_string(),
            Err(_) => self.time.clone(),
        };
        let place = match (&self.repo, &self.branch) {
            (Some(repo), Some(branch)) => format!("{repo}@{branch}"),
            (Some(repo), None) => repo.clone(),
            (None, _) => self.cwd.clone(),
        };
        let mut header = vec![
            format!("#{}", self.id),
            time,
            place,
            self.agent.clone().unwrap_or_else(|| "-".to_owned()),
        ];
        header.extend(self.category.clone());
        if self.resolved {
            header.push("(resolved)".to_owned());
        }

        writeln!(out, "{}", header.join("  "))?;
        for line in self.message.lines() {
            writeln!(out, "     {line}")?;
        }
        Ok(())
    }

    /// Encodes records as JSON Lines.
    fn encode_lines(records: &[Self]) -> anyhow::Result<String> {
        let mut buf = String::new();
        for r in records {
            buf += &serde_json::to_string(r)?;
            buf.push('\n');
        }
        Ok(buf)
    }
}

// --- impl Log --- //

impl Log {
    /// `$XDG_DATA_HOME/complain/complaints.jsonl`, falling back to
    /// `~/.local/share`. Empty env vars count as unset.
    fn default_location() -> anyhow::Result<Self> {
        let data_home = match helpers::env_path("XDG_DATA_HOME") {
            Some(dir) => dir,
            None => helpers::env_path("HOME")
                .context("$HOME is not set")?
                .join(".local/share"),
        };
        let path = data_home.join("complain/complaints.jsonl");
        Ok(Self { path })
    }

    fn archive_path(&self) -> PathBuf {
        self.path.with_file_name("complaints.archive.jsonl")
    }

    fn read(&self) -> anyhow::Result<Vec<Complaint>> {
        Self::read_file(&self.path)
    }

    fn read_archive(&self) -> anyhow::Result<Vec<Complaint>> {
        Self::read_file(&self.archive_path())
    }

    fn append(&self, records: &[Complaint]) -> anyhow::Result<()> {
        Self::append_file(&self.path, records)
    }

    fn append_archive(&self, records: &[Complaint]) -> anyhow::Result<()> {
        Self::append_file(&self.archive_path(), records)
    }

    /// Atomically replaces the file's contents via a temp file and rename.
    fn rewrite(&self, records: &[Complaint]) -> anyhow::Result<()> {
        let path = &self.path;
        let name = path.file_name().context("Log path has no file name")?;
        let mut tmp_name = OsString::from(".");
        tmp_name.push(name);
        tmp_name.push(format!(".{}.tmp", std::process::id()));
        let tmp = path.with_file_name(tmp_name);

        fs::write(&tmp, Complaint::encode_lines(records)?)
            .with_context(|| format!("Failed to write {}", tmp.display()))?;
        fs::rename(&tmp, path)
            .with_context(|| format!("Failed to replace {}", path.display()))
    }

    /// Reads all records; a missing file is empty, a malformed line is an
    /// error.
    fn read_file(path: &Path) -> anyhow::Result<Vec<Complaint>> {
        let text = match fs::read_to_string(path) {
            Ok(text) => text,
            Err(e) if e.kind() == io::ErrorKind::NotFound => {
                return Ok(Vec::new());
            }
            Err(e) => {
                return Err(e).with_context(|| {
                    format!("Failed to read {}", path.display())
                });
            }
        };
        text.lines()
            .enumerate()
            .filter(|(_, line)| !line.trim().is_empty())
            .map(|(i, line)| {
                serde_json::from_str(line).with_context(|| {
                    format!("{}:{}: malformed record", path.display(), i + 1)
                })
            })
            .collect()
    }

    /// Appends with a single `write_all` on an `O_APPEND` handle, so
    /// concurrent writers can't interleave within a line.
    fn append_file(path: &Path, records: &[Complaint]) -> anyhow::Result<()> {
        let buf = Complaint::encode_lines(records)?;
        if let Some(dir) = path.parent() {
            fs::create_dir_all(dir).with_context(|| {
                format!("Failed to create {}", dir.display())
            })?;
        }
        OpenOptions::new()
            .create(true)
            .append(true)
            .open(path)
            .and_then(|mut f| f.write_all(buf.as_bytes()))
            .with_context(|| format!("Failed to append to {}", path.display()))
    }
}

/// Where a complaint was filed, via the `git` and `jj` CLIs. Everything
/// here is best-effort: a missing CLI or a non-repo `cwd` yields `None`.
mod git {
    use super::*;

    /// The basename of the repo root.
    pub(super) fn repo_name(cwd: &Path) -> Option<String> {
        let top = read(cwd, "git", &["rev-parse", "--show-toplevel"])?;
        Some(Path::new(&top).file_name()?.to_string_lossy().into_owned())
    }

    pub(super) fn branch(cwd: &Path) -> Option<String> {
        read(cwd, "git", &["branch", "--show-current"])
    }

    /// The nearest bookmark at or above `@`. Colocated jj repos leave git
    /// HEAD detached, so this stands in for the current branch there.
    pub(super) fn jj_bookmark(cwd: &Path) -> Option<String> {
        let names = read(
            cwd,
            "jj",
            &[
                "log",
                "--ignore-working-copy",
                "--no-pager",
                "--no-graph",
                "--color=never",
                "-r",
                "heads(::@ & bookmarks())",
                "-T",
                r#"local_bookmarks.map(|b| b.name()).join(" ") ++ " ""#,
            ],
        )?;
        names.split_whitespace().next().map(str::to_owned)
    }

    /// Runs `program` in `cwd`, returning its trimmed stdout if it
    /// succeeded and printed something.
    fn read(cwd: &Path, program: &str, args: &[&str]) -> Option<String> {
        let stdout = duct::cmd(program, args)
            .dir(cwd)
            .stdin_null()
            .stderr_null()
            .read()
            .ok()?;
        let stdout = stdout.trim();
        (!stdout.is_empty()).then(|| stdout.to_owned())
    }
}

mod helpers {
    use super::*;

    /// Reads an env var as a path, treating an empty value as unset.
    pub(super) fn env_path(name: &str) -> Option<PathBuf> {
        env::var_os(name)
            .filter(|v| !v.is_empty())
            .map(PathBuf::from)
    }

    /// Which agent harness we're running under, by its env vars.
    pub(super) fn detect_agent() -> Option<String> {
        if env::var_os("CLAUDECODE").is_some() {
            return Some("claude".to_owned());
        }
        let prefixes = [
            ("CODEX_", "codex"),
            ("OPENCODE_", "opencode"),
            ("KIMI_", "kimi"),
            ("GOOSE_", "goose"),
        ];
        let names = env::vars_os()
            .map(|(name, _)| name.to_string_lossy().into_owned())
            .collect::<Vec<_>>();
        prefixes
            .iter()
            .find(|(prefix, _)| names.iter().any(|n| n.starts_with(prefix)))
            .map(|(_, agent)| (*agent).to_owned())
    }

    /// `#1, #2, #3`
    pub(super) fn fmt_ids(ids: &[u64]) -> String {
        ids.iter()
            .map(|id| format!("#{id}"))
            .collect::<Vec<_>>()
            .join(", ")
    }
}

#[cfg(test)]
mod test {
    use clap::CommandFactory;

    use super::*;

    /// Verify the clap command tree (arg ids, defaults, subcommand names).
    #[test]
    fn verify_cli() {
        ComplainArgs::command().debug_assert();
    }

    /// Runs a command against `log`, returning its stdout.
    fn run(
        log: &Log,
        cmd: impl FnOnce(&Log, &mut Vec<u8>) -> anyhow::Result<()>,
    ) -> anyhow::Result<String> {
        let mut out = Vec::new();
        cmd(log, &mut out)?;
        Ok(String::from_utf8(out).unwrap())
    }

    fn file(log: &Log, msg: &str, category: Option<&str>) -> String {
        let category = category.map(str::to_owned);
        run(log, |l, out| ComplainArgs::file(l, msg, category, out)).unwrap()
    }

    fn list(log: &Log, all: bool, repo: Option<&str>, json: bool) -> String {
        let repo = repo.map(str::to_owned);
        let args = ListArgs { all, repo, json };
        run(log, |l, out| args.run(l, out)).unwrap()
    }

    fn resolve(log: &Log, ids: Vec<u64>) -> anyhow::Result<String> {
        run(log, |l, out| ResolveArgs { ids }.run(l, out))
    }

    fn clear(log: &Log) -> anyhow::Result<String> {
        run(log, |l, out| ClearArgs {}.run(l, out))
    }

    fn ids(records: anyhow::Result<Vec<Complaint>>) -> Vec<u64> {
        records.unwrap().iter().map(|r| r.id).collect()
    }

    #[test]
    fn archive_path() {
        let log = Log {
            path: PathBuf::from("/x/c.jsonl"),
        };
        assert_eq!(
            log.archive_path(),
            Path::new("/x/complaints.archive.jsonl")
        );
    }

    #[test]
    fn file_list_resolve_clear() {
        let tempdir = tempfile::tempdir().unwrap();
        let log = &Log {
            path: tempdir.path().join("nested/complaints.jsonl"),
        };

        assert_eq!(list(log, true, None, false), "No complaints.\n");
        let blank = run(log, |l, out| ComplainArgs::file(l, "  \n", None, out));
        assert!(blank.is_err());

        assert_eq!(file(log, "a", None), "Filed complaint #1\n");
        assert_eq!(
            file(log, "b\nsecond", Some("docs")),
            "Filed complaint #2\n"
        );
        assert_eq!(file(log, "c", None), "Filed complaint #3\n");

        let listed = list(log, false, None, false);
        assert!(listed.contains("  docs\n     b\n     second\n"), "{listed}");

        // Unknown ids fail without touching the file.
        let before = fs::read(&log.path).unwrap();
        let err = resolve(log, vec![2, 9, 8]).unwrap_err().to_string();
        assert!(err.contains("#8, #9"), "{err}");
        assert_eq!(fs::read(&log.path).unwrap(), before);

        assert_eq!(resolve(log, vec![3, 1, 3]).unwrap(), "Resolved #1, #3.\n");
        assert_eq!(resolve(log, vec![1]).unwrap(), "Resolved #1.\n");

        assert!(!list(log, false, None, false).contains("#1 "));
        let all = list(log, true, None, false);
        assert_eq!(all.matches("(resolved)").count(), 2, "{all}");

        assert_eq!(clear(log).unwrap(), "Archived 2 resolved complaint(s).\n");
        assert_eq!(ids(log.read()), [2]);
        assert_eq!(ids(log.read_archive()), [1, 3]);
        assert_eq!(clear(log).unwrap(), "Nothing to archive.\n");

        // Ids keep counting past archived records.
        assert_eq!(file(log, "d", None), "Filed complaint #4\n");
    }

    #[test]
    fn list_filters_and_json() {
        let tempdir = tempfile::tempdir().unwrap();
        let log = &Log {
            path: tempdir.path().join("complaints.jsonl"),
        };
        let line = |id, repo: &str| {
            format!(
                r#"{{"id":{id},"time":"2026-10-21T14:03:09Z","cwd":"/w",{repo}"#
            ) + r#""message":"m","resolved":false}"#
        };
        let lines = [line(1, r#""repo":"dotfiles","#), line(2, "")];
        fs::write(&log.path, lines.join("\n") + "\n").unwrap();

        assert_eq!(list(log, false, None, true), lines.join("\n") + "\n");
        assert_eq!(
            list(log, false, None, false),
            "#1  2026-10-21 14:03Z  dotfiles  -\n     m\n\
             #2  2026-10-21 14:03Z  /w  -\n     m\n",
        );
        assert_eq!(
            list(log, false, Some("dotfiles"), true),
            format!("{}\n", lines[0])
        );
        assert_eq!(list(log, false, Some("nope"), true), "");
    }

    #[test]
    fn malformed_line_is_an_error() {
        let tempdir = tempfile::tempdir().unwrap();
        let log = &Log {
            path: tempdir.path().join("complaints.jsonl"),
        };
        fs::write(&log.path, "not json\n").unwrap();

        let args = ListArgs {
            all: true,
            repo: None,
            json: false,
        };
        assert!(run(log, |l, out| args.run(l, out)).is_err());
        assert!(clear(log).is_err());
        assert!(
            run(log, |l, out| ComplainArgs::file(l, "x", None, out)).is_err()
        );
        assert_eq!(fs::read_to_string(&log.path).unwrap(), "not json\n");
    }
}

---
name: codex-review
description: Get an independent, read-only second-opinion code review from the Codex CLI and triage its findings. Use when asked for a Codex review of commits, diffs, files, or another exact scope.
argument-hint: <what to review, e.g. "commits 4-6", "the unstaged diff", "backend/src/server/hba.rs">
---

# Codex review

Goal: Get an independent review from `codex` (OpenAI's CLI agent), then relay
its findings with your own assessment.

Review scope: **$ARGUMENTS**

Codex is a separate agent with **zero context** from this session. Drive it by
shelling out via `Bash`: resolve the scope, prompt it well, run it, triage.

## Steps

1. **Resolve the scope.** For commits, pin the exact `parent..top` range — verify
   the parent chain (`git log --pretty=format:'%h %p %s'`), don't guess from
   positions. For a worktree review, note staged vs unstaged.

2. **Write the prompt to a file** (`/tmp/codex-review-prompt.txt`) — inline args
   mangle backticks/quotes. Include:
   - **Read-only mandate** + (for commits) "ignore uncommitted worktree changes."
   - **Exact scope**, and tell it to `git show`/`git diff` itself *and read whole
     files for context*, not just the diff.
   - **Domain context** — it knows nothing: what the feature does, key invariants,
     where the load-bearing logic lives.
   - **Pointers**, priority-ordered: the specific properties/edge cases to
     scrutinize. This is where the value is; generic asks yield generic results.
   - **Output format:** findings by severity (BLOCKER/HIGH/MEDIUM/LOW/NIT), each
     with title, `file:line`, rationale, concrete fix; exact repro for bugs; no
     praise or non-actionable nitpicks.

3. **Run it read-only, backgrounded** (slow — minutes on a large diff):
   ```bash
   codex exec --sandbox read-only - < /tmp/codex-review-prompt.txt
   ```
   Poll the output file; don't block. The review repeats under a final `codex` /
   `tokens used` block — read that clean copy.

4. **Triage, don't dump.** For each finding add your own one-line take: real?
   actual severity here? worth doing? Codex is a useful skeptic but lacks your
   context and will flag intended behavior or sub-millisecond edges as bugs.
   Surface the substance, deflate the noise, and **wait for the user** before
   fixing anything.

## Follow-ups (reuse the same session)

A resumed session keeps Codex's full prior context — its earlier findings, any
rules it proposed, the files it read. Use it to push back on a finding, have it
react to revised code/prose, or workshop over several rounds, instead of a fresh
review that re-establishes everything.

- Grab the session id from the first run's header line: `session id: <uuid>`.
- Resume — `resume` rejects `--sandbox` (errors "unexpected argument"); set the
  sandbox via a `-c` config override instead:
  ```bash
  codex exec resume -c 'sandbox_mode="read-only"' <SESSION_ID> - < /tmp/codex-followup.txt
  ```
- `--last` resumes the most recent session if you didn't capture the id. The `-`
  stdin and background-and-poll pattern are the same as a fresh run.

## Tips

- `--sandbox read-only` — Codex defaults to `workspace-write` and will edit files.
- Naming the key files/symbols + exact range gets a far sharper review than a
  bare range.
- You're typically prompting the frontier model in the GPT series, a very
  different model from yourself. Use it for an adversarial second opinion, not
  as a Claude substitute.

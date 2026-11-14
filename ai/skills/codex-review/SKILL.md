---
name: codex-review
description: Get an independent, read-only second-opinion code review from Codex and triage its findings. Use when asked for a Codex review of commits, diffs, files, or another exact scope.
argument-hint: <what to review, e.g. "commits 4-6", "the unstaged diff", "backend/src/server/hba.rs">
---

# Codex review

Goal: Get an independent review from Codex (OpenAI's coding agent), then relay
its findings with your own assessment.

Review scope: **$ARGUMENTS**

Codex is a separate agent with **zero context** from this session. Resolve the
scope, prompt it well, run it, and triage its findings.

## Steps

1. **Resolve the scope.** For commits, pin the exact `parent..top` range — verify
   the parent chain (`git log --pretty=format:'%h %p %s'`), don't guess from
   positions. For a worktree review, note staged vs unstaged.

2. **Write the prompt to a file.** Inline args mangle backticks and quotes, and
   the file records what was asked. Other sessions run reviews too, so give the
   file its own name, such as `/tmp/codex-review-<topic>.txt`. Include:
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

3. **Run it read-only, without blocking on it.** A review of a large diff
   takes minutes.

   **Through Paseo.** A Paseo agent shows in the app, outlives a Stop of this
   session, and can be read or steered, so run the reviewer as a Paseo agent
   when the `mcp__paseo__*` tools are available. Read the **paseo** skill, take
   the Codex profile from `list_profiles`, and `create_agent` with that
   profile. Set `cwd` to the checkout under review, and have the
   `initialPrompt` say to read the prompt file and follow it. Add
   `settings.features: { "plan_mode": true }` if `inspect_provider` lists the
   `plan_mode` feature. The review is the agent's final message, which the
   finish notification carries.

   All of Paseo's Codex modes permit writes. In plan mode Codex declines to
   write, but it is only following an instruction, and no sandbox stops it. So
   where a stray write would do damage, as on a stack that someone is still
   editing, have Codex review a frozen copy made with
   `git archive <commit> | tar -x -C <dir>`. The copy has no history to
   `git show`, so put the diff beside it as a patch file.

   **Through the CLI**, when Paseo's tools are missing. Run it in the
   background:
   ```bash
   codex exec --sandbox read-only - < /tmp/codex-review-<topic>.txt
   ```
   Poll the output file. The review repeats under a final `codex` /
   `tokens used` block, so read that clean copy. Outside a git repo, `exec`
   needs `--skip-git-repo-check`.

4. **Triage, don't dump.** For each finding add your own one-line take: real?
   actual severity here? worth doing? Codex is a useful skeptic but lacks your
   context and will flag intended behavior or sub-millisecond edges as bugs.
   Surface the substance, deflate the noise, and **wait for the user** before
   fixing anything.

## Follow-ups (reuse the same reviewer)

The same reviewer keeps its full prior context — its earlier findings, any
rules it proposed, the files it read. Use it to push back on a finding, have it
react to revised code/prose, or workshop over several rounds, instead of a fresh
review that re-establishes everything. Paseo cannot resume a CLI session, and
the CLI cannot resume a Paseo agent, so follow up through whichever one ran
the review.

**Paseo:** `send_agent_prompt` to the same agent. Archive the agent once the
review is finished.

**CLI:**

- Grab the session id from the first run's header line: `session id: <uuid>`.
- Resume — `resume` rejects `--sandbox` (errors "unexpected argument"); set the
  sandbox via a `-c` config override instead:
  ```bash
  codex exec resume -c 'sandbox_mode="read-only"' <SESSION_ID> - < /tmp/codex-followup.txt
  ```
- `--last` resumes the most recent session if you didn't capture the id. The `-`
  stdin and background-and-poll pattern are the same as a fresh run.

## Tips

- The CLI defaults to `workspace-write` and will edit files, so always pass
  `--sandbox read-only`.
- Naming the key files/symbols + exact range gets a far sharper review than a
  bare range.
- You're typically prompting the frontier model in the GPT series, a very
  different model from yourself. Use it for an adversarial second opinion, not
  as a Claude substitute.

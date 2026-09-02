---
name: knowledge-doc
description: >-
  Write or update a living knowledge doc for the current work, in the repo's
  tmp/ if gitignored, else a global /tmp path. Use when asked to write down
  what you learned, record knowledge, or leave notes for other agents.
---

Write a living knowledge doc capturing what you've learned in this session.
Its purpose is to survive context compaction and to hand knowledge to other
agents (and future you) working on the same thing.

## Where it goes

Put it in the repo's `tmp/` **only if that directory is gitignored**
(`git check-ignore -q tmp`); otherwise use a global
`/tmp/<repo-or-project-name>/`, creating it if needed. Never commit the
doc, and tell me which path you chose.

Name it `knowledge.md`. If it already exists, **update it in place**:
revise stale claims, add what's new, delete what's now wrong. If it's
obviously from a different project, just replace it. Note the date of
the current state.

## What goes in it

Write for a competent agent who has never seen this session, so don't
reference "our conversation" or assume shared context. Favor durable,
hard-won specifics over restating what the code already says. Good material:

- Current state: what's done, what's in flight, where it lives (branch,
  commits, files), and the exact commands that verify it.
- How the design ended up this way, and directions explored and rejected,
  with the reason so nobody re-litigates them.
- Traps and surprises: bugs that took real debugging, non-obvious invariants,
  tooling/build quirks, anything that cost you time. Be specific enough to
  act on.
- Decisions made with the human, and any judgment calls left open for them.
- Open follow-ups and known limitations.

Skip anything a reader can trivially get from the code, git history, or the
repo's own docs. This doc is working knowledge, not rationale-for-review, so
if the repo has a separate reviewer-facing changelog, keep the two separate.

Keep it organized under headings and skimmable. A short doc that earns every
line beats an exhaustive one, so let length follow the material.

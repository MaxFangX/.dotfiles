---
name: complain
description: >-
  File a one-line complaint when a tool, doc, permission, or workflow fails or
  wastes your time, so the human can fix it later. Use whenever you hit
  avoidable friction mid-task; file it and move on, don't stop the task.
---

# Complain

`complain` is a global log of friction that agents hit while working.
Complaints accumulate; the human sweeps the log now and then and fixes
everything in a batch. Filing is cheap and never interrupts your task.

## When to file

File when you hit something the human could fix once so no agent hits it
again:

- A tool crashes, hangs, or returns a misleading result.
- A permission prompt or sandbox rule blocks an obviously routine command.
- A skill, CLAUDE.md, or README says something wrong or missing that cost
  you a detour.
- A workflow has an avoidable manual step, flaky test, or slow path.
- The environment is missing a tool or has a broken config.

Don't file "this was hard" or "the task was ambiguous". A complaint needs
to point at something concrete that could be changed.

## How to file

Right after the friction, in one line, with the cause and the fix if you
know it. Add `-c` with a short category when one is obvious:

```
complain -c tool-failure "jj-hunk-tool panics on hunk headers with tabs"
complain -c docs "paseo skill says --detach; the flag is --background"
complain -c permissions "cargo clippy needs approval every run"
```

Suggested categories: `tool-failure`, `docs`, `permissions`, `workflow`,
`env`. Free-form is fine.

Then carry on with the task. Don't wait for anything and don't fix the
underlying issue unless it is in scope.

Context (cwd, repo, branch, which agent you are) is captured
automatically.

## Reviewing the log

Only when asked to sweep or review complaints:

```
complain list             # unresolved, newest last
complain list --json      # raw records, one per line
complain resolve 3 5      # mark fixed
complain clear            # archive resolved entries
```

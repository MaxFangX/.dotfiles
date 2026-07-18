---
name: jj-rebase
description: >-
  Rebase the current workspace's branch onto master using jj, then git switch
  to the branch. Use when the user asks to jj rebase this branch or workspace
  onto master.
---

First, read the /jj-surgery skill.

Then, identify the branch associated with this workspace (usually it matches
the workspace name) and use jj to rebase this branch onto master. You may stop
and ask me here if unclear.

Once done, git switch to the branch (instead of staying at jj's detached HEAD).

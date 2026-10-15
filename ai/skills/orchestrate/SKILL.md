---
name: orchestrate
description: Fan work out to long-running worker agents through Paseo instead of Claude Code's Task tool. Use when delegating work that may outlive one sitting, needs its own jj workspace or git worktree, or must survive the user stopping agents — "spawn workers", "fan out", "orchestrate", "delegate in parallel", "run these in the background".
---

# Orchestrate

Workers are Paseo agents, created with `create_agent`, not Task agents from
the Agent tool. A Task child dies for good when the user presses Stop on
you, even while you are idle waiting on it: Claude Code marks it
user-stopped and refuses to resume it. A Paseo agent is a full session. It
survives Stop, archive, app quit, and daemon restart; the user can open it
as a tab, read it, and steer it; `send_agent_prompt` resumes it with its
context intact. Read the **paseo** skill for the tool reference.

## Which mechanism

- **Paseo agent**: anything that may outlive this sitting, needs its own
  workspace, or the user may want to inspect or pause. Multi-hour
  implementation work is always this.
- **Agent tool**: short read-only lookups that finish inside the current
  turn (an Explore search). Never for work the user may need to pause.

## Spawning a worker

1. **Launch config.** Call `list_profiles` and materialize the best profile
   into `create_agent` as the paseo skill describes. Set `settings.modeId`
   at creation; a worker without a mode bounces every permission request
   to you as a notification.
2. **Workspace.** The worker owns its directory exclusively.
   - jj repo: from the repo, run
     `just -g workspace add <abs-dir> --no-paseo` to create the colocated
     jj workspace and bookmark, then
     `create_workspace { isolation: "local", path: <abs-dir>, projectId }`
     with your own workspace's `projectId` from `list_workspaces`. Do not
     use worktree isolation here: it makes a git worktree jj does not know
     about.
   - git-only repo: `create_workspace { isolation: "worktree", mode: "branch-off", branchName, baseBranch }`.
3. **Brief.** `create_agent` with a `title`, the `workspaceId`, and an
   `initialPrompt` that stands alone; the worker starts with zero context.
   Use the briefing template from the **paseo-handoff** skill: task,
   context, relevant files, acceptance criteria, constraints. Add two
   standing instructions: end the final message with a line starting
   `DONE:` summarizing what landed, and keep Agent tool use short because
   those children do not survive a Stop.
4. Leave `notifyOnFinish` on. Do not poll `list_agents` or
   `get_agent_status`; the notification arrives on its own.

## Reading notifications

- **finished**, last message has a `DONE:` line: review its commits in its
  workspace, then integrate or send fixes with `send_agent_prompt`.
- **was stopped**, or **finished** without a `DONE:` line: the user paused
  it. The response is partial. Do not integrate it, re-plan around it, or
  spawn a replacement. Tell the user it is paused and wait; a later
  `send_agent_prompt` continues it where it left off.
- **needs permission**: `respond_to_permission` when the brief covers the
  request, otherwise surface it to the user.
- **errored**: read `get_agent_activity`, then send a follow-up or report.

## Pausing and resuming

Stop on a worker ends its current turn only. Its session, workspace, and
commits persist, and `send_agent_prompt` resumes it. Only its own Agent
tool children are lost, and it redoes those on resume. If you lose track of
worker ids after a compaction, `list_agents` filtered by `cwd` recovers
them.

Leave teardown to the user: `archive_agent` and
`just -g workspace remove` only when asked.

---
name: agent-browser
description: >-
  Drive the agent browser for web research, signups, checkout walkthroughs,
  and testing web apps. On headed hosts it is a shared Brave instance on a
  local CDP port that works with the screen locked; on headless hosts each
  agent gets a private headless Chromium. Use when a task needs a real
  browser. A session's main agent uses the `agent-browser` MCP server, and
  subagents use the `agent-browser` CLI with their own named session.
---

# Agent browser

On a headed host (a Mac or Linux laptop), one Brave instance listens on
`127.0.0.1:9222`. Its profile is separate from the human's main one, and
it keeps running while the machine is locked (not asleep). All agents and
the human share its cookies, so a login made in any tab is available in
every tab.

If nothing answers on the port, run `agent-brave`. It is idempotent and
returns once the port answers, launching the browser if needed; a window
appearing on the human's screen is fine. If it fails, say so and hand it
to the human.

On a headless host (a remote dev box, no display), there is no `agent-brave`
and no shared browser. Instead, both interfaces below launch a private
headless Chromium per session. That suits testing a web app on that box's
own localhost, and basic access to other sites such as docs, but falls
short of most authentication: nothing is shared, so nobody can sign in for
you. Thus a login wall ends the task with a report, and anything that
needs the human's accounts is done from a headed host instead.

## Two interfaces

**MCP server `agent-browser`** (Playwright MCP). For the main agent of a
session. It has one active tab, so before anything else open your own with
`browser_tabs` (action `new`) and stay in it.

**CLI `agent-browser`** (Vercel's). For subagents, or when several agents
must browse at once. The global config already picks the browser (`cdp` and
`pinTab` on headed hosts), so pass only `--session`, on every invocation.
Each session gets its own tab:

```sh
agent-browser --session <name> open https://example.com
agent-browser --session <name> snapshot -i -c
agent-browser --session <name> click @e5
agent-browser --session <name> fill @e7 "text"
agent-browser --session <name> screenshot /tmp/x.png
agent-browser --session <name> tab close && agent-browser --session <name> close
```

`agent-browser skills get core` prints the version-matched usage guide,
and `--full` adds the command reference. Read it the first time you use
the CLI in a session. `close` only disconnects the session, never the browser.

## Rules

- Pick a session name nobody else would (task slug plus a short random
  suffix). The usage guide's `session id --scope worktree` recipe returns
  the same id for every agent in a worktree, so ignore it. Pinning doesn't
  stop a session from switching tabs, so never `tab <id>` into a tab you
  did not open.
- Finish with `tab close` then `close` (CLI) or close your tab (MCP), so
  the browser does not fill with dead tabs.
- Keep snapshots small: `-i` (interactive only), `-c`, `-d <depth>`,
  `--delta`.
- Login walls, captchas, 2FA: stop, leave the tab open and named in your
  report, and hand it to the human. On a headed host they sign in from the
  same window and the session carries on. Never enter the human's own
  credentials.
- Logging out or clearing cookies in your tab logs out every agent.

## Gotchas

- On macOS, one CLI `press` of any key floods the page with keydown
  events until it navigates (vercel-labs/agent-browser#2053). So avoid
  `press`, and instead submit with `fill` and a click on the submit
  control.
- If a site hangs on a long-idle tab, Brave's Memory Saver (Settings >
  System) in this profile is the usual cause.

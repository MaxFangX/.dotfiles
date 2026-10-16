---
name: agent-browser
description: >-
  Drive the shared agent browser, a Brave instance on a local CDP port, for
  web research, signups, and checkout walkthroughs. Works with the screen
  locked. Use when a task needs a real browser session: a session's main
  agent uses the `agent-browser` MCP server, subagents use the
  `agent-browser` CLI with their own named session.
---

# Agent browser

One Brave instance listens on `127.0.0.1:9222`. Its profile is separate
from the human's main one, and it keeps running while the Mac is locked
(not asleep). All agents and the human share its cookies, so a login made
in any tab is available in every tab.

If nothing answers on the port, run `agent-brave`. It is idempotent and
returns once the port answers, launching the browser if needed; a window
appearing on the human's screen is fine. If it fails, say so and hand it
to the human.

## Two interfaces

**MCP server `agent-browser`** (Playwright MCP attached over CDP). For the
main agent of a session. It has one active tab, so before anything else
open your own with `browser_tabs` (action `new`) and stay in it.

**CLI `agent-browser`** (Vercel's). For subagents, or when several agents
must browse at once. The global config already sets `cdp` and `pinTab`,
so pass only `--session`, on every invocation; each session gets its own
tab:

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
  report, and hand it to the human. They sign in from the same window and
  the session carries on. Never enter the human's own credentials.
- Logging out or clearing cookies in your tab logs out every agent.

## Gotchas

- On macOS, one CLI `press` of any key floods the page with keydown
  events until it navigates (vercel-labs/agent-browser#2053). So avoid
  `press`, and instead submit with `fill` and a click on the submit
  control.
- If a site hangs on a long-idle tab, Brave's Memory Saver (Settings >
  System) in this profile is the usual cause.

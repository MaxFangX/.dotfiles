---
name: mcp-cli
description: >-
  Call a tool on an MCP server that this session does not load, from the
  shell, using the server's existing Claude Code configuration and OAuth
  credentials. Use when a skill names a server (folk, superhuman, ticktick,
  clickup, hey) and no `mcp__<server>__*` tool is available.
---

# mcp-cli

Some MCP servers are configured for Claude Code but never loaded into a
session, so that their tool names stay out of every session's context. They
remain reachable from the shell:

```sh
echo '{"key": "value"}' | mcp-cli <server> <tool>
```

- `<server>` is the name in `claude mcp list`; `<tool>` is the bare tool
  name, without any `mcp__<server>__` prefix.
- Arguments are one JSON object on stdin; use `< /dev/null` for a tool
  that takes none.
- stdout is the tool's payload, often JSON. Write it to a file and `jq` a
  projection into context rather than reading a large result whole.
- Exit 1 reports the failure on stderr. `-v` passes the server's own
  stderr through.
- It only calls tools. There is no `tools/list`, so take tool names and
  parameters from the server's skill (`tools.md` beside its SKILL.md),
  and expect a wrong guess to surface only as the server's validation
  error.
- OAuth servers share Claude Code's stored credentials, refreshed in
  place. A server that has never been signed in to needs one
  `claude mcp login <server>` first.

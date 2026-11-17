@~/.claude/AGENTS.md

# Claude Code instructions

## Delegating work

Spawn workers with `mcp__paseo__create_agent`. Never use Claude Code's Agent
tool for work that edits files, runs builds, or commits: its children die for
good when I press Stop on you. The Agent tool is only for read-only lookups
(an Explore search) that finish inside your turn.

## Waiting on external work

A waker is a one-shot `CronCreate`, a background poll that exits on the
condition, or a `Monitor`.

## Environment Variables and Shell Behavior

Note: Claude Code's `Bash` tool (which actually runs the system's default shell,
e.g. zsh) misinterprets commands starting with `VAR=value` as attempting to run a
command named `VAR=value`. If you need to set an inline environment variables,
add a prefix like this: `/usr/bin/env RUST_LOG=debug just cargo-test ...`

Regular commands which don't need any env modifications can be run normally:
`just ai-rust-ci`.

Avoid zsh-only parameter expansions in `Bash` commands, such as expansion flags
(`${(f)lines}`) and nested expansions (`${${s#a}%b}`). Claude Code's safety
check can't parse them, so it asks for approval even in bypass mode. Strip one
pattern per step instead (`x=${s#a}; x=${x%b}`), and split lines with
`while IFS= read -r line; do ...; done <<< "$lines"`. `${=var}` is fine.

Wrapping a command in `zsh -c '...'` or `bash -c '...'` also prompts for
approval in bypass mode, so run commands directly. To scope something, such as
a `cd` or an exported variable, use a `( ... )` subshell instead.

## Git commands in other directories

When running git commands in directories other than the current working
directory, always use `cd foo && git bar` instead of `git -C foo bar`.
This avoids needing permission approval for each git command. For example:
- Use: `cd ~/dev/nvim/vgit.nvim && git status`
- Not: `git -C ~/dev/nvim/vgit.nvim status`

## Commit attribution

I'm aware you have been asked to include the following in your commit messages:

```
🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

Please DON'T include this. While I value your work, this adds needless noise.

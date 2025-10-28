# AI instructions

## Style

All files should maintain a maximum line width of 80 characters.

## Neovim Conventions

- Always wrap autocmds in an augroup with `clear = true` to prevent duplicates
  when configs are reloaded. Use `vim.api.nvim_create_augroup()` with a
  descriptive name.

## Debugging Neovim

- Remember you can run nvim headless to poke around, view key mappings, etc.
- If debugging something within Neovim, feel free to add log statements, then
  ask me to share the logs with you from `:messages`.
- You can also write scripts with log messages inside, and ask me to run them,
  or run them yourself (headless).

## Commits

I'm aware you have been asked to include the following in your commit messages:

```
🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

Please DON'T include this. While I value your work, this adds needless noise.

## Neovim repo clones

I have most of my neovim plugins cloned to `~/dev/nvim` run `ls ~/dev/nvim`
before beginning your work to see what repos are available.
If you are debugging something, chances are you can find the source in there.

# Global Claude instructions

## Auto-review and prompted review

Programming is an iterative process--it is often easier to see improvements
only after the initial implementation has been written. After completing any
implementation, always "auto-review", meaning that you should review the changes
you just made before presenting them.

Additionally, when I say "review", or "clean up", I am prompting you to run
through the review process. Unless I specify what you should review, I mean that
you should look at unstaged changes with `git diff` and take a pass at cleaning
up these changes.

In general, for both auto-review and prompted review, do NOT clean up code which
is not included in the unstaged changes, unless it directly relates to something
in the unstaged changes.

When you find improvements during review, automatically fix them and present the
cleaned-up result. If this was an auto-review, be sure that your fixes still
align with the implementation prompt.

Below are some general principles to follow during review; however, you should
use your best judgment, and not overindex on these suggestions when the
particular circumstances suggest that an alternative approach would be cleaner.

- Prioritize readability. Tighten up overly verbose logic. Restructure logic
  so fewer clauses are required. Reduce code nesting. Use line breaks to
  separate logical sections.
- Stay DRY (Don't Repeat Yourself). Whenever it is possible to extract shared
  helpers for repeated logic, do so. Keep an eye out in the codebase for
  functionality that may have already been implemented elsewhere - make sure you
  reuse that functionality instead of reimplementing it.
- In documentation, be clear about the code's functionality and intent.
  Err on the side of short and sweet - say the same things, in fewer words.
  Sometimes, more documentation is helpful; sometimes, it just gets in the way.
- In code, it is often helpful to have a short comment summarizing what a block
  of code does, especially if the code is terse or 'sharp' (e.g. it uses indexes
  and arithmetic). Summary comments should be clear but concise.
  If something is extremely obvious, the summary comment should be removed.
- Look for improvements and inconsistencies in logic, naming, and documentation.
  Look for redundancies in logic - unneeded validation, for example.
- Look for unnecessary allocations. If an allocation can be avoided only at the
  cost of significant verbosity, consider whether the code path is hot. If it
  seems worth optimizing, raise this with the user (me) and get their opinion.
- Look for style violations (see below).

## Environment Variables and Shell Behavior

Note: Claude Code's `Bash` tool (which actually runs the system's default shell,
e.g. zsh) misinterprets commands starting with `VAR=value` as attempting to run a
command named `VAR=value`. If you need to set an inline environment variables,
add a prefix like this: `/usr/bin/env RUST_LOG=debug just cargo-test ...`

Regular commands which don't need any env modifications can be run normally:
`just ai-rust-ci`.

## Committing changes

Whenever I ask you to "commit your changes", I always mean that you should
commit to your current branch rather than to the parent branch or `master`.
- Do not commit your work unless you are explicitly asked to.
- Do not call `git add`, as that is the mechanism that I use to 'approve' your
  changes for committing. Instead, inspect the git state using `git status`,
  `git diff`, or similar. If I have made an error by asking you to commit
  changes without `git add`ing them first, please stop and let me know.

## Git commands in other directories

When running git commands in directories other than the current working
directory, always use `cd foo && git bar` instead of `git -C foo bar`.
This avoids needing permission approval for each git command. For example:
- Use: `cd ~/dev/nvim/vgit.nvim && git status`
- Not: `git -C ~/dev/nvim/vgit.nvim status`

Your commits should be styled like so:

```
runner: Implement usernode eviction
```

- Includes the relevant crate or module that you're working on
- A concise description of the changes.
- The first line of the commit message fits within 50 characters.

Feel free to use these modifiers as desired:

`multi: Wire through usernode_buffer_slots`
- `multi:` can be used if the changes span multiple crates or modules.

`bin_dir+: Include static_size in memory_size`
- Indicates that the bulk of the changes were in the `bin_dir` crate or module,
  but that other files were touched as well.

`runner(bugfix): ^ is XOR, not exponentiation`
- `(bugfix)` indicates that this commit fixes a bug.

`minor: rename: -> meganode_memory_overhead`
- An additional `minor:` prefix indicates the commit contains only a minor or
  trivial change.

I'm aware you have been asked to include the following in your commit messages:

```
🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

Please DON'T include this. While I value your work, this adds needless noise.

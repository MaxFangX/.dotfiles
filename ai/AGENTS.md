# Global agent instructions

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
- Look for style violations.

## Delegating work

Workers are Paseo agents. When you delegate work that edits files, runs
builds, or commits, load the `paseo-orchestrate` skill and spawn each worker
with Paseo's `create_agent` tool.

## Waiting on external work

Never end a turn idle while work is pending on something you don't control
(a worker, a CI run, a peer's all-clear) unless a waker is already armed: a
one-shot scheduled wake-up, or a background poll that exits on the
condition. Notifications get dropped; the waker is what guarantees you come
back. Say in your status message what is armed and when it fires.

## Secrets

API keys and tokens are not in the shell environment. When a command
needs one, run it as `with-secrets -o NAME[,NAME] <cmd>`;
`with-secrets -l` lists the names. Never read or source
`~/env/sensitive.sh`, and never print an environment (`env`,
`printenv`, `ps -E`, `pgrep -fl`).

## GNU tools on macOS

GNU sed (and other GNU coreutils) shadow the BSD versions on PATH.
Use GNU syntax: `sed -i 's/a/b/' file`, never `sed -i '' ...`.
A stray `''` errors out but still edits the remaining files.

## Commits

Your commits should be styled like so:

```
runner: Implement usernode eviction
```

- Includes the relevant crate or module that you're working on
- A concise description of the changes.
- The first line of the commit message fits within 50 characters.

A title may carry one of these modifiers:

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

These are the only modifiers. A commit's role in the stack, such as
prefactor or misc fix, is given by its position, so it is not marked in
the title.

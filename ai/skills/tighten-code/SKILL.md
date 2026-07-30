---
name: tighten-code
description: Tighten code added or modified on the current branch for elegance, architecture, readability, reuse, minimal state, and naming. Use for a focused structural code-cleanup pass.
---

# Tighten code

Tighten the *code* added or modified on the current branch.
(For a comment pass, run `/tighten-comments`; for both, run `/tighten`).
Be skeptical and thorough.
Make changes tight, focused, and minimal—but well-documented with concise,
informative comments.
Scrutinize how everything is structured, and architect things in the cleanest,
highest leverage per LOC written way.
Run this inside a single subagent to keep the token-heavy reading (the diff,
surrounding code, and examples) out of the main context, then relay its
summary.
The subagent applies the improvements directly and does not spawn further
subagents.

## Principles

### Elegance

Did the change leave the system with the most elegant design that would have
emerged if the change had been a foundational assumption from the start? If not,
refactor the code to achieve that design.

### Architecture

Scrutinize the overall structure. Are the right abstractions in place?
Could things be restructured to be simpler, more composable, or higher leverage?
Question whether each type, trait, and module boundary is earning its keep.

### Readability

Prioritize simplicity and readability above all else.

- Tighten overly verbose logic.
- Restructure logic to reduce clauses and nesting.
- Use line breaks to separate logical sections.

### DRY (Don't Repeat Yourself)

- Extract shared helpers for repeated logic.
- Check the codebase for existing functionality—reuse it instead of
  reimplementing.

### Minimize State

**The number of cases that need to be handled explodes combinatorially as
state increases.**
Keep state to an absolute minimum. Lean on the type system as much as possible.

Scrutinize every stateful field and parameter.
Do we really need it?
For `Option<_>`s, can the `None` case be handled entirely outside,
during init?

Use fallible initialization to prune the state space.
Instead of adding an `enabled: bool` field to a struct, wrap the entire struct
in an `Option<_>`. The struct then operates on already-pruned state—it no longer
has to handle the case where it's disabled.

Be maximally expressive with our types.
Nonsense states should not be representable.
If two fields always exist together or never exist at all, make them a single
field like `Option<(Foo, Bar)>` instead of separate `Option<Foo>` and
`Option<Bar>` fields.

### Naming

Look for improvements and inconsistencies in naming.
Names should be clear, consistent, and follow codebase conventions.

### Documentation

When writing documentation, prioritize clarity and precision above all else, but
err on the side of brevity. Document the code's functionality and intent.
More documentation isn't always better—sometimes it just gets in the way.
This pass covers docs only at a high level; see `/tighten-comments` for detailed
instructions for tightening comments.

---
name: tighten
description: Tighten both code and comments added or modified on the current branch. Use for a full cleanup pass that runs the code standards review before the comment review.
---

# Tighten

Tighten both the code and the comments added or modified on the current branch
by running two focused passes in sequence:

1. Invoke the `/tighten-code` skill for the code pass (review principles
   plus the full code standards rulebook, from formatting and idioms to
   structure, state, and invariants).
2. Then invoke the `/tighten-comments` skill for the comment pass (summary
   comments, clause-by-clause tightening, references, TODO/`compat:` formats,
   professionalism).

Run code first: restructuring logic often rewrites or removes the very comments
the second pass would otherwise polish.
Once both passes finish, report a single combined summary.

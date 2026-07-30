---
name: tighten
description: Tighten both code and comments added or modified on the current branch. Use for a full cleanup pass that runs the structural code review before the comment review.
---

# Tighten

Tighten both the code and the comments added or modified on the current branch
by running two focused passes in sequence:

1. Invoke the `/tighten-code` skill — the structural pass (elegance, architecture,
   readability, DRY, state minimization, naming).
2. Then invoke the `/tighten-comments` skill — the comment pass (summary comments,
   clause-by-clause tightening, references, TODO/`compat:` formats,
   professionalism).

Run code first: restructuring logic often rewrites or removes the very comments
the second pass would otherwise polish. Each skill runs its review in its own
subagent, so this orchestrator just chains them.
Once both finish, relay a single combined summary.

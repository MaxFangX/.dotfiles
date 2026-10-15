---
name: lexe-way
description: Make any code read as if a senior Lexe engineer had written it by hand, by finding the precedents and past review feedback for each thing the code does and mirroring them in names, structure, and the way each problem is solved. Use when asked for a "lexe way" pass on whatever is pointed at (a file, module, commit, or branch).
argument-hint: [scope: whatever is pointed at; defaults to the code added or modified on the current branch]
---

# The Lexe way

Scope: **$ARGUMENTS**. The scope is the code being cleaned up, whatever was
pointed at, such as a file, a module, a commit, or a whole branch. With no
argument, it is the code added or modified on the current branch.

Lexe's engineering standards are mostly implicit. They live in the code
senior engineers have written and in the feedback they have given. No
document can enumerate them: they shift as the codebase evolves, so any
snapshot goes stale, and most of them are small choices that apply only in
specific circumstances, so any listing short of vast is incomplete. The
documented parts (`/tighten-code` and `/tighten-comments`, among others) are
inputs, not the source. The source is precedent: for each thing the code
does, what did senior engineers do when they did the same thing, and what
did they ask others to change? Find that and mirror it. Everything is on
the table, from names and structure to the way a problem is solved: when
precedent shows a simpler or better way to do what the code does, take it.

## Usage guide

Work through the steps below. Fix directly, and only within the scope.

## 1. Inventory what the code does

Read the code and list what it does as *categories*, not as its feature. A
category is anything that could have been done another way and has probably
been done before, at any level of size: a retry loop, a request type, a
coined term, a test harness, an error-handling convention, a module layout,
or, for a branch, the way it is cut into commits, to name a few. Most
categories have appeared somewhere in the repo already.

## 2. Gather precedents and feedback

For each category from the inventory:

- **The nearest siblings.** The items beside the new one, whatever holds
  them (the same trait, struct, module, command list, and so on), show how
  this repo does that. Diff the new item against them.
- **The shared crates.** The `lexe-*` crates that most of the workspace
  depends on (`lexe-std`, `lexe-common`, `lexe-tokio`, `lexe-api-core`, and
  their kin) hold Lexe's standardized, opinionated APIs for a subset of what
  every service does, such as retrying, backing off, spawning and shutting
  down tasks, representing time and amounts, and building API errors. Where
  such an API exists it settles the category outright: use it instead of
  anything hand-rolled. It usually doesn't, though. Most categories have no
  categorical answer, only similar problems the repo has solved in similar
  ways, and finding those is what the siblings and the history are for.
- **History and review.** For whatever the siblings and shared crates leave
  unsettled, invoke `/learn-from-examples` with a goal that names those
  categories, batched into one goal where they are related. Include the
  scope's paths or commits, so the collector can compare the code against its
  precedents. Among the references it returns, reviewer feedback says what
  was not good enough and what replaced it, so give it the greatest weight.
  How deep to dig is a judgment call: a one-line change rarely needs
  history; a new subsystem usually does.

From these, infer the standard for each category. Where the repo disagrees
with itself, note both sides.

## 3. Decide with evidence and judgment

Precedent is evidence, not a verdict. A reviewer's comment was about one
piece of code under its own constraints, and a sibling was written for its
own situation, so a precedent applies here only if the conditions that made
it right there also hold here. Check that for each change. Some precedents
look applicable and fail on inspection; for instance, a guard another module
needed is unreachable here by the API's contract, or a helper's semantics
differ in a way this code relies on. Construct that failure concretely and
record the precedent as rejected. Weigh, as a senior engineer would, instead
of pattern matching.

Every change that survives cites its precedent, whatever form it takes: a
sibling, a helper, a reviewer comment, a commit. Where precedents disagree,
prefer the more recent, since standards change; among equals, prefer the
nearest sibling. Flag the call either way.

Some precedents change what the code does, not just how it reads: a
hand-rolled loop replaced by the house helper gets its cadence, a state
machine reshaped after a sibling drops a case that could never happen. These
are often the biggest improvements available, so make them. Two courtesies to
the user, who knows what callers depend on better than the code shows: keep
each behavior change apart from the cosmetic changes, so it can be judged and,
if need be, declined on its own, and put them at the top of the report.

Name and refer to things the way the repo already does. A term the team has
already learned beats a new term for the same concept, which everyone would
then have to learn. When something is genuinely new, don't stretch an existing
name over it, since that breeds ambiguity; pick the name whose connotations
best convey what it is.

## 4. Change and review

Review the result by the standard of step 3, so that findings rest on
evidence and judgment the same way the changes did. Otherwise the review
becomes a second opinion on taste.

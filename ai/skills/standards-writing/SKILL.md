---
name: standards-writing
description: Write or revise a skill or instruction file that defines standards, such as a tighten skill or the comment rules in AGENTS.md. Use when creating or editing one.
---

# Writing standards

A standards document is a skill or instruction file that defines standards,
such as `/tighten-comments` or the comment rules in `AGENTS.md`. It is read
by a competent AI that has the document and its task in front of it. The
reader does not have the incidents that prompted a rule, the author's intent
beyond what is written, or the conversation in which the document was
drafted. Every sentence occupies context on every task the document is loaded
for, so each one must earn its place, and the reader applies each sentence as
written. A reader who knows what the document is for handles the cases it
never named, so encode the intent and the tests to apply, not a catalog of
cases. Don't advise caution the reader already has, and don't prescribe what
ordinary practice already covers, such as how changes land in version
control.

An AI drafting standards defaults to cataloging cases, hedging, and appending
exceptions, so this skill is biased toward fewer sentences and sharper tests.
When unsure, cut the sentence.

## Intent and bias

A standards document exists to override a default. An AI's default is too
many comments, so `/tighten-comments` is biased toward cutting. Name the
default and the bias, and keep the bias intact when editing. A reader already
inclined to keep something reads a rule that permits keeping it as permission,
so one loosely worded exception can undo the document. Give the bias a
tie-breaker where close cases cluster, as in "When unsure, cut."

## Stating rules

- State a rule as a test the reader can apply, with its threshold. "A
  function gets a label only when what it does is not immediately clear from
  its name and signature" can be applied as written. "A label is fine when
  mildly redundant" is applied by feel, and the reader's feel is the default
  the document exists to override. "Not immediately clear" and "unclear" set
  different bars, so choose the threshold phrase deliberately.
- Define each term a test relies on, once, where it is first used, and use it
  consistently. A test on whether a comment is "derivable" must say whether
  intent counts, or the reader counts only mechanics and cuts every comment
  that says why.
- Quantifiers are read literally. "Only a comment that restates a call is
  derivable" says nothing else may be cut, and "always keep" forbids
  judgment, which is right only where the document means to forbid it. Check
  what each "only", "always", "never", and "most" implies beyond the case in
  mind.
- Don't present an assumption as a finding. "A pass with few deletions has
  under-deleted" can't be verified by the reader, who will act on it anyway.
  Keep a descriptive claim only when it is known to hold.
- Say each thing once. Before adding a sentence, check whether another
  section already implies it. Two phrasings of one rule make the reader
  reconcile them and look for a difference that isn't there.
- An exception that can't be stated without weakening the main test is left
  out. One that can is a clause in that test, not a section of its own.
- Length follows frequency and importance. Explaining a good rule clearly is
  worth the space; restating and hedging are not.

## Examples

- An example conveys a test better than a definition can, if it is
  unmistakable, meaning that the code is short and plain, the point is the
  only thing the example could be showing, and a reader with no context draws
  the same conclusion.
- Prefer one unmistakable example to several that each need explaining. A
  second example earns its place when it shows a different failure of the
  same test.
- An example may be invented, informed by real incidents.
- Introduce an example with "For example," or with a lead-in that states the
  contrast it shows, such as "Here the code shows that we skip, but not
  why:". A trailing verdict such as "so the comment stays" is a sign the
  example did not make the point on its own, so fix the example instead.

## Writing

Every standards document is held to `/tighten-comments`. It is written for
code comments, but its principles apply to the document's prose as well, and
a document about writing is also held to every rule it imposes. A phrase made
up for the occasion, such as "plain from the code", has no fixed meaning for
the reader. The register is neither casual, as in "stays" and "goes" for keep
and cut, nor pedantic. Parallel cases are a list, and a paragraph holding two
topics is two sections, so the reader can scan.

## Process

1. For a revision, find the pattern behind the incidents that prompted it.
   Before adding a case, look for a missing definition in an existing test, a
   threshold set in the wrong place, or a claim that was never checked. For a
   new skill, name the default it overrides and write the `description`
   first. It is the only text the harness reads before loading the skill, so
   state what the skill does and when to use it, in one or two sentences.
2. Where a sentence sets a test or threshold, drafting it in several framings
   and comparing them is the reliable way to find the one most likely to
   produce the behavior. This can happen in your reasoning or in the chat.
3. Simulate the reader: an AI that has the document and a task, and none of
   the conversation behind it. For each sentence, ask what that reader is
   likely to think and do, and whether that is what you want. Where it is
   not, or where the sentence can be read two ways, look for the wording that
   makes the intended reading the likely one and the misreadings unlikely.
   The common failures are a sentence that forbids a good action and one that
   permits the default.
4. Re-read the whole document, not only the diff, for redundancy and
   contradiction, and audit it against its own rules. A rule stated both in a
   skill and in `AGENTS.md` or another skill changes in both.
5. The programmer reviews in context and may cut, so say which edits you are
   confident in, which you are not, and where you disagree with a requested
   one.

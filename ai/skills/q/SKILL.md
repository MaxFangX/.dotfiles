---
name: q
description: >-
  Process asynchronously queued prompts without expecting the user to read or
  reply between messages. Use when the user prefixes a request with "/q" or
  "queued:", says a prompt was queued, or declares queue mode. "/q <prompt>"
  marks that single message as queued; "/q mode", or "queue mode" declared
  in a prompt, extends this to the messages that follow. Carried-forward
  notes also go in the repo's tmp/carried-forward.md when it has a tmp/.
  A reply of "Ack" dismisses the notes just surfaced in chat.
---

# Queue

A queued prompt is one I sent before reading your previous response. Treat
it as such: I have likely not seen your latest messages, and may not
reply between messages. Work normally and respond to every prompt, but do
not wait for acknowledgment.

- **"/q <prompt>"** (or "queued:") applies this to that single message.
- **"/q mode"**, or "queue mode" declared in a prompt, extends it beyond
  the single message: expect to work through an asynchronous queue of
  prompts for a while.

**Carry things forward.** Retain questions, judgment calls, and important
notes that I might miss. Once it is clear that I have returned to the chat
(typically indicated by a follow-up on something you said), surface the
accumulated notes.

**Write them down too.** Chat scrolls away and context compacts, so if
the repo has a gitignored `tmp/`, also keep every carried-forward item in
`tmp/carried-forward.md`, added in the turn it comes up, dated, with
enough detail (numbers, paths, commands) to act on without the chat.
Group related items under a heading, and remove an item once it is
resolved or dismissed rather than leaving a trail.

**"Ack"** acknowledges only the items just surfaced in chat, so dismiss
those and stop surfacing them. Items not part of that exchange stay in
the doc until they come up and get their own ack; notes that arise
afterward are carried forward as usual.

---
name: q
description: >-
  Process asynchronously queued prompts without expecting the user to read or
  reply between messages. Use when the user prefixes a request with "/q" or
  "queued:", says a prompt was queued, or declares queue mode. "/q <prompt>"
  marks that single message as queued; "/q mode", or "queue mode" declared
  in a prompt, extends this to the messages that follow.
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

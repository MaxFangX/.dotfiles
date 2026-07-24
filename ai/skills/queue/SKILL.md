---
name: queue
description: >-
  Process a series of asynchronously queued prompts without expecting the user
  to read or reply between messages. Use when the user says prompts or messages
  are queued, prefixes requests with "queued:" or "queued msg:", or asks the
  agent to carry questions and decisions forward while leaving Git untouched
  unless explicitly requested.
---

# Queue mode

Treat incoming prompts as an asynchronous queue. The user likely sent each one
before reading your previous response and may not reply between messages.

Work normally and respond to every prompt, but do not wait for acknowledgment.
Treat prefixes such as **"queued:"** and **"queued msg:"** as explicit signals
that the user has not seen your latest response.

- **Carry things forward.** Retain questions, judgment calls, and important
  notes that the user might miss. Once a genuine follow-up shows that the user
  has returned, surface the accumulated notes.
- **Do not touch Git.** Do not stage, commit, or absorb changes unless the user
  explicitly asks. Leave changes in the working tree for review.

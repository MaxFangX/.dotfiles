#!/usr/bin/env node
// Register <dir> as a paseo workspace of the project owning <main-repo-root>,
// printing the new workspace id on stdout.
//
// Since paseo 0.2 (upstream #2098), an externally created worktree that paseo
// first sees by path becomes its *own* project, detaching it from the repo's
// other workspaces. That is intended for folders added in the app, but our
// worktrees are cut from a repo paseo already knows. `workspace.create.request`
// accepts an explicit projectId; `paseo run` has no --project flag, so we
// pre-create the record here and let the caller attach with --workspace.
//
// Speaks the daemon's websocket protocol directly (plain JSON frames; session
// requests are wrapped as {type: "session", message}), like paseo-archive.mjs.
// Best-effort: prints nothing and exits 0 when the daemon is unreachable or the
// project can't be resolved, leaving the caller to fall back to a plain run. A
// daemon-side creation error is echoed to stderr so the fallback isn't silent.
//
// Usage: paseo-register.mjs <dir> <main-repo-root>

import { randomUUID } from "node:crypto";
import path from "node:path";
import process from "node:process";

if (!process.argv[3]) process.exit(0);
const target = path.resolve(process.argv[2]);
const mainRoot = path.resolve(process.argv[3]);

const exit = (code, id) => {
  if (id) console.log(id);
  process.exit(code);
};
setTimeout(() => exit(0), 5000).unref();

let ws;
try {
  ws = new WebSocket("ws://127.0.0.1:6767/ws");
} catch {
  exit(0);
}
const send = (message) => ws.send(JSON.stringify({ type: "session", message }));

ws.onerror = () => exit(0);
ws.onclose = () => exit(0);
ws.onopen = () => {
  ws.send(
    JSON.stringify({
      type: "hello",
      clientId: "cid_workspace_add_register",
      clientType: "cli",
      protocolVersion: 1,
    }),
  );
  send({ type: "fetch_workspaces_request", requestId: "req_fetch" });
};

ws.onmessage = (ev) => {
  let msg;
  try {
    msg = JSON.parse(ev.data);
  } catch {
    return;
  }
  const inner = msg.type === "session" ? msg.message : null;

  if (inner?.type === "fetch_workspaces_response") {
    const entries = inner.payload?.entries ?? [];
    // Reuse an existing record for this directory, if any.
    const existing = entries.find((w) => w.workspaceDirectory === target);
    if (existing) exit(0, existing.id);
    // Find the project by way of the main repo's own workspace — the same
    // fallback paseo uses to home the worktrees it creates itself.
    const source = entries.find((w) => w.workspaceDirectory === mainRoot);
    if (!source?.projectId) exit(0);
    send({
      type: "workspace.create.request",
      // Since paseo 0.9.1 the daemon persists creation results by request id and
      // rejects a reused id with a different payload (workspace_request_key_conflict),
      // so the id must be fresh per invocation.
      requestId: `req_create_${randomUUID()}`,
      source: { kind: "directory", path: target, projectId: source.projectId },
    });
  } else if (inner?.type === "workspace.create.response") {
    const id = inner.payload?.workspace?.id;
    if (!id) console.error(`paseo-register: ${inner.payload?.error ?? "workspace.create failed"}`);
    exit(0, id);
  }
};

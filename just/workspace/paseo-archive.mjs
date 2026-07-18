#!/usr/bin/env node
// Archive the paseo workspace record for a removed directory so it leaves the
// app's workspace list immediately. As of 2026-07-18, the daemon only notices a
// missing directory when something refetches the workspace list (e.g. clicking
// around in the UI), so without this poke the stale record lingers.
//
// Speaks the daemon's websocket protocol directly (plain JSON frames; session
// requests are wrapped as {type: "session", message}), so it needs no paseo
// client library — just Node >= 22 for the built-in WebSocket. Best-effort:
// exits 0 silently when the daemon is unreachable or has no matching record.
//
// Usage: paseo-archive.mjs <dir>

import path from "node:path";
import process from "node:process";

if (!process.argv[2]) process.exit(0);
const target = path.resolve(process.argv[2]);

const exit = (code, msg) => {
  if (msg) console.log(msg);
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
      clientId: "cid_workspace_remove_cleanup",
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
    const entry = entries.find((w) => w.workspaceDirectory === target);
    if (!entry) exit(0);
    send({
      type: "archive_workspace_request",
      workspaceId: entry.id,
      requestId: "req_archive",
    });
  } else if (inner?.type === "archive_workspace_response") {
    exit(0, `Archived paseo workspace record for ${target}`);
  }
};

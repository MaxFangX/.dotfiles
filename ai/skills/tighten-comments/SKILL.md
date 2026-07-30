---
name: tighten-comments
description: Tighten code comments added or modified on the current branch for brevity, clarity, durable context, ownership, and project conventions. Use for a focused comment and documentation cleanup pass.
model: sonnet
---

# Tighten comments

Review code comments (public and private) added or modified.
Be skeptical, and thorough.
Make sure comments are helpful and information-dense, but space-minimized and
concise.

## Guidelines

### Contextual and Semantic

Ensure that the comment adds value, is coherent, and is consistent with the
code.
For example, some comments are valuable because they add context which isn't
obvious just from reading the code alone.

Examples:

```rust
    let router = Router::new()
        .merge(user_backend_router(state.clone()))
        .merge(user_gateway_router(state.clone()))
        .merge(public_gateway_router(state.clone()))
        // Axum provides no way to route a CONNECT request to a handler in the
        // using a path and MethodRouter (the 'standard' way), since the 'path'
        // is empty and MethodRouter doesn't support CONNECT. Instead, we set a
        // custom fallback which intercepts CONNECT requests and routes them to
        // the node_proxy handler, calling the default fallback otherwise.
        .fallback_service(proxy_or_fallback.with_state(state));
```

```rust
    const LIVENESS_CHECK_INTERVAL: Duration = Duration::from_secs(5);
    let mut liveness_interval =
        tokio::time::interval(LIVENESS_CHECK_INTERVAL);

    // The last N liveness results. If all are Err, we shutdown the LSP.
    const N: usize = 2;
    let mut last_n_results = VecDeque::with_capacity(N);
```

### Summary comments

Short comments above blocks of logic that summarize what the block does.
Even if seemingly redundant, these enable quick codebase navigation without
reading implementation details.
Think of them as docs for blocks within functions.

Examples:

```rust
// Map each output to its replacement (`rp_`) txid and # of confs,
// then find and return the most confirmed of these if one exists,
// filtering out any with missing information.
let maybe_replacement = output_statuses
    .into_iter()
    .filter_map(|output_status| {
        let rp_txid = LxTxid(output_status.txid?);
        let rp_tx_status = output_status.status?;
        let rp_height = rp_tx_status.block_height?;
        let rp_height_diff = best_height.checked_sub(rp_height)?;
        let rp_confs = rp_height_diff + 1;
        Some((rp_txid, rp_confs))
    })
    .max_by_key(|(_txid, confs)| *confs);
if let Some((rp_txid, confs)) = maybe_replacement {
    let conf_status = TxConfStatus::HasReplacement { rp_txid, confs };
    return Ok(conf_status);
}
```

```rust
// data := ""

data.put_u8(version);
data.put(key_id.as_slice());
let plaintext_offset = data.len();

// data := [version] || [key_id]

write_data_cb(&mut data);

// data := [version] || [key_id] || [plaintext]

self.derive_encrypt_key(&key_id).encrypt_in_place(
    aad.as_slice(),
    &mut data,
    plaintext_offset,
);

// data := [version] || [key_id] || [ciphertext] || [tag]
```

### Brevity and clarity

When writing documentation, prioritize brevity above all else, then write to
maximize clarity and precision within the limited space available. More
documentation usually gets in the way, unless there is a specific reason more
documentation is needed.

Comments and docs should be written for a competent future maintainer. Prefer
deletion unless the comment adds information that is hard to infer from names,
types, and nearby code, or prevents a plausible wrong change.

Assume a senior reader who knows the rest of the system but not this area.
Tighten clause by clause, cutting rather than rewording: if A obviously implies
B (from the code below or another clause), state A and cut B.
Keep only the minimum needed to convey what's local and non-obvious: an
invariant, gotcha, or workaround (with the problem it solves).

Examples:

**Old comment**:
```rust
/// Mock settings DB that returns `hasSeenReceiveHint: true`.
/// Use this to test the receive page without the peek hint animation.
```
**Suggested**:
```rust
/// Mock settings DB with `hasSeenReceiveHint: true`.
```

**Old comment**
```rust
// NOTE: This function is only required being pessimistic about the user's
// internet connection.
```

**Suggested**
```rust
// NOTE: Needed for slow connections where data may not be ready immediately.
```

Deletion example: the function body's `match` already shows the no-op/skip
behavior, so narrating it is redundant:

**Old comment**
```rust
/// (Re)installs the SGX target so a toolchain upgrade doesn't break the build.
/// No-op if already installed; skipped when `rustup` isn't on `PATH`.
```
**Suggested**
```rust
/// (Re)installs the SGX target so a toolchain upgrade doesn't break the build.
```

### Write for the future reader

Comments and docs should be written with the assumption that the future reader
lacks access to the context of our current chat session. For example, a bug
fix which was a major achievement for us is completely irrelevant information
for a future reader who lives in a world in which the bug no longer exists and
does not pose any threat; the fixed bug is worth documenting only if it could
plausibly be reintroduced without such a warning. Judge what's worth
documenting based on the future reader's standards, not our own.

Comments and docs should be written from the vantage point of a future reader,
for whom our changes are already history. For example, if we are leaving
behind cruft (such as a redirect from an old URL), documentation should focus
on why the cruft must continue to be kept, rather than our original
justification for the change that introduced it (e.g. "/pricing is a better
and simpler URL than /fees-and-pricing"), unless it is still relevant to the
future reader. Such justifications, oriented towards PR reviewers, should be
written in commit details, discoverable in review and through `git blame`
rather than in permanent documentation, which imposes a maintenance burden.

### Document behavior at its owner

A brief one-line doc comment that labels an item is fine, even if mildly
redundant. Don't expand it into an implementation story about how the value is
produced, refreshed, persisted, synchronized, or consumed. Put behavioral,
lifecycle, and provenance docs at the semantic owner — the type, state machine,
constructor, transition method, API endpoint, or usage site that defines the
behavior. An item comment should describe the item's durable meaning or
contract; if it mostly explains surrounding code's use of the item, move it
there or delete it. Conversely, keep these docs when the item itself is the
state, API contract, or transition being defined — there the behavior is the
item's own contract.

### Keep rationale out of the code

When you want to explain a change beyond what the code itself needs — the
rationale, the alternatives weighed, why it ended up this way — write it to the
repo's rationale outlet, not a code comment, and explain as much as you want.
Prefer a local `ai-changelog.md` if the repo has one; otherwise write to
`/tmp/YYYY-MM-DD-<project>-changelog.md`. It's your space to record reasoning
for the reviewer, kept out of the code and read asynchronously. Feel free to
delete stale entries, especially anything clearly from a previous session.

### Calibrate against examples

Match the rough verbosity and style of nearby comments (peers in the same
struct, enum, module, or scope), unless there is a specific reason this item
needs more. The necessary length of the comment scales with the complexity
of the item documented.

### Professionalism

Comments should maintain a high standard of written English.
They should be grammatically correct, idiomatic, and free of typos.
Comments are essential for maintaining a readable codebase; write them with
care.

### References

Comments that reference existing structs, functions, traits, etc. should link
to the existing code.

Example:

```rust
/// Handles a [`MegaRunnerCommand::UserLeaseRenewalRequest`].
    fn handle_user_lease_renewal_request(
        &mut self,
        req: MegaRunnerUserLeaseRenewalRequest,
        now: TimestampMs,
    ) {
```


### TODO format

Use the TODO format to indicate what needs to be done in the near or long term
future.
Should comply with the other guidelines.

Format: `TODO(username): <description>`

Examples:

```rust
// TODO(a-mpch): Add option to update budget limits, budget restriction type
// (single-use, monthly, yearly, total, etc.).
```

```rust
// TODO(max): Find a way to avoid evicting entries of connected user nodes.
```

```rust
// TODO(max): Deprecated since lsp-v0.8.10. Remove once unused.
```

### Compatibility

Use the compatibility format when serialization changes are made (field
renames, aliases added).

Format: `compat: <change description> in <component>-v<version>`

`component` is either `node`, `lsp`, `app`, `sgx-info`, or `sdk-sidecar`.
`version` is the next version to be released with the change.

Example: Get the latest deployed LSP version:
```bash
git tag -l 'lsp*' --sort=-v:refname | head -1
```

Examples:

```rust
// compat: alias added in lsp-v0.7.0
#[serde(rename = "peer", alias = "external_peer")]
pub external_peer: Option<LnPeer>,
```

```rust
// compat: renamed in node-v0.8.10
#[serde(rename = "fees", alias = "fee")]
pub fee: Amount,
```

## Execution flow

The main agent runs this review inside a single subagent, to keep the
token-heavy reading (the diff, surrounding code, and comment examples) out of
the main context, then relays its summary.

The subagent reviews the comment changes in the current diff following the
Guidelines above: for each added or modified comment it applies them, then
changes, skips, or removes the comment. It reports a concise summary of what
changed and why (and does not spawn further subagents).

If a removed comment holds reviewer-facing rationale worth keeping, don't move
it to another comment — save it to the rationale outlet (see "Keep rationale out
of the code") and note the path in the summary.


## What NOT to do

- Don't review comments unrelated to the PR context.
- Don't force changes.
  The rationale must be strong enough to justify any suggestion.
- Don't remove summary comments just because they restate what the code does.

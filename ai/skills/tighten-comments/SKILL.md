---
name: tighten-comments
description: Tighten code comments added or modified on the current branch for brevity, clarity, durable context, ownership, and project conventions. Use for a focused comment and documentation cleanup pass.
---

# Tighten comments

Review code comments (public and private) added or modified.
Be skeptical, and thorough.

## Guidelines

### Reader effort

The top-level goal, which every rule below serves, is the least total effort to
understand the code, with comments counted as part of the code. A comment sits
in front of the code it describes, so a weak one costs twice: once to read, and
once to check against the code below it. A comment can be accurate and still
fail this test, if understanding it costs more than reading the code. An
argument has to be worked out, so prefer a label ("Early return if the
condition is already satisfied.") to an argument ("Do this before X, so that Y
is not missed").

For most code, the lowest-effort presentation has close to no comments: names,
types, and control-flow structure that are self-describing. Only necessarily
complex code needs more, and sometimes code that seems to need more is only
badly structured, so that a restructure or rename would bring it back to close
to none. So before keeping a comment, ask whether a better name would make it
unnecessary. Rename the item in this pass when every use sits in files already
in the diff; otherwise flag the rename in the summary. Here the comment exists
because `N` is a poor name, and `LIVENESS_WINDOW` would make it unnecessary:

```rust
// The last N liveness results. If all are Err, we shut down the LSP.
const N: usize = 2;
let mut last_n_results = VecDeque::with_capacity(N);
```

### Non-obvious context

Comments that say what a senior engineer would not get from the code. There are
two tiers, and the first is the default.

Not derivable from the code at any effort: an assumption about code elsewhere,
a contract with another system, the behavior of an external library, a choice
that looks like a mistake, or a correct-looking change that no type or test
would catch. Always keep, usually in a sentence or two.

```rust
let router = Router::new()
    .merge(user_backend_router(state.clone()))
    .merge(user_gateway_router(state.clone()))
    .merge(public_gateway_router(state.clone()))
    // Axum normally routes a request to a handler using its path and a
    // MethodRouter, but a CONNECT request has an empty path and
    // MethodRouter doesn't support CONNECT. Instead, we set a custom
    // fallback which intercepts CONNECT requests and routes them to the
    // node_proxy handler, calling the default fallback otherwise.
    .fallback_service(proxy_or_fallback.with_state(state));
```

A fragile invariant is not automatically in this tier. The bar is whether a
senior engineer would notice it from the code as written; a subscribe call at
the very top of a function is plainly meant to come before the reads below it.
Otherwise prefer code that enforces it or a name that states it (see "Execution
flow"), and comment only when it is too subtle for any of these.

Derivable but expensive: a proof, a case analysis, a capacity argument.
Checking a written argument is far cheaper than reconstructing one, so keep it
when reconstructing it would take significant effort. Keep it also when a wrong
change would be found late. If the compiler or a test would catch the mistake,
no comment is needed. If a regtest failure would, probably none. If production
funds or channel state would, keep the comment even though the argument is
derivable.

### Summary comments

Short comments above a block of code that say what the block does. They are doc
comments for blocks within a function.

A summary is redundant by design, so it is justified only by the **leverage
principle**: the summary must be much quicker to read than the block it
summarizes. Keep a summary only when the block is costly to read, meaning that
even a reader who knows the codebase would have to trace through it to say what
it does. If the block's names or first few lines already say what it does, the
reader still reads the code and now reads the comment first as well, so the
summary saves nothing. Cut it. When unsure, cut.

In practice, leverage comes from terse or sharp code: dense iterator chains,
index arithmetic, byte layouts, state threaded through several steps.

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

### Separate clauses with blank lines

Within a function, put a blank line between logical steps. Each step can then
be read on its own, so most need no summary. A step that does need one gets a
short label above it.

### Tighten clause by clause

Write for a senior reader who knows the rest of the system but not this area.
Prefer deletion unless the comment adds information that is hard to infer from
names, types, and nearby code. Tighten clause by clause, cutting rather than
rewording. If the code below or another clause makes it obvious that A implies
B, state A and cut B.

A comment much longer than its peers (in the same struct, enum, module, or
scope) is a sign to cut it, not a sign the peers need more.

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
does not pose any threat, but the fixed bug is worth documenting if it could
plausibly be reintroduced without such a warning. Judge what's worth
documenting based on the future reader's standards, not our own.

Comments and docs should be written from the vantage point of a future reader,
for whom our changes are already history. For example, if we are leaving behind
cruft (such as a redirect from an old URL), documentation should focus on why
the cruft must continue to be kept, rather than our original justification for
the change that introduced it (e.g. "/pricing is a better and simpler URL than
/fees-and-pricing"), unless it is still relevant to the future reader. Such
justifications belong in commit details or the changelog (see "Write rationale
in the changelog or commit message"), not in permanent documentation.

### Document behavior at its owner

A brief one-line doc comment that labels an item is fine when the name and type
leave its meaning open. "Attempts remaining, not attempts made" on `retries:
u32` is worth keeping, while "Client for the user node" on `node_client:
NodeClient` is not. Don't expand a label into an implementation story about how
the value is produced, refreshed, persisted, synchronized, or consumed. Put
behavioral, lifecycle, and provenance docs at the semantic owner, meaning the
type, state machine, constructor, transition method, API endpoint, or usage
site that defines the behavior. An item comment should describe the item's
durable meaning or contract, so if it mostly explains surrounding code's use of
the item, move it there or delete it. Conversely, when the item itself is the
state, API contract, or transition being defined, the behavior is the item's
own contract, so keep these docs on it.

### Scope comments to the code they explain

A comment's position tells the reader its scope: a doc comment speaks for
the whole item, a comment above a statement for that statement, a comment
on one step of a chain for that step. So place a comment on the exact
scope where it applies.

```rust
// BAD placement: a retry detail presented as the method's main description.
/// Retries within [`ACQUIRE_TIMEOUT`]. Notably, a `LeaseRejected`
/// response does *not* stop the retries, since a crash-restarted
/// supervisor must outwait its previous incarnation's unexpired lease.
async fn acquire_runner_lease(
    &self,
    data: AcquireRunnerLeaseRequest,
) -> Result<AcquireRunnerLeaseResponse, BackendApiError> {
    let req = self
        .rest
        .post(format!("{backend}/lexe/acquire_runner_lease"), &data)
        .timeout(timeout::lease::REQUEST_TIMEOUT);
    // GOOD placement: on the exact scope where it applies.
    // A crash-restarted supervisor must outwait its previous incarnation's
    // unexpired lease, so a `LeaseRejected` response does *not* stop the
    // retries.
    let retries = Retries::from_timeout(ACQUIRE_TIMEOUT);
    self.rest.send_with_retries(req, &retries).await
}
```

Another example of comments placed at exactly the scopes they apply to:

```rust
// Meganodes with at least one running usernode whose lease has expired.
let mega_ids_to_evict = self
    .user_leases
    .values()
    // Expired leases
    .filter(|lease| lease.expires_at <= now)
    // That aren't already evicting
    .filter(|lease| !self.user_evicting.contains(&lease.user_pk))
    .map(|lease| lease.mega_id)
    .collect::<HashSet<_>>();
```

### Write rationale in the changelog or commit message

When you want to explain a change beyond what the code itself needs, such as
the rationale, the alternatives weighed, or why it ended up this way, write it
in the commit message or the repo's changelog, not a code comment. The
changelog is your space to record reasoning for the reviewer, kept out of the
code and read asynchronously, so explain there as much as you want. Prefer a
local `ai-changelog.md` if the repo has one; otherwise write to
`/tmp/YYYY-MM-DD-<project>-changelog.md`. Feel free to delete stale entries,
especially anything clearly from a previous session.

### Write comments as forward chains of reasoning

A reader who meets a claim before its justification must remember it without
yet knowing why it holds, then re-read the comment backwards to check the
logic. Thus, order the sentences so each is fully motivated by the ones before
it. Set up the situation, walk through what can happen, and let the rule or
mechanism land as the conclusion. A comment long enough to have structure
should read as a derivation, not a conclusion followed by its reasons.

These rules govern how to order a long comment, not whether to write one.
Reader effort still comes first, so if a competent future reader doesn't need
the justification, cut it rather than chain it. If a forward-chain rewrite
grows a comment noticeably, that's a sign to reconsider whether the
justification is needed at all.

**Old comment** (conclusion first, justification backfilled):
```rust
// `GREATEST` keeps the expiry monotonic, since a renewal that stalled
// server-side can commit after a faster retry and would otherwise
// overwrite the newer expiry with an older one.
```
**Suggested** (hazard first, mechanism lands as the conclusion):
```rust
// A renewal that stalled server-side can commit after a faster retry,
// overwriting the newer expiry with an older one. `GREATEST` prevents
// this by keeping the expiry monotonic.
```

**Prose is not the only chain.** In a sequence of steps, a case split, or a
lifecycle, each item builds on the ones before it, so the list layout is itself
the logic, and flattening it into prose hides the structure. Carry such content
as a list, with prose supplying the premises and conclusions around the
enumerated core:

```rust
/// Fetch updated payments and metadata, synchronizing both streams.
///
/// Both the payments and metadata tables can be updated independently.
/// To allow the client to tail both consistently, we:
///
/// 1. Fetch both `get_updated_payments` and `get_updated_payment_metadata`
///    with the same start_index.
/// 2. Compute END = min(last_payment_index, last_metadata_index).
/// 3. Filter both lists to items with index <= END.
/// 4. For any payment in the filtered list, ensure we have its metadata.
/// 5. For any metadata in the filtered list, ensure we have its payment.
/// 6. Merge, dedupe by ID (taking latest versions), sort by pwm_updated_at:
///    `pwm_updated_at = max(payment.updated_at, metadata.updated_at)`.
///
/// The client uses END as the next query's start_index, so any item past
/// END in the "shorter" list is included in subsequent queries and no
/// updates are missed.
```

**Mark every inferential step.** When a sentence is inferred from the one
before it, mark the relationship explicitly with a connective ("so", "thus",
"however", "instead", "otherwise") or a phrase that points back ("this", "in
this case", "by then"). A bare sentence is reserved for two roles: introducing
a new premise, which is not inferred, so marking it would falsely present it as
inferred; and landing a conclusion the chain has already forced, where a
connective is useless.

An example where every step is marked and both bare roles appear:
```rust
// Google and Lexe have valid but non-matching files. This could
// happen if persistence partially failed, updating one copy but not
// the other. GDrive offers rollback protection, so it is the
// primary source of truth. We'll update Lexe with Google's version.
```

**Marks must point forward.** Pick the connective that matches the true
relationship, preferring forms that continue the chain over forms that
backfill it:

- Consequence: ", so ..." / "Thus, ..." / ", which ..."
- Contrast, or substitution after a rejected action: ", but ..." /
  "however, ..." / "Instead, ..."
- Requirement: justify with what goes wrong when violated (", otherwise
  ...") rather than a "because" that has to describe the hypothetical.
- Reason (", since ..." / ", because ...") points backwards. Restructure
  the sentence into a forward chain instead.

**Old comment** (backwards "since" delays the rule's justification):
```rust
// Skip the release if any meganode is still running (hung shutdown), since
// releasing would let the backend grant our users to another runner
// while the hung meganodes may still be running their usernodes.
```
**Suggested** (the hazard stated first, the rule lands last):
```rust
// If a meganode hung during shutdown, its usernodes may still be
// running, and releasing our lease would let the backend grant those
// same users to another runner. So if any meganode is still running,
// skip the release and let the lease expire on its own.
```

**Don't splice the chain with punctuation.** An em-dash, colon, semicolon, or
parenthesis that joins two clauses leaves their true relationship unstated, so
the reader must infer the connective the writer skipped. Heavy use of these
splices is a sign the writing has not been worked through. Rewrite nearly all
of them with the connective spelled out, per the table above. Exceptions: a
colon is fine when it attaches a label rather than joining two claims, as in
`// Hot: ...` or `/// Default env: ...`. A semicolon is fine between parallel
statements, like two cases described side by side. But if any connective would
fit, the semicolon is hiding it, so spell the connective out.

**Old comment** (a colon hiding a causal link):
```rust
// Report our initial capacity immediately: acquisition (re)seeded the
// backend with an empty report.
```
**Suggested** (the cause first, the instruction follows):
```rust
// Acquisition (re)seeded the backend with an empty report, so report
// our initial capacity immediately.
```

**Separate facts that aren't inferred.** The converse also holds, so don't
chain two facts when neither follows from the other. "The latest update read so
far, `None` while the wallet has no payments" joins a definition and a special
case; "Starts the cursor at `latest_update`, so polls only read updates after
it" presents a parallel fact as a consequence. Give each such fact its own
sentence. In a short doc comment, each sentence may take its own line.

A parenthetical that carries a premise or the substance of a claim forces the
reader to leave the chain, read the aside, and return to it. Inline it into the
flow as a full clause, or drop it.

**Old comment** (the expectation's premise hidden in an aside):
```rust
// We expect exactly one HTLC per side; only trampoline forwards
// (which we don't route) have more than one.
```
**Suggested** (premise carried in the main line):
```rust
// Only trampoline forwards have more than one HTLC per side, and we
// don't route those, so we expect exactly one on each.
```

### Use plain language

**Use only standardized terminology, simpler terms preferred.** The point of
technical writing is to explain without ambiguity. A term is standardized when
everyone who reads it arrives at the same precise meaning, ideally even without
context. We see common words in context all the time, so they are standardized
by frequency of use; rarer terms of art like "CSPRNG" are standardized by
industry definition. A made-up term like "tick-granular" is neither, so each
reader must guess its meaning from the surrounding context, and different
readers may guess differently. Thus, use standardized terms. In practice these
are usually the simplest words that say the thing: not "renewers" but the tasks
that renew, not "tick-granular" but only checked once per tick, not "dispatch"
but send, not "intervening" but in between.

**Say the thing directly, not through an analogy.** An analogy asks the reader
to understand a second thing and then map it onto the subject, so it costs more
than a direct statement. Analogies are a hallmark of AI writing, so treat each
one as a candidate for replacement.

**Old comment**:
```rust
// Treat the server's index as the high-water mark: once it rises above
// ours, everything we cached sits below the waterline, so drain the cache.
```
**Suggested**:
```rust
// Clear the cache if the server's latest update is ahead of ours.
```

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

Review the comment changes in the current diff following the Guidelines above.
For each added or modified comment, first ask whether it should exist at all,
and only then tighten what remains. A pass that ends with many rewrites and no
deletions has almost certainly under-deleted. Report a concise summary of what
changed and why.

This pass changes no behavior and renames only within the diff (see "Reader
effort"), so the programmer can take it without re-reviewing code. A comment
that exists because the code is hard to read (a getter with a side effect, a
method doing two jobs, a block that needs a summary) is a code smell, so leave
the code alone and note the suggested restructure in the summary for a
`/tighten-code` pass.

If a removed comment holds reviewer-facing rationale worth keeping, don't move
it to another comment. Save it in the changelog (see "Write rationale in the
changelog or commit message") and note the path in the summary.

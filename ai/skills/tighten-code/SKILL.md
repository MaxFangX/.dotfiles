---
name: tighten-code
description: Lexe's code standards: the review principles and the full rulebook, from formatting and idioms to structure, state, and invariants. Use to tighten the code on the current branch, check a scope for violations, or clean up subpar code.
argument-hint: [optional scope, e.g. a file, commit, or "the last 3 commits"]
---

# Lexe Code Standards

The review principles and the full rulebook for code readability,
idioms, conventions, and structure.
(For a comment pass, run `/tighten-comments`; for both, run `/tighten`.)

## Usage guide

Taking this *entire* document into consideration, review the scope given
in $ARGUMENTS, or the code added or modified on the current branch if no
scope was given. Be skeptical and thorough. Fix any violations directly,
without touching code outside the scope, keeping fixes minimal. Then
report a concise summary and flag any judgment calls where a rule
arguably shouldn't apply.

## Writing this guide

Keep sections concise and examples limited, as this entire document must be
readable by AIs (e.g. Claude Code) and consumes precious context.

## Review principles

Open-ended questions to weigh against the scope, beyond the checkable
rules in the chapters that follow.

### Elegance

Did the change leave the system with the most elegant design that would have
emerged if the change had been a foundational assumption from the start? If not,
refactor the code to achieve that design.

### Architecture

Scrutinize the overall structure. Are the right abstractions in place?
Could things be restructured to be simpler, more composable, or higher leverage?
Question whether each type, trait, and module boundary is earning its keep.

### Readability

Prioritize simplicity and readability above all else.

- Tighten overly verbose logic.
- Restructure logic to reduce clauses and nesting.
- Use line breaks to separate logical sections.

### DRY (Don't Repeat Yourself)

- Extract shared helpers for repeated logic.
- Check the codebase for existing functionality, and reuse it instead of
  reimplementing.

### Naming

Look for improvements and inconsistencies in naming.
Names should be clear, consistent, and follow codebase conventions.

### Documentation

When writing documentation, prioritize clarity and precision above all else, but
err on the side of brevity. Document the code's functionality and intent.
More documentation isn't always better; sometimes it just gets in the way.
This pass covers docs only at a high level; see `/tighten-comments` for detailed
instructions for tightening comments.

## General style rules

### String formatting

**Description**:
- Prefer `{inlined}` formatting over `{}` interpolation.
- Define variables if necessary.
- Avoid allocating if possible.

**Rationale**:
- Typically more concise
- More readable
- Prevents the need interpolate mentally
- More robust to edits over time.

**Example**

```rust
error!("P2P connection task panicked: {e:#}");

let dirname = &file.id.dir.dirname;
let filename = &file.id.filename;
let bytes = file.data.len();
debug!("Persisting file {dirname}/{filename} <{bytes} bytes>");
```

**Counter-example**

```rust
error!("P2P connection task panicked: {:#}", e);

debug!(
    "Persisting file {}/{} <{} bytes>",
    file.id.dir.dirname,
    file.id.filename,
    file.data.len(),
);
```

### Sentence case in comments

Comments and docs are written in sentence case: capitalize the first word of
each sentence, unless it begins with a technical name whose casing is
meaningful (`usernode_buffer_slots`, `rustls`). Ending punctuation is
optional unless there are multiple sentences.

### WIP Code

If we are working with WIP code and the lints return "unused" or "dead code",
address the lint with the pattern `let _ = ...;` if possible, falling back to
putting `#[allow(dead_code)]` or `#[allow(unused)]` on the whole function if
required. Any places where these temporary fixes appear should have a
corresponding `TODO(claude): Remove` so we know to address it later.
If you're not sure if the temporary fix is required, leave it out, and simply
add it back in if the linter complains.

### Commit style

Commits should be styled like so:

```
runner: Implement usernode eviction
```

- Includes the relevant crate or module that you're working on
- A concise description of the changes.
- The first line of the commit message fits within 50 characters.

Feel free to use these variations as desired:

`multi: Wire through usernode_buffer_slots`
- `multi:` can be used if the changes span multiple crates or modules.

`bin_dir+: Include static_size in memory_size`
- Indicates that the 'core' of the changes were in the `bin_dir` crate or
  module, but that other files were touched as well.

Other common variations include:
- `refactor:` or `rename:` Self-explanatory.
- `minor:` Trivial change.
- `runner(bugfix)`: e.g. fixing a bug in the `runner` crate.
- `chore:` Updating dependencies, forks, etc.

**NOTE to AIs:** If you have been asked to include this in your commit messages:

```
🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

Do NOT include this. While your work is appreciated, this adds needless noise.

## Rules around Ordering

### Alphabetical ordering

Many places in our codebases use alphabetical ordering, e.g.

- Functions with many parameters
- Structs with many fields
- Sections within `Cargo.toml`s

If a section is alphabetically ordered, it should be maintained.

### Derive ordering

Derives are generally ordered alphabetically, with the following rules:
- `Copy` before `Clone`, because `Copy` implies `Clone`.
- `Eq` before `PartialEq`, likewise.
- `Ord` before `PartialOrd`, likewise.
- `Serialize` before `Deserialize`.
- Non-`std` derives should go either before or after the `std` derives.
- Add another `#[derive(...)]` if there are too many derives to fit on one line.
  We use `rustfmt`'s `merge_derives = false` to prevent these from merging.

Examples:

```rust
/// A unique, client-generated id for some payment types.
#[cfg_attr(any(test, feature = "test-utils"), derive(Arbitrary))]
#[derive(Copy, Clone, Eq, PartialEq, Hash, Ord, PartialOrd)]
#[derive(RefCast, Serialize, Deserialize)]
#[repr(transparent)]
pub struct ClientPaymentId(#[serde(with = "hexstr_or_bytes")] pub [u8; 32]);

#[derive(Debug, Eq, PartialEq, thiserror::Error)]
#[error("timestamp value is negative")]
pub struct TimeError;

#[derive(Copy, Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
#[derive(SerializeDisplay, DeserializeFromStr)]
pub struct PaymentCreatedIndex {
    pub created_at: TimestampMs,
    pub id: PaymentId,
}
```

### File ordering: Highest abstraction first

Place top-level, high-abstraction items before low-level, implementation-detail
ones: public functions before the helpers they call, and composite types before
the primitives they're built from. Reading top-to-bottom, the file should unroll
the call and reference graph downwards, roughly breadth-first.

**Rationale**: Most readers of a file are primarily interested in using it and
understanding it, rather than editing it.

### File ordering: Imports, re-exports, and modules

The top of files should be structured in the following order:
- Imports. Avoid glob imports like `use lexe_api::cli::*;`.
- Re-exports. Use sparingly, as canonical names should be preferred.
- Public modules (`pub mod`)
- Private modules (`mod`)

**Example**

```rust
use std::net::{SocketAddr, TcpListener, TcpStream};

use tokio::runtime::Runtime;

use crate::api::ports::Port;
use crate::root_seed::RootSeed;

pub use reqwest;
pub use secrecy::Secret;

/// `Arbitrary`-like proptest strategies for foreign types.
pub mod arbitrary;

/// SGX types.
mod enclave;
/// Hex utils
mod hex;
```

## Code idioms

### Prefer iterator chains for collections

When working with collections, prefer iterator chains over imperative loops.
- NOTE: When `.collect()`ing, prefer the turbofish (e.g. `.collect::<Vec<_>>()`)
  over type ascription (e.g. `let list: Vec<_> = ...`), as it keeps the type
  annotation close to the operations being performed, and allows for continued
  chaining after collection.

**Rationale**:
- Iterator chains are clean, concise, and can be read line-by-line.
- In many cases, they allow us to avoid unnecessary mutability.

**Example**

```rust
let user_pks = self
    .runner
    .mega_nodes
    .values()
    .flat_map(|mnode| mnode.user_nodes.keys())
    .filter(|_| self.rng.gen_bool(0.1))
    .copied()
    .collect::<HashSet<_>>();
```

**Counter-example**

```rust
let mut user_pks = HashSet::new();
for mnode in self.runner.mega_nodes.values() {
    for user_pk in mnode.user_nodes.keys() {
        if self.rng.gen_bool(0.1) {
            user_pks.insert(*user_pk);
        }
    }
}
```

### Line length

Every line must be strictly under 80 characters. This applies to all code,
comments, and documentation, except URLs and bash commands in doc comments.

**Rationale**:
- Improves readability on standard terminals
- Allows side-by-side file comparison
- Enforces concise, well-structured code

### Match arm simplification

When a match arm contains only a single expression which resolves to unit `()`,
prefer the concise form `,` without surrounding braces `{}`. If the match arm
intentionally does nothing, return `()` instead of `{}`.

**Motivation:** This makes code more concise and reduces wasted vertical space.

**Example**

Concise and clearly denotes the type of the match block.

```rust
match runner_command {
    RunnerCommand::UserFinished(req) => self.handle_user_finished(req),
    // Ignore activity during shutdown
    RunnerCommand::UserActivity(_) => (),
    RunnerCommand::UserRunRequest(req) => {
        let error = RunnerApiError::service_unavailable("Shutting down");
        let _ = req.user_ready_waiter.send(Err(error));
    }
}
```

**Counter-example**

Wasted vertical space using unnecessary braces

```rust
match runner_command {
    RunnerCommand::UserFinished(req) => {
        self.handle_user_finished(req);
    }
    RunnerCommand::UserActivity(_) => {
        // Ignore activity during shutdown
    }
    RunnerCommand::UserRunRequest(req) => {
        let error = RunnerApiError::service_unavailable("Shutting down");
        let _ = req.user_ready_waiter.send(Err(error));
    }
}
```

### Prefer `?` over `match` for early returns

Prefer the `?` operator over `match` for early returns in functions and closures
that return `Option` or `Result`.

**Rationale**: The `?` operator is concise and usually maintains clarity.

**Example**

When possible, `?` is much more concise.

```rust
let (txt_prefix, _) = txt.as_bytes().split_first_chunk::<PREFIX_LEN>()?;
```

**Counter-example**

Matching takes much more vertical space, but sometimes it is our only option.

```rust
let txt_prefix = match txt.as_bytes().split_first_chunk::<PREFIX_LEN>() {
    Some((p, _)) => p,
    None => return None,
};
```

## Structure and state

### Minimum visibility

Structs, fields, and functions should have the minimum required visibility.
- This allows cargo to detect when these objects aren't used.
- Struct fields don't need anything more granular than `pub` or not `pub`, as
  these are already handled by the struct visibility.

Examples

```rust
// Only items used by other crates should be fully public.
pub Error;

pub(crate) struct MegaContext {
    // We don't need the verbosity of `pub(crate)` as the struct is already
    // `pub(crate)`. Just use `pub` or nothing.
    pub measurement: enclave::Measurement,

    machine_id: enclave::MachineId,
}

impl MegaContext {
    pub(crate) fn method(&self) {
        helpers::do_thing(machine_id);
    }
}

mod helpers {
    use super::*;

    pub(super) fn do_thing(machine_id: enclave::MachineId) {
        ...
    }
}
```

### Minimize the module root namespace

The root of a module should hold only a handful of items: the entrypoint(s)
and core types. Each root item should generally be a namespace of its own
(a type with its `impl`s, or an inline module) rather than a *leaf* item
like a lone function or constant. Leaf items at the root are reserved for
the module's primary API. Group everything else one level down:

- Functions and constants belong on the type they relate to, as methods,
  associated functions, and associated consts. Reserve free functions for
  the module's entrypoints, and for function-oriented modules where the
  functions *are* the API (`hex::encode()`, `git::fetch_remote()`). Call
  sites namespace these by module (see [Namespacing](#namespacing)), so
  they stay discoverable.
- `mod helpers` is the catch-all for helpers that don't belong anywhere
  else; it goes at the end of the file, before `mod test`.
- Inline modules hold `pub(super)` items and should `use super::*`, which
  reduces import spam by concentrating all imports at the top of the file.
- `// --- Section --- //` separator comments group items which must stay in
  the parent namespace, e.g. the types themselves.

**Example**

```rust
/// Sync the node's channel backups to durable storage.
pub fn sync_backups(vfs: &Vfs) -> anyhow::Result<()> { ... }

/// A channel backup archive, as persisted to the VFS.
struct Archive(Vec<u8>);

impl Archive {
    /// Maximum size we'll persist, in bytes.
    const MAX_SIZE: usize = 65536;
    const VERSION: u8 = 2;

    fn seal(channels: &[Channel]) -> Self {
        let payload = Self::serialize_channels(channels);
        ...
    }

    // A helper used only by `Archive` lives in its impl, not at the root.
    fn serialize_channels(channels: &[Channel]) -> Vec<u8> { ... }
}

mod helpers {
    use super::*;

    // Doesn't relate to any one type, so it goes in the catch-all tail.
    pub(super) fn backoff_delay(attempt: u32) -> Duration { ... }
}
```

**Counter-example**

```rust
pub fn sync_backups(vfs: &Vfs) -> anyhow::Result<()> { ... }

// Leaf items are scattered across the module root, so the consts need an
// `ARCHIVE_` prefix and helpers are indistinguishable from entrypoints.
const ARCHIVE_MAX_SIZE: usize = 65536;
const ARCHIVE_VERSION: u8 = 2;

struct Archive(Vec<u8>);

fn seal_archive(channels: &[Channel]) -> Archive { ... }

fn serialize_channels(channels: &[Channel]) -> Vec<u8> { ... }

fn backoff_delay(attempt: u32) -> Duration { ... }
```

### Minimize state

**The number of cases that need to be handled explodes combinatorially as
state increases.**
Keep state to an absolute minimum, and lean on the type system as much as
possible. Nonsense states should not be representable.

- Scrutinize every stateful field and parameter. Do we really need it?
  For `Option<_>`s, can the `None` case be handled entirely outside,
  during init?
- Use fallible initialization to prune the state space. Instead of adding
  an `enabled: bool` field to a struct, wrap the entire struct in an
  `Option<_>`. The struct then operates on already-pruned state; it no
  longer has to handle the case where it's disabled.
- Be maximally expressive with our types. If two fields always exist
  together or never exist at all, make them a single field like
  `Option<(Foo, Bar)>` instead of separate `Option<Foo>` and
  `Option<Bar>` fields.

## Rules for Clarity and Unambiguity

### Amount suffixes

Any variable or named field representing a Bitcoin amount which does not use the
`Amount` newtype should include either a `_btc`, `_sat`, or `_msat` suffix.
Fields that *do* use the `Amount` newtype do not need a suffix.

```rust
pub struct OpenChannelArgs {
    /// the value of the channel we want to open, in BTC.
    value_btc: Decimal,
    ...
}

pub struct Balance {
    pub immature_sat: u64,
    pub trusted_pending_sat: u64,
    pub untrusted_pending_sat: u64,
    pub confirmed_sat: u64,
}

pub async fn payment_claimed(
    amt_msat: u64,
) -> anyhow::Result<()> {
    ...
}

pub struct OnchainSend {
    pub amount: Amount,
    pub fees: Amount,
    ...
}
```

**Rationale**:

Do not assume that other Lexe devs will be as familiar with these structs as you
are. Adding the amount suffix removes all uncertainty and makes the Bitcoin unit
clear at a glance.

### Namespacing

Namespace foreign functions and constants by importing their containing module
or crate instead of the function or constant itself. Import types and traits
directly unless the containing crate or module is semantically part of the name.
Examples:

- Imported directly: `RestClient`, `RootSeed`, `IntoResponse`
- Namespaced:
  - `anyhow::Result`
  - `bcs::Error`
  - `reqwest::Client`
  - `sha256::Hash`
  - `enclave::Measurement`, `enclave::dev::measurement()`

**Rationale**: This helps differentiate between items which are defined locally
vs items defined in a foreign module or crate.

These are not hard rules; use discretion to determine what is most readable.

```rust
use axum::response::IntoResponse;
use lexe_common::{
    api::{rest, rest::RestClient},
    client::NodeClient,
    enclave::Measurement,
    tls,
};

const MAX_CONNECTIONS: usize = 1024;

struct MyClient {
    idx: i32,
    rest: RestClient,
}

// Use `anyhow::Result` so readers immediately know it's not the normal `Result`
pub async fn ping_server() -> anyhow::Result<()> {
    // It is easy to tell which const is local and which is foreign
    let crypto = tls::LEXE_CRYPTO_PROVIDER;
    let num_connections = MAX_CONNECTIONS;

    // Likewise with local vs foreign functions
    let routes = route_handler().unwrap();
    let server = rest::serve_routes(routes, crypto, num_connections);

    // `Client` is too generic so we namespace with `reqwest::`
    let reqwest = reqwest::Client::new();
    let rest = RestClient::from_inner(reqwest);
    let client = MyClient { rest };

    client.ping().await.context("Ping failed")?;

    Ok(())
}

// Traits like `IntoResponse` are imported directly, but `Error` is too generic
// so we namespace it with `anyhow::`
fn route_handler(
    measurement: Measurement
) -> Result<impl IntoResponse, anyhow::Error> {
    todo!()
}
```

## Serialization

Lexe generally uses `serde` for serialization to/from strings and bytes.

### Enum serialization

- Enums should prefer to use `snake_case`, which is semantically more 'fused' or
  'unified' than other cases, which best aligns with the discrete nature of an
  enum. `snake_case` is also the easiest to select in an editor, e.g. with `ve`
  in vim, as opposed to `veee` for `kebab-case`.
- User facing enums should use `kebab-case`, which is most visually appealing
  and easiest to type.
- Enums for errors (which don't use an error code scheme) should use
  `PascalCase`, to be consistent with how they are printed in `Debug` impls.

```rust
#[derive(Copy, Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
#[cfg_attr(test, derive(strum::VariantArray))]
pub enum ConfirmationPriority {
    High,
    Normal,
    Background,
}

/// An SGX binary kind (seen in a `releases.json` file)
#[derive(Copy, Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
#[derive(Serialize, Deserialize, VariantArray)]
#[serde(rename_all = "kebab-case")]
pub enum BinKind {
    Node,
    Lsp,
    SgxInfo,
}

/// Contains a reason for why an outbound lightning payment failed.
#[derive(Copy, Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
// (Note how there is no `#[serde(rename_all = ...)]` here)
#[cfg_attr(test, derive(Arbitrary, strum::VariantArray))]
pub enum LxOutboundPaymentFailure {
    /// We exhausted all of our retry attempts.
    NoRetries,
    /// The intended recipient rejected our payment.
    Rejected,
    /// The user abandoned this payment via `ChannelManager::abandon_payment`.
    Abandoned,
    /// Any unrecognized variant we might deserialize. This variant is for
    /// forwards compatibility (old node reads new state).
    #[serde(other)]
    Unknown,
}
```

## Instrumentation

### Tracing span names

The names of `tracing::Span`s should be formatted like `(my-span)`, i.e.:

- Surrounded by `()`.
- Connected by `-` instead of space ` ` if there are multiple words in the span.
- Should be relatively short, e.g. `(bgp)` instead of `(background-processor)`.

```rust
#[instrument(skip_all, name = "(cool-span)")]
async fn am_i_cool(i_think_im_cool: bool) -> bool {
    false
}
```

**Rationale**: 

The `()` visually differentiate between `inherited:spans` and
`module::definitions`.

Example log without `()`:

```
2023-03-01T06:01:00.334028Z DEBUG lsp:bgp:http request: lexe_api::rest: sending request
```

Example log with `()`:

```
2023-03-01T06:01:00.334028Z DEBUG (lsp):(bgp):(http-request): lexe_common::api::rest: sending request
```


## Cargo.toml dependencies

### Minimize dependencies in foundational crates

**Description**:
- Foundational crates are crates that most Lexe targets depend on or low-level
  crates on the critical `cargo build` path. Any crate used by a `build.rs`
  build script is a foundational crate.
- Foundational crates must not depend on any heavy dependencies, like the
  `reqwest` HTTP client, `axum` server, `tokio` async runtime, proc-macro
  crates, `bitcoin` or `lightning` crates, and so on.

**Rationale**:
- Foundational crates must be dependency minimized to reduce clean-build times.
- Reducing dependencies prevents dependent crates from paying unnecessary build
  costs for things they don't use.
- Dep minimization moves foundational crates lower in the build tree, allowing
  `cargo` to build more crates in parallel and reduces the depth of the
  dependency tree.
- For example, adding a `lightning` dep will add ~49sec to the clean release
  build time in CI. Adding a proc-macro dep like `serde` will add ~5-6 sec to
  the clean build time in CI.
- A `build.rs` script that transitively depends on `lexe-common` for a few
  utility functions will add ~43 sec to GHA CI debug build.

**Consequences**:
- Vendoring logic, duplicating impls, and "manual impl'ing" over
  `#[derive(..)]` are often preferable in foundational crates.
- Foundational crates should carefully tune the `default-features` and
  `features` of their dependencies.
- Instead of `serde+serde_derive`, just use `serde_core` and manually impl the
  `serialize`/`deserialize`.
- Instead of `thiserror`, manually impl `fmt::Display`.


## Markdown Style

### Line length and sentence breaks

**Description**:
- Restrict each line strictly to 80 characters.
- Add newlines at sentence boundaries, not at arbitrary character positions.
- Don't use em-dashes in your writing.

**Rationale**:
- Improves diff readability, since edits to one sentence won't reflow the
  entire paragraph.
- Keeps the markdown readable in narrow vim splits.

**Example**

```md
Lexe builds self-custodial Lightning nodes which run inside secure hardware
enclaves in the cloud.
This allows Lexe to keep user nodes online 24/7 without retaining custody of
users' keys, as Lexe cannot read the keys from inside of the enclaves.
This unique architecture requires a Lightning implementation that could be
deeply customized for the unforgiving programming environment that Lexe operates
in, which led us to LDK.
```

**Counter-example (no newlines)**

```md
Lexe builds self-custodial Lightning nodes which run inside secure hardware enclaves in the cloud. This allows Lexe to keep user nodes online 24/7 without retaining custody of users' keys, as Lexe cannot read the keys from inside of the enclaves. This unique architecture requires a Lightning implementation that could be deeply customized for the unforgiving programming environment that Lexe operates in—which led us to LDK.
```

**Counter-example (newlines at arbitrary places)**

```md
Lexe builds self-custodial Lightning nodes which run inside secure hardware
enclaves in the cloud. This allows Lexe to keep user nodes online 24/7 without
retaining custody of users' keys, as Lexe cannot read the keys from inside of
the enclaves. This unique architecture requires a Lightning implementation that
could be deeply customized for the unforgiving programming environment that Lexe
operates in—which led us to LDK.
```

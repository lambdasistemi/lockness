# Chainpoint sessions

As a terminal, make several dependent reads and paginate results from one selected ledger state, even while the provider follows new blocks. If that state cannot be served, receive a named refusal rather than a silently newer answer.

## Find a usable chainpoint

The terminal first intersects accepted anchor publications with the ledger provider's advertised retained views and history coverage. It selects one network, chainpoint and compatible commitment scheme that satisfy its action policy, then asks the provider to acquire that exact view. The anchor continues publishing independently; it does not negotiate sessions.

Availability can change between discovery and acquisition. Acquisition either confirms the selected view and lease or explicitly refuses it. With no usable overlap, the terminal waits, changes provider or explicitly selects another acceptable chainpoint. It never combines answers from different points or searches combinations of already-fetched data. The discovery wire format remains open; this handshake is required. See the [proof-composition sequence](../architecture/system.md#proof-composition).

## Session contract

Use **chainpoint** throughout Lockness. This corresponds to Cardano API's [`ChainPoint`](https://cardano-api.cardano.intersectmbo.org/cardano-api/src/Cardano.Api.Block.html#ChainPoint): either genesis or a slot number paired with a block-header hash. The network is separate context and must also be bound by the protocol. A slot number alone does not identify a chainpoint across competing branches.

A session token binds reads to the network, selected chainpoint and a retained view; it is not a source of trust. A chainpoint names a chain position, a view exposes state at that position, and a session retains access under a lease. The terminal verifies results against its separately accepted commitment. Different providers may issue different tokens for the same chainpoint. Whether sessions can be acquired at genesis remains a service-contract decision.

<!-- diagram: session -->
<div class="diagram"><a href="../diagrams/session.png?v=42c240417184fe73"><img src="../diagrams/session.png?v=42c240417184fe73" alt="A retained session supports repeated reads; expiry and missing views refuse, and rollback policy is explicitly unresolved." width="784" loading="lazy"></a></div>
<p class="diagram-links"><a href="../diagrams/session.png?v=42c240417184fe73">Open full size</a> · <a href="../diagrams/session.mmd?v=814064504407234d">Mermaid source</a></p>

Retention and lease limits are not yet fixed. The design must bound resource use without evicting an active view contrary to its advertised contract. A rollback does not turn a block hash into a different block; the policy for sessions on an abandoned branch remains open. No automatic chainpoint substitution is allowed.

## Storage separation

<!-- diagram: storage -->
<div class="diagram"><a href="../diagrams/storage.png?v=4f706cef2479e092"><img src="../diagrams/storage.png?v=4f706cef2479e092" alt="A session pins index roots that resolve immutable content and supply membership witnesses for one chainpoint." width="346" loading="lazy"></a></div>
<p class="diagram-links"><a href="../diagrams/storage.png?v=4f706cef2479e092">Open full size</a> · <a href="../diagrams/storage.mmd?v=0e3d8cf3d2f021c4">Mermaid source</a></p>

Immutable content survives rollback. Chain-index membership and branch status determine which content belongs to the selected ledger state. Storing an object is not evidence that it is live or canonical.

Retained views may use persistent index nodes, shared snapshots, or an isolated overlay reconstructed using rollback information. The mechanism has not been chosen. A read-only RocksDB snapshot is not itself a writable rollback target, and [snapshot handles do not survive database restarts](https://github.com/facebook/rocksdb/wiki/Snapshot). A restart-surviving view needs a durable design, for example versioned nodes, persisted rollback overlays or separately retained [database checkpoints](https://github.com/facebook/rocksdb/wiki/Checkpoints). A RocksDB checkpoint is a storage mechanism, distinct from a Cardano chainpoint. Storage growth, write amplification, historical-read latency and session concurrency require measurement before choosing an implementation.

## History coverage before costing

Choose archive coverage before sizing or committing to ledger-provider operating costs. Retaining every transaction and selecting transactions by generic asset or address filters are different service offers; neither is assumed here. Both preserve complete transaction CBOR for the transactions they offer.

The contract must specify the starting chainpoint, selection rules, retention, backfill, referenced and spent-output resolution, and missing-coverage responses. A filter is sufficient only if a representative MPFS or Singular replay can obtain every dependency it needs, including transactions or outputs outside that filter. Serving reconstruction material does not by itself prove completeness.

Exit evidence is a declared coverage offer and a deterministic application replay that reproduces the authenticated application root. Measure that workload and its reference closure; do not assign a generic cost estimate to an unspecified archive. The [roadmap](../roadmap.md#specify-roots-reconstruction-and-settlement) makes this a prerequisite for engine sizing.

## Decisions

| Chosen direction | Alternative | Reason |
| --- | --- | --- |
| Select a chainpoint before reading | Combine independently fetched latest responses | Avoid mixed chainpoints and trial-and-error matching. |
| Bounded retained views and sessions | Promise arbitrary historical views indefinitely | Make availability and storage commitments explicit. |
| Immutable content separate from chainpoint indexes | Roll payload storage backward for every query | Share content while restoring only references and commitments. |

## Open questions

- What happens to an active session after its selected block leaves the canonical chain?
- What retention and lease policy bounds storage and prevents resource exhaustion?
- Which roots and indexes are captured atomically in a view?
- Which wire format exposes retained views and anchor publications for the required discovery handshake?
- Which history/reference queries are bounded by the point, and how is incomplete archive coverage reported?
- Which failures require retrying the same point, and which require explicit terminal selection of a new point?

The first formal design slice should model acquisition, reads, rollback, expiry and eviction before optimizing physical storage.

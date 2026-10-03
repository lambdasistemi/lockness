# Checkpoint sessions

As a client, make several dependent reads and paginate results from one selected ledger state, even while the provider follows new blocks. If that state cannot be served, receive a named refusal rather than a silently newer answer.

## Session contract

A checkpoint is identified by network, slot and block hash. A session token binds reads to that point and to a retained view; it is not a source of trust. The client verifies results against its separately accepted commitment. Different providers may issue different tokens for the same point.

```mermaid
stateDiagram-v2
    [*] --> Requested: Select a published point
    Requested --> Active: Acquire a retained view
    Requested --> Unavailable: Point cannot be served
    Active --> Active: Read or paginate at the same point
    Active --> Expired: Bounded lease expires
    Active --> Closed: Client releases session
    Active --> BranchDecision: Selected block is rolled back
    BranchDecision --> [*]: Behavior awaits design ruling
    Unavailable --> [*]: Explicit refusal
    Expired --> [*]: Explicit refusal on further use
    Closed --> [*]: Release retained reference
```

Retention and lease limits are not yet fixed. The design must bound resource use without evicting an active view contrary to its advertised contract. A rollback does not turn a block hash into a different block; the policy for sessions on an abandoned branch remains open. No automatic checkpoint substitution is allowed.

## Storage separation

```mermaid
flowchart LR
    S[Read session at point P] -->|Select| V[Retained index roots for P]
    V -->|Resolve live membership and assets| R[Content references]
    R -->|Fetch by hash| B[Append-only content store]
    V -->|Construct witnesses| W[Proof response]
    B -->|Supply exact bytes| W
```

Immutable content survives rollback. Chain-index membership and branch status determine which content belongs to the selected ledger state. Storing an object is not evidence that it is live or canonical.

Retained views may use persistent index nodes, shared snapshots, or an isolated overlay reconstructed using rollback information. The mechanism has not been chosen. A read-only RocksDB snapshot is not itself a writable rollback target. Storage growth, write amplification, historical-read latency and session concurrency require measurement before choosing an implementation.

## Decisions

| Chosen direction | Alternative | Reason |
| --- | --- | --- |
| Select a chain point before reading | Combine independently fetched latest responses | Avoid mixed checkpoints and trial-and-error matching. |
| Bounded retained views and sessions | Promise arbitrary historical views indefinitely | Make availability and storage commitments explicit. |
| Immutable content separate from checkpoint indexes | Roll payload storage backward for every query | Share content while restoring only references and commitments. |

## Open questions

- What happens to an active session after its selected block leaves the canonical chain?
- What retention and lease policy bounds storage and prevents resource exhaustion?
- Which roots and indexes are captured atomically in a view?
- How are checkpoint availability and publisher history discovered?
- Which history/reference queries are bounded by the point, and how is incomplete archive coverage reported?
- Which failures require retrying the same point, and which require explicit client selection of a new point?

The first formal design slice should model acquisition, reads, rollback, expiry and eviction before optimizing physical storage.

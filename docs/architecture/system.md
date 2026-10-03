# Architecture and operating cost

As a project maintainer, separate the cost of establishing trusted roots from the cost of serving data, so applications can buy capacity while terminals retain their verification policy.

## Why data should travel with proofs

A terminal uses ledger answers to make decisions. If an answer is merely a provider assertion, the terminal depends on that provider's correctness. With a proof, it can check the answer's stated claim against a commitment independently accepted from anchors. The proof connects the supplied data to the accepted ledger state at the selected chainpoint.

The resulting value is control over what the terminal consumes. Data providers can be replaced or cached, and proof construction can be delegated, while verification and anchor selection remain with the terminal. Applications can share the expensive work of chain following without sharing a server's unchecked interpretation of their state.

For example, a terminal preparing an MPFS or Singular transaction needs the application root in a particular NFT's state output. It verifies the output's ledger witness against its accepted anchor root, binds the NFT identity and exact datum, then verifies the application proof against the application root in that datum. The ledger provider need not interpret the application, and the application proof builder need not be trusted to supply a correct proof.

For an external effect, the same verified ledger fact becomes an input to the terminal's action policy. Proof verification does not itself authorize a payment, unlock a resource or establish a real-world fact. That policy also decides which anchors, chainpoints, freshness and rollback conditions are acceptable.

| Evidence | What the terminal can check | What still needs a separate contract |
| --- | --- | --- |
| Anchor signature | Who endorsed a root and the message it binds | Whether that anchor and chainpoint meet the terminal's trust policy |
| Ledger witness | Its stated claim about data at the accepted chainpoint | Completeness or absence beyond that claim, and freshness |
| Application proof | Its stated claim against the application root in verified state | Whether the intended transition is authorized and will validate when submitted |

Data should travel with the evidence needed to verify the claims a terminal relies on. This is a logical association; data and proofs can be retrieved separately if their claim, commitment and chainpoint bindings match. Raw historical transactions can remain untrusted reconstruction inputs when the resulting state is checked against an anchored root. A proof against a root supplied only by the same untrusted data server does not provide the independent trust boundary described here.

## Components and chain following

| Component | Chain following | Responsibility |
| --- | --- | --- |
| `lockness-ledgers` | Runs nodes and follows the chain | Store ledger content, maintain authenticated indexes, handle rollback, retain query views and serve evidence. |
| `lockness-anchors` | Runs nodes and follows the chain | Compute commitments from a trusted validated feed and publish a signed commitment for every block. |
| `lockness-applications` | Not required | Retrieve relevant historical data, interpret it, reconstruct application state and generate proofs. |
| `lockness-terminals` | Not required | Consume and verify roots, data and proofs; build transactions or drive real-world effects from verified facts. |

```mermaid
flowchart TB
    N[Anchor's node] -->|Validated blocks and rollbacks| P[Lockness anchor]
    M[Provider's node] -->|Validated blocks and rollbacks| D[Lockness ledger]
    P -->|Signed publications| C[Lockness terminal]
    D -->|Data and ledger witnesses| C
    D -->|Transactions and referenced outputs| A[Lockness application]
    A -->|Application proofs| C
```

Anchors and ledgers are plural because any number of independent instances may exist. Both roles run nodes. Anchors serve signed roots; ledgers serve data and proofs. They can reuse the generic commitment engine without sharing a running process. Independent publishers establish their own commitments. Signing an untrusted provider's supplied root does not create independent assurance. The cost and trust consequences of shared node infrastructure must be explicit.

A terminal is the consuming role, including wallets, applications and integrations with external systems. It verifies the roots, proofs and data it uses, then builds transactions or uses the verified facts to drive real-world effects. The authorization and execution of those effects are application policy, not an action performed by the generic ledger service.

## Offload computation while retaining trust control

Running your own anchor is the optimal trust deal when independence is the objective: your node validates the chain and your anchor computes the roots used by your terminals. The anchor maintains the current commitment state required by its scheme and handles rollback. It need not operate the ledger service's transaction archive, historical query views or public query and proof-serving capacity. Actual anchor costs remain to be measured.

Observing institutional root publications offers an exceptionally attractive operational alternative. The terminal checks signatures and publication bindings under its chosen institutional policy, while the institutions operate anchors. This reduces local infrastructure by accepting institutional endorsements. The protocol must make that choice explicit and must not silently replace it when data providers change.

With either source of accepted roots, storage, indexing, reconstruction and proof generation can be delegated to providers. Correctness checks remain with terminals; delivery commitments belong to the application–provider market. Increasing offloaded work need not increase trust in a data provider's assertions, provided the same required claims remain verifiable.

The [trust and availability model](../design/trust-and-availability.md) defines the service commitments and switching requirements. Payment processing, provider discovery and remedies for missed commitments remain open integration choices.

## Data and trust are separate

A root publisher endorses a commitment for a network and chainpoint. A client owns the trusted keys and acceptance policy. A ledger provider and an application proof builder remain untrusted for correctness; valid evidence, rather than their identity, permits the client to use a result.

Signed messages need an unambiguous network, slot, block hash, commitment scheme/version and root identity. Publisher agreement rules, key rotation, freshness and branch correction are unresolved protocol contracts. A signature identifies an endorsement; it does not establish the correctness of the endorsed ledger.

## Proof composition

The two proof values have different temporal roles. **Ledger proofs concern on-chain validity in the present**, meaning the ledger state at the selected chainpoint. **Application proofs concern on-chain validation in the future**, when a proposed transaction executes.

| Proof value | What it establishes or supports | Where it is checked |
| --- | --- | --- |
| Ledger proof | A claim about the already established ledger state at the selected chainpoint: the present facts used for construction. | Off-chain, by the terminal against an accepted anchor commitment. |
| Application proof | Evidence for the application validator to check a proposed transition: future validation. | In the terminal before use, then on-chain from the transaction redeemer. |

“Present” is chainpoint-relative, not a promise that an old view remains the chain tip. “Future validation” describes the proof's role, not a guarantee that the submitted transaction succeeds after intervening state changes.

```mermaid
sequenceDiagram
    participant P as Anchor
    participant C as Terminal
    participant L as Lockness ledger
    participant A as Application builder
    P->>C: Signed commitment for point P
    C->>L: Acquire a read session at P
    L-->>C: Session token or chainpoint unavailable
    C->>L: Read NFT state with ledger witness
    L-->>C: Exact output and proof for P
    C->>C: Verify against accepted ledger commitment
    A->>L: Retrieve reconstruction transactions at P
    L-->>A: CBOR and required historical references
    A-->>C: Application state and proof for the anchored root
    C->>C: Verify before transaction construction
```

Application builders may generate proofs on behalf of clients. A client may instead reconstruct the tree locally. The application root comes from the verified state output; it is distinct from the ledger-index root. A reused proof must match the receiving context's claim, encoding and root. Valid evidence at an old chainpoint is not a promise that a future transaction will still be admissible.

**Transaction boundary:** ledger proofs remain off-chain and are not included in transaction redeemers. A terminal uses them to check the ledger data it builds from. Application-level proofs are included in redeemers and checked by the application validators against the on-chain application state. Cardano validates inputs, value conservation and the other applicable ledger rules against its actual state; it does not consume the terminal's CSMT witness as a substitute for those checks. Signed anchor-root publication remains separate from transaction submission.

Historical transactions may be untrusted reconstruction material. Matching the reconstructed tree to an authenticated root establishes the resulting committed state under the application's reconstruction rules; it does not automatically prove every asserted historical event or the completeness of arbitrary transaction-history queries.

## Service boundary

The generic service retains transaction CBOR and ledger references. It must understand enough ledger structure to index and follow the chain, but does not decide what a redeemer means for MPFS or Singular. Exact history coverage and spent/reference-input resolution remain to be specified. Application proof builders interpret datums, redeemers and other application-relevant transaction fields.

Not every response needs a proof. Each endpoint must state its claim and whether its payload is authenticated evidence or untrusted reconstruction material. Evidence-bearing responses may bundle data and proofs. Separate retrieval can remain possible, but Koios wire compatibility is not a requirement for the stronger chainpoint contract.

## Decisions

| Chosen direction | Alternative | Reason |
| --- | --- | --- |
| Generic chain-following engine reused across publisher and provider roles | A full chain indexer for every application | Keep infrastructure cost in reusable ledger capabilities. |
| Independent signed commitments plus verifying clients | Trust the data server's own advertised root | Separate data availability from authority. |
| Optional application proof builder | Require every client to reconstruct every proof | Permit delegation of computation without delegating correctness. |
| Preserve transaction CBOR and resolve required references | Select a small set of fields based on one application | Other applications may consume different transaction fields. |

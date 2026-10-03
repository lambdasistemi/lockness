# Architecture and operating cost

As a project maintainer, separate the cost of establishing trusted roots from the cost of serving data, so applications can buy capacity while terminals retain their verification policy.

## Why data should travel with proofs

A terminal uses ledger answers to make decisions. If an answer is merely a provider assertion, the terminal depends on that provider's correctness. With a proof, it can check the answer's stated claim against a commitment independently accepted from anchors. The proof connects the supplied data to the accepted ledger state at the selected chainpoint.

The resulting value is control over what the terminal consumes. Data providers can be replaced or cached, and proof construction can be delegated, while verification and anchor selection remain with the terminal. Applications can share the expensive work of chain following without sharing a server's unchecked interpretation of their state.

For example, a terminal preparing an [MPFS](../projects.md#application-consumers) or [Singular](https://github.com/lambdasistemi/singular) transaction needs the [application root](../concepts.md#two-roots-with-different-scopes) in a particular [NFT state output](../concepts.md#assets-and-nft-state-outputs). It verifies the output's ledger witness against its accepted ledger root, binds the NFT identity and exact datum, then verifies the application proof against the application root in that datum. The ledger provider need not interpret the application, and the application proof builder need not be trusted to supply a correct proof.

For an external effect, the verified ledger fact becomes an input to the terminal's [action and settlement policy](#external-effects-and-settlement). Proof verification alone does not authorize the effect.

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

<!-- diagram: infrastructure -->
<div class="diagram"><a href="../diagrams/infrastructure.png?v=c2f7334c98e52a39"><img src="../diagrams/infrastructure.png?v=c2f7334c98e52a39" alt="Anchor and provider operate separate nodes; terminals combine roots with evidence, and application builders consume ledger history." width="632" loading="lazy"></a></div>
<p class="diagram-links"><a href="../diagrams/infrastructure.png?v=c2f7334c98e52a39">Open full size</a> · <a href="../diagrams/infrastructure.mmd?v=c8ccd06fe2d3ef6b">Mermaid source</a></p>

Anchors and ledger providers are plural because any number of independent instances may exist. Both roles run nodes. Anchors serve signed roots; ledger providers serve data and proofs. They can reuse the generic commitment engine without sharing a running process. Anchors establish their own commitments. Signing an untrusted provider's supplied root does not create independent assurance. The cost and trust consequences of shared node infrastructure must be explicit.

Terminals can avoid their own chain follower because accepted anchor publications supply their view of chain progress. The root-acceptance policy must cover freshness and branch changes.

A terminal is the consuming role, including wallets, applications and integrations with external systems. It verifies the roots, proofs and data it uses, then builds transactions or uses the verified facts to drive real-world effects. The authorization and execution of those effects are application policy, not an action performed by the ledger provider.

## Offload computation while retaining trust control

An anchor maintains current commitment state and handles rollback. A ledger provider additionally retains history and query views and serves data and proofs. These workloads can be operated and paid for separately.

The [trust and availability model](../design/trust-and-availability.md#two-attractive-trust-deals) owns the own-anchor and institutional-publication choices. The [existing CSMT-UTXO engine](../projects.md#csmt-utxo-the-existing-engine) supplies commitment machinery; its benchmarks and metrics start measurement of node and anchor costs. The ledger provider's archive, retained views and query capacity require separate design and measurement.

## Data and trust are separate

An anchor endorses a commitment for a network and chainpoint. A terminal owns the trusted keys and acceptance policy. A ledger provider and an application proof builder remain untrusted for correctness; valid evidence, rather than their identity, permits the terminal to use a result.

**`lockness-applications` is an untrusted computation service, just like the ledger provider.** It may interpret transactions, reconstruct a tree and generate application proofs; none of those answers is authoritative merely because the service supplies it. The terminal verifies each required application claim against a root authenticated through the ledger proof and exact state datum. A service-supplied replacement root, a proof for a different NFT or application, and evidence that fails verification must be rejected. Missing evidence does not become an accepted fact.

An application service may verify its own inputs as part of its implementation. That does not replace the terminal's verification. Delegation of construction and interpretation leaves the terminal responsible for the accepted proof contract, chain of roots and policy for acting on the result. The application validator checks the relevant redeemer proof again if a transaction is submitted.

Signed messages need an unambiguous network, slot, block hash, commitment scheme/version and root identity. Publisher agreement rules, key rotation, freshness and branch correction are unresolved protocol contracts. A signature identifies an endorsement; it does not establish the correctness of the endorsed ledger.

## Proof composition

The first root is **application-independent and chain-wide**: it commits to the ledger quantities covered by its scheme. For [CSMT-UTXO](../projects.md#csmt-utxo-the-existing-engine), that scope is the live UTxO set across the chain. It is not a commitment to every historical transaction or every possible ledger quantity.

An **application root is carried inside a UTxO**, in the state output's datum for the integration described here. Once the terminal proves that exact output belongs to the ledger state at the selected chainpoint, it has also authenticated the datum containing the application's root. This is where the application tree is anchored to the ledger.

The terminal can then verify application data against that root. If a proved application value contains another root, the same process can continue into another application tree. Each link requires its own proof and interpretation: the terminal binds the root's exact bytes, encoding, scheme and application identity to the parent claim. Ledger inclusion authenticates the starting datum; it does not automatically validate every descendant claim.

<!-- diagram: root-chain -->
<div class="diagram"><a href="../diagrams/root-chain.png?v=7098983bec3bc069"><img src="../diagrams/root-chain.png?v=7098983bec3bc069" alt="The ledger root authenticates a UTxO and datum, which carries an application root. Application proofs can authenticate further roots, with a separate check at every link." width="267" loading="lazy"></a></div>
<p class="diagram-links"><a href="../diagrams/root-chain.png?v=7098983bec3bc069">Open full size</a> · <a href="../diagrams/root-chain.mmd?v=bf3e8ea6f206cf6f">Mermaid source</a></p>

This **chain of roots** is the bridge from generic ledger evidence to application evidence. The ledger provider need not understand the application or its nested trees. Read [the two root scopes](../concepts.md#two-roots-with-different-scopes) and [nested application roots](../concepts.md#a-chain-of-application-roots) for the terms used here.

For CSMT-UTXO, the concrete ledger claim is **membership of an output in the committed UTxO set**, under the scheme’s encoding. The proof does not independently rerun Cardano transaction validation or establish canonicality.

The two proof values have different temporal roles. **Ledger proofs concern on-chain validity in the present**, meaning the ledger state at the selected chainpoint. **Application proofs concern on-chain validation in the future**, when a proposed transaction executes.

| Proof value | What it establishes or supports | Where it is checked |
| --- | --- | --- |
| Ledger proof | A claim about the already established ledger state at the selected chainpoint: the present facts used for construction. | Off-chain, by the terminal against an accepted anchor commitment. |
| Application proof | Evidence for the application validator to check a proposed transition: future validation. | In the terminal before use, then on-chain from the transaction redeemer. |

“Present” is chainpoint-relative, not a promise that an old view remains the chain tip. “Future validation” describes the proof's role, not a guarantee that the submitted transaction succeeds after intervening state changes.

Before acquiring a session, the terminal [finds a usable chainpoint](../design/chainpoints.md#find-a-usable-chainpoint): an accepted anchor publication and a provider offer must agree on the network, chainpoint and commitment scheme. Provider availability is a claim to confirm at acquisition, not a source of trusted roots.

<!-- diagram: proof-composition -->
<div class="diagram"><a href="../diagrams/proof-composition.png?v=d37d9a9efc1520f7"><img src="../diagrams/proof-composition.png?v=d37d9a9efc1520f7" alt="The terminal selects an accepted and available chainpoint, acquires a session, verifies the NFT output, then checks the application proof against its authenticated root." width="660" loading="lazy"></a></div>
<p class="diagram-links"><a href="../diagrams/proof-composition.png?v=d37d9a9efc1520f7">Open full size</a> · <a href="../diagrams/proof-composition.mmd?v=867014ec3a114c43">Mermaid source</a></p>

Application builders may generate proofs on behalf of terminals. A terminal may instead reconstruct the tree locally. The application root comes from the verified state output; it is distinct from the ledger root. A reused proof must match the receiving context's claim, encoding and root. Valid evidence at an old chainpoint is not a promise that a future transaction will still be admissible.

**Transaction boundary:** ledger proofs remain off-chain and are not included in transaction redeemers. A terminal uses them to check the ledger data it builds from. Application-level proofs are included in redeemers and checked by the application validators against the on-chain application state. Cardano validates inputs, value conservation and the other applicable ledger rules against its actual state; it does not consume the terminal's CSMT witness as a substitute for those checks. Signed anchor-root publication remains separate from transaction submission.

Historical transactions may be untrusted reconstruction material. Matching the reconstructed tree to an authenticated root establishes the resulting committed state under the application's reconstruction rules; it does not automatically prove every asserted historical event or the completeness of arbitrary transaction-history queries.

## External effects and settlement

Before an irreversible effect, the terminal must apply an explicit settlement condition as well as verify the fact and authorize the action. A signature records an anchor's observation; a valid proof at that chainpoint cannot establish that its block will remain on the selected chain.

The policy must define the required chain depth or settlement evidence, how later accepted publications establish continued ancestry, and what happens if the point is abandoned or evidence is unavailable. Cardano settlement is probabilistic: the threshold must reflect the network's consensus assumptions and the effect's risk tolerance. Agreement among several anchors at one chainpoint does not replace this condition. See [Cardano's settlement problem statement](https://cips.cardano.org/cps/CPS-0017).

Unlike a submitted transaction, a real-world effect is not rechecked by Cardano before execution. Lockness must refuse or defer the effect when its settlement policy is unsatisfied; the concrete policy and supporting publication evidence remain open contracts.

## Service boundary

The ledger provider retains transaction CBOR and ledger references. It must understand enough ledger structure to index and follow the chain, but does not decide what a redeemer means for MPFS or Singular. [History coverage](../design/chainpoints.md#history-coverage-before-costing) and spent/reference-input resolution must be specified before sizing the ledger provider. Application proof builders interpret datums, redeemers and other application-relevant transaction fields.

Not every response needs a proof. Each endpoint must state its claim and whether its payload is authenticated evidence or untrusted reconstruction material. Evidence-bearing responses may bundle data and proofs. Separate retrieval can remain possible, but Koios wire compatibility is not a requirement for the stronger chainpoint contract.

## Decisions

| Chosen direction | Alternative | Reason |
| --- | --- | --- |
| Generic chain-following engine reused across anchor and provider roles | A full chain indexer for every application | Keep infrastructure cost in reusable ledger capabilities. |
| Independent signed commitments plus verifying terminals | Trust the data server's own advertised root | Separate data availability from authority. |
| Optional application proof builder | Require every terminal to reconstruct every proof | Permit delegation of computation without delegating correctness. |
| Preserve transaction CBOR and resolve required references | Select a small set of fields based on one application | Other applications may consume different transaction fields. |

Continue with [chainpoint sessions](../design/chainpoints.md), [the existing projects](../projects.md), or [decisions and evidence](../design/decisions.md).

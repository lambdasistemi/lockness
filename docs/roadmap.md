# Delivery roadmap

As a project maintainer, fund generic chain-following capabilities and make one complete application journey verifiable before expanding the service surface.

## Delivery dependencies

The next outcome is a reviewable contract for a terminal to verify an application claim through a chain of roots while purchasing data availability. Work proceeds through the dependencies below; this is a proposed project structure, not a claim that teams or implementation milestones have started.

<!-- diagram: roadmap -->
<div class="diagram"><a href="diagrams/roadmap.png?v=a7b74cfeb7dd25a4"><img src="diagrams/roadmap.png?v=a7b74cfeb7dd25a4" alt="Root, session and availability contracts feed engine measurement and a complete verification journey before implementation work is assigned." width="604" loading="lazy"></a></div>
<p class="diagram-links"><a href="diagrams/roadmap.png?v=a7b74cfeb7dd25a4">Open full size</a> · <a href="diagrams/roadmap.mmd?v=6c53d6bbd5ad273f">Mermaid source</a></p>

The contract workstreams can be developed together. The complete journey depends on all of them: measurements alone cannot settle trust or rollback behavior, and correct proofs alone cannot establish provider availability.

| Workstream | Concrete deliverable | Ready to advance when |
| --- | --- | --- |
| [Roots and proof composition](architecture/system.md#proof-composition) | Root scopes, network/chainpoint bindings, publication policy, proof and datum encodings, and rules for nested application roots | A terminal can identify the exact claim at every link and reject substituted roots, applications and evidence |
| [Chainpoint sessions and history](design/chainpoints.md) | Acquisition, lease, retention, rollback and archive-coverage contracts, with an executable session model | Reviewed model statements, explicit cryptographic assumptions, counterexamples and a playable simulation expose the promised success and refusal behavior |
| [Availability and substitution](design/trust-and-availability.md#what-applications-buy) | Observable service offers and a provider-switching contract | Coverage and failures can be measured, and switching preserves root policy, selected chainpoint and claim strength |

The sections below define the remaining deliverables and their exit evidence. Each can become an implementation epic after its contract and owning repository are agreed.

## Settle the chainpoint contract

Record the remaining rulings, create a small executable Lean model, audit its statements, and use proofs and a playable simulation to expose conflicting guarantees. Model cryptography through explicit assumptions; do not claim that a session model proves cryptographic soundness. Team selection and execution are a later decision.

Exit evidence: reviewed behavior for acquisition, reads, expiry, eviction and abandoned branches, including explicit refusals. A session cannot silently move to another chainpoint. History queries must declare the coverage needed for application reconstruction.

## Specify the trust and availability offers

Describe both deployment choices: an operator runs its own anchor for maximum trust independence, or observes chosen institutional publications for low local infrastructure cost under explicit institutional trust. Define root acceptance separately from the purchased data service. No live institutional participation is assumed.

Turn the [availability dimensions](design/trust-and-availability.md#what-applications-buy) into observable service contracts. Specify compatible proof/claim encodings, provider-local session acquisition, missing-coverage responses and switching without changing anchor policy. Resolve rollback behavior before promising session availability. Discovery, billing and remedies remain integration choices, not prerequisites to invent an on-chain marketplace.

Exit evidence: separate root-acceptance and data-delivery contracts for both trust choices, plus a declared verification boundary for the two untrusted services: ledger providers and application proof builders. The provider offer names what is measured and how unavailability is reported.

## Measure the ledger engine

Assess the existing [CSMT-UTXO engine](projects.md#csmt-utxo-the-existing-engine), RocksDB and rollback interfaces against the accepted contract. Prototype content retention and bounded chainpoint views. Measure ingestion cost, storage growth, chainpoint acquisition, query latency and concurrent sessions. Reuse existing code where the contract fits; do not assume every existing abstraction does.

Measure the anchor's node, validation and current commitment maintenance separately from the ledger service's historical storage, retained views and query/proof capacity. Use those measurements to explain what an operator retains locally and what applications can purchase. Do not infer negligible anchor cost or optimal prices.

Exit evidence: reproducible measurements bound to the engine revision, hardware, network or replay data, initial state size and query load. Compare complete commitment maintenance with clearly identified baselines; publish retention, ingestion and concurrent-read tradeoffs. Select a storage mechanism only after those costs are visible.

## Demonstrate one complete journey

<!-- diagram: roadmap-journey -->
<div class="diagram"><a href="diagrams/roadmap-journey.png?v=7f90550b39a7ee88"><img src="diagrams/roadmap-journey.png?v=7f90550b39a7ee88" alt="The terminal keeps one accepted chainpoint and root policy while checking ledger evidence from two providers and application proofs from an untrusted builder; failed evidence is rejected before action." width="784" loading="lazy"></a></div>
<p class="diagram-links"><a href="diagrams/roadmap-journey.png?v=7f90550b39a7ee88">Open full size</a> · <a href="diagrams/roadmap-journey.mmd?v=ec6814596749f58c">Mermaid source</a></p>

Use independently configured publisher keys, a pinned chainpoint and one NFT. Verify its ledger witness, retrieve the complete reconstruction inputs, interpret the application, match the reconstructed root and verify an application proof before transaction construction.

Exercise chain advance, rollback, missing history, expired sessions, altered data and mismatched roots. Preserve explicit refusals. A passing happy path is insufficient.

Run the journey against two compatible providers. Switch at the same network and chainpoint with unchanged anchor policy, acquire provider-local sessions, and check equivalent claims. Exercise unavailable replacement coverage and attempted root substitution. Repeat with locally established roots and a test institutional publication policy, clearly identified as test publishers. These are the product acceptance targets behind the scaling proposition.

Exit evidence: a terminal accepts equivalent claims from both providers, rejects invalid ledger and application evidence, and refuses unavailable history or views. Demonstrate a nested application root with each link checked. Preserve the distinction between locally verified transaction construction and actual on-chain validation; a real-world effect uses its own authorization policy.

## Assign implementation work

Reconcile the [existing internal milestone](https://github.com/lambdasistemi/cardano-utxo-csmt/milestone/3) and [HTTP milestone](https://github.com/lambdasistemi/cardano-utxo-csmt/milestone/4) with the accepted project contracts. They currently describe an earlier architecture. No issue is moved, closed or accepted merely by creating this repository.

The project-level record belongs here. Component code and repository-specific acceptance belong in their implementation repositories. Broader ledger queries, additional publisher operations and application services follow demonstrated need.

| Role | Work to assign after contract agreement | Acceptance boundary |
| --- | --- | --- |
| Anchors | Independent root computation and publication, own-anchor and institutional-policy integration | Correct network, chainpoint, scheme and root binding; measured operating cost |
| Ledgers | Retained views, history/reference retrieval and generic proofs | Covered claims verify; session, rollback and coverage behavior match the agreed contract |
| Applications | Application interpretation, reconstruction and proof construction | Untrusted outputs verify against the authenticated application root, including nested roots |
| Terminals | Root policy, proof composition, provider switching and action policy | All required evidence is checked before transaction construction or external action |

Exit evidence: implementation issues trace to these contracts and demonstrations, with the old CSMT epics reconciled explicitly. This planning document does not itself move those tickets or release their pause.

## Delivery status

This bootstrap supplies a reviewable design record and documentation checks. It starts no implementation workers, changes no production deployment and releases no existing paused lane. There is no product release pipeline until a releasable artifact and its owning repository are selected.

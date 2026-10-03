# Delivery roadmap

As a project maintainer, fund generic chain-following capabilities and make one complete application journey verifiable before expanding the service surface.

## Settle the chainpoint contract

Record the remaining rulings, create a small executable Lean model, audit its statements, and use proofs and a playable simulation to expose conflicting guarantees. Model cryptography through explicit assumptions; do not claim that a session model proves cryptographic soundness. Team selection and execution are a later decision.

## Specify the trust and availability offers

Describe both deployment choices: an operator runs its own anchor for maximum trust independence, or observes chosen institutional publications for low local infrastructure cost under explicit institutional trust. Define root acceptance separately from the purchased data service. No live institutional participation is assumed.

Turn the [availability dimensions](design/trust-and-availability.md#what-applications-buy) into observable service contracts. Specify compatible proof/claim encodings, provider-local session acquisition, missing-coverage responses and switching without changing anchor policy. Resolve rollback behavior before promising session availability. Discovery, billing and remedies remain integration choices, not prerequisites to invent an on-chain marketplace.

## Measure the ledger engine

Assess the existing [CSMT-UTXO engine](projects.md#csmt-utxo-the-existing-engine), RocksDB and rollback interfaces against the accepted contract. Prototype content retention and bounded chainpoint views. Measure ingestion cost, storage growth, chainpoint acquisition, query latency and concurrent sessions. Reuse existing code where the contract fits; do not assume every existing abstraction does.

Measure the anchor's node, validation and current commitment maintenance separately from the ledger service's historical storage, retained views and query/proof capacity. Use those measurements to explain what an operator retains locally and what applications can purchase. Do not infer negligible anchor cost or optimal prices.

## Demonstrate one complete journey

Use independently configured publisher keys, a pinned chainpoint and one NFT. Verify its ledger witness, retrieve the complete reconstruction inputs, interpret the application, match the reconstructed root and verify an application proof before transaction construction.

Exercise chain advance, rollback, missing history, expired sessions, altered data and mismatched roots. Preserve explicit refusals. A passing happy path is insufficient.

Run the journey against two compatible providers. Switch at the same network and chainpoint with unchanged anchor policy, acquire provider-local sessions, and check equivalent claims. Exercise unavailable replacement coverage and attempted root substitution. Repeat with locally established roots and a test institutional publication policy, clearly identified as test publishers. These are the product acceptance targets behind the scaling proposition.

## Assign implementation work

Reconcile the [existing internal milestone](https://github.com/lambdasistemi/cardano-utxo-csmt/milestone/3) and [HTTP milestone](https://github.com/lambdasistemi/cardano-utxo-csmt/milestone/4) with the accepted project contracts. They currently describe an earlier architecture. No issue is moved, closed or accepted merely by creating this repository.

The project-level record belongs here. Component code and repository-specific acceptance belong in their implementation repositories. Broader ledger queries, additional publisher operations and application services follow demonstrated need.

## Delivery status

This bootstrap supplies a reviewable design record and documentation checks. It starts no implementation workers, changes no production deployment and releases no existing paused lane. There is no product release pipeline until a releasable artifact and its owning repository are selected.

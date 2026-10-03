# Delivery roadmap

As a project maintainer, fund generic chain-following capabilities and make one complete application journey verifiable before expanding the service surface.

## Settle the chainpoint contract

Record the remaining rulings, create a small executable Lean model, audit its statements, and use proofs and a playable simulation to expose conflicting guarantees. Model cryptography through explicit assumptions; do not claim that a session model proves cryptographic soundness. Team selection and execution are a later decision.

## Measure the ledger engine

Assess the existing CSMT, RocksDB and rollback interfaces against the accepted contract. Prototype content retention and bounded chainpoint views. Measure ingestion cost, storage growth, chainpoint acquisition, query latency and concurrent sessions. Reuse existing code where the contract fits; do not assume every existing abstraction does.

## Demonstrate one complete journey

Use independently configured publisher keys, a pinned chainpoint and one NFT. Verify its ledger witness, retrieve the complete reconstruction inputs, interpret the application, match the reconstructed root and verify an application proof before transaction construction.

Exercise chain advance, rollback, missing history, expired sessions, altered data and mismatched roots. Preserve explicit refusals. A passing happy path is insufficient.

## Assign implementation work

Reconcile the [existing internal milestone](https://github.com/lambdasistemi/cardano-utxo-csmt/milestone/3) and [HTTP milestone](https://github.com/lambdasistemi/cardano-utxo-csmt/milestone/4) with the accepted project contracts. They currently describe an earlier architecture. No issue is moved, closed or accepted merely by creating this repository.

The project-level record belongs here. Component code and repository-specific acceptance belong in their implementation repositories. Broader ledger queries, additional publisher operations and application services follow demonstrated need.

## Delivery status

This bootstrap supplies a reviewable design record and documentation checks. It starts no implementation workers, changes no production deployment and releases no existing paused lane. There is no product release pipeline until a releasable artifact and its owning repository are selected.

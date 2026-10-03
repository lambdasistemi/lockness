# Projects and existing evidence

As an integrator, move from a Lockness role to the existing project, documentation and evidence behind it. Lockness defines the cross-project contracts; these repositories own implementations.

## CSMT-UTXO: the existing engine

[Cardano UTxO CSMT](https://github.com/lambdasistemi/cardano-utxo-csmt) already follows the chain, maintains a compact sparse Merkle tree over the live UTxO set, computes roots and serves inclusion proofs. It is the existing engine to assess for both Lockness anchor commitment maintenance and ledger data/proof services.

Use its [architecture](https://lambdasistemi.github.io/cardano-utxo-csmt/architecture/), [database schema](https://lambdasistemi.github.io/cardano-utxo-csmt/database-schema/), [getting started guide](https://lambdasistemi.github.io/cardano-utxo-csmt/getting-started/) and [API reference](https://lambdasistemi.github.io/cardano-utxo-csmt/swagger-ui/) to explore what exists.

Its [benchmark code](https://github.com/lambdasistemi/cardano-utxo-csmt/tree/main/bench) covers CSMT insertion, storage and deserialization paths. Start cost assessment there and at its [runtime metrics](https://github.com/lambdasistemi/cardano-utxo-csmt#rest-api). Benchmark definitions are not a measured Lockness deployment budget: distinguish full commitment maintenance from KV-only baselines, include the node's cost, and measure the additional archive, retained-view and serving workload separately. See the [measurement roadmap](roadmap.md#measure-the-ledger-engine).

The existing [internal-index epic](https://github.com/lambdasistemi/cardano-utxo-csmt/issues/240) and [HTTP epic](https://github.com/lambdasistemi/cardano-utxo-csmt/issues/246) need reconciliation with Lockness contracts. Their existence does not establish the new service guarantees.

## Application consumers

| Project | Explore | Connection to Lockness |
| --- | --- | --- |
| MPFS | [Repository and documentation](https://github.com/lambdasistemi/cardano-mpfs-offchain) · [existing facts verifier](https://github.com/lambdasistemi/cardano-mpfs-offchain/blob/0f82465f5f828c2ab987a166e9e24c2368228d01/cardano-mpfs-verify/lib/Cardano/MPFS/Client/Verify/Read.hs) | Prior implementation checks reconstructed facts against the application root in an anchored state output. |
| Singular | [Repository and documentation](https://github.com/lambdasistemi/singular) | Application consumer whose state interpretation and proof construction stay outside the generic ledger service. |

Follow the [asset and NFT concepts](concepts.md#assets-and-nft-state-outputs) into the [proof-composition sequence](architecture/system.md#proof-composition). The proposed history-retrieval integration still needs the [complete journey](roadmap.md#demonstrate-one-complete-journey); these links do not claim it is delivered.

## Assess the evidence

The [decision record](design/decisions.md#evidence-available-today) distinguishes existing MPFS verification and CSMT work from unresolved Lockness guarantees. The [roadmap](roadmap.md) describes the next evidence needed. The [trust and availability model](design/trust-and-availability.md) explains which commitments applications would purchase.

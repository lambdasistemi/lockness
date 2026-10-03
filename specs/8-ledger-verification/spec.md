# Verify an application root from a ledger answer

As a design reviewer, run a terminal's ledger verification at a selected chainpoint. An honest answer returns the application root parsed from the authenticated output. A witness valid only under a provider's substituted root returns `evidenceFailure` at the selected point. Two honest outputs carrying the same asset demonstrate why membership alone cannot establish a unique application root.

## Architectural contract

The terminal supplies an independently accepted root for the exact network, slot and block hash. Session acquisition establishes point coherence; its provider root field supplies no endorsement. Ledger and application providers remain arbitrary. Cryptography, object interpretation and asset uniqueness are explicit hypotheses.

## Requirements

| Name | Required outcome |
| --- | --- |
| finite-ledger | Ground truth is `Chainpoint → Finset (TxIn × TxOut)` with genuine finite-set semantics; duplicate assets remain representable. |
| accepted-root-bound-witness | The witness is checked against the independently accepted argument, never an answer or session root. |
| exact-object-binding | Input, output, asset and datum observations refer to the same witnessed object bytes, preserved without normalization. |
| selected-point-binding | Every accepted answer identifies the exact selected network, slot and block hash; every verification refusal carries that selected point. |
| schema-bound-interpretation | Asset identity matches policy; datum bytes parse under policy schema to a root or verification refuses. |
| unique-output-soundness | With honest-root correspondence, witness/observation soundness and separate OneShot, acceptance identifies the unique asset-bearing honest output and its datum root. |
| nonvacuous-honest-witness | An honest finite ledger, accepted root, successful answer and all soundness premises are inhabited together. |
| substituted-root-refutation | The same witness checks under the provider root and fails at the actual accepted-root check; earlier guards succeed. |
| duplicate-asset-refutation | Without OneShot, two distinct honest members with the same asset and different datum roots are accepted; the unchanged unique-output claim is constructively false. |
| runnable-ledger-scenarios | `lockness-sim ledger honest`, `substituted-root` and `duplicate-asset` exercise the actual verifier and discriminating witnesses. |
| inherited-contract-preservation | Preserve root/session semantics, lifecycle, three refusal constructors, original byte fields, controls and all-source theorem inventory. |
| reviewable-delivery | Matching docs/speech, accessible source/preview, persistent independent checkpoint audit, final-head local checks and exact-head remote CI precede readiness. |

## Evidence boundary

Proofs establish model properties under stated premises. Simulator outcomes establish concrete model paths. Documentation and CI have separate revision-bound receipts. Component implementation, witness construction, CSMT/Plutus/storage, wire formats, leases, pricing, deployment and live-chain acceptance remain outside this ticket. The paused cardano-utxo-csmt lane stays paused.

## Shared-interface authority

The epic owner's ledger-interface-v1 ruling approves the concrete successor interface, dependency and path fence. The frozen planning contract below records that release; no broader component or successor-ticket work follows.

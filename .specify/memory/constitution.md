# Lockness constitution

## Purpose

Lockness enables terminals to consume anchored data: verify the claims behind transactions and real-world actions while choosing trust independently of data provision. It owns the project-level design for independently endorsed Cardano ledger commitments, evidence at selected chainpoints, and application verification. Component implementation remains separately owned.

## Core principles

1. Documentation, specifications, vision and acceptance outrank implementation. Code is regenerable from a good record; the record is not regenerable from code. Every change updates its documentation in the same diff. Acceptance is stated in user-visible terms before code; scope reductions must not erase the record.
2. Data provision and trust provision are distinct. Clients explicitly select trusted publishers and verify evidence before using facts.
3. A session never silently changes chainpoint. Network, slot, block hash, commitment identity and version must be unambiguous.
4. Ledger services remain application independent. Preserve transaction information; application libraries interpret its meaning.
5. Proof construction may be delegated. Verification, exact claim binding and the client's trust policy may not be replaced by provider assertions.
6. Historical material, authenticated membership, completeness, currentness and application-state reconstruction are distinct claims.
7. Reuse one generic chain-following engine across appropriate deployment roles; independently endorsed roots require an explicit trusted ledger source, not blind signing of a provider's root.

8. Ledger witnesses are off-chain verification evidence for terminals, not transaction redeemers. Application proofs enter redeemers and are checked by application validators; Cardano checks transaction validity against its actual ledger state. Anchor root publication is separate.

9. Distinguish proof values by time and purpose: ledger proofs concern on-chain validity at the selected chainpoint (present); application proofs concern on-chain validation of a proposed transaction (future). Neither a historical witness nor preflight verification promises future transaction acceptance.

## Development

Design direction, accepted model, source behavior, tests, deployment and release are reported separately. Use Nix-backed documentation checks. Change shared contracts through a reviewed decision and preserve counterexamples. Do not infer authorization to launch teams, merge implementations or publish releases from a planning artifact.

## Governance

Unresolved decisions remain visible. The initial design has no accepted Lean model or implementation correspondence evidence. Changes to promised behavior require an explicit ruling and revision of the affected model, stories and acceptance criteria.

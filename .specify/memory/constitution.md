# Lockness constitution

## Purpose

Lockness enables terminals to consume anchored data: verify the claims behind transactions and real-world actions while choosing trust independently of data provision. It owns the project-level design for independently endorsed Cardano ledger commitments, evidence at selected chainpoints, and application verification. Component implementation remains separately owned.

A terminal is a lightweight Web2 application with cryptographic capabilities. Its application purpose and risk determine trust, freshness and action policy. It selects a chainpoint, retrieves untrusted data and independently accepted anchor evidence, verifies the required asset claims, then enables blockchain transaction construction or off-chain data consumption. It does not require a per-application chain follower.

The project proposition is Web2 scaling with explicit trust management: applications purchase availability and computation from competing providers while terminals retain control over accepted evidence.

## Core principles

1. Documentation, specifications, vision and acceptance outrank implementation. Code is regenerable from a good record; the record is not regenerable from code. Every change updates its documentation in the same diff. Acceptance is stated in user-visible terms before code; scope reductions must not erase the record.
2. Data provision and trust provision are distinct. Clients explicitly select trusted publishers and verify evidence before using facts.
3. A session never silently changes chainpoint. Network, slot, block hash, commitment identity and version must be unambiguous.
4. Ledger services remain application independent. Preserve transaction information; application libraries interpret its meaning.
5. Proof construction may be delegated. Verification, exact claim binding and the client's trust policy may not be replaced by provider assertions.
   Both ledger providers and `lockness-applications` services are untrusted for correctness. A ledger proof authenticates the UTxO and datum that carry an application root; application proofs may authenticate values carrying further roots. Every link and its interpretation must be checked before the terminal consumes a descendant claim.
6. Historical material, authenticated membership, completeness, currentness and application-state reconstruction are distinct claims.
7. Reuse one generic chain-following engine across appropriate deployment roles; independently endorsed roots require an explicit trusted ledger source, not blind signing of a provider's root.

8. Ledger witnesses are off-chain verification evidence for terminals, not transaction redeemers. Application proofs enter redeemers and are checked by application validators; Cardano checks transaction validity against its actual ledger state. Anchor root publication is separate.

9. Distinguish proof values by time and purpose: ledger proofs concern on-chain validity at the selected chainpoint (present); application proofs concern on-chain validation of a proposed transaction (future). Neither a historical witness nor preflight verification promises future transaction acceptance.

10. Running your own anchor is the optimal deal for trust independence; observing chosen institutional publications is an exceptionally attractive operational deal with explicit institutional trust. Both permit outsourcing ledger services. Do not imply equal trust assumptions or negligible anchor cost.
11. Availability is a priced commitment between applications and providers. Correctness verification and delivery obligations are separate contracts. Provider switching must preserve accepted roots, chainpoints and claim strength, or explicitly refuse unavailable coverage.
12. Market-driven scaling is a project objective requiring interoperable evidence, practical switching and measurable service commitments. Do not claim demonstrated optimal economics from a design alone.

## Development

Design direction, accepted model, source behavior, tests, deployment and release are reported separately. Use Nix-backed documentation checks. Change shared contracts through a reviewed decision and preserve counterexamples. Do not infer authorization to launch teams, merge implementations or publish releases from a planning artifact.

## Governance

Unresolved decisions remain visible. The initial design has no accepted Lean model or implementation correspondence evidence. Changes to promised behavior require an explicit ruling and revision of the affected model, stories and acceptance criteria.

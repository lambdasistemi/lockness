# Selected-point sessions

As a design reviewer, run the session simulator and observe acquisition at exactly the selected chainpoint or `unavailablePoint` carrying that point. A provider offering a newer point must be refused.

## Stories and requirements

- **selected-point-acquisition:** For an unrestricted provider, successful acquisition preserves full network, slot and block-hash identity. Returned session root fields and bytes remain unchanged.
- **absent-point-refusal:** Every provider returning no session at the selected point produces `unavailablePoint` at that point.
- **mismatched-point-refusal:** Sessions at a newer slot, another hash at the same slot, or another network are refused at the selected point.
- **session-lifecycle:** Requested sessions become active or unavailable; active reads retain the session; expiry and release lead to expired and closed states; further expired reads refuse `unavailablePoint` at the original point.
- **semantic-no-substitution-control:** A compiled production acquisition mutation accepting a newer session constructively falsifies the unchanged general no-substitution proposition and rejects its unchanged proof. Setup failures do not count.
- **reviewer-scenarios:** `lockness-sim session` executes honest, absent-point and newer-point scenarios; expiry-read refusal has a permanent executable check. Unknown commands and scenarios fail with usage errors.
- **predecessor-preservation:** Preserve root behavior, source-wide elaborated theorem inventory and hole/axiom controls, pinned dependency closure and speech delivery alias.
- **reviewable-delivery:** Matching model documentation and speech, independent committed checkpoint approvals, local final-head gates, exact-head remote Build Gate/Docs build and source-bound preview precede readiness.

All requirements are BLOCKING for this scoped acceptance. This is model and documentation evidence, with no component implementation, deployment, settlement or live-chain claim.

## Boundaries

Accepted predecessor: `c1e659af4a0d5766fb512bfbd25707bbd6099603`. `Types.lean` remains frozen at blob `50661f3d80f483c23960404afff23c2a07ca7f2d`. Refusals remain exactly `noRoot`, `unavailablePoint`, `evidenceFailure`. Cryptographic/honest-root assumptions are inherited separately from session acquisition. No leases, retention numbers, resource policy, eviction, genesis-availability ruling, wire formats, storage, HTTP, CBOR or Plutus. Branch abandonment remains owned by #10. Future binaries belong to the implementation milestone.

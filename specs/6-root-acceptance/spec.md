# Root acceptance contract

As a design reviewer, I run `lake exe lockness-sim accept-root <scenario>` in `lean/` and see the accepted root or `no-root`, with the selected point.

Authority: Lockness #6 and #16, the ticket brief and approved four-seat roster. Model bootstrap only; no component implementation.

| Row | Invariant | Severity | Required outcome |
| --- | --- | --- | --- |
| pinned-model-build | Reproducible Lean model | ADVISORY | Pinned `lake build` through check-model and actual CI; no mathlib. |
| exact-protocol-values | Shared exact identities | BLOCKING | Eight named types; unchanged byte values; exactly three refusals carrying selected point; no substitution. |
| abstract-signature-boundary | Abstract signature verification | BLOCKING | Exact acceptRoot interface with explicit executable observations; SigValid stays an uncomputed Prop hypothesis, observation relationship explicit. |
| trusted-root-endorsement | Trusted set and agreement | BLOCKING | Accepted root has a nonempty endorsing set contained in trustedKeys and satisfying agreement at the exact point and root. Duplicate publications do not invent distinct key agreement. |
| untrusted-key-counterexample | Trust independent of validity | BLOCKING | Hypothesis-valid untrusted publication yields noRoot; subset-check mutation accepts it and semantically falsifies the general theorem. |
| axiom-clean-simulator | Proved and runnable evidence | BLOCKING | Every theorem has axiom output without sorryAx; CI rejects holes; honest, untrusted-key and subset-mutation scenarios exercise model paths and check outcomes. |

Agreement cannot authorize an empty endorsement. Root endorsement does not imply honest-ledger-root correspondence: later consumers require a separate explicit hypothesis. No hidden trust-policy strengthening. Syntax, import, tactic and setup failures alone do not establish semantic counterexamples.

Session lifecycle, ledger verification, app proofs, effects, wire formats, cryptography implementation, CSMT internals, storage, lease values and pricing are outside this slice. External functions stay arbitrary. Shared types freeze after accepted merge. No merge or release authority.

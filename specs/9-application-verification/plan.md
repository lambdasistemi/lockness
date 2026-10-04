# Application verification plan

As a reviewer, see how the application step and whole fold extend the accepted root, session and ledger model without changing their behavior.

## Strategy

1. Extend the shared types exactly as released: application proof and value byte aliases, the application query, four policy fields, the session's untrusted ledger answer and the claim.
2. Adapt inherited fixtures mechanically: only the new fields with neutral values; every inherited outcome unchanged.
3. Add the application step (`verifyApp`, `verifyChain`) and its abstract hypotheses, then the whole fold (`accept`), `holds`, soundness, provider invariance and refusal theorems.
4. Add the jointly inhabited fixture, the replaced-root, session-root and ambiguous-value counterexamples, finite refusal tests and the compiled mutation script.
5. Wire the `app` simulator scenarios, usage text and model-gate stages.
6. Update reader-facing documentation and curated speech; publish an immutable model commit, then a forward source-pin documentation commit.

## Constraints

- Root, RootProofs, Session, Ledger and LedgerProofs sources stay byte-identical; acquire, NoSubstitution and every #7/#8 statement unchanged.
- Lean, Mathlib and Nix pins, lakefile, lake manifest, environment, dependency setup, `tools/check-model.sh` and the CI workflow stay unchanged; a need returns as a question.
- Per-link queries are out of scope: every link uses `policy.query` (named limit, reviewed by #11).
- No proof format, wire encoding, CSMT, storage, transaction, settlement or binary release work.

## Slices

| Slice | Content | Commits |
| --- | --- | --- |
| application-model | Types successor, adaptations, App/Accept modules, proofs, fixtures, counterexamples, tests, simulator, mutation script, gate wiring | RED bundle, GREEN candidate, squashed to one behavior commit |
| application-docs | README, model index and decisions pages with speech companions; immutable source links to the model commit | one docs commit, forward-pinned |

## Evidence and limits

Required checks are the CI commands `./tools/check-model.sh` and `./tools/check-docs.sh`, the Docs build job and the PR preview on the exact pushed head. Invocations are counted from receipts: expensive tier 40, cheap tier 250, 900 s per command. Remote main is refreshed before the final verification cycle; a moved base is integrated by a history-preserving merge.

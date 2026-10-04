# Verdict layer plan

As a reviewer, see how the verdict layer wraps the accepted fold. Behaviour changes only where the ruling names it.

## Strategy

1. Extend the shared types exactly as released: Binding, Reconstruction, Reason, Verdict, `Policy.verifier`, `Session.binding`, the optional witness and the optional reconstruction.
2. Add the binding guard and the optional-witness gate to `verifyLedger`. Restate only the ruled supporting statements and keep every named theorem's statement.
3. Adapt inherited fixtures mechanically with neutral values, so that every inherited outcome is unchanged.
4. Add `unverifiedReason`, `verdict`, NoPromotion, the verified soundness and invariance statements and the classification theorems.
5. Add the jointly inhabited fixtures, the promotion counterexample, the finite tests and the compiled mutation script.
6. Wire the seven `verdict` simulator scenarios, the usage text and the model-gate stages.
7. Update the reader-facing documentation and curated speech. Publish an immutable model commit, then a forward source-pin documentation commit.

## Constraints

- Root, RootProofs, Session, App, AppProofs, Accept, AcceptProofs and Axioms stay byte-identical.
- Pins, lakefile, manifest, env, setup-deps, `tools/check-model.sh` and the CI workflow stay unchanged; a need returns as a question.
- An elaborated-statement inventory diff against base shows exactly the ruled restatements and neutral adaptations.
- The verifier-off verdict is `unverified noVerifier` even with no offer: a named limit in docs.
- No `act`, no payload on Verdict, no wire encoding, no concrete verifier or witness format, no CSMT, storage, settlement or binary release.

## Slices

| Slice | Content | Commits |
| --- | --- | --- |
| verdict-model | Types successor, ledger guards, adaptations, Verdict modules, proofs, fixtures, counterexample, tests, simulator, mutation script, gate wiring | RED bundle, GREEN candidate, squashed to one immutable model commit |
| verdict-docs | decisions, model index and README with speech companions; source links pinned to the model commit | one forward docs commit |

## Evidence and limits

The required checks are the CI commands `./tools/check-model.sh` and `./tools/check-docs.sh`, the Docs build job and the PR preview, all on the exact pushed head.

Invocations are counted from receipts and checked before each run:
- expensive tier 40, cheap tier 250 (ruling verdict-interface-v1);
- 900 s per command.

Remote main is refreshed before the final verification cycle. A moved base is integrated by a history-preserving merge.

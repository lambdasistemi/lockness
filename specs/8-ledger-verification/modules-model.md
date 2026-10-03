# Ledger model responsibilities

As a reviewer, follow the dependency boundary from unchanged root/session contracts through ledger verification to model scenarios.

| Module | Responsibility and dependency direction |
| --- | --- |
| shared-types | Own opaque byte identities, policy observations and answer data; additive successor requires epic ruling. No cryptographic implementation. |
| ledger-verification | Own finite honest ledger, witness/observation soundness, separate OneShot, accepted-root verification and observation inversion; depends on shared types. |
| ledger-proofs | Own honest unique-output/datum-root conclusion with each premise explicit; depends on ledger verification and unchanged root endorsement/correspondence contracts. |
| ledger-counterexamples | Own inhabited honest premises and constructive root-substitution/duplicate-asset refutations; depends on real verifier. |
| ledger-simulator | Own executable honest/substituted-root/duplicate-asset observations; consumes actual model and counterexamples. |
| model-integration | Dispatch ledger scenarios and include all modules/theorems/controls in existing pinned gates; preserve root/session paths. |
| model-documents | Explain guarantees, assumptions, alternatives, runnable scenarios and evidence limits with matching curated speech. |

Fields and premises are owned by `data-model.md`; operation signatures are owned by `functions-model.md`. The released exact path fence and dependency pin are in `plan.md`. No implementation bodies or component implementation are specified here.

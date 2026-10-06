# Completeness modules

As a reviewer, see each new responsibility, its dependency direction and the inherited modules it must not change.

| Module | Responsibility | Depends on |
| --- | --- | --- |
| `Lockness.Types` (shared, ruled change) | `CompletenessAnswer`, `LedgerAnswer.completeness`, `Policy.checkCompleteness`, `Policy.assetPrefix`, `Policy.requireCompleteness`; see data-model | Std |
| `Lockness.Ledger` (inherited, ruled change) | the completeness guard after the witness guard, including the requirement; every statement unchanged | Types |
| `Lockness.LedgerProofs` (inherited) | proof bodies of the two inversions follow the guard; statements unchanged | Ledger |
| `Lockness.Verdict` (inherited, ruled change) | the classification change in `unverifiedReason`; every statement unchanged | Accept |
| `Lockness.VerdictProofs` (inherited) | proof bodies of `verdict_unverified` and `verdict_reconstruction_irrelevant` follow the classification; statements unchanged | Verdict |
| `Lockness.Completeness` | key layout, prefix relation, `CompletenessSound`, `AssetKeyLayout`, `EntriesClaim`, `verifyEntries`, `acceptEntries` and the two soundness statements | Context, Session, Ledger |
| `Lockness.CompletenessProofs` | inversions, refusals, the all-entries theorem, uniqueness by completeness and the classification theorems | Completeness, AcceptProofs, VerdictProofs |
| `Lockness.Counterexamples.CompletenessFixtures` | fixture entries, layout, ledgers, completeness observation and policies; jointly inhabited premises | VerdictFixtures, Completeness |
| `Lockness.Counterexamples.CompletenessRefutation` | operation-parameterized refutations and the dropped-hypothesis refutation | CompletenessFixtures |
| `Lockness.Tests.Completeness` | signature ascriptions, every guard's refusal, provider roots and prefixes ignored, reachability | CompletenessProofs, counterexamples |
| `Lockness.Sim.Completeness` | `completeness` scenarios over the real model | counterexamples |
| `checks/completeness-mutations.sh` | compiled mutants against unchanged statements, proofs and the real simulator | built model |

Integration: `Lockness.lean` imports, the `Main.lean` dispatcher and usage text, appended stages in `checks/model.sh`. Neutral adaptations: the four positional `Policy` and seven positional `LedgerAnswer` constructions.

Frozen: `Root`, `RootProofs`, `Session`, `App`, `AppProofs`, `Accept`, `AcceptProofs`, `Context`, `ContextStatements`, `ContextProofs`, `Chain`, `Act`, `ActProofs`, `Axioms`, every other inherited simulator module, test and mutation script, `tools/`, `lean/env`, the build configuration, pins and CI.

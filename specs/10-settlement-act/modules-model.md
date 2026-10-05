# Settlement and act modules

As a reviewer, see each new responsibility, its dependency direction and the inherited modules it must not change.

| Module | Responsibility | Depends on |
| --- | --- | --- |
| `Lockness.Types` (shared, ruled change) | `Branch`, `Chain`, the moved `Reason`, `Policy.settlement`, `Policy.constructUnverified`; see data-model | Std |
| `Lockness.Chain` | chain ground truth (`tip`, `canonical`, `rollback`, `Extends`), the consensus model and the continued-ancestry hypothesis, and the chain lemmas | Types |
| `Lockness.Session` (inherited, ruled change) | the `abandoned` state, its read refusal and the `abandon` transition; `active_transition` restated; every other statement unchanged | Types, Chain |
| `Lockness.Act` | `Action`, `Basis`, `Authorized`, `act`, `SettlementStability` | Verdict, Chain |
| `Lockness.ActProofs` | the act theorems, the settlement theorem and their composition with the verdict layer | Act, VerdictProofs |
| `Lockness.Counterexamples.ActFixtures` | fixture chains, consensus model and settled policy; jointly inhabited premises | VerdictFixtures, ContextFixtures, Act |
| `Lockness.Counterexamples.SettlementRollback` | the rollback refutation, parameterized by operation, and the consensus-premise refutation | ActFixtures, ActProofs |
| `Lockness.Tests.Act` | signature ascriptions, finite outcome tests and reachability, including the `abandon` transition | ActProofs, counterexamples |
| `Lockness.Sim.Effect` | `effect` scenarios over the real verdict and act | counterexamples |
| `checks/effect-mutations.sh` | compiled mutants against unchanged statements, proofs and the real simulator | built model |

Integration: `Lockness.lean` imports, the `Main.lean` dispatcher and usage text, appended stages in `checks/model.sh`. Neutral adaptations: the four positional `Policy` constructions in `Counterexamples/Fixtures.lean` and `Tests/Observation.lean` gain the two neutral values.

Frozen: `Root`, `RootProofs`, `Ledger`, `LedgerProofs`, `App`, `AppProofs`, `Accept`, `AcceptProofs`, `Verdict`, `VerdictProofs`, `Context`, `ContextStatements`, `ContextProofs`, `Axioms`, every inherited simulator module, test and mutation script, `tools/`, `lean/env`, the build configuration, pins and CI.

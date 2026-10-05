# Operating context modules

As a reviewer, see each new responsibility, its dependency direction and the inherited modules it must not change.

| Module | Responsibility | Depends on |
| --- | --- | --- |
| `Lockness.Types` (shared, ruled change) | `Context`, `Policy.context`, `MessageModel`, `MessageBinding`; see data-model | Std |
| `Lockness.Context` | `outOfContext`, `acceptContextRoot`, `ContextSoundness` | Root |
| `Lockness.Accept` (inherited, ruled change) | `accept` binds its root through `acceptContextRoot`; every other line unchanged | Context, Session, Ledger, App |
| `Lockness.AcceptProofs` (inherited, proofs only) | `accept_observations` and `accept_refusal_cases` re-proved; statements unchanged | Accept, ContextProofs |
| `Lockness.Verdict` (inherited, ruled change) | an out-of-context refusal is classified `refused` before the declared-absence reasons | Accept |
| `Lockness.VerdictProofs` (inherited, ruled change) | `unbound_only_unverified` restated as ruled; other statements unchanged | Verdict, AcceptProofs |
| `Lockness.ContextProofs` | refusal and in-context inversions of `acceptContextRoot`, the guard theorems, `verdict_context_sound` | Context, VerdictProofs |
| `Lockness.Counterexamples.ContextFixtures` | context fixtures: honest, other-network selection, foreign-publication (ignored and only-foreign), unaccepted-scheme and unbound-message offers; two abstract-model instances; jointly inhabited premises | AppFixtures, Verdict |
| `Lockness.Counterexamples.ContextRefutation` | guard-removal and binding-removal refutations, parameterized by operation | ContextFixtures, Context |
| `Lockness.Tests.Context` | signature ascriptions and finite outcome tests | ContextProofs, counterexamples |
| `Lockness.Sim.Context` | `context` scenarios over the real verdict and accept | counterexamples |
| `checks/context-mutations.sh` | compiled mutants against unchanged statements, proofs and the real simulator | built model |

Integration: `Lockness.lean` imports, the `Main.lean` dispatcher and usage text, appended stages in `checks/model.sh`. Neutral adaptations: the four positional `Policy` constructions in `Counterexamples/Fixtures.lean` and `Tests/Observation.lean` gain the neutral context; `Tests/Verdict.lean` mirrors the restated `unbound_only_unverified`.

Frozen: `Root`, `RootProofs`, `Session`, `Ledger`, `LedgerProofs`, `App`, `AppProofs`, `Axioms`, every inherited simulator module, every inherited mutation script, `tools/`, the build configuration, pins and CI.

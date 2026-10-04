# Application verification modules

As a reviewer, see each new responsibility, its dependency direction and the inherited modules it must not change.

| Module | Responsibility | Depends on |
| --- | --- | --- |
| `Lockness.Types` (shared) | Released successor declarations only; see data-model | Std |
| `Lockness.App` | Builder, application tree semantics and hypotheses, chain semantics, `verifyApp`, `verifyChain` | Types, Mathlib Set |
| `Lockness.Accept` | Whole fold `accept`, `holds`, `AcceptSoundness`, `ProviderInvariance` | Root, Session, Ledger, App |
| `Lockness.AppProofs` | Application step inversion, claimed-root-first and refusal theorems | App |
| `Lockness.AcceptProofs` | Fold refusal, soundness and provider-invariance theorems | Accept, AppProofs, RootProofs, Session, LedgerProofs |
| `Lockness.Counterexamples.AppFixtures` | Jointly inhabited finite fixture for every premise | Accept, LedgerFixtures |
| `Lockness.Counterexamples.AppRootMutation` | Replaced-root and session-root refutations parameterized by an operation | AppFixtures |
| `Lockness.Counterexamples.AppAmbiguity` | Invariance statement without `AppFunctional` and its constructive refutation | AppFixtures |
| `Lockness.Tests.App` | Signature ascriptions, honest acceptance and finite refusal tests | AcceptProofs, counterexamples |
| `Lockness.Sim.App` | `app` scenarios over the real fold | counterexamples |
| `checks/app-mutations.sh` | Compiled production mutations against unchanged statements and the real simulator | built model |

Integration: `Lockness.lean` imports, `Main.lean` dispatcher and usage text, `checks/model.sh` appended stages and usage controls. Mechanical adaptations: fixtures that construct `Policy` or `Session` positionally gain only the new fields with neutral values.

Frozen: `Root`, `RootProofs`, `Session`, `Ledger`, `LedgerProofs`, `Sim.AcceptRoot`, `Sim.Ledger`, existing mutation scripts, build configuration and pins.

# Verdict layer modules

As a reviewer, see each new responsibility, its dependency direction and the inherited modules it must not change.

| Module | Responsibility | Depends on |
| --- | --- | --- |
| `Lockness.Types` (shared) | Released successor declarations only; see data-model | Std |
| `Lockness.Ledger` (inherited, ruled change) | `verifyLedger` binding guard and optional-witness gate; every other definition unchanged | Types |
| `Lockness.LedgerProofs` (inherited, ruled change) | `verifyLedger_observations` restated as ruled; other statements unchanged | Ledger |
| `Lockness.Verdict` | `unverifiedReason`, `verdict`, `NoPromotion`, `VerdictSoundness`, `VerdictProviderInvariance` | Accept |
| `Lockness.VerdictProofs` | Accept binding/witness inversion, no promotion, verified iff, refused/unverified characterizations, wrong-witness, unbound and misbound theorems, verified soundness and invariance, reconstruction irrelevance | Verdict, AcceptProofs, LedgerProofs |
| `Lockness.Counterexamples.VerdictFixtures` | Seven offers over the #9 fixture policy; jointly inhabited premises with a verified verdict | AppFixtures, Verdict |
| `Lockness.Counterexamples.VerdictPromotion` | Promotion and verifier-ignored refutations of NoPromotion and VerdictSoundness parameterized by an operation | VerdictFixtures |
| `Lockness.Tests.Verdict` | Signature ascriptions and finite outcome tests of every fixture | VerdictProofs, counterexamples |
| `Lockness.Sim.Verdict` | `verdict` scenarios over the real verdict and accept | counterexamples |
| `checks/verdict-mutations.sh` | Compiled production mutations against unchanged statements, proofs and the real simulator | built model |

Integration: `Lockness.lean` imports, the `Main.lean` dispatcher and usage text, and appended stages in `checks/model.sh`. Mechanical adaptations: inherited constructions gain only the new fields with neutral values. `checks/ledger-mutations.sh` follows the new witness-gate fragment.

Frozen: `Root`, `RootProofs`, `Session`, `App`, `AppProofs`, `Accept`, `AcceptProofs`, `Axioms`, the other mutation scripts, the build configuration and the pins.

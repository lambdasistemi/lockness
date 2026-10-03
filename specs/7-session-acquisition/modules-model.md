# Session responsibilities

As a reviewer, locate the owner of acquisition, lifecycle and observable scenarios without changing the shared protocol types.

| Module | Responsibility | Dependency direction |
| --- | --- | --- |
| `Lockness.Session` | Full-point acquisition, definitional point accessor, lifecycle and general proofs | Consumes frozen `Lockness.Types`; no ledger, app or effect dependencies |
| `Lockness.Sim.Session` | Honest, absent and newer-point journeys with discriminating outcomes | Consumes session model and named verification witnesses |
| `Lockness.Tests.Session` | Permanent session/lifecycle and identity checks | Consumes session model |
| `Lockness.Counterexamples.SessionMutation` | Constructive semantic no-substitution refutation | Consumes session model; no shared type replacement |

Integration is restricted to `lean/Main.lean`, `lean/Lockness.lean`, `lean/checks/model.sh`, `lean/checks/mutations.sh`, optional `lean/checks/session-mutations.sh`. Preserve all existing root behavior and dependency portability. Documentation paths are the released model page/speech alias, README/speech and decisions/speech only for delivered session behavior. The data and functions models specify this module's contract; no upstream abstraction is changed.

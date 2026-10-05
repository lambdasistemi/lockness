# Operating context functions

As a reviewer, see every new or changed signature with explicit argument names. Statements are as ruled in context-interface-v1 (answers/A-001 with C1); the exact frozen text is in the ticket gate.

## Changed

| Name | Arguments → result | Constraint |
| --- | --- | --- |
| `accept` | unchanged signature | Binds its root through `acceptContextRoot` instead of `acceptRoot`; every later step unchanged |
| `verdict` | unchanged signature | After accept's refusal, an out-of-context selection is `refused` before the declared-absence reasons; the verifier switch stays first |
| `unbound_only_unverified` | inherited binders plus `(inContext : outOfContext policy publications selectedPoint = false)` | Ruled restatement; conclusion unchanged |

## New

| Name | Arguments → result | Constraint |
| --- | --- | --- |
| `outOfContext` | `(policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint) → Bool` | Reads no provider or builder |
| `acceptContextRoot` | `(policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint) → Except Refusal Root` | `evidenceFailure selectedPoint` when out of context, else `acceptRoot` unchanged |
| `ContextConclusion` | `[SignatureModel] [MessageModel] (policy : Policy) (publications : List Publication) (claim : Claim) → Prop` | Network, scheme and exact message binding of the endorsements |
| `ContextSoundness` | `[SignatureModel] [MessageModel] (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict) → Prop` | Premises `ObservationSound policy` and `MessageBinding` |
| `acceptContextRoot_refusal`, `acceptContextRoot_in_context`, `accept_in_context`, `out_of_context_refused`, `out_of_context_never_unverified`, `wrong_network_refused`, `unaccepted_scheme_refused`, `foreign_publication_ignored`, `verdict_context_sound` | ruled statements | Axioms limited to propext, Classical.choice and Quot.sound |
| `guard_removed_refutes_context_soundness`, `scheme_unchecked_refutes_context_soundness` | `(operation) (accepted : operation <fixture> = .verified <claim>) → ¬ ContextSoundness operation` under the honest-signature instances | Parameterized by the compiled mutant |
| `unbound_message_refutes` | `(sound : <ContextSoundness without the MessageBinding premise, unfolded>) → False` under the signature-only instances | Witness for the binding-removal mutant |
| `Lockness.Sim.contextScenario` | `(scenario : String) → IO UInt32` | Unknown scenario exits 64 |

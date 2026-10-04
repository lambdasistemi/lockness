# Verdict layer functions

As a reviewer, see every new or changed signature with explicit argument names. Statements are as ruled in verdict-interface-v1 (answers/A-001, C1 applied).

## Changed

| Name | Arguments → result | Constraint |
| --- | --- | --- |
| `verifyLedger` | `(policy : Policy) (acceptedRoot : Root) (session : Session) (answer : LedgerAnswer) → Except Refusal Root` | Signature unchanged. Adds the binding guard after the point guard; the witness gate fails on an absent witness. New failures are `evidenceFailure session.selectedPoint`. |
| `verifyLedger_observations` | unchanged binders | Conclusion records the binding guard and a present witness checked under `acceptedRoot` |

## New

| Name | Arguments → result | Constraint |
| --- | --- | --- |
| `unverifiedReason` | `(selectedPoint : Chainpoint) (provider : Provider) → Option Reason` | Reads only the session that acquire accepts: `.unbound` gives unboundSession; a session bound to the selected point without a witness gives noWitness; `.bound q` with `q ≠ selected` gives none (refused) |
| `verdict` | `(policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) → Verdict` | Ruled order; wraps the unchanged `accept` |
| `NoPromotion` | `(operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict) → Prop` | As ruled; no hypotheses |
| `VerdictSoundness`, `VerdictProviderInvariance` | same operation type `→ Prop` | AcceptSoundness and ProviderInvariance with the verified premise |
| `Session.withReconstruction` | `(reconstruction : Option Reconstruction) (session : Session) → Session` | Replaces only the answer's reconstruction |
| `verdict_no_promotion` | `: NoPromotion verdict` | — |
| `verdict_verified_iff`, `accept_bound_witnessed`, `verdict_refused`, `verdict_refusal`, `verdict_unverified`, `witnessed_never_unverified`, `unbound_only_unverified`, `misbound_refused`, `verdict_sound`, `verdict_provider_invariant`, `verdict_reconstruction_irrelevant` | ruled statements | Axioms limited to propext, Classical.choice and Quot.sound |
| `promoted_refutes_no_promotion`, `promoted_refutes_soundness`, `verifier_refutes_no_promotion` | `(operation) (promoted : operation <promotion fixture> = .verified substitutedClaim) → ¬ …` | Parameterized by the compiled mutant |
| `Lockness.Sim.verdictScenario` | `(scenario : String) → IO UInt32` | Unknown scenario exits 64 |

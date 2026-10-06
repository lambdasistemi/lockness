# Completeness functions

As a reviewer, see every new or changed signature with explicit argument names. Statements are as ruled in completeness-interface-v1; the exact frozen text is in the ticket gate.

## Changed (signatures and statements unchanged)

| Name | Constraint |
| --- | --- |
| `verifyLedger (policy) (acceptedRoot) (session) (answer)` | one completeness guard after the witness guard, including the policy's requirement |
| `unverifiedReason (selectedPoint) (provider)` | `noWitness` only when neither a witness nor a completeness answer is present |

## New

| Name | Arguments → result | Constraint |
| --- | --- | --- |
| `UnderPrefix` | `(layout : KeyLayout) (keyPrefix : Bytes) (entry : TxIn × TxOut) → Prop` | byte prefix of some key |
| `CompletenessSound` | `(policy) (ledger) (honestRoot) (layout) → Prop` | abstract |
| `AssetKeyLayout` | `(policy) (carries) (layout) → Prop` | abstract |
| `verifyEntries` | `(policy) (acceptedRoot : Root) (session) (keyPrefix : Bytes) → Except Refusal (List (TxIn × TxOut))` | refusals `evidenceFailure session.selectedPoint` |
| `acceptEntries` | `(policy) (publications) (selectedPoint) (keyPrefix) (provider) → Except Refusal EntriesClaim` | context root acceptance, acquisition, entries verification |
| `EntriesSoundness`, `CompleteLedgerSoundness` | `(operation) → Prop` | as ruled |
| `accept_entries_sound` | `EntriesSoundness acceptEntries` | |
| `verifyLedger_complete_sound` | `CompleteLedgerSoundness verifyLedger` | no `OneShot` premise |
| `RequiredCompleteLedgerSoundness`, `verifyLedger_required_complete_sound` | `(operation) → Prop`; `RequiredCompleteLedgerSoundness verifyLedger` | the offered-completeness premise replaced by `policy.requireCompleteness = true` |
| `verifyLedger_required` | inversion: a required policy's success has a completeness answer | |
| `completeness_never_unverified`, `completeness_wrong_refused` | as ruled | |
| `verifyEntries_observations`, `verifyLedger_completeness`, `acceptEntries_observations`, `verifyEntries_refusal`, `acceptEntries_refusal`, `acceptEntries_never_adopts` | inversions and refusals | |
| `completenessScenario` | `(scenario : String) → IO UInt32` | exit 0, 1, or 64 for an unknown scenario |

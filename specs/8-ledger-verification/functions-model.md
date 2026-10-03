# Ledger operation contracts

As a reviewer, inspect the public signature and the exact premises behind its conclusions separately from executable observations.

| Name | Explicit arguments | Result or constraint |
| --- | --- | --- |
| `verifyLedger` | `policy : Policy`, `acceptedRoot : Root`, `session : Session`, `answer : LedgerAnswer` | `Except Refusal Root`; exact point/object/asset/schema binding, witness under independent root, selected-point evidence refusal. |
| `checks` | Policy, Witness, Root, exact input/output pair | Prop for a successful executable witness observation of the pair's unchanged bytes. |
| `WitnessSound` | Policy, honest Ledger, point-to-honest-root function | Prop connecting honest-root equality and successful checking to exact membership. |
| `OneShot` | Honest Ledger, selected asset, honest carries relation | Prop asserting at most one asset-bearing member at every point. |
| `LedgerSoundness` | Operation with verifyLedger's signature | Universal unique-output and interpreted-datum-root guarantee under explicit correspondence, witness/observation and OneShot premises. |
| `verifyLedger_sound` | Universal policy/root/session/answer/returned root and honest-state premises | Proof of the complete unique-output soundness guarantee. |
| `verifyLedger_refusal` | Policy, accepted root, session, answer, refusal and failed-result premise | Proof of exact evidenceFailure at session.selectedPoint. |
| `ledgerScenario` | `scenario : String` | `IO UInt32`; actual model assertions for three named scenarios; usage failure for unknown scenario. |

## Frozen logical statements

`Ledger := Chainpoint → Finset (TxIn × TxOut)`. Let `entry` range over exact input/output pairs and `p` over full chainpoints. These statements quantify arbitrary policies, ledgers and callbacks; no global honest instance is installed.

- `checks (policy : Policy) (w : Witness) (root : Root) (entry : TxIn × TxOut) : Prop` denotes `policy.checkWitness w root (policy.objectBytes entry) = true`.
- `WitnessSound (policy : Policy) (ledger : Ledger) (honestRoot : Chainpoint → Root) : Prop` asserts, for every p/w/root/entry, root = honestRoot p and checks imply entry ∈ ledger p.
- `ObjectEncodingFaithful (policy : Policy) : Prop` asserts injectivity of policy.objectBytes over input/output pairs.
- `AssetObservationSound (policy : Policy) (carries : TxOut → Asset → Prop) : Prop` asserts, for every output and asset, policy.assetOf output = some asset implies carries output asset.
- `DatumObservationSound (policy : Policy) (honestDatumRoot : Schema → TxOut → Option Root) : Prop` asserts, for every schema/output/datum/root, policy.datumOf output = some datum and policy.parseDatum schema datum = some root imply honestDatumRoot schema output = some root.
- `OneShot (ledger : Ledger) (asset : Asset) (carries : TxOut → Asset → Prop) : Prop` asserts, for every point and two member pairs carrying asset, those pairs are equal.

`LedgerSoundness (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root) : Prop` quantifies every policy, ledger, honestRoot, carries, honestDatumRoot, acceptedRoot, session, answer and returned appRoot. Its premises are WitnessSound policy ledger honestRoot; ObjectEncodingFaithful policy; AssetObservationSound policy carries; DatumObservationSound policy honestDatumRoot; OneShot ledger policy.asset carries; acceptedRoot = honestRoot session.selectedPoint; and operation policy acceptedRoot session answer = .ok appRoot. Its conclusion is:

```lean
∃ entry : TxIn × TxOut,
  entry ∈ ledger session.selectedPoint ∧
  carries entry.2 policy.asset ∧
  honestDatumRoot policy.schema entry.2 = some appRoot ∧
  ∀ other ∈ ledger session.selectedPoint,
    carries other.2 policy.asset → other = entry
```

`verifyLedger_sound : LedgerSoundness verifyLedger` preserves this exact conclusion. Root endorsement is supplied separately by the inherited root acceptance proofs; honestRoot equality remains a distinct selected-point correspondence premise. Counterexample B removes only OneShot from this statement and proves its negation constructively with every retained premise jointly inhabited.

The acceptance inversion exposes answer.point = session.selectedPoint, exact decode/re-encode binding, accepted-argument witness checking, policy asset observation and schema datum parse to the returned root. `verifyLedger_refusal` states any error equals evidenceFailure session.selectedPoint. Supporting proof names may refine these contracts within the released modules. No concrete codec or witness algorithm is prescribed here.

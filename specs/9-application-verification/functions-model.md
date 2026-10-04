# Application verification contracts

As a reviewer, inspect each public signature and the exact premises behind each conclusion.

| Name | Explicit arguments | Result or constraint |
| --- | --- | --- |
| `verifyApp` | `policy : Policy`, `selectedPoint : Chainpoint`, then `root : Root`, `answer : AppAnswer` | `Except Refusal AppValue`; partial application has the issue's `Root → AppAnswer → Except Refusal AppValue` (stated deviation). Guards in order: claimed root equals root; answer point equals selected point; application/context/claim equal policy query; `policy.checkApp answer.proof root policy.query answer.value`. Failures are `evidenceFailure selectedPoint`. |
| `verifyChain` | `policy`, `selectedPoint`, `builder : Builder`, `fuel : Nat`, `root : Root` | `Except Refusal (List Root × AppValue)`; fuel 0 and absent builder refuse; final value when `policy.nextRoot` is none; otherwise prepend the next root and recurse with one less fuel. |
| `accept` | `policy`, `publications : List Publication`, `selectedPoint`, `provider : Provider`, `builder : Builder` | `Except Refusal Claim`; acceptRoot, acquire, `verifyLedger policy root session session.ledger`, `verifyChain … policy.fuel appRoot`; claim point is the selected point. |
| `ledgerScenario`-style `appScenario` | `scenario : String` | `IO UInt32`; honest, replaced-root, nested, ambiguous-value; unknown is usage failure 64. |

## Frozen hypotheses

- `AppSound (policy : Policy) (tree : AppTree) : Prop`: for every proof, root, query and value, `policy.checkApp proof root query value = true → (query, value) ∈ tree root`.
- `AppFunctional (tree : AppTree) : Prop`: for every root, query and values v₁ v₂, membership of both pairs implies v₁ = v₂.
- `NestingInterpretationFaithful (policy : Policy) (honestNext : AppValue → Option Root) : Prop`: for every value, `policy.nextRoot value = honestNext value`.

## Frozen statements

`AcceptSoundness (operation : Policy → List Publication → Chainpoint → Provider → Builder → Except Refusal Claim) : Prop` quantifies every policy, publications, selectedPoint, provider, builder, claim, ledger, honestRoot, carries, honestDatumRoot, tree and honestNext. Premises: `HonestRootCorrespondence policy publications honestRoot`; `WitnessSound policy ledger honestRoot`; `ObjectEncodingFaithful policy`; `AssetObservationSound policy carries`; `DatumObservationSound policy honestDatumRoot`; `OneShot ledger policy.asset carries`; `AppSound policy tree`; `NestingInterpretationFaithful policy honestNext`; `operation policy publications selectedPoint provider builder = .ok claim`. Conclusion:

```lean
claim.point = selectedPoint ∧ claim.ledgerRoot = honestRoot selectedPoint ∧
  holds policy carries honestDatumRoot tree honestNext (ledger selectedPoint) claim
```

`holds policy carries honestDatumRoot tree honestNext entries claim` denotes:

```lean
claim.query = policy.query ∧
  ∃ entry ∈ entries, carries entry.2 policy.asset ∧
    (∀ other ∈ entries, carries other.2 policy.asset → other = entry) ∧
    honestDatumRoot policy.schema entry.2 = some claim.appRoot ∧
    ChainHolds tree honestNext claim.query claim.appRoot claim.links claim.value
```

`ProviderInvariance operation : Prop` quantifies every policy, publications, selectedPoint, provider₁, provider₂, builder₁, builder₂, claim₁, claim₂, ledger, honestRoot, carries, honestDatumRoot and tree. Premises: the six ledger and root premises above, `AppSound policy tree`, `AppFunctional tree`, and both `operation … providerᵢ builderᵢ = .ok claimᵢ`. Conclusion `claim₁ = claim₂`.

## Theorems

- `accept_sound : AcceptSoundness accept`; `accept_provider_invariant : ProviderInvariance accept`.
- `accept_refusal`: any `accept … selectedPoint … = .error refusal` gives `refusal.selectedPoint = selectedPoint`, for every branch.
- `verifyApp_claimed_root_first`: for every policy, `answer.root ≠ root` gives `verifyApp policy selectedPoint root answer = .error (.evidenceFailure selectedPoint)`.
- `verifyApp_refusal`, `verifyChain_refusal`: every error is `evidenceFailure selectedPoint`.
- Refutations take an operation and its acceptance witness and conclude `¬ AcceptSoundness operation`; the ambiguity refutation concludes the negation of `ProviderInvariance` with only `AppFunctional` removed (hand-copied statement, #11 residual).

`#print axioms` for each lists only propext, Classical.choice and Quot.sound. Supporting proof names may refine these within the released modules. No proof format or codec is prescribed.

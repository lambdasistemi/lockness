import Lockness.Counterexamples.AppFixtures

namespace Lockness.Counterexamples.AppExamples

-- The frozen invariance statement with exactly the AppFunctional premise removed.
-- Hand-copied from ProviderInvariance; its faithfulness is a reviewed residual.
def ProviderInvarianceWithoutAppFunctional
    (operation : Policy → List Publication → Chainpoint → Provider → Builder →
      Except Refusal Claim) : Prop :=
  ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider₁ provider₂ : Provider) (builder₁ builder₂ : Builder) (claim₁ claim₂ : Claim)
    (ledger : Ledger) (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (tree : AppTree),
    HonestRootCorrespondence policy publications honestRoot →
    WitnessSound policy ledger honestRoot → ObjectEncodingFaithful policy →
    AssetObservationSound policy carries → DatumObservationSound policy honestDatumRoot →
    OneShot ledger policy.asset carries → AppSound policy tree →
    operation policy publications selectedPoint provider₁ builder₁ = .ok claim₁ →
    operation policy publications selectedPoint provider₂ builder₂ = .ok claim₂ →
    claim₁ = claim₂

-- Both values are committed under the ledger's application root for the same query.
def ambiguousValues : List AppValue := valuesAt true finalQuery LedgerExamples.appRoot₁
def firstValue : AppValue := ambiguousValues.headD []
def secondValue : AppValue := ambiguousValues.getLastD []

def choosingBuilder (proof : AppProof) (value : AppValue) : Builder := fun root =>
  if root = LedgerExamples.appRoot₁ then some (answerFor proof finalQuery root value) else none

def ambiguousClaim (value : AppValue) : Claim :=
  { expectedClaim true LedgerExamples.entry₁ finalQuery with value := value }

theorem ambiguous_values : ambiguousValues.length = 2 ∧ firstValue ∈ ambiguousValues ∧
    secondValue ∈ ambiguousValues ∧ firstValue ≠ secondValue := by decide

theorem ambiguous_claims_differ : ambiguousClaim firstValue ≠ ambiguousClaim secondValue := by
  decide

theorem ambiguous_acceptance :
    accept (appPolicy true finalQuery) publications selected providerA
      (choosingBuilder proofA firstValue) = .ok (ambiguousClaim firstValue) ∧
    accept (appPolicy true finalQuery) publications selected providerB
      (choosingBuilder proofB secondValue) = .ok (ambiguousClaim secondValue) := by decide

theorem ambiguous_not_functional : ¬ AppFunctional (treeFor true) := by
  intro functional
  have same := functional LedgerExamples.appRoot₁ finalQuery firstValue secondValue
    (show (LedgerExamples.appRoot₁, finalQuery, firstValue) ∈ contents true by decide)
    (show (LedgerExamples.appRoot₁, finalQuery, secondValue) ∈ contents true by decide)
  exact ambiguous_values.2.2.2 same

theorem ambiguous_retained_premises :
    HonestRootCorrespondence (appPolicy true finalQuery) publications LedgerExamples.honestRoot ∧
    WitnessSound (appPolicy true finalQuery) (LedgerExamples.ledgerFor false)
      LedgerExamples.honestRoot ∧
    ObjectEncodingFaithful (appPolicy true finalQuery) ∧
    AssetObservationSound (appPolicy true finalQuery) LedgerExamples.carries ∧
    DatumObservationSound (appPolicy true finalQuery) LedgerExamples.honestDatumRoot ∧
    OneShot (LedgerExamples.ledgerFor false) (appPolicy true finalQuery).asset
      LedgerExamples.carries ∧
    AppSound (appPolicy true finalQuery) (treeFor true) :=
  ⟨fixture_correspondence true finalQuery, fixture_witness_sound true finalQuery,
    fixture_encoding_faithful true finalQuery, fixture_asset_sound true finalQuery,
    fixture_datum_sound true finalQuery, fixture_one_shot true finalQuery,
    fixture_app_sound true finalQuery⟩

-- Two builders, two different accepted claims: invariance without AppFunctional is false.
theorem ambiguous_refutes_invariance_without_app_functional :
    ¬ ProviderInvarianceWithoutAppFunctional accept := by
  intro invariant
  obtain ⟨correspondence, witness, encoding, asset, datum, oneShot, appSound⟩ :=
    ambiguous_retained_premises
  exact ambiguous_claims_differ (invariant (appPolicy true finalQuery) publications selected
    providerA providerB (choosingBuilder proofA firstValue) (choosingBuilder proofB secondValue)
    (ambiguousClaim firstValue) (ambiguousClaim secondValue) (LedgerExamples.ledgerFor false)
    LedgerExamples.honestRoot LedgerExamples.carries LedgerExamples.honestDatumRoot
    (treeFor true) correspondence witness encoding asset datum oneShot appSound
    ambiguous_acceptance.1 ambiguous_acceptance.2)

end Lockness.Counterexamples.AppExamples

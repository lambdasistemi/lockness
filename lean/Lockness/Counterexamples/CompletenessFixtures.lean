import Lockness.Completeness
import Lockness.Counterexamples.VerdictFixtures

namespace Lockness.Counterexamples.CompletenessExamples
open AppExamples LedgerExamples VerdictExamples

-- The #9/#28 fixture ledger at every point: entry₁ (asset, address A), entry₃ (address A) and
-- entry₄ (address B); the duplicate ledger adds #8's entry₂ (asset, address B).
def entry₃ : TxIn × TxOut := ([3, 0, 255], [4, 0, 255])
def entry₄ : TxIn × TxOut := ([4, 0, 255], [5, 0, 255])
def addressA : Bytes := [10]
def addressB : Bytes := [20]
def addressOf (output : TxOut) : Bytes :=
  if output = entry₂.2 ∨ output = entry₄.2 then addressB else addressA

-- A fixture layout, not a proposed key encoding: address keys under [0], asset keys under [1].
def keysOf (entry : TxIn × TxOut) : List IndexKey :=
  ([0] ++ addressOf entry.2 ++ entry.1) ::
    (outputAsset entry.2).toList.map fun held => [1] ++ held ++ entry.1
def layout : KeyLayout := fun entry => {key | key ∈ keysOf entry}
def assetKeyPrefix (held : Asset) : Bytes := [1] ++ held
def prefixA : Bytes := [0] ++ addressA
-- A prefix no entry is stored under.
def absentPrefix : Bytes := [0, 99]
-- A prefix narrower than prefixA, holding only entry₁.
def narrowPrefix : Bytes := prefixA ++ entry₁.1

def ledgerList (duplicate : Bool) : List (TxIn × TxOut) :=
  if duplicate then [entry₁, entry₂, entry₃, entry₄] else [entry₁, entry₃, entry₄]
def ledgerOf (duplicate : Bool) : Ledger := fun _ => (ledgerList duplicate).toFinset

-- Honest semantics: the entries the index stores under a prefix, read from the ledger and the
-- layout; never from a guard.
def under (keyPrefix : Bytes) (entry : TxIn × TxOut) : Bool :=
  (keysOf entry).any keyPrefix.isPrefixOf
def honestEntries (duplicate : Bool) (keyPrefix : Bytes) : List (TxIn × TxOut) :=
  (ledgerList duplicate).filter (under keyPrefix)
def honestList (duplicate : Bool) (keyPrefix : Bytes) : List Bytes :=
  (honestEntries duplicate keyPrefix).map objectBytes
def sameSet (first second : List Bytes) : Bool :=
  first.all (· ∈ second) && second.all (· ∈ first)

-- One proof value. Under the accepted root it checks exactly the honest listing, as a set; under
-- the provider root it also checks the listing that omits entry₃ (the #8 provider-root pattern).
def completenessProof : Bytes := [7, 7, 0, 255]
def checkFor (duplicate : Bool) (proof : Bytes) (root : Root) (keyPrefix : Bytes)
    (listed : List Bytes) : Bool :=
  decide (proof = completenessProof) &&
    ((decide (root = acceptedRoot) && sameSet listed (honestList duplicate keyPrefix)) ||
     (decide (root = providerRoot) && sameSet listed [objectBytes entry₁]))

def completePolicy (duplicate : Bool) : Policy :=
  { VerdictExamples.policy with
    checkCompleteness := checkFor duplicate
    assetPrefix := assetKeyPrefix }
def requiredPolicy (duplicate : Bool) : Policy :=
  { completePolicy duplicate with requireCompleteness := true }
-- Violates CompletenessSound: every listing checks.
def permissivePolicy : Policy :=
  { completePolicy false with checkCompleteness := fun _ _ _ _ => true }

def withCompleteness (answer : Option CompletenessAnswer) (session : Session) : Session :=
  { session with ledger := { session.ledger with completeness := answer } }
def answerOf (keyPrefix : Bytes) (entries : List (TxIn × TxOut)) : CompletenessAnswer :=
  ⟨keyPrefix, entries.map objectBytes, completenessProof⟩
-- The honest #9 offer at the selected point, carrying a completeness answer.
def offer (answer : CompletenessAnswer) : Provider :=
  offering (withCompleteness (some answer) (offerVia providerRootA))
-- The honest ledger answer with an asset listing that omits entry₂ on the duplicate ledger.
def omittingAnswer : LedgerAnswer :=
  { (offerVia providerRootA).ledger with
    completeness := some (answerOf (assetKeyPrefix asset) [entry₁]) }
-- No witness, and a wrong asset listing.
def wrongWithoutWitness : Provider :=
  offering (withCompleteness (some (answerOf (assetKeyPrefix asset) [entry₃])) noWitnessSession)

theorem under_iff (keyPrefix : Bytes) (entry : TxIn × TxOut) :
    under keyPrefix entry = true ↔ UnderPrefix layout keyPrefix entry := by
  simp [under, UnderPrefix, layout, List.any_eq_true, List.isPrefixOf_iff_prefix]

theorem sameSet_iff (first second : List Bytes) :
    sameSet first second = true ↔ ∀ bytes, bytes ∈ first ↔ bytes ∈ second := by
  simp only [sameSet, Bool.and_eq_true, List.all_eq_true, decide_eq_true_eq]
  constructor
  · rintro ⟨forward, backward⟩ bytes
    exact ⟨forward bytes, backward bytes⟩
  · intro same
    exact ⟨fun bytes member => (same bytes).1 member, fun bytes member => (same bytes).2 member⟩

theorem fixture_completeness_sound (duplicate : Bool) :
    CompletenessSound (completePolicy duplicate) (ledgerOf duplicate) honestRoot layout := by
  intro p proof root keyPrefix listed correspondence checked bytes
  subst correspondence
  have honestCase : sameSet listed (honestList duplicate keyPrefix) = true := by
    simp only [completePolicy, checkFor, honestRoot, Bool.and_eq_true, Bool.or_eq_true,
      decide_eq_true_eq] at checked
    rcases checked with ⟨_, ⟨_, same⟩ | ⟨wrongRoot, _⟩⟩
    · exact same
    · exact absurd wrongRoot.symm provider_root_distinct
  rw [(sameSet_iff _ _).1 honestCase bytes]
  simp only [honestList, honestEntries, List.mem_map, List.mem_filter, ledgerOf, List.mem_toFinset,
    under_iff]
  constructor
  · rintro ⟨entry, ⟨member, under⟩, same⟩
    exact ⟨entry, member, under, same⟩
  · rintro ⟨entry, member, under, same⟩
    exact ⟨entry, ⟨member, under⟩, same⟩

theorem fixture_asset_layout (duplicate : Bool) :
    AssetKeyLayout (completePolicy duplicate) carries layout := by
  intro entry carried
  refine ⟨[1] ++ asset ++ entry.1, ?_, ?_⟩
  · have held : outputAsset entry.2 = some asset := carried
    simp [layout, keysOf, held]
  · simp [completePolicy, assetKeyPrefix, VerdictExamples.policy, appPolicy, policyFor]

theorem complete_correspondence (duplicate : Bool) :
    HonestRootCorrespondence (completePolicy duplicate) publications honestRoot :=
  AppExamples.fixture_correspondence false finalQuery

theorem complete_faithful (duplicate : Bool) : ObjectEncodingFaithful (completePolicy duplicate) :=
  objectBytes_injective

theorem complete_asset_sound (duplicate : Bool) :
    AssetObservationSound (completePolicy duplicate) carries :=
  fun _ _ observed => observed

theorem complete_datum_sound (duplicate : Bool) :
    DatumObservationSound (completePolicy duplicate) honestDatumRoot := by
  intro selectedSchema output datum root observed parsed
  simp only [completePolicy, VerdictExamples.policy, appPolicy, policyFor] at observed parsed
  simp [honestDatumRoot, observed, parsed]

-- Every premise of accept_entries_sound, verifyLedger_complete_sound and
-- verifyLedger_required_complete_sound, inhabited together on one fixture.
theorem completeness_premises_inhabited (duplicate : Bool) :
    HonestRootCorrespondence (completePolicy duplicate) publications honestRoot ∧
    CompletenessSound (completePolicy duplicate) (ledgerOf duplicate) honestRoot layout ∧
    ObjectEncodingFaithful (completePolicy duplicate) ∧
    AssetObservationSound (completePolicy duplicate) carries ∧
    DatumObservationSound (completePolicy duplicate) honestDatumRoot ∧
    AssetKeyLayout (completePolicy duplicate) carries layout ∧
    acceptedRoot = honestRoot selected :=
  ⟨complete_correspondence duplicate, fixture_completeness_sound duplicate,
    complete_faithful duplicate, complete_asset_sound duplicate, complete_datum_sound duplicate,
    fixture_asset_layout duplicate, rfl⟩

-- The required policy differs only in requireCompleteness, so the same premises hold for it.
theorem required_premises_inhabited (duplicate : Bool) :
    HonestRootCorrespondence (requiredPolicy duplicate) publications honestRoot ∧
    CompletenessSound (requiredPolicy duplicate) (ledgerOf duplicate) honestRoot layout ∧
    ObjectEncodingFaithful (requiredPolicy duplicate) ∧
    AssetObservationSound (requiredPolicy duplicate) carries ∧
    DatumObservationSound (requiredPolicy duplicate) honestDatumRoot ∧
    AssetKeyLayout (requiredPolicy duplicate) carries layout ∧
    (requiredPolicy duplicate).requireCompleteness = true :=
  ⟨complete_correspondence duplicate, fixture_completeness_sound duplicate,
    complete_faithful duplicate, complete_asset_sound duplicate, complete_datum_sound duplicate,
    fixture_asset_layout duplicate, rfl⟩

end Lockness.Counterexamples.CompletenessExamples

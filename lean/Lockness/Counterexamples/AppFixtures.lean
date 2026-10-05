import Lockness.Accept
import Lockness.Counterexamples.LedgerFixtures

namespace Lockness.Counterexamples.AppExamples

-- The ledger step reuses the #8 fixture; its checking root comes from root acceptance.
def selected : Chainpoint := LedgerExamples.point
def publications : List Publication := [honestPublication, secondPublication]

def finalQuery : AppQuery := ⟨[1, 0, 255], [2, 0, 255], [3, 0, 255]⟩
def nestedQuery : AppQuery := ⟨[1, 0, 255], [2, 0, 255], [4, 0, 255]⟩
def innerRoot : Root := ⟨[2], [1, 0, 255]⟩
def otherRoot : Root := ⟨[2], [2, 0, 255]⟩
def finalValue : AppValue := [10, 0, 255]
def carrierValue : AppValue := [11, 0, 255]
def innerValue : AppValue := [12, 0, 255]
def forgedValue : AppValue := [13, 0, 255]
def alternateValue : AppValue := [14, 0, 255]
def substitutedValue : AppValue := [15, 0, 255]
def proofA : AppProof := [0, 255, 0, 1]
def proofB : AppProof := [255, 0, 255, 2]
def badProof : AppProof := [99]

-- Committed application content: each row is a root, a query and a value.
-- `ambiguous` adds a second value for one query under the ledger's application root.
def contents (ambiguous : Bool) : List (Root × AppQuery × AppValue) :=
  [(LedgerExamples.appRoot₁, finalQuery, finalValue),
   (LedgerExamples.appRoot₁, nestedQuery, carrierValue),
   (innerRoot, nestedQuery, innerValue),
   (otherRoot, finalQuery, forgedValue),
   (otherRoot, nestedQuery, forgedValue),
   (LedgerExamples.appRoot₃, finalQuery, substitutedValue)] ++
  (if ambiguous then [(LedgerExamples.appRoot₁, finalQuery, alternateValue)] else [])

def treeFor (ambiguous : Bool) : AppTree := fun root => {pair | (root, pair) ∈ contents ambiguous}

def honestNext (value : AppValue) : Option Root :=
  if value = carrierValue then some innerRoot else none

-- Two proof byte strings are valid for every committed row; no proof format is modelled.
def checkFor (ambiguous : Bool) (proof : AppProof) (root : Root) (query : AppQuery)
    (value : AppValue) : Bool :=
  decide ((proof = proofA ∨ proof = proofB) ∧ (root, query, value) ∈ contents ambiguous)

def appPolicy (ambiguous : Bool) (query : AppQuery) : Policy :=
  { LedgerExamples.policyFor false with
    query := query
    checkApp := checkFor ambiguous
    nextRoot := honestNext
    fuel := 2 }

def valuesAt (ambiguous : Bool) (query : AppQuery) (root : Root) : List AppValue :=
  ((contents ambiguous).filter fun row => decide (row.1 = root ∧ row.2.1 = query)).map
    fun row => row.2.2

def answerFor (proof : AppProof) (query : AppQuery) (root : Root) (value : AppValue) : AppAnswer :=
  ⟨query.application, query.context, selected, root, query.claim, value, proof⟩

-- An honest builder answers with the first committed value under the queried root.
def honestBuilder (ambiguous : Bool) (proof : AppProof) (query : AppQuery) : Builder := fun root =>
  (valuesAt ambiguous query root).head?.map (answerFor proof query root)

-- Untrusted session and ledger-answer roots differ between the two providers.
def providerRootA : Root := LedgerExamples.providerRoot
def providerRootB : Root := ⟨[0], [8, 0, 255]⟩
def offerVia (untrusted : Root) : Session :=
  ⟨selected, untrusted, { LedgerExamples.answer₁ with root := untrusted }, .bound selected⟩
def providerA : Provider := fun _ => some (offerVia providerRootA)
def providerB : Provider := fun _ => some (offerVia providerRootB)
-- The #8 substituted ledger answer, offered with the provider's own root.
def substitutingProvider : Provider := fun _ =>
  some ⟨selected, LedgerExamples.providerRoot, LedgerExamples.substitutedAnswer, .bound selected⟩

-- Claims another root with a proof valid there; every other guard passes.
def replacedAnswer : AppAnswer := answerFor proofA finalQuery otherRoot forgedValue
def replacingBuilder : Builder := fun root =>
  if root = LedgerExamples.appRoot₁ then some replacedAnswer else none
-- Claims the true root, with a proof valid only under another root.
def trueRootForgedBuilder : Builder := fun root =>
  if root = LedgerExamples.appRoot₁ then some (answerFor proofA finalQuery root forgedValue)
  else none

-- Honest everywhere except at the second link, where `change` rewrites or drops the answer.
def secondLinkBuilder (change : AppAnswer → Option AppAnswer) : Builder := fun root =>
  if root = innerRoot then (honestBuilder false proofA nestedQuery root).bind change
  else honestBuilder false proofA nestedQuery root

-- The honest chain walks the committed content, independently of every guard.
def honestChain (ambiguous : Bool) (query : AppQuery) : Nat → Root → Option (List Root × AppValue)
  | 0, _ => none
  | steps + 1, root =>
    match (valuesAt ambiguous query root).head? with
    | none => none
    | some value =>
      match honestNext value with
      | none => some ([], value)
      | some next =>
        match honestChain ambiguous query steps next with
        | none => none
        | some (links, final) => some (next :: links, final)

-- Expected claims come from honest semantics: the honest root, the entry's honest datum root
-- and the honest chain. None is read from accept or from a guard.
def semanticClaim (ambiguous : Bool) (entry : TxIn × TxOut) (query : AppQuery) : Option Claim :=
  match LedgerExamples.honestDatumRoot LedgerExamples.schema entry.2 with
  | none => none
  | some appRoot =>
    match honestChain ambiguous query 4 appRoot with
    | none => none
    | some (links, value) =>
      some ⟨selected, LedgerExamples.honestRoot selected, query, appRoot, links, value⟩

-- The fallback is unreachable for the fixtures below; tests prove each semantic claim exists.
def expectedClaim (ambiguous : Bool) (entry : TxIn × TxOut) (query : AppQuery) : Claim :=
  match semanticClaim ambiguous entry query with
  | some claim => claim
  | none => ⟨selected, LedgerExamples.honestRoot selected, query,
      LedgerExamples.honestRoot selected, [], []⟩

def oneLinkClaim : Claim := expectedClaim false LedgerExamples.entry₁ finalQuery
def nestedClaim : Claim := expectedClaim false LedgerExamples.entry₁ nestedQuery
def substitutedClaim : Claim := expectedClaim false LedgerExamples.impostor finalQuery
-- What a verifier trusting the claimed root would report: the forged value under the true root.
def forgedClaim : Claim := { oneLinkClaim with value := replacedAnswer.value }

theorem fixture_correspondence (ambiguous : Bool) (query : AppQuery) :
    HonestRootCorrespondence (appPolicy ambiguous query) publications LedgerExamples.honestRoot := by
  intro chosenPoint chosenRoot endorsement
  obtain ⟨keys, candidate, witnesses⟩ := endorsement
  cases keys with
  | nil => exact False.elim (candidate.1 rfl)
  | cons key rest =>
    obtain ⟨_, publication, member, _, _, binding, _⟩ := witnesses key (by simp)
    simp only [publications, List.mem_cons, List.not_mem_nil, or_false] at member
    rcases member with rfl | rfl
    · subst binding
      show honestPublication.root = LedgerExamples.acceptedRoot
      decide
    · subst binding
      show secondPublication.root = LedgerExamples.acceptedRoot
      decide

theorem fixture_witness_sound (ambiguous : Bool) (query : AppQuery) :
    WitnessSound (appPolicy ambiguous query) (LedgerExamples.ledgerFor false)
      LedgerExamples.honestRoot :=
  LedgerExamples.fixture_witness_sound false

theorem fixture_encoding_faithful (ambiguous : Bool) (query : AppQuery) :
    ObjectEncodingFaithful (appPolicy ambiguous query) :=
  LedgerExamples.fixture_encoding_faithful false

theorem fixture_asset_sound (ambiguous : Bool) (query : AppQuery) :
    AssetObservationSound (appPolicy ambiguous query) LedgerExamples.carries :=
  LedgerExamples.fixture_asset_sound false

theorem fixture_datum_sound (ambiguous : Bool) (query : AppQuery) :
    DatumObservationSound (appPolicy ambiguous query) LedgerExamples.honestDatumRoot :=
  LedgerExamples.fixture_datum_sound false

theorem fixture_one_shot (ambiguous : Bool) (query : AppQuery) :
    OneShot (LedgerExamples.ledgerFor false) (appPolicy ambiguous query).asset
      LedgerExamples.carries :=
  LedgerExamples.honest_one_shot

theorem fixture_app_sound (ambiguous : Bool) (query : AppQuery) :
    AppSound (appPolicy ambiguous query) (treeFor ambiguous) := by
  intro proof root chosen value checked
  simp only [appPolicy, checkFor, decide_eq_true_eq] at checked
  exact checked.2

theorem fixture_nesting (ambiguous : Bool) (query : AppQuery) :
    NestingInterpretationFaithful (appPolicy ambiguous query) honestNext := fun _ => rfl

theorem honest_contents_functional :
    ∀ first ∈ contents false, ∀ second ∈ contents false,
      first.1 = second.1 → first.2.1 = second.2.1 → first.2.2 = second.2.2 := by decide

theorem fixture_app_functional : AppFunctional (treeFor false) := by
  intro root query first second firstMember secondMember
  exact honest_contents_functional (root, query, first) firstMember (root, query, second)
    secondMember rfl rfl

end Lockness.Counterexamples.AppExamples

import Lockness.Ledger
import Lockness.Counterexamples.SessionMutation

namespace Lockness.Counterexamples.LedgerExamples

def point : Chainpoint := Counterexamples.point
def acceptedRoot : Root := SessionExamples.acceptedRoot
def providerRoot : Root := ⟨[0], [9, 0, 255]⟩
def appRoot₁ : Root := ⟨[1], [1, 0, 255]⟩
def appRoot₂ : Root := ⟨[1], [2, 0, 255]⟩
def appRoot₃ : Root := ⟨[1], [3, 0, 255]⟩
def asset : Asset := [0, 255, 1]
def schema : Schema := [0, 255, 2]
def witness : Witness := [255, 0, 255, 0]
def entry₁ : TxIn × TxOut := ([0, 255, 0], [1, 0, 255])
def entry₂ : TxIn × TxOut := ([255, 0, 255], [2, 0, 255])
def impostor : TxIn × TxOut := ([0, 0, 255], [3, 0, 255])

-- Fixture framing proves injectivity for arbitrary byte pairs, including zero and 255.
-- It is an inhabited abstract representation, not a proposed ledger wire format.
def pack (input output : Bytes) : Bytes :=
  match input with
  | [] => 255 :: output
  | byte :: rest => 0 :: byte :: pack rest output

def unpack : Bytes → Option (TxIn × TxOut)
  | [] => none
  | tag :: rest =>
    if tag = 255 then some ([], rest)
    else if tag = 0 then
      match rest with
      | [] => none
      | byte :: tail =>
        match unpack tail with
        | none => none
        | some entry => some (byte :: entry.1, entry.2)
    else none

theorem unpack_pack (input output : Bytes) : unpack (pack input output) = some (input, output) := by
  induction input with
  | nil => cases output <;> simp [pack, unpack]
  | cons byte rest ih => simp [pack, unpack, ih]

def objectBytes (entry : TxIn × TxOut) : Bytes := pack entry.1 entry.2

theorem objectBytes_injective : Function.Injective objectBytes := by
  intro first second equality
  have decoded := congrArg unpack equality
  simpa [objectBytes, unpack_pack] using decoded

def outputAsset (output : TxOut) : Option Asset :=
  if output = entry₁.2 ∨ output = entry₂.2 ∨ output = impostor.2 then some asset else none

def outputDatum (output : TxOut) : Option Bytes :=
  if output = entry₁.2 then some appRoot₁.bytes
  else if output = entry₂.2 then some appRoot₂.bytes
  else if output = impostor.2 then some appRoot₃.bytes else none

def parse (selectedSchema : Schema) (datum : Bytes) : Option Root :=
  if selectedSchema = schema then
    if datum = appRoot₁.bytes then some appRoot₁
    else if datum = appRoot₂.bytes then some appRoot₂
    else if datum = appRoot₃.bytes then some appRoot₃ else none
  else none

def carries (output : TxOut) (actualAsset : Asset) : Prop := outputAsset output = some actualAsset

instance (output : TxOut) (actualAsset : Asset) : Decidable (carries output actualAsset) :=
  inferInstanceAs (Decidable (outputAsset output = some actualAsset))

def honestDatumRoot (selectedSchema : Schema) (output : TxOut) : Option Root :=
  (outputDatum output).bind (parse selectedSchema)

def ledgerFor (duplicate : Bool) : Ledger := fun _ =>
  if duplicate then {entry₁, entry₂} else {entry₁}

def honestRoot : Chainpoint → Root := fun _ => acceptedRoot

def policyFor (duplicate : Bool) : Policy :=
  { twoKeyPolicy with
    asset := asset
    schema := schema
    decodeObject := unpack
    objectBytes := objectBytes
    checkWitness := fun w root bytes => decide (w = witness ∧
      ((root = acceptedRoot ∧ (bytes = objectBytes entry₁ ∨
        (duplicate = true ∧ bytes = objectBytes entry₂))) ∨
       (root = providerRoot ∧ bytes = objectBytes impostor)))
    assetOf := outputAsset
    datumOf := outputDatum
    parseDatum := parse }

def session : Session := ⟨point, providerRoot, ⟨point, [], some [], providerRoot, none⟩, .bound point⟩
def answer₁ : LedgerAnswer := ⟨point, objectBytes entry₁, some witness, providerRoot, none⟩
def answer₂ : LedgerAnswer := ⟨point, objectBytes entry₂, some witness, providerRoot, none⟩
def substitutedAnswer : LedgerAnswer := ⟨point, objectBytes impostor, some witness, providerRoot, none⟩

theorem root_independently_accepted :
    acceptRoot twoKeyPolicy [honestPublication, secondPublication] point = .ok acceptedRoot := by decide

theorem provider_root_distinct : providerRoot ≠ acceptedRoot := by decide

theorem fixture_encoding_faithful (duplicate : Bool) : ObjectEncodingFaithful (policyFor duplicate) :=
  objectBytes_injective

theorem fixture_witness_sound (duplicate : Bool) :
    WitnessSound (policyFor duplicate) (ledgerFor duplicate) honestRoot := by
  intro p w root entry correspondence checked
  subst root
  simp only [checks, policyFor, honestRoot, decide_eq_true_eq] at checked
  obtain ⟨_, honest | substituted⟩ := checked
  · rcases honest.2 with first | ⟨enabled, second⟩
    · have eq := objectBytes_injective first
      subst entry
      cases duplicate <;> simp [ledgerFor]
    · have eq := objectBytes_injective second
      subst entry
      simp [ledgerFor, enabled]
  · exact False.elim (provider_root_distinct substituted.1.symm)

theorem fixture_asset_sound (duplicate : Bool) : AssetObservationSound (policyFor duplicate) carries := by
  intro output actualAsset observed
  exact observed

theorem fixture_datum_sound (duplicate : Bool) :
    DatumObservationSound (policyFor duplicate) honestDatumRoot := by
  intro selectedSchema output datum root observed parsed
  simp only [policyFor] at observed parsed
  simp [honestDatumRoot, observed, parsed]

theorem honest_one_shot : OneShot (ledgerFor false) asset carries := by
  intro p first member _ second otherMember _
  simp only [ledgerFor, Bool.false_eq_true, ↓reduceIte, Finset.mem_singleton] at member otherMember
  exact member.trans otherMember.symm

end Lockness.Counterexamples.LedgerExamples

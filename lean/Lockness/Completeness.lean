import Lockness.Context
import Lockness.Session
import Lockness.Ledger

namespace Lockness

abbrev IndexKey := Bytes

-- The keys under which the honest index stores each entry: an address layout gives one per
-- output, an asset layout one per asset the output carries. Never computed by the terminal.
abbrev KeyLayout := (TxIn × TxOut) → Set IndexKey

def UnderPrefix (layout : KeyLayout) (keyPrefix : Bytes) (entry : TxIn × TxOut) : Prop :=
  ∃ key ∈ layout entry, keyPrefix <+: key

-- A completeness proof that checks against the honest root at a point lists exactly the object
-- bytes of the entries stored under the prefix in that point's ledger. Abstract, beside
-- WitnessSound; never computed.
def CompletenessSound (policy : Policy) (ledger : Ledger) (honestRoot : Chainpoint → Root)
    (layout : KeyLayout) : Prop :=
  ∀ p proof root keyPrefix listed, root = honestRoot p →
    policy.checkCompleteness proof root keyPrefix listed = true →
    ∀ bytes, bytes ∈ listed ↔
      ∃ entry ∈ ledger p, UnderPrefix layout keyPrefix entry ∧ policy.objectBytes entry = bytes

-- The asset layout: every output carrying the policy's asset is stored under its asset prefix.
def AssetKeyLayout (policy : Policy) (carries : TxOut → Asset → Prop) (layout : KeyLayout) : Prop :=
  ∀ entry, carries entry.2 policy.asset → UnderPrefix layout (policy.assetPrefix policy.asset) entry

structure EntriesClaim where
  point : Chainpoint
  ledgerRoot : Root
  keyPrefix : Bytes
  entries : List (TxIn × TxOut)
  deriving DecidableEq, Repr

-- The offered completeness answer is checked under the accepted root and for the terminal's
-- requested prefix only; the answer's roots and its own prefix are data, never authority.
def verifyEntries (policy : Policy) (acceptedRoot : Root) (session : Session) (keyPrefix : Bytes) :
    Except Refusal (List (TxIn × TxOut)) :=
  if session.ledger.point = session.selectedPoint then
    if session.binding = .bound session.selectedPoint then
      match session.ledger.completeness with
      | none => .error (.evidenceFailure session.selectedPoint)
      | some answer =>
        if answer.keyPrefix = keyPrefix then
          if policy.checkCompleteness answer.proof acceptedRoot keyPrefix answer.entries = true then
            match answer.entries.mapM policy.decodeObject with
            | none => .error (.evidenceFailure session.selectedPoint)
            | some decoded =>
              if decoded.map policy.objectBytes = answer.entries then .ok decoded
              else .error (.evidenceFailure session.selectedPoint)
          else .error (.evidenceFailure session.selectedPoint)
        else .error (.evidenceFailure session.selectedPoint)
    else .error (.evidenceFailure session.selectedPoint)
  else .error (.evidenceFailure session.selectedPoint)

-- The all-entries acceptance in the frozen order: context root acceptance, acquisition, then
-- entries verification under the accepted root. No application, verdict or act step.
def acceptEntries (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (keyPrefix : Bytes) (provider : Provider) : Except Refusal EntriesClaim :=
  match acceptContextRoot policy publications selectedPoint with
  | .error refusal => .error refusal
  | .ok root =>
    match acquire selectedPoint provider with
    | .error refusal => .error refusal
    | .ok session =>
      match verifyEntries policy root session keyPrefix with
      | .error refusal => .error refusal
      | .ok entries => .ok ⟨selectedPoint, root, keyPrefix, entries⟩

def EntriesSoundness
    (operation : Policy → List Publication → Chainpoint → Bytes → Provider →
      Except Refusal EntriesClaim) : Prop :=
  ∀ policy publications selectedPoint keyPrefix provider claim (ledger : Ledger) honestRoot layout,
    HonestRootCorrespondence policy publications honestRoot →
    CompletenessSound policy ledger honestRoot layout → ObjectEncodingFaithful policy →
    operation policy publications selectedPoint keyPrefix provider = .ok claim →
    claim.point = selectedPoint ∧ claim.ledgerRoot = honestRoot selectedPoint ∧
      claim.keyPrefix = keyPrefix ∧
      ∀ entry, entry ∈ claim.entries ↔
        entry ∈ ledger selectedPoint ∧ UnderPrefix layout keyPrefix entry

-- LedgerSoundness with WitnessSound and OneShot replaced by completeness of the asset prefix.
def CompleteLedgerSoundness
    (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root) : Prop :=
  ∀ policy ledger honestRoot carries honestDatumRoot layout acceptedRoot session answer appRoot
    completeness,
    ObjectEncodingFaithful policy → AssetObservationSound policy carries →
    DatumObservationSound policy honestDatumRoot → CompletenessSound policy ledger honestRoot layout →
    AssetKeyLayout policy carries layout → acceptedRoot = honestRoot session.selectedPoint →
    answer.completeness = some completeness →
    operation policy acceptedRoot session answer = .ok appRoot →
    ∃ entry : TxIn × TxOut,
      entry ∈ ledger session.selectedPoint ∧ carries entry.2 policy.asset ∧
      honestDatumRoot policy.schema entry.2 = some appRoot ∧
      ∀ other ∈ ledger session.selectedPoint, carries other.2 policy.asset → other = entry

-- CompleteLedgerSoundness with the offered completeness answer replaced by the terminal's
-- requirement: whatever the provider sends, the guarantee rests on completeness, not OneShot.
def RequiredCompleteLedgerSoundness
    (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root) : Prop :=
  ∀ policy ledger honestRoot carries honestDatumRoot layout acceptedRoot session answer appRoot,
    ObjectEncodingFaithful policy → AssetObservationSound policy carries →
    DatumObservationSound policy honestDatumRoot → CompletenessSound policy ledger honestRoot layout →
    AssetKeyLayout policy carries layout → acceptedRoot = honestRoot session.selectedPoint →
    policy.requireCompleteness = true →
    operation policy acceptedRoot session answer = .ok appRoot →
    ∃ entry : TxIn × TxOut,
      entry ∈ ledger session.selectedPoint ∧ carries entry.2 policy.asset ∧
      honestDatumRoot policy.schema entry.2 = some appRoot ∧
      ∀ other ∈ ledger session.selectedPoint, carries other.2 policy.asset → other = entry

end Lockness

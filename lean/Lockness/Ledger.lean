import Lockness.Types
import Mathlib.Data.Finset.Basic

namespace Lockness

abbrev Ledger := Chainpoint → Finset (TxIn × TxOut)

def checks (policy : Policy) (w : Witness) (root : Root) (entry : TxIn × TxOut) : Prop :=
  policy.checkWitness w root (policy.objectBytes entry) = true

def WitnessSound (policy : Policy) (ledger : Ledger) (honestRoot : Chainpoint → Root) : Prop :=
  ∀ p w root entry, root = honestRoot p → checks policy w root entry → entry ∈ ledger p

def ObjectEncodingFaithful (policy : Policy) : Prop := Function.Injective policy.objectBytes

def AssetObservationSound (policy : Policy) (carries : TxOut → Asset → Prop) : Prop :=
  ∀ output asset, policy.assetOf output = some asset → carries output asset

def DatumObservationSound (policy : Policy)
    (honestDatumRoot : Schema → TxOut → Option Root) : Prop :=
  ∀ schema output datum root, policy.datumOf output = some datum →
    policy.parseDatum schema datum = some root → honestDatumRoot schema output = some root

def OneShot (ledger : Ledger) (asset : Asset) (carries : TxOut → Asset → Prop) : Prop :=
  ∀ point first, first ∈ ledger point → carries first.2 asset →
    ∀ second, second ∈ ledger point → carries second.2 asset → first = second

def LedgerSoundness
    (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root) : Prop :=
  ∀ policy ledger honestRoot carries honestDatumRoot acceptedRoot session answer appRoot,
    WitnessSound policy ledger honestRoot → ObjectEncodingFaithful policy →
    AssetObservationSound policy carries → DatumObservationSound policy honestDatumRoot →
    OneShot ledger policy.asset carries → acceptedRoot = honestRoot session.selectedPoint →
    operation policy acceptedRoot session answer = .ok appRoot →
    ∃ entry : TxIn × TxOut,
      entry ∈ ledger session.selectedPoint ∧ carries entry.2 policy.asset ∧
      honestDatumRoot policy.schema entry.2 = some appRoot ∧
      ∀ other ∈ ledger session.selectedPoint, carries other.2 policy.asset → other = entry

-- Provider roots are data; the terminal supplies the checking root independently.
def verifyLedger (policy : Policy) (acceptedRoot : Root) (session : Session)
    (answer : LedgerAnswer) : Except Refusal Root :=
  if answer.point = session.selectedPoint then
    match policy.decodeObject answer.object with
    | none => .error (.evidenceFailure session.selectedPoint)
    | some entry =>
      if policy.objectBytes entry = answer.object then
        if policy.checkWitness answer.witness acceptedRoot answer.object = true then
          if policy.assetOf entry.2 = some policy.asset then
            match policy.datumOf entry.2 with
            | none => .error (.evidenceFailure session.selectedPoint)
            | some datum =>
              match policy.parseDatum policy.schema datum with
              | none => .error (.evidenceFailure session.selectedPoint)
              | some root => .ok root
          else .error (.evidenceFailure session.selectedPoint)
        else .error (.evidenceFailure session.selectedPoint)
      else .error (.evidenceFailure session.selectedPoint)
  else .error (.evidenceFailure session.selectedPoint)

end Lockness

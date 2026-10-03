import Std

deriving instance DecidableEq for Except

namespace Lockness

abbrev Bytes := List UInt8
abbrev Key := Bytes
abbrev TxIn := Bytes
abbrev TxOut := Bytes
abbrev Asset := Bytes
abbrev Schema := Bytes
abbrev Witness := Bytes

structure Chainpoint where
  network : Bytes
  slot : Nat
  blockHash : Bytes
  deriving DecidableEq, Repr

structure Root where
  scheme : Bytes
  bytes : Bytes
  deriving DecidableEq, Repr

structure Publication where
  key : Key
  point : Chainpoint
  root : Root
  signature : Bytes
  message : Bytes
  deriving DecidableEq, Repr

structure Policy where
  trustedKeys : List Key
  agreement : List Key → Bool
  verify : Publication → Bool
  asset : Asset
  schema : Schema
  decodeObject : Bytes → Option (TxIn × TxOut)
  objectBytes : (TxIn × TxOut) → Bytes
  checkWitness : Witness → Root → Bytes → Bool
  assetOf : TxOut → Option Asset
  datumOf : TxOut → Option Bytes
  parseDatum : Schema → Bytes → Option Root

-- Each instance is an arbitrary hypothesis, not an implementation of signatures.
class SignatureModel where
  valid : Publication → Prop

def SigValid [SignatureModel] (publication : Publication) : Prop :=
  SignatureModel.valid publication

def ObservationSound [SignatureModel] (policy : Policy) : Prop :=
  ∀ publication, policy.verify publication = true → SigValid publication

inductive Refusal where
  | noRoot (selectedPoint : Chainpoint)
  | unavailablePoint (selectedPoint : Chainpoint)
  | evidenceFailure (selectedPoint : Chainpoint)
  deriving DecidableEq, Repr

def Refusal.selectedPoint : Refusal → Chainpoint
  | .noRoot point | .unavailablePoint point | .evidenceFailure point => point

structure Session where
  selectedPoint : Chainpoint
  acceptedRoot : Root
  deriving DecidableEq, Repr

structure LedgerAnswer where
  point : Chainpoint
  object : Bytes
  witness : Bytes
  root : Root
  deriving DecidableEq, Repr

structure AppAnswer where
  application : Bytes
  context : Bytes
  point : Chainpoint
  root : Root
  claim : Bytes
  value : Bytes
  proof : Bytes
  deriving DecidableEq, Repr

end Lockness

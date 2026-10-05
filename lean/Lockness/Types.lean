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
abbrev AppProof := Bytes
abbrev AppValue := Bytes

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

structure AppQuery where
  application : Bytes
  context : Bytes
  claim : Bytes
  deriving DecidableEq, Repr

-- The terminal's declared operating context; a scheme identifier carries its version.
structure Context where
  network : Bytes
  schemes : List Bytes
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
  query : AppQuery
  checkApp : AppProof → Root → AppQuery → AppValue → Bool
  nextRoot : AppValue → Option Root
  fuel : Nat
  verifier : Bool
  context : Context

-- Each instance is an arbitrary hypothesis, not an implementation of signatures.
class SignatureModel where
  valid : Publication → Prop

def SigValid [SignatureModel] (publication : Publication) : Prop :=
  SignatureModel.valid publication

def ObservationSound [SignatureModel] (policy : Policy) : Prop :=
  ∀ publication, policy.verify publication = true → SigValid publication

-- Each instance is an arbitrary hypothesis, not a message encoding.
class MessageModel where
  encodes : Bytes → Chainpoint → Root → Prop

-- A valid signature's message encodes its publication's point and root, and nothing else.
def MessageBinding [SignatureModel] [MessageModel] : Prop :=
  (∀ publication, SigValid publication →
    MessageModel.encodes publication.message publication.point publication.root) ∧
  ∀ message point root point' root', MessageModel.encodes message point root →
    MessageModel.encodes message point' root' → point = point' ∧ root = root'

inductive Refusal where
  | noRoot (selectedPoint : Chainpoint)
  | unavailablePoint (selectedPoint : Chainpoint)
  | evidenceFailure (selectedPoint : Chainpoint)
  deriving DecidableEq, Repr

def Refusal.selectedPoint : Refusal → Chainpoint
  | .noRoot point | .unavailablePoint point | .evidenceFailure point => point

inductive Binding where
  | bound (point : Chainpoint)
  | unbound
  deriving DecidableEq, Repr

-- Transaction bytes plus resolved spent outputs; carried for rebuilding, never evidence.
structure Reconstruction where
  transaction : Bytes
  spent : List (TxIn × TxOut)
  deriving DecidableEq, Repr

structure LedgerAnswer where
  point : Chainpoint
  object : Bytes
  witness : Option Witness
  root : Root
  reconstruction : Option Reconstruction
  deriving DecidableEq, Repr

structure Session where
  selectedPoint : Chainpoint
  acceptedRoot : Root
  ledger : LedgerAnswer
  binding : Binding
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

structure Claim where
  point : Chainpoint
  ledgerRoot : Root
  query : AppQuery
  appRoot : Root
  links : List Root
  value : AppValue
  deriving DecidableEq, Repr

inductive Reason where
  | noWitness
  | unboundSession
  | noVerifier
  deriving DecidableEq, Repr

-- The terminal classification of an outcome; never a wire object.
inductive Verdict where
  | verified (claim : Claim)
  | refused (refusal : Refusal)
  | unverified (reason : Reason)
  deriving DecidableEq, Repr

end Lockness

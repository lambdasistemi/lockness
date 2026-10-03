import Lockness.Types

namespace Lockness

-- A policy observes publications; equality binds every byte and the full point.
def observedKeys (policy : Policy) (publications : List Publication)
    (point : Chainpoint) (root : Root) : List Key :=
  (List.map Publication.key (List.filter (fun (publication : Publication) =>
    decide (publication.point = point ∧ publication.root = root) && policy.verify publication)
    publications)).eraseDups

-- This filter is the trusted-set check; the counterexample bypasses only it.
def endorsingKeys (policy : Policy) (publications : List Publication)
    (point : Chainpoint) (root : Root) : List Key :=
  (observedKeys policy publications point root).filter fun key =>
    decide (key ∈ policy.trustedKeys)

def Candidate (policy : Policy) (keys : List Key) : Prop :=
  keys ≠ [] ∧ keys.Nodup ∧ policy.agreement keys = true

instance (policy : Policy) (keys : List Key) : Decidable (Candidate policy keys) :=
  inferInstanceAs (Decidable (keys ≠ [] ∧ keys.Nodup ∧ policy.agreement keys = true))

def selectRoot (policy : Policy) (keysFor : Root → List Key) (point : Chainpoint) :
    List Root → Except Refusal Root
  | [] => .error (.noRoot point)
  | root :: rest =>
    if Candidate policy (keysFor root) then .ok root
    else selectRoot policy keysFor point rest

def acceptRoot (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) : Except Refusal Root :=
  selectRoot policy (endorsingKeys policy publications selectedPoint) selectedPoint
    (publications.map Publication.root)

-- Witnesses carry the original publications, including their untouched evidence.
def ObservedEndorsement (policy : Policy) (publications : List Publication)
    (point : Chainpoint) (root : Root) (key : Key) : Prop :=
  ∃ publication ∈ publications, publication.key = key ∧
    publication.point = point ∧ publication.root = root ∧ policy.verify publication = true

def TrustedEndorsement (policy : Policy) (publications : List Publication)
    (point : Chainpoint) (root : Root) : Prop :=
  ∃ keys : List Key, Candidate policy keys ∧
    ∀ key ∈ keys, key ∈ policy.trustedKeys ∧
      ObservedEndorsement policy publications point root key

def RootSafety (accept : Policy → List Publication → Chainpoint → Except Refusal Root) : Prop :=
  ∀ policy publications point root, accept policy publications point = .ok root →
    TrustedEndorsement policy publications point root

-- Agreement and trust do not compute an honest ledger root.
def HonestRootCorrespondence (policy : Policy) (publications : List Publication)
    (honestRoot : Chainpoint → Root) : Prop :=
  ∀ point root, TrustedEndorsement policy publications point root → root = honestRoot point

end Lockness

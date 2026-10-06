import Lockness.Accept

namespace Lockness

-- Reads only the session acquire accepts. Only a declared absence is a reason: an unbound
-- session, or a session bound to the selected point whose answer carries neither a witness nor a
-- completeness answer. A session bound to another point is a contradiction in the offer, not an
-- absence.
def unverifiedReason (selectedPoint : Chainpoint) (provider : Provider) : Option Reason :=
  match acquire selectedPoint provider with
  | .error _ => none
  | .ok session =>
    if session.binding = .unbound then some .unboundSession
    else if session.binding = .bound selectedPoint then
      if session.ledger.witness = none then
        if session.ledger.completeness = none then some .noWitness else none
      else none
    else none

-- The terminal's classification around the unchanged accept: a missing verifier first,
-- consulting nothing; then accept's claim; then a declared absence; else accept's refusal.
def verdict (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) : Verdict :=
  if policy.verifier then
    match accept policy publications selectedPoint provider builder with
    | .ok claim => .verified claim
    | .error refusal =>
      if outOfContext policy publications selectedPoint then .refused refusal
      else match unverifiedReason selectedPoint provider with
      | some reason => .unverified reason
      | none => .refused refusal
  else .unverified .noVerifier

-- A verified claim exists only when the verifier is configured, the offered session is bound
-- to the selected point, its answer carries a witness and accept returned that claim.
def NoPromotion
    (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict) : Prop :=
  ∀ policy publications selectedPoint provider builder claim,
    operation policy publications selectedPoint provider builder = .verified claim →
    policy.verifier = true ∧
    ∃ session witness, provider selectedPoint = some session ∧
      session.selectedPoint = selectedPoint ∧
      session.binding = .bound selectedPoint ∧ session.ledger.witness = some witness ∧
      accept policy publications selectedPoint provider builder = .ok claim

-- AcceptSoundness with the verified premise in place of accept's success.
def VerdictSoundness
    (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict) : Prop :=
  ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (claim : Claim) (ledger : Ledger)
    (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (tree : AppTree)
    (honestNext : AppValue → Option Root),
    HonestRootCorrespondence policy publications honestRoot →
    WitnessSound policy ledger honestRoot → ObjectEncodingFaithful policy →
    AssetObservationSound policy carries → DatumObservationSound policy honestDatumRoot →
    OneShot ledger policy.asset carries → AppSound policy tree →
    NestingInterpretationFaithful policy honestNext →
    operation policy publications selectedPoint provider builder = .verified claim →
    claim.point = selectedPoint ∧ claim.ledgerRoot = honestRoot selectedPoint ∧
      holds policy carries honestDatumRoot tree honestNext (ledger selectedPoint) claim

-- ProviderInvariance with the verified premises in place of accept's successes.
def VerdictProviderInvariance
    (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict) : Prop :=
  ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider₁ provider₂ : Provider) (builder₁ builder₂ : Builder) (claim₁ claim₂ : Claim)
    (ledger : Ledger) (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (tree : AppTree),
    HonestRootCorrespondence policy publications honestRoot →
    WitnessSound policy ledger honestRoot → ObjectEncodingFaithful policy →
    AssetObservationSound policy carries → DatumObservationSound policy honestDatumRoot →
    OneShot ledger policy.asset carries → AppSound policy tree → AppFunctional tree →
    operation policy publications selectedPoint provider₁ builder₁ = .verified claim₁ →
    operation policy publications selectedPoint provider₂ builder₂ = .verified claim₂ →
    claim₁ = claim₂

-- Replaces only the offered answer's reconstruction.
def Session.withReconstruction (reconstruction : Option Reconstruction) (session : Session) :
    Session :=
  { session with ledger := { session.ledger with reconstruction := reconstruction } }

end Lockness

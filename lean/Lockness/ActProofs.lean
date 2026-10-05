import Lockness.Act
import Lockness.VerdictProofs

namespace Lockness

-- An effect is authorized only on a verified claim at the selected point, with an offer bound to
-- that point and the settlement observation holding on the terminal's chain view.
theorem act_effect_requires (policy : Policy) (verdict : Verdict) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) (authorized : Authorized)
    (success : act policy .effect verdict provider selectedPoint chain = .ok authorized) :
    ∃ claim session, verdict = .verified claim ∧ claim.point = selectedPoint ∧
      acquire selectedPoint provider = .ok session ∧ session.binding = .bound selectedPoint ∧
      policy.settlement selectedPoint chain = true ∧
      authorized = ⟨.effect, selectedPoint, .claim claim⟩ := by
  cases verdict with
  | refused refusal => simp [act] at success
  | unverified reason => simp [act] at success
  | verified claim =>
    by_cases here : claim.point = selectedPoint
    · cases acquired : acquire selectedPoint provider with
      | error refusal => simp [act, here, acquired] at success
      | ok session =>
        by_cases bound : session.binding = .bound selectedPoint
        · by_cases settled : policy.settlement selectedPoint chain = true
          · simp [act, here, acquired, bound, settled] at success
            exact ⟨claim, session, rfl, here, rfl, bound, settled, success.symm⟩
          · simp [act, here, acquired, bound, settled] at success
        · simp [act, here, acquired, bound] at success
    · simp [act, here] at success

-- The settlement theorem: under continued ancestry, a successful effect keeps the selected point
-- canonical in every possible future the consensus model admits.
theorem act_settlement [ConsensusModel] : SettlementStability act := by
  intro policy verdict provider selectedPoint chain authorized final success chain' later admitted
  -- The observation is read off the only branch of act that authorizes an effect.
  have settled : policy.settlement selectedPoint chain = true := by
    cases verdict with
    | refused refusal => simp [act] at success
    | unverified reason => simp [act] at success
    | verified claim =>
      by_cases here : claim.point = selectedPoint
      · cases acquired : acquire selectedPoint provider with
        | error refusal => simp [act, here, acquired] at success
        | ok session =>
          by_cases bound : session.binding = .bound selectedPoint
          · cases observed : policy.settlement selectedPoint chain
            · simp [act, here, acquired, bound, observed] at success
            · rfl
          · simp [act, here, acquired, bound] at success
      · simp [act, here] at success
  exact final selectedPoint chain chain' settled later admitted

-- An unverified verdict never carries an effect, for every policy, reason, offer and chain.
theorem unverified_effect_refused (policy : Policy) (reason : Reason) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) :
    act policy .effect (.unverified reason) provider selectedPoint chain =
      .error (.evidenceFailure selectedPoint) := rfl

-- With the verifier off, the effect is refused whatever the context, offer and chain.
theorem no_verifier_effect_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (chain : Chain)
    (off : policy.verifier = false) :
    act policy .effect (verdict policy publications selectedPoint provider builder) provider
      selectedPoint chain = .error (.evidenceFailure selectedPoint) := by
  have unconfigured : verdict policy publications selectedPoint provider builder =
      .unverified .noVerifier := by
    simp [verdict, off]
  rw [unconfigured]
  rfl

-- An authorized effect composes with the verdict's no-promotion guarantee.
theorem effect_no_promotion (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (chain : Chain)
    (authorized : Authorized)
    (success : act policy .effect (verdict policy publications selectedPoint provider builder)
      provider selectedPoint chain = .ok authorized) :
    policy.verifier = true ∧
    ∃ claim session witness, provider selectedPoint = some session ∧
      session.selectedPoint = selectedPoint ∧ session.binding = .bound selectedPoint ∧
      session.ledger.witness = some witness ∧
      accept policy publications selectedPoint provider builder = .ok claim ∧
      authorized.basis = .claim claim ∧ policy.settlement selectedPoint chain = true := by
  obtain ⟨claim, _, verified, _, _, _, settled, granted⟩ :=
    act_effect_requires policy _ provider selectedPoint chain authorized success
  obtain ⟨configured, session, witness, offered, samePoint, bound, present, accepted⟩ :=
    verdict_no_promotion policy publications selectedPoint provider builder claim verified
  subst granted
  exact ⟨configured, claim, session, witness, offered, samePoint, bound, present, accepted, rfl,
    settled⟩

-- The action rule alone decides construction on an unverified verdict, from the offer acquired at
-- the selected point.
theorem unverified_construct_iff (policy : Policy) (reason : Reason) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) (authorized : Authorized) :
    act policy .construct (.unverified reason) provider selectedPoint chain = .ok authorized ↔
      policy.constructUnverified reason = true ∧
        ∃ session, acquire selectedPoint provider = .ok session ∧
          authorized = ⟨.construct, selectedPoint, .offer reason session⟩ := by
  constructor
  · intro success
    by_cases rule : policy.constructUnverified reason = true
    · cases acquired : acquire selectedPoint provider with
      | error refusal => simp [act, rule, acquired] at success
      | ok session =>
        simp [act, rule, acquired] at success
        exact ⟨rule, session, rfl, success.symm⟩
    · simp [act, rule] at success
  · rintro ⟨rule, session, acquired, rfl⟩
    simp [act, rule, acquired]

-- Construction never reads the chain, so it asserts nothing about settlement.
theorem construct_chain_irrelevant (policy : Policy) (verdict : Verdict) (provider : Provider)
    (selectedPoint : Chainpoint) (chain chain' : Chain) :
    act policy .construct verdict provider selectedPoint chain =
      act policy .construct verdict provider selectedPoint chain' := by
  cases verdict <;> rfl

theorem act_action (policy : Policy) (action : Action) (verdict : Verdict) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) (authorized : Authorized)
    (success : act policy action verdict provider selectedPoint chain = .ok authorized) :
    authorized.action = action := by
  cases action with
  | effect =>
    obtain ⟨_, _, _, _, _, _, _, granted⟩ :=
      act_effect_requires policy verdict provider selectedPoint chain authorized success
    subst granted
    rfl
  | construct =>
    cases verdict with
    | refused refusal => simp [act] at success
    | verified claim =>
      by_cases here : claim.point = selectedPoint
      · simp [act, here] at success
        subst success
        rfl
      · simp [act, here] at success
    | unverified reason =>
      by_cases rule : policy.constructUnverified reason = true
      · cases acquired : acquire selectedPoint provider with
        | error refusal => simp [act, rule, acquired] at success
        | ok session =>
          simp [act, rule, acquired] at success
          subst success
          rfl
      · simp [act, rule] at success

theorem act_never_adopts (policy : Policy) (action : Action) (verdict : Verdict)
    (provider : Provider) (selectedPoint : Chainpoint) (chain : Chain) (authorized : Authorized)
    (success : act policy action verdict provider selectedPoint chain = .ok authorized) :
    authorized.point = selectedPoint := by
  cases action with
  | effect =>
    obtain ⟨_, _, _, _, _, _, _, granted⟩ :=
      act_effect_requires policy verdict provider selectedPoint chain authorized success
    subst granted
    rfl
  | construct =>
    cases verdict with
    | refused refusal => simp [act] at success
    | verified claim =>
      by_cases here : claim.point = selectedPoint
      · simp [act, here] at success
        subst success
        rfl
      · simp [act, here] at success
    | unverified reason =>
      by_cases rule : policy.constructUnverified reason = true
      · cases acquired : acquire selectedPoint provider with
        | error refusal => simp [act, rule, acquired] at success
        | ok session =>
          simp [act, rule, acquired] at success
          subst success
          rfl
      · simp [act, rule] at success

-- Every refusal is at the selected point: a refusal elsewhere is re-pointed, and acquire refuses
-- only at the point it was asked.
theorem act_refusal (policy : Policy) (action : Action) (verdict : Verdict) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) (refusal : Refusal)
    (failed : act policy action verdict provider selectedPoint chain = .error refusal) :
    refusal.selectedPoint = selectedPoint := by
  cases verdict with
  | refused found =>
    by_cases same : found.selectedPoint = selectedPoint
    · simp [act, same] at failed
      subst failed
      exact same
    · simp [act, same] at failed
      subst failed
      rfl
  | verified claim =>
    by_cases here : claim.point = selectedPoint
    · cases action with
      | construct => simp [act, here] at failed
      | effect =>
        cases acquired : acquire selectedPoint provider with
        | error found =>
          simp [act, here, acquired] at failed
          subst failed
          exact (acquire_refusal _ _ _ acquired) ▸ rfl
        | ok session =>
          by_cases bound : session.binding = .bound selectedPoint
          · cases observed : policy.settlement selectedPoint chain
            · simp [act, here, acquired, bound, observed] at failed
              subst failed
              rfl
            · simp [act, here, acquired, bound, observed] at failed
          · simp [act, here, acquired, bound] at failed
            subst failed
            rfl
    · simp [act, here] at failed
      subst failed
      rfl
  | unverified reason =>
    cases action with
    | effect =>
      simp [act] at failed
      subst failed
      rfl
    | construct =>
      by_cases rule : policy.constructUnverified reason = true
      · cases acquired : acquire selectedPoint provider with
        | error found =>
          simp [act, rule, acquired] at failed
          subst failed
          exact (acquire_refusal _ _ _ acquired) ▸ rfl
        | ok session => simp [act, rule, acquired] at failed
      · simp [act, rule] at failed
        subst failed
        rfl

-- Under continued ancestry and a consensus model admitting the present chain, a point that is not
-- canonical in the terminal's view never carries an effect.
theorem abandoned_effect_refused [ConsensusModel] (policy : Policy) (verdict : Verdict)
    (provider : Provider) (selectedPoint : Chainpoint) (chain : Chain) (authorized : Authorized)
    (final : ContinuedAncestry policy) (present : ConsensusModel.admits chain chain)
    (gone : ¬ canonical selectedPoint chain) :
    act policy .effect verdict provider selectedPoint chain ≠ .ok authorized := by
  intro success
  exact gone (act_settlement policy verdict provider selectedPoint chain authorized final success chain
    (.refl chain) present)

end Lockness

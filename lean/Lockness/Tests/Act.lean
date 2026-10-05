import Lockness.ActProofs
import Lockness.Counterexamples.SettlementRollback

namespace Lockness.Tests.Act
open Counterexamples Counterexamples.AppExamples Counterexamples.VerdictExamples
open Counterexamples.ContextExamples Counterexamples.ActExamples

-- Released types, fields and signatures.
example : Branch = List Chainpoint := rfl
example : Chain = List Branch := rfl
example (policy : Policy) : Chainpoint → Chain → Bool := policy.settlement
example (policy : Policy) : Reason → Bool := policy.constructUnverified
example : List Action := [.construct, .effect]
example (claim : Claim) (reason : Reason) (session : Session) : List Basis :=
  [.claim claim, .offer reason session]
example (action : Action) (point : Chainpoint) (basis : Basis) : Authorized := ⟨action, point, basis⟩
example (authorized : Authorized) : Action × Chainpoint × Basis :=
  (authorized.action, authorized.point, authorized.basis)
example : Authorized → Authorized → Bool := fun first second => decide (first = second)
example : Policy → Action → Verdict → Provider → Chainpoint → Chain → Except Refusal Authorized := act
example [ConsensusModel] : Chain → Chain → Prop := ConsensusModel.admits
example (point : Chainpoint) (chain : Chain) : Bool := decide (canonical point chain)

-- Ruled definitions, ascribed in full so that any change to a definition fails here.
example (chain : Chain) : tip chain = chain.headD [] := rfl
example (point : Chainpoint) (chain : Chain) : canonical point chain = (point ∈ tip chain) := rfl
example (depth : Nat) (fork : Branch) (chain : Chain) :
    rollback depth fork chain = ((tip chain).take ((tip chain).length - depth) ++ fork) :: chain := rfl
example (chain : Chain) : Extends chain chain := .refl chain
example {chain later : Chain} (depth : Nat) (fork : Branch) (earlier : Extends chain later) :
    Extends chain (rollback depth fork later) := .step depth fork earlier
example [ConsensusModel] (policy : Policy) :
    ContinuedAncestry policy ↔
      ∀ point chain chain', policy.settlement point chain = true → Extends chain chain' →
        ConsensusModel.admits chain chain' → canonical point chain' := Iff.rfl
example (policy : Policy) (action : Action) (verdict : Verdict) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) :
    act policy action verdict provider selectedPoint chain =
      match verdict with
      | .refused refusal =>
        .error (if refusal.selectedPoint = selectedPoint then refusal else .evidenceFailure selectedPoint)
      | .verified claim =>
        if claim.point ≠ selectedPoint then .error (.evidenceFailure selectedPoint) else
        match action with
        | .construct => .ok ⟨.construct, selectedPoint, .claim claim⟩
        | .effect =>
          match acquire selectedPoint provider with
          | .error refusal => .error refusal
          | .ok session =>
            if session.binding = .bound selectedPoint then
              if policy.settlement selectedPoint chain then .ok ⟨.effect, selectedPoint, .claim claim⟩
              else .error (.evidenceFailure selectedPoint)
            else .error (.evidenceFailure selectedPoint)
      | .unverified reason =>
        match action with
        | .effect => .error (.evidenceFailure selectedPoint)
        | .construct =>
          if policy.constructUnverified reason then
            match acquire selectedPoint provider with
            | .error refusal => .error refusal
            | .ok session => .ok ⟨.construct, selectedPoint, .offer reason session⟩
          else .error (.evidenceFailure selectedPoint) := rfl
example [ConsensusModel]
    (operation : Policy → Action → Verdict → Provider → Chainpoint → Chain →
      Except Refusal Authorized) :
    SettlementStability operation ↔
      ∀ policy verdict provider selectedPoint chain authorized, ContinuedAncestry policy →
        operation policy .effect verdict provider selectedPoint chain = .ok authorized →
        ∀ chain', Extends chain chain' → ConsensusModel.admits chain chain' →
          canonical selectedPoint chain' := Iff.rfl
example (state : SessionState) :
    readSession state =
      match state with
      | .active session => .ok session
      | .requested point | .unavailable point => .error (.unavailablePoint point)
      | .expired session | .closed session | .abandoned session =>
        .error (.unavailablePoint session.point) := by
  cases state <;> rfl
example (session : Session) (chain : Chain) (gone : ¬ canonical session.point chain) :
    SessionTransition (.active session) (.abandoned session) := .abandon session chain gone

-- Ruled statements, ascribed in full.
example (depth : Nat) (fork : Branch) (chain : Chain) : Extends chain (rollback depth fork chain) :=
  rollback_extends depth fork chain
example {first second third : Chain} (one : Extends first second) (two : Extends second third) :
    Extends first third := extends_trans one two
example (point : Chainpoint) (depth : Nat) (fork : Branch) (chain : Chain) :
    canonical point (rollback depth fork chain) ↔
      point ∈ (tip chain).take ((tip chain).length - depth) ∨ point ∈ fork :=
  rollback_canonical point depth fork chain
example (session : Session) :
    readSession (.abandoned session) = .error (.unavailablePoint session.point) :=
  abandoned_read session
example (session : Session) (after : SessionState) :
    ¬ SessionTransition (.abandoned session) after := abandoned_terminal session after
-- The single restated inherited statement.
example (session : Session) (after : SessionState)
    (transition : SessionTransition (.active session) after) :
    after = .active session ∨ after = .expired session ∨ after = .closed session ∨
      after = .abandoned session := active_transition session after transition
example [ConsensusModel] : SettlementStability act := act_settlement
example (policy : Policy) (verdict : Verdict) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) (authorized : Authorized)
    (success : act policy .effect verdict provider selectedPoint chain = .ok authorized) :
    ∃ claim session, verdict = .verified claim ∧ claim.point = selectedPoint ∧
      acquire selectedPoint provider = .ok session ∧ session.binding = .bound selectedPoint ∧
      policy.settlement selectedPoint chain = true ∧
      authorized = ⟨.effect, selectedPoint, .claim claim⟩ :=
  act_effect_requires policy verdict provider selectedPoint chain authorized success
example (policy : Policy) (reason : Reason) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) :
    act policy .effect (.unverified reason) provider selectedPoint chain =
      .error (.evidenceFailure selectedPoint) :=
  unverified_effect_refused policy reason provider selectedPoint chain
example (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (chain : Chain)
    (off : policy.verifier = false) :
    act policy .effect (verdict policy publications selectedPoint provider builder) provider
      selectedPoint chain = .error (.evidenceFailure selectedPoint) :=
  no_verifier_effect_refused policy publications selectedPoint provider builder chain off
example (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (chain : Chain)
    (authorized : Authorized)
    (success : act policy .effect (verdict policy publications selectedPoint provider builder)
      provider selectedPoint chain = .ok authorized) :
    policy.verifier = true ∧
    ∃ claim session witness, provider selectedPoint = some session ∧
      session.selectedPoint = selectedPoint ∧ session.binding = .bound selectedPoint ∧
      session.ledger.witness = some witness ∧
      accept policy publications selectedPoint provider builder = .ok claim ∧
      authorized.basis = .claim claim ∧ policy.settlement selectedPoint chain = true :=
  effect_no_promotion policy publications selectedPoint provider builder chain authorized success
example (policy : Policy) (reason : Reason) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) (authorized : Authorized) :
    act policy .construct (.unverified reason) provider selectedPoint chain = .ok authorized ↔
      policy.constructUnverified reason = true ∧
        ∃ session, acquire selectedPoint provider = .ok session ∧
          authorized = ⟨.construct, selectedPoint, .offer reason session⟩ :=
  unverified_construct_iff policy reason provider selectedPoint chain authorized
example (policy : Policy) (verdict : Verdict) (provider : Provider)
    (selectedPoint : Chainpoint) (chain chain' : Chain) :
    act policy .construct verdict provider selectedPoint chain =
      act policy .construct verdict provider selectedPoint chain' :=
  construct_chain_irrelevant policy verdict provider selectedPoint chain chain'
example (policy : Policy) (action : Action) (verdict : Verdict) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) (authorized : Authorized)
    (success : act policy action verdict provider selectedPoint chain = .ok authorized) :
    authorized.action = action :=
  act_action policy action verdict provider selectedPoint chain authorized success
example (policy : Policy) (action : Action) (verdict : Verdict)
    (provider : Provider) (selectedPoint : Chainpoint) (chain : Chain) (authorized : Authorized)
    (success : act policy action verdict provider selectedPoint chain = .ok authorized) :
    authorized.point = selectedPoint :=
  act_never_adopts policy action verdict provider selectedPoint chain authorized success
example (policy : Policy) (action : Action) (verdict : Verdict) (provider : Provider)
    (selectedPoint : Chainpoint) (chain : Chain) (refusal : Refusal)
    (failed : act policy action verdict provider selectedPoint chain = .error refusal) :
    refusal.selectedPoint = selectedPoint :=
  act_refusal policy action verdict provider selectedPoint chain refusal failed
example [ConsensusModel] (policy : Policy) (verdict : Verdict)
    (provider : Provider) (selectedPoint : Chainpoint) (chain : Chain) (authorized : Authorized)
    (final : ContinuedAncestry policy) (present : ConsensusModel.admits chain chain)
    (gone : ¬ canonical selectedPoint chain) :
    act policy .effect verdict provider selectedPoint chain ≠ .ok authorized :=
  abandoned_effect_refused policy verdict provider selectedPoint chain authorized final present gone

-- Fixture statements and refutations.
example (point : Chainpoint) (chain : Chain) :
    settledPolicy.settlement point chain = decide (point ∈ buried chain) := rfl
example (reason : Reason) : settledPolicy.constructUnverified reason = decide (reason = .noWitness) :=
  rfl
example (chain chain' : Chain) :
    @ConsensusModel.admits fixtureConsensus chain chain' =
      ((buried chain).isPrefixOf (tip chain') = true) := rfl
example : @ContinuedAncestry fixtureConsensus settledPolicy := fixture_continued_ancestry
example :
    @ContinuedAncestry fixtureConsensus settledPolicy ∧
    verdict settledPolicy publications selected verifiedProvider builder = .verified oneLinkClaim ∧
    act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected settledChain = .ok ⟨.effect, selected, .claim oneLinkClaim⟩ ∧
    act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected tipChain = .error (.evidenceFailure selected) :=
  settled_effect_inhabited
example
    (operation : Policy → Action → Verdict → Provider → Chainpoint → Chain →
      Except Refusal Authorized)
    (authorizes : operation settledPolicy .effect (.verified oneLinkClaim) verifiedProvider selected
      tipChain = .ok ⟨.effect, selected, .claim oneLinkClaim⟩) :
    ¬ @SettlementStability fixtureConsensus operation :=
  settlement_dropped_refutes operation authorizes
example :
    ¬ (∀ (policy : Policy) (verdict : Verdict) (provider : Provider) (selectedPoint : Chainpoint)
        (chain : Chain) (authorized : Authorized), @ContinuedAncestry fixtureConsensus policy →
        act policy .effect verdict provider selectedPoint chain = .ok authorized →
        ∀ chain', Extends chain chain' → canonical selectedPoint chain') :=
  consensus_dropped_refutes

-- The fixture contracts the scenarios rely on, each evaluated.
theorem fixture_chains :
    canonical selected tipChain ∧ canonical selected settledChain ∧
    ¬ canonical selected rolledChain ∧ ¬ canonical selected regrownChain ∧
    ¬ canonical selected deepChain ∧
    settledPolicy.settlement selected settledChain = true ∧
    settledPolicy.settlement selected tipChain = false ∧
    settledPolicy.settlement selected rolledChain = false ∧
    settledPolicy.settlement selected regrownChain = false ∧
    (buried tipChain).isPrefixOf (tip rolledChain) = true ∧
    (buried rolledChain).isPrefixOf (tip regrownChain) = true ∧
    (buried settledChain).isPrefixOf (tip deepChain) = false := by decide

-- Rollback is reachable: every fixture future is an Extends step, and the replaced branch is kept.
example : Extends tipChain rolledChain := rolled_extends
example : Extends tipChain regrownChain := regrown_extends
example : Extends settledChain deepChain := deep_extends
example : rolledChain.tail = tipChain ∧ deepChain.tail = settledChain := by decide

theorem fixture_verdicts :
    verdict settledPolicy publications selected verifiedProvider builder = .verified oneLinkClaim ∧
    verdict settledPolicy publications selected noWitnessProvider builder = .unverified .noWitness ∧
    verdict settledPolicy publications selected unboundProvider builder =
      .unverified .unboundSession ∧
    verdict noVerifierSettledPolicy publications selected verifiedProvider builder =
      .unverified .noVerifier ∧
    verdict outOfContextNoVerifierPolicy publications selected verifiedProvider builder =
      .unverified .noVerifier ∧
    selected.network ≠ outOfContextNoVerifierPolicy.context.network ∧
    outOfContextNoVerifierPolicy.verifier = false := by decide
example : noVerifierSettledPolicy.settlement = settledPolicy.settlement ∧
    outOfContextNoVerifierPolicy.settlement = settledPolicy.settlement := ⟨rfl, rfl⟩

-- Finite outcomes of the five scenarios, each evaluated by the real verdict and act.
theorem construct_outcome :
    act settledPolicy .construct (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected tipChain = .ok ⟨.construct, selected, .claim oneLinkClaim⟩ ∧
    act settledPolicy .construct (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected settledChain = .ok ⟨.construct, selected, .claim oneLinkClaim⟩ ∧
    act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected tipChain = .error (.evidenceFailure selected) := by decide

theorem settled_effect_outcome :
    act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected settledChain = .ok ⟨.effect, selected, .claim oneLinkClaim⟩ ∧
    act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
      unboundProvider selected settledChain = .error (.evidenceFailure selected) := by decide

theorem rolled_back_outcome :
    act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected rolledChain = .error (.evidenceFailure selected) ∧
    act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected regrownChain = .error (.evidenceFailure selected) ∧
    readSession (.abandoned verifiedSession) = .error (.unavailablePoint selected) := by decide

-- The abandon transition is reachable at the fixture rollback, and nothing follows it.
example : SessionTransition (.active verifiedSession) (.abandoned verifiedSession) :=
  .abandon verifiedSession rolledChain (by decide)
example (after : SessionState) : ¬ SessionTransition (.abandoned verifiedSession) after :=
  abandoned_terminal verifiedSession after
-- The rolled-back point never settles under the jointly inhabited hypothesis.
example (authorized : Authorized) :
    act settledPolicy .effect (verdict settledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected rolledChain ≠ .ok authorized :=
  @abandoned_effect_refused fixtureConsensus settledPolicy _ verifiedProvider selected rolledChain
    authorized fixture_continued_ancestry rolled_self_admitted (by decide)

theorem unverified_construct_outcome :
    act settledPolicy .construct (verdict settledPolicy publications selected noWitnessProvider builder)
      noWitnessProvider selected tipChain =
        .ok ⟨.construct, selected, .offer .noWitness noWitnessSession⟩ ∧
    act noVerifierSettledPolicy .construct
      (verdict noVerifierSettledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected tipChain = .error (.evidenceFailure selected) ∧
    act settledPolicy .construct (verdict settledPolicy publications selected unboundProvider builder)
      unboundProvider selected tipChain = .error (.evidenceFailure selected) := by decide

theorem unverified_effect_outcome :
    act settledPolicy .effect (verdict settledPolicy publications selected noWitnessProvider builder)
      noWitnessProvider selected settledChain = .error (.evidenceFailure selected) ∧
    act settledPolicy .effect (verdict settledPolicy publications selected unboundProvider builder)
      unboundProvider selected settledChain = .error (.evidenceFailure selected) ∧
    act noVerifierSettledPolicy .effect
      (verdict noVerifierSettledPolicy publications selected verifiedProvider builder)
      verifiedProvider selected settledChain = .error (.evidenceFailure selected) ∧
    act outOfContextNoVerifierPolicy .effect
      (verdict outOfContextNoVerifierPolicy publications selected verifiedProvider builder)
      verifiedProvider selected settledChain = .error (.evidenceFailure selected) := by decide

-- Refusals stay at the selected point: a foreign refusal, a claim at another point and a withheld
-- offer.
theorem refusal_outcomes :
    act settledPolicy .effect (.refused (.noRoot otherPoint)) verifiedProvider selected
      settledChain = .error (.evidenceFailure selected) ∧
    act settledPolicy .construct (.refused (.noRoot selected)) verifiedProvider selected
      settledChain = .error (.noRoot selected) ∧
    act settledPolicy .construct (.verified { oneLinkClaim with point := otherPoint })
      verifiedProvider selected settledChain = .error (.evidenceFailure selected) ∧
    act settledPolicy .effect (.verified oneLinkClaim) (fun _ => none) selected settledChain =
      .error (.unavailablePoint selected) ∧
    act settledPolicy .construct (.unverified .noWitness) (fun _ => none) selected tipChain =
      .error (.unavailablePoint selected) := by decide

-- The neutral values on inherited literals: nothing settled, no unverified construction.
theorem neutral_values :
    honestPolicy.settlement selected settledChain = false ∧
    honestPolicy.constructUnverified .noWitness = false ∧
    policy.settlement selected settledChain = false ∧
    policy.constructUnverified .noWitness = false := by decide

-- The verified claim is the honest semantic claim.
theorem act_claim_semantic :
    semanticClaim false LedgerExamples.entry₁ finalQuery = some oneLinkClaim := by decide

#print axioms rollback_extends
#print axioms extends_trans
#print axioms rollback_canonical
#print axioms abandoned_read
#print axioms abandoned_terminal
#print axioms active_transition
#print axioms act_settlement
#print axioms act_effect_requires
#print axioms unverified_effect_refused
#print axioms no_verifier_effect_refused
#print axioms effect_no_promotion
#print axioms unverified_construct_iff
#print axioms construct_chain_irrelevant
#print axioms act_action
#print axioms act_never_adopts
#print axioms act_refusal
#print axioms abandoned_effect_refused
#print axioms fixture_continued_ancestry
#print axioms settled_effect_inhabited
#print axioms settlement_dropped_refutes
#print axioms consensus_dropped_refutes

end Lockness.Tests.Act

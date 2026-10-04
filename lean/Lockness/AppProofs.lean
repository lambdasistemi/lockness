import Lockness.App

namespace Lockness

-- Inversion records every guard, with the proof checked under the trusted root and query.
theorem verifyApp_observations (policy : Policy) (selectedPoint : Chainpoint) (root : Root)
    (answer : AppAnswer) (value : AppValue)
    (success : verifyApp policy selectedPoint root answer = .ok value) :
    answer.root = root ∧ answer.point = selectedPoint ∧
    answer.application = policy.query.application ∧ answer.context = policy.query.context ∧
    answer.claim = policy.query.claim ∧
    policy.checkApp answer.proof root policy.query value = true ∧ value = answer.value := by
  dsimp only [verifyApp] at success
  split at success
  · rename_i claimed
    split at success
    · rename_i pointEq
      split at success
      · rename_i fields
        split at success
        · rename_i checked
          cases success
          exact ⟨claimed, pointEq, fields.1, fields.2.1, fields.2.2, checked, rfl⟩
        · cases success
      · cases success
    · cases success
  · cases success

-- A claimed root other than the trusted root is refused whatever the proof checker says.
theorem verifyApp_claimed_root_first (policy : Policy) (selectedPoint : Chainpoint) (root : Root)
    (answer : AppAnswer) (claimed : answer.root ≠ root) :
    verifyApp policy selectedPoint root answer = .error (.evidenceFailure selectedPoint) := by
  simp [verifyApp, claimed]

theorem verifyApp_refusal (policy : Policy) (selectedPoint : Chainpoint) (root : Root)
    (answer : AppAnswer) (refusal : Refusal)
    (failure : verifyApp policy selectedPoint root answer = .error refusal) :
    refusal = .evidenceFailure selectedPoint := by
  dsimp only [verifyApp] at failure
  split at failure
  · split at failure
    · split at failure
      · split at failure
        · cases failure
        · cases failure; rfl
      · cases failure; rfl
    · cases failure; rfl
  · cases failure; rfl

-- One checked link: the answer, its verified value and either the end or the rest of the chain.
theorem verifyChain_step (policy : Policy) (selectedPoint : Chainpoint) (builder : Builder)
    (fuel : Nat) (root : Root) (links : List Root) (value : AppValue)
    (success : verifyChain policy selectedPoint builder (fuel + 1) root = .ok (links, value)) :
    ∃ answer carrier, builder root = some answer ∧
      verifyApp policy selectedPoint root answer = .ok carrier ∧
      ((policy.nextRoot carrier = none ∧ links = [] ∧ value = carrier) ∨
        ∃ next rest, policy.nextRoot carrier = some next ∧ links = next :: rest ∧
          verifyChain policy selectedPoint builder fuel next = .ok (rest, value)) := by
  simp only [verifyChain] at success
  split at success
  · cases success
  · rename_i answer built
    split at success
    · cases success
    · rename_i carrier checked
      split at success
      · rename_i last
        have pair := Prod.mk.inj (Except.ok.inj success)
        exact ⟨answer, carrier, built, checked, Or.inl ⟨last, pair.1.symm, pair.2.symm⟩⟩
      · rename_i next carries
        split at success
        · cases success
        · rename_i rest final tail
          have pair := Prod.mk.inj (Except.ok.inj success)
          refine ⟨answer, carrier, built, checked, Or.inr ⟨next, rest, carries, pair.1.symm, ?_⟩⟩
          rw [← pair.2]
          exact tail

theorem verifyChain_refusal (policy : Policy) (selectedPoint : Chainpoint) (builder : Builder)
    (fuel : Nat) (root : Root) (refusal : Refusal)
    (failure : verifyChain policy selectedPoint builder fuel root = .error refusal) :
    refusal = .evidenceFailure selectedPoint := by
  induction fuel generalizing root with
  | zero =>
    simp only [verifyChain] at failure
    cases failure
    rfl
  | succ fuel ih =>
    simp only [verifyChain] at failure
    split at failure
    · cases failure
      rfl
    · split at failure
      · rename_i rejected
        cases failure
        exact verifyApp_refusal policy selectedPoint root _ _ rejected
      · split at failure
        · cases failure
        · split at failure
          · rename_i rejected
            cases failure
            exact ih _ rejected
          · cases failure

-- Every link's value is committed under that link's trusted root, and nesting is honest.
theorem verifyChain_holds (policy : Policy) (selectedPoint : Chainpoint) (builder : Builder)
    (tree : AppTree) (honestNext : AppValue → Option Root) (appSound : AppSound policy tree)
    (nesting : NestingInterpretationFaithful policy honestNext) (fuel : Nat) (root : Root)
    (links : List Root) (value : AppValue)
    (success : verifyChain policy selectedPoint builder fuel root = .ok (links, value)) :
    ChainHolds tree honestNext policy.query root links value := by
  induction fuel generalizing root links value with
  | zero =>
    simp only [verifyChain] at success
    cases success
  | succ fuel ih =>
    obtain ⟨answer, carrier, _, checked, outcome⟩ :=
      verifyChain_step policy selectedPoint builder fuel root links value success
    obtain ⟨_, _, _, _, _, proof, _⟩ :=
      verifyApp_observations policy selectedPoint root answer carrier checked
    have member := appSound answer.proof root policy.query carrier proof
    rcases outcome with ⟨last, finalLinks, finalValue⟩ | ⟨next, rest, carries, nextLinks, tail⟩
    · rw [finalLinks, finalValue]
      exact .final root carrier member ((nesting carrier).symm.trans last)
    · rw [nextLinks]
      exact .link root next carrier rest value member ((nesting carrier).symm.trans carries)
        (ih next rest value tail)

-- With functional content, two builders that both succeed verify the same links and value.
theorem verifyChain_functional (policy : Policy) (selectedPoint : Chainpoint)
    (builder₁ builder₂ : Builder) (tree : AppTree) (appSound : AppSound policy tree)
    (functional : AppFunctional tree) (fuel : Nat) (root : Root) (links₁ links₂ : List Root)
    (value₁ value₂ : AppValue)
    (first : verifyChain policy selectedPoint builder₁ fuel root = .ok (links₁, value₁))
    (second : verifyChain policy selectedPoint builder₂ fuel root = .ok (links₂, value₂)) :
    links₁ = links₂ ∧ value₁ = value₂ := by
  induction fuel generalizing root links₁ links₂ value₁ value₂ with
  | zero =>
    simp only [verifyChain] at first
    cases first
  | succ fuel ih =>
    obtain ⟨answer₁, carrier₁, _, checked₁, outcome₁⟩ :=
      verifyChain_step policy selectedPoint builder₁ fuel root links₁ value₁ first
    obtain ⟨answer₂, carrier₂, _, checked₂, outcome₂⟩ :=
      verifyChain_step policy selectedPoint builder₂ fuel root links₂ value₂ second
    obtain ⟨_, _, _, _, _, proof₁, _⟩ :=
      verifyApp_observations policy selectedPoint root answer₁ carrier₁ checked₁
    obtain ⟨_, _, _, _, _, proof₂, _⟩ :=
      verifyApp_observations policy selectedPoint root answer₂ carrier₂ checked₂
    have same : carrier₁ = carrier₂ := functional root policy.query carrier₁ carrier₂
      (appSound _ _ _ _ proof₁) (appSound _ _ _ _ proof₂)
    rw [← same] at outcome₂
    rcases outcome₁ with ⟨last₁, links₁Eq, value₁Eq⟩ | ⟨next₁, rest₁, carries₁, links₁Eq, tail₁⟩ <;>
      rcases outcome₂ with ⟨last₂, links₂Eq, value₂Eq⟩ | ⟨next₂, rest₂, carries₂, links₂Eq, tail₂⟩
    · exact ⟨links₁Eq.trans links₂Eq.symm, value₁Eq.trans value₂Eq.symm⟩
    · rw [last₁] at carries₂
      cases carries₂
    · rw [last₂] at carries₁
      cases carries₁
    · rw [carries₁] at carries₂
      cases carries₂
      obtain ⟨sameLinks, sameValue⟩ := ih next₁ rest₁ rest₂ value₁ value₂ tail₁ tail₂
      exact ⟨by rw [links₁Eq, links₂Eq, sameLinks], sameValue⟩

end Lockness

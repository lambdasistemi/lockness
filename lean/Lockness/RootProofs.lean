import Lockness.Root

namespace Lockness

private theorem selectRoot_candidate (policy : Policy) (keysFor : Root → List Key)
    (point : Chainpoint) (roots : List Root) (root : Root)
    (success : selectRoot policy keysFor point roots = .ok root) :
    Candidate policy (keysFor root) := by
  induction roots with
  | nil => simp [selectRoot] at success
  | cons candidate rest ih =>
    simp only [selectRoot] at success
    split at success
    · rename_i h
      cases success
      exact h
    · exact ih success

private theorem endorsingKeys_witness (policy : Policy) (publications : List Publication)
    (point : Chainpoint) (root : Root) (key : Key)
    (member : key ∈ endorsingKeys policy publications point root) :
    key ∈ policy.trustedKeys ∧ ObservedEndorsement policy publications point root key := by
  simp only [endorsingKeys, List.mem_filter, decide_eq_true_eq] at member
  refine ⟨member.2, ?_⟩
  have observed := member.1
  simp only [observedKeys, List.mem_eraseDups, List.mem_map, List.mem_filter,
    Bool.and_eq_true, decide_eq_true_eq] at observed
  obtain ⟨publication, ⟨inList, ⟨binding, verified⟩⟩, keyEq⟩ := observed
  exact ⟨publication, inList, keyEq, binding.1, binding.2, verified⟩

theorem acceptRoot_safe : RootSafety acceptRoot := by
  intro policy publications point root success
  refine ⟨endorsingKeys policy publications point root, ?_, ?_⟩
  · exact selectRoot_candidate policy _ point _ root success
  · intro key member
    exact endorsingKeys_witness policy publications point root key member

-- Validity follows only from the caller's soundness assumption for observations.
theorem acceptRoot_valid [SignatureModel] (policy : Policy) (publications : List Publication)
    (point : Chainpoint) (root : Root) (success : acceptRoot policy publications point = .ok root)
    (sound : ObservationSound policy) :
    ∃ keys : List Key, Candidate policy keys ∧
      ∀ key ∈ keys, key ∈ policy.trustedKeys ∧
        ∃ publication ∈ publications, publication.key = key ∧
          publication.point = point ∧ publication.root = root ∧ SigValid publication := by
  obtain ⟨keys, candidate, witnesses⟩ := acceptRoot_safe policy publications point root success
  refine ⟨keys, candidate, ?_⟩
  intro key member
  obtain ⟨trusted, publication, inList, keyEq, pointEq, rootEq, verified⟩ := witnesses key member
  exact ⟨trusted, publication, inList, keyEq, pointEq, rootEq, sound publication verified⟩

theorem acceptRoot_honest (policy : Policy) (publications : List Publication)
    (point : Chainpoint) (root : Root) (honestRoot : Chainpoint → Root)
    (success : acceptRoot policy publications point = .ok root)
    (correspondence : HonestRootCorrespondence policy publications honestRoot) :
    root = honestRoot point :=
  correspondence point root (acceptRoot_safe policy publications point root success)

-- Public refusal inversion: no substitution or alternative failure from this function.
theorem acceptRoot_refusal (policy : Policy) (publications : List Publication)
    (point : Chainpoint) (refusal : Refusal)
    (failure : acceptRoot policy publications point = .error refusal) :
    refusal = .noRoot point := by
  unfold acceptRoot at failure
  generalize publications.map Publication.root = roots at failure
  induction roots with
  | nil => simpa [selectRoot] using failure.symm
  | cons root rest ih =>
    simp only [selectRoot] at failure
    split at failure
    · contradiction
    · exact ih failure

end Lockness

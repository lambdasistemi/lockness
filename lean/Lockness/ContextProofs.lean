import Lockness.ContextStatements
import Lockness.VerdictProofs

namespace Lockness

-- Root acceptance in context refuses only as acceptRoot does (noRoot) or as the guard does.
theorem acceptContextRoot_refusal (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (refusal : Refusal)
    (failure : acceptContextRoot policy publications selectedPoint = .error refusal) :
    refusal = .noRoot selectedPoint ∨ refusal = .evidenceFailure selectedPoint := by
  unfold acceptContextRoot at failure
  split at failure
  · cases failure
    exact Or.inr rfl
  · exact Or.inl (acceptRoot_refusal policy publications selectedPoint refusal failure)

-- An accepted root in context is acceptRoot's root, on the context network, under an accepted
-- scheme.
theorem acceptContextRoot_in_context (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (root : Root)
    (success : acceptContextRoot policy publications selectedPoint = .ok root) :
    acceptRoot policy publications selectedPoint = .ok root ∧
      outOfContext policy publications selectedPoint = false ∧
      selectedPoint.network = policy.context.network ∧ root.scheme ∈ policy.context.schemes := by
  unfold acceptContextRoot at success
  split at success
  · cases success
  · rename_i inside
    have inContext : outOfContext policy publications selectedPoint = false := by
      simpa using inside
    have facts := inContext
    simp only [outOfContext, success, Bool.or_eq_false_iff, decide_eq_false_iff_not,
      not_not] at facts
    exact ⟨success, inContext, facts.1, facts.2⟩

theorem accept_in_context (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (claim : Claim)
    (success : accept policy publications selectedPoint provider builder = .ok claim) :
    claim.point.network = policy.context.network ∧
      claim.ledgerRoot.scheme ∈ policy.context.schemes := by
  unfold accept at success
  split at success
  · cases success
  · rename_i root rooted
    obtain ⟨_, _, network, scheme⟩ :=
      acceptContextRoot_in_context policy publications selectedPoint root rooted
    -- Every later step keeps the selected point and the root bound in context.
    split at success
    · cases success
    · split at success
      · cases success
      · split at success
        · cases success
        · cases success
          exact ⟨network, scheme⟩

-- The guard precedes acquisition: an out-of-context selection reads no provider or builder.
theorem out_of_context_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder)
    (outside : outOfContext policy publications selectedPoint = true) :
    accept policy publications selectedPoint provider builder =
      .error (.evidenceFailure selectedPoint) := by
  have rooted : acceptContextRoot policy publications selectedPoint =
      .error (.evidenceFailure selectedPoint) := by
    simp [acceptContextRoot, outside]
  simp [accept, rooted]

-- With a verifier, out of context is refused before any declared absence.
theorem out_of_context_never_unverified (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder)
    (configured : policy.verifier = true)
    (outside : outOfContext policy publications selectedPoint = true) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) := by
  have refused := out_of_context_refused policy publications selectedPoint provider builder outside
  simp [verdict, configured, refused, outside]

theorem wrong_network_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder)
    (configured : policy.verifier = true)
    (other : selectedPoint.network ≠ policy.context.network) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) := by
  have outside : outOfContext policy publications selectedPoint = true := by
    simp [outOfContext, other]
  exact out_of_context_never_unverified policy publications selectedPoint provider builder
    configured outside

theorem unaccepted_scheme_refused (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder)
    (configured : policy.verifier = true) (root : Root)
    (rootAccepted : acceptRoot policy publications selectedPoint = .ok root)
    (unaccepted : root.scheme ∉ policy.context.schemes) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) := by
  have outside : outOfContext policy publications selectedPoint = true := by
    simp [outOfContext, rootAccepted, unaccepted]
  exact out_of_context_never_unverified policy publications selectedPoint provider builder
    configured outside

-- selectRoot without a candidate among the roots refuses with noRoot.
theorem selectRoot_no_candidate (policy : Policy) (keysFor : Root → List Key)
    (point : Chainpoint) (roots : List Root)
    (rejected : ∀ root ∈ roots, ¬ Candidate policy (keysFor root)) :
    selectRoot policy keysFor point roots = .error (.noRoot point) := by
  induction roots with
  | nil => rfl
  | cons root rest ih =>
    simp only [selectRoot]
    rw [if_neg (rejected root (List.mem_cons_self ..))]
    exact ih fun other member => rejected other (List.mem_cons_of_mem _ member)

-- Appended roots that already occur, or are not candidates, never change the selection.
theorem selectRoot_append_ignored (policy : Policy) (keysFor : Root → List Key)
    (point : Chainpoint) (first rest : List Root)
    (ignored : ∀ root ∈ rest, root ∈ first ∨ ¬ Candidate policy (keysFor root)) :
    selectRoot policy keysFor point (first ++ rest) = selectRoot policy keysFor point first := by
  induction first with
  | nil =>
    exact selectRoot_no_candidate policy keysFor point rest fun root member =>
      (ignored root member).resolve_left (by simp)
  | cons root first ih =>
    simp only [List.cons_append, selectRoot]
    by_cases candidate : Candidate policy (keysFor root)
    · rw [if_pos candidate, if_pos candidate]
    · rw [if_neg candidate, if_neg candidate]
      apply ih
      intro other member
      rcases ignored other member with earlier | rejected
      · rcases List.mem_cons.mp earlier with same | later
        · subst same
          exact Or.inr candidate
        · exact Or.inl later
      · exact Or.inr rejected

-- Publications whose point is not the selected point endorse nothing at it.
theorem endorsingKeys_append_unmatched (policy : Policy) (publications others : List Publication)
    (point : Chainpoint) (unmatched : ∀ other ∈ others, other.point ≠ point) :
    endorsingKeys policy (publications ++ others) point = endorsingKeys policy publications point := by
  funext root
  have none : List.filter (fun publication : Publication =>
      decide (publication.point = point ∧ publication.root = root) && policy.verify publication)
      others = [] := by
    rw [List.filter_eq_nil_iff]
    intro other member
    simp [unmatched other member]
  simp only [endorsingKeys, observedKeys, List.filter_append, none, List.append_nil]

-- Appending publications whose point is not the selected point leaves root acceptance unchanged.
theorem acceptRoot_append_unmatched (policy : Policy) (publications others : List Publication)
    (point : Chainpoint) (unmatched : ∀ other ∈ others, other.point ≠ point) :
    acceptRoot policy (publications ++ others) point = acceptRoot policy publications point := by
  unfold acceptRoot
  rw [endorsingKeys_append_unmatched policy publications others point unmatched, List.map_append]
  apply selectRoot_append_ignored
  intro root _
  by_cases endorsed : root ∈ publications.map Publication.root
  · exact Or.inl endorsed
  · -- No offered publication carries this root, so no key endorses it.
    have unendorsed : List.filter (fun publication : Publication =>
        decide (publication.point = point ∧ publication.root = root) && policy.verify publication)
        publications = [] := by
      rw [List.filter_eq_nil_iff]
      intro publication member matched
      simp only [Bool.and_eq_true, decide_eq_true_eq] at matched
      exact endorsed (List.mem_map.mpr ⟨publication, member, matched.1.2⟩)
    have empty : endorsingKeys policy publications point root = [] := by
      simp only [endorsingKeys, observedKeys, unendorsed, List.map_nil, List.eraseDups_nil,
        List.filter_nil]
    exact Or.inr fun candidate => candidate.1 empty

-- Untrusted input from another network cannot veto a selection, nor change its outcome.
theorem foreign_publication_ignored (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder)
    (others : List Publication)
    (foreign : ∀ other ∈ others, other.point.network ≠ policy.context.network) :
    acceptContextRoot policy (publications ++ others) selectedPoint =
        acceptContextRoot policy publications selectedPoint ∧
      accept policy (publications ++ others) selectedPoint provider builder =
        accept policy publications selectedPoint provider builder ∧
      verdict policy (publications ++ others) selectedPoint provider builder =
        verdict policy publications selectedPoint provider builder := by
  have same : outOfContext policy (publications ++ others) selectedPoint =
        outOfContext policy publications selectedPoint ∧
      acceptContextRoot policy (publications ++ others) selectedPoint =
        acceptContextRoot policy publications selectedPoint := by
    by_cases network : selectedPoint.network = policy.context.network
    · -- In context, a foreign publication's point is not the selected point.
      have unmatched : ∀ other ∈ others, other.point ≠ selectedPoint := by
        intro other member samePoint
        exact foreign other member (by rw [samePoint]; exact network)
      have sameRoot := acceptRoot_append_unmatched policy publications others selectedPoint unmatched
      have sameOutside : outOfContext policy (publications ++ others) selectedPoint =
          outOfContext policy publications selectedPoint := by
        simp only [outOfContext, sameRoot]
      exact ⟨sameOutside, by unfold acceptContextRoot; rw [sameOutside, sameRoot]⟩
    · -- On another network, both selections are out of context whatever was fetched.
      constructor <;> simp [acceptContextRoot, outOfContext, network]
  have sameAccept : accept policy (publications ++ others) selectedPoint provider builder =
      accept policy publications selectedPoint provider builder := by
    simp only [accept, same.2]
  exact ⟨same.2, sameAccept, by simp only [verdict, sameAccept, same.1]⟩

-- Proof route: verified implies accept's claim, its root accepted in context (the guard is read
-- here, not through a lemma), acceptRoot_valid under ObservationSound, then both MessageBinding
-- conjuncts for the exact encoding.
theorem verdict_context_sound [SignatureModel] [MessageModel] : ContextSoundness verdict := by
  intro policy publications selectedPoint provider builder claim observationSound binding verified
  obtain ⟨_, accepted⟩ :=
    (verdict_verified_iff policy publications selectedPoint provider builder claim).mp verified
  obtain ⟨root, _, _, _, _, rootAccepted, _, _, _, rfl⟩ :=
    accept_observations policy publications selectedPoint provider builder claim accepted
  have inContext : outOfContext policy publications selectedPoint = false := by
    cases outside : outOfContext policy publications selectedPoint with
    | false => rfl
    | true =>
      rw [out_of_context_refused policy publications selectedPoint provider builder outside]
        at accepted
      cases accepted
  simp only [outOfContext, rootAccepted, Bool.or_eq_false_iff, decide_eq_false_iff_not,
    not_not] at inContext
  obtain ⟨network, scheme⟩ := inContext
  obtain ⟨keys, candidate, endorsed⟩ :=
    acceptRoot_valid policy publications selectedPoint root rootAccepted observationSound
  have bound := binding
  unfold MessageBinding at bound
  obtain ⟨encodesOwn, encodesOne⟩ := bound
  unfold ContextConclusion
  refine ⟨network, scheme, keys, candidate, ?_⟩
  intro key member
  obtain ⟨trusted, publication, inList, keyEq, pointEq, rootEq, valid⟩ := endorsed key member
  refine ⟨trusted, publication, inList, keyEq, pointEq, rootEq, valid, ?_⟩
  have encoded := encodesOwn publication valid
  rw [pointEq, rootEq] at encoded
  intro point other
  constructor
  · intro encodedOther
    exact encodesOne _ _ _ _ _ encodedOther encoded
  · rintro ⟨rfl, rfl⟩
    exact encoded

end Lockness

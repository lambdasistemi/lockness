import Lockness.Counterexamples.Fixtures

namespace Lockness.Counterexamples

-- Works for any acceptor, including a compiled copy of the production mutation.
theorem emptyTrust_refutes_safety
    (accept : Policy → List Publication → Chainpoint → Except Refusal Root)
    (accepted : accept untrustedPolicy [untrustedPublication] point = .ok root) :
    ¬ RootSafety accept := by
  intro safety
  obtain ⟨keys, candidate, witnesses⟩ := safety untrustedPolicy [untrustedPublication] point root accepted
  rcases keys with _ | ⟨key, rest⟩
  · exact candidate.1 rfl
  · have trusted := (witnesses key (by simp)).1
    simp [untrustedPolicy] at trusted

end Lockness.Counterexamples

import Lockness.RootProofs
import Lockness.Counterexamples.TrustRefutation

namespace Lockness.Counterexamples

-- Validity is an arbitrary, inhabited hypothesis. No global SignatureModel instance.
theorem valid_untrusted_signature : @SigValid ⟨fun _ => True⟩ untrustedPublication := trivial

theorem valid_untrusted_refused [SignatureModel] (_valid : SigValid untrustedPublication) :
    acceptRoot untrustedPolicy [untrustedPublication] point = .error (.noRoot point) := by decide

-- Refutation of the unchanged universal guarantee, not just a failed proof tactic.
theorem subsetMutation_refutes_safety : ¬ RootSafety acceptRootWithoutSubsetCheck := by
  exact emptyTrust_refutes_safety acceptRootWithoutSubsetCheck (by decide)

-- Honest endorsement does not establish the ledger root without correspondence.
theorem endorsement_alone_not_honest :
    ∃ (policy : Policy) (publications : List Publication) (point : Chainpoint)
      (root : Root) (honestRoot : Chainpoint → Root),
      acceptRoot policy publications point = .ok root ∧ root ≠ honestRoot point := by
  exact ⟨honestPolicy, [honestPublication], point, root, fun _ => ⟨[99], [99]⟩,
    by decide, by decide⟩

end Lockness.Counterexamples

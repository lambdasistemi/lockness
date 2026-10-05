import Lockness.Counterexamples.ContextFixtures

namespace Lockness.Counterexamples.ContextExamples
open AppExamples VerdictExamples

-- Only refutations live here: this module is rebuilt against every context mutant, so it asserts
-- no concrete verdict or accept outcome that a mutant changes. The unbound-message offer is in
-- context, so no context mutant changes its verdict.

-- Parameterized by the compiled mutant without the network guard: the terminal configured for
-- network [1] verifies the honest root endorsed on network [0].
theorem guard_removed_refutes_context_soundness
    (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict)
    (accepted : operation wrongNetworkPolicy publications selected verifiedProvider builder =
      .verified oneLinkClaim) :
    ¬ @ContextSoundness honestSignatures fixtureMessages operation := by
  intro sound
  unfold ContextSoundness at sound
  -- Applied premise by premise, so the module also compiles against the binding-dropped mutant.
  have conclusion : @ContextConclusion honestSignatures fixtureMessages wrongNetworkPolicy
      publications oneLinkClaim := by
    apply sound <;> first
      | exact contextPolicy_observation_sound _ | exact fixture_message_binding | exact accepted
  unfold ContextConclusion at conclusion
  -- The claim's point is on network [0]; the terminal is configured for network [1].
  exact absurd conclusion.1 (by decide)

-- Parameterized by the compiled mutant without the scheme guard: scheme [0] verified under a
-- context accepting only scheme [1].
theorem scheme_unchecked_refutes_context_soundness
    (operation : Policy → List Publication → Chainpoint → Provider → Builder → Verdict)
    (accepted : operation unacceptedSchemePolicy publications selected verifiedProvider builder =
      .verified oneLinkClaim) :
    ¬ @ContextSoundness honestSignatures fixtureMessages operation := by
  intro sound
  unfold ContextSoundness at sound
  have conclusion : @ContextConclusion honestSignatures fixtureMessages unacceptedSchemePolicy
      publications oneLinkClaim := by
    apply sound <;> first
      | exact contextPolicy_observation_sound _ | exact fixture_message_binding | exact accepted
  unfold ContextConclusion at conclusion
  exact absurd conclusion.2.1 (by decide)

-- Without MessageBinding, context soundness is false on the real verdict: valid signatures over
-- messages naming network [1] endorse the selected point on network [0].
theorem unbound_message_refutes
    (sound : ∀ policy publications selectedPoint provider builder claim,
      @ObservationSound signatureOnly policy →
      verdict policy publications selectedPoint provider builder = .verified claim →
      @ContextConclusion signatureOnly fixtureMessages policy publications claim) : False := by
  have conclusion := sound signatureOnlyPolicy unboundMessagePublications selected verifiedProvider
    builder oneLinkClaim signatureOnly_observation_sound (by decide)
  unfold ContextConclusion at conclusion
  obtain ⟨_, _, keys, ⟨nonempty, _, _⟩, endorsed⟩ := conclusion
  cases keys with
  | nil => exact nonempty rfl
  | cons key rest =>
    obtain ⟨_, publication, member, _, _, _, _, encodes⟩ := endorsed key (List.mem_cons_self ..)
    -- Every offered publication is signed over the message naming network [1].
    have message : publication.message = foreignMessage := by
      simp only [unboundMessagePublications, publications, List.map_cons, List.map_nil,
        List.mem_cons, List.not_mem_nil, or_false] at member
      rcases member with rfl | rfl <;> rfl
    have decoded : decodeMessage publication.message = some (foreignPoint, honestPublication.root) := by
      rw [message]
      decide
    have named := (encodes foreignPoint honestPublication.root).mp decoded
    exact absurd named.1 (by decide)

end Lockness.Counterexamples.ContextExamples

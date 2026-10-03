import Lockness.Counterexamples.SubsetMutation

namespace Lockness.Tests
open Counterexamples

-- Runtime observations are arbitrary; these examples make no cryptographic claim.
example : acceptRoot honestPolicy [honestPublication] point = .ok root := by decide
example : acceptRoot untrustedPolicy [untrustedPublication] point =
    .error (.noRoot point) := by decide
example : acceptRoot honestPolicy [] point = .error (.noRoot point) := by decide
example : acceptRoot { honestPolicy with agreement := fun _ => true } [] point =
    .error (.noRoot point) := by decide
example : acceptRoot { untrustedPolicy with agreement := fun _ => true }
    [untrustedPublication] point = .error (.noRoot point) := by decide
example : acceptRoot { honestPolicy with verify := fun _ => false }
    [honestPublication] point = .error (.noRoot point) := by decide
example : acceptRoot honestPolicy
    [{ honestPublication with point := { point with slot := point.slot + 1 } }] point =
    .error (.noRoot point) := by decide
example : acceptRoot honestPolicy
    [{ honestPublication with point := { point with network := [99] } }] point =
    .error (.noRoot point) := by decide
example : acceptRoot honestPolicy
    [{ honestPublication with point := { point with blockHash := [99] } }] point =
    .error (.noRoot point) := by decide
example : acceptRoot { honestPolicy with agreement := fun keys => keys.length >= 2 }
    [honestPublication, honestPublication] point = .error (.noRoot point) := by decide
example : acceptRoot twoKeyPolicy [honestPublication, secondPublication] point =
    .ok root := by decide
example : acceptRoot twoKeyPolicy
    [honestPublication, { secondPublication with root := { root with scheme := [99] } }]
    point = .error (.noRoot point) := by decide
example : acceptRoot twoKeyPolicy
    [honestPublication, { secondPublication with root := { root with bytes := [99] } }]
    point = .error (.noRoot point) := by decide
example : acceptRoot honestPolicy
    [untrustedPublication, honestPublication] point = .ok root := by decide
-- Exact sequence equality includes zero bytes, byte order and length.
example : (show Bytes from [0, 255, 0]) ≠ [255, 0] := by decide
example : (show Bytes from [0, 255, 0]) ≠ [0, 0, 255] := by decide
example : ({ honestPublication with signature := [0, 255, 0] }).signature =
    [0, 255, 0] := rfl
example : ({ honestPublication with message := [0, 255, 0] }).message =
    [0, 255, 0] := rfl
example : (Refusal.unavailablePoint point).selectedPoint = point := rfl
example : (Refusal.evidenceFailure point).selectedPoint = point := rfl
example : (Refusal.noRoot point).selectedPoint = point := rfl
example : RootSafety acceptRoot := acceptRoot_safe
example : ¬ RootSafety acceptRootWithoutSubsetCheck := subsetMutation_refutes_safety
example : @SigValid ⟨fun _ => True⟩ untrustedPublication := valid_untrusted_signature

-- Reachable hypotheses for the general validity and correspondence statements.
example : @ObservationSound ⟨fun _ => True⟩ honestPolicy := by
  intro _ _
  trivial
example : TrustedEndorsement twoKeyPolicy [honestPublication, secondPublication] point root :=
  acceptRoot_safe _ _ _ _ (by decide)
example : HonestRootCorrespondence honestPolicy [honestPublication] (fun _ => root) := by
  intro selected accepted endorsement
  obtain ⟨keys, candidate, witnesses⟩ := endorsement
  cases keys with
  | nil => exact False.elim (candidate.1 rfl)
  | cons key rest =>
    obtain ⟨_, publication, member, _, _, binding, _⟩ := witnesses key (by simp)
    simp only [List.mem_singleton] at member
    subst publication
    exact binding.symm

end Lockness.Tests

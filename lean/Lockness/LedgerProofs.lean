import Lockness.Ledger

namespace Lockness

-- Inversion records the same decoded output and bytes at every observation boundary.
theorem verifyLedger_observations (policy : Policy) (acceptedRoot : Root) (session : Session)
    (answer : LedgerAnswer) (appRoot : Root)
    (success : verifyLedger policy acceptedRoot session answer = .ok appRoot) :
    answer.point = session.selectedPoint ∧
    ∃ entry datum, policy.decodeObject answer.object = some entry ∧
      policy.objectBytes entry = answer.object ∧
      policy.checkWitness answer.witness acceptedRoot answer.object = true ∧
      policy.assetOf entry.2 = some policy.asset ∧
      policy.datumOf entry.2 = some datum ∧
      policy.parseDatum policy.schema datum = some appRoot := by
  unfold verifyLedger at success
  split at success
  · rename_i pointEq
    split at success
    · cases success
    · rename_i entry decoded
      split at success
      · rename_i binding
        split at success
        · rename_i witness
          split at success
          · rename_i asset
            split at success
            · cases success
            · rename_i datum observed
              split at success
              · cases success
              · rename_i root parsed
                cases success
                exact ⟨pointEq, entry, datum, decoded, binding, witness, asset, observed, parsed⟩
          · cases success
        · cases success
      · cases success
  · cases success

theorem verifyLedger_sound : LedgerSoundness verifyLedger := by
  intro policy ledger honestRoot carries honestDatumRoot acceptedRoot session answer appRoot
    witnessSound _encodingFaithful assetSound datumSound oneShot correspondence accepted
  obtain ⟨_, entry, datum, _decoded, binding, witness, asset, observed, parsed⟩ :=
    verifyLedger_observations policy acceptedRoot session answer appRoot accepted
  have checked : checks policy answer.witness acceptedRoot entry := by
    simpa [checks, binding] using witness
  have member := witnessSound session.selectedPoint answer.witness acceptedRoot entry
    correspondence checked
  have actualAsset := assetSound entry.2 policy.asset asset
  refine ⟨entry, member, actualAsset, datumSound _ _ _ _ observed parsed, ?_⟩
  intro other otherMember otherAsset
  exact oneShot session.selectedPoint other otherMember otherAsset entry member actualAsset

theorem verifyLedger_refusal (policy : Policy) (acceptedRoot : Root) (session : Session)
    (answer : LedgerAnswer) (refusal : Refusal)
    (failure : verifyLedger policy acceptedRoot session answer = .error refusal) :
    refusal = .evidenceFailure session.selectedPoint := by
  unfold verifyLedger at failure
  split at failure
  · split at failure
    · cases failure; rfl
    · split at failure
      · split at failure
        · split at failure
          · split at failure
            · cases failure; rfl
            · split at failure
              · cases failure; rfl
              · cases failure
          · cases failure; rfl
        · cases failure; rfl
      · cases failure; rfl
  · cases failure; rfl

end Lockness

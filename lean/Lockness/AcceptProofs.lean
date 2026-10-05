import Lockness.Accept
import Lockness.AppProofs
import Lockness.RootProofs
import Lockness.LedgerProofs

namespace Lockness

-- Inversion: every accepted claim records the four steps and the roots they bound.
theorem accept_observations (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (claim : Claim)
    (success : accept policy publications selectedPoint provider builder = .ok claim) :
    ∃ root session appRoot links value,
      acceptRoot policy publications selectedPoint = .ok root ∧
      acquire selectedPoint provider = .ok session ∧
      verifyLedger policy root session session.ledger = .ok appRoot ∧
      verifyChain policy selectedPoint builder policy.fuel appRoot = .ok (links, value) ∧
      claim = ⟨selectedPoint, root, policy.query, appRoot, links, value⟩ := by
  unfold accept at success
  split at success
  · cases success
  · rename_i root inContext
    -- Root acceptance in context returns acceptRoot's own root.
    have accepted : acceptRoot policy publications selectedPoint = .ok root := by
      unfold acceptContextRoot at inContext
      split at inContext
      · cases inContext
      · exact inContext
    split at success
    · cases success
    · rename_i session acquired
      split at success
      · cases success
      · rename_i appRoot verified
        split at success
        · cases success
        · rename_i links value chain
          cases success
          exact ⟨root, session, appRoot, links, value, accepted, acquired, verified, chain, rfl⟩

-- Every branch: root, acquisition, ledger and application refusals keep the selected point.
theorem accept_refusal_cases (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (refusal : Refusal)
    (failure : accept policy publications selectedPoint provider builder = .error refusal) :
    refusal = .noRoot selectedPoint ∨ refusal = .unavailablePoint selectedPoint ∨
      refusal = .evidenceFailure selectedPoint := by
  unfold accept at failure
  split at failure
  · rename_i rejected
    cases failure
    -- The context guard refuses with evidenceFailure; acceptRoot only with noRoot.
    unfold acceptContextRoot at rejected
    split at rejected
    · cases rejected
      exact Or.inr (Or.inr rfl)
    · exact Or.inl (acceptRoot_refusal policy publications selectedPoint _ rejected)
  · split at failure
    · rename_i unavailable
      cases failure
      exact Or.inr (Or.inl (acquire_refusal selectedPoint provider _ unavailable))
    · rename_i session acquired
      split at failure
      · rename_i rejected
        cases failure
        have samePoint : session.selectedPoint = selectedPoint :=
          acquire_no_substitution selectedPoint provider session acquired
        rw [verifyLedger_refusal policy _ session session.ledger _ rejected, samePoint]
        exact Or.inr (Or.inr rfl)
      · split at failure
        · rename_i rejected
          cases failure
          exact Or.inr (Or.inr (verifyChain_refusal policy selectedPoint builder policy.fuel _ _
            rejected))
        · cases failure

theorem accept_refusal (policy : Policy) (publications : List Publication)
    (selectedPoint : Chainpoint) (provider : Provider) (builder : Builder) (refusal : Refusal)
    (failure : accept policy publications selectedPoint provider builder = .error refusal) :
    refusal.selectedPoint = selectedPoint := by
  rcases accept_refusal_cases policy publications selectedPoint provider builder refusal failure with
    same | same | same <;> rw [same] <;> rfl

theorem accept_sound : AcceptSoundness accept := by
  intro policy publications selectedPoint provider builder claim ledger honestRoot carries
    honestDatumRoot tree honestNext correspondence witnessSound encodingFaithful assetSound
    datumSound oneShot appSound nesting accepted
  obtain ⟨root, session, appRoot, links, value, rootAccepted, acquired, verified, chain, rfl⟩ :=
    accept_observations policy publications selectedPoint provider builder claim accepted
  have honest : root = honestRoot selectedPoint :=
    acceptRoot_honest policy publications selectedPoint root honestRoot rootAccepted correspondence
  have samePoint : session.selectedPoint = selectedPoint :=
    acquire_no_substitution selectedPoint provider session acquired
  obtain ⟨entry, member, carried, datum, unique⟩ := verifyLedger_sound policy ledger honestRoot
    carries honestDatumRoot root session session.ledger appRoot witnessSound encodingFaithful
    assetSound datumSound oneShot (honest.trans (congrArg honestRoot samePoint.symm)) verified
  rw [samePoint] at member unique
  refine ⟨rfl, honest, ?_⟩
  unfold holds
  exact ⟨rfl, entry, member, carried, unique, datum,
    verifyChain_holds policy selectedPoint builder tree honestNext appSound nesting policy.fuel
      appRoot links value chain⟩

theorem accept_provider_invariant : ProviderInvariance accept := by
  intro policy publications selectedPoint provider₁ provider₂ builder₁ builder₂ claim₁ claim₂
    ledger honestRoot carries honestDatumRoot tree correspondence witnessSound encodingFaithful
    assetSound datumSound oneShot appSound functional accepted₁ accepted₂
  obtain ⟨root₁, session₁, appRoot₁, links₁, value₁, rootAccepted₁, acquired₁, verified₁, chain₁,
    rfl⟩ := accept_observations policy publications selectedPoint provider₁ builder₁ claim₁ accepted₁
  obtain ⟨root₂, session₂, appRoot₂, links₂, value₂, rootAccepted₂, acquired₂, verified₂, chain₂,
    rfl⟩ := accept_observations policy publications selectedPoint provider₂ builder₂ claim₂ accepted₂
  -- Root acceptance reads no provider or builder, so both folds bind the same root.
  have sameRoot : root₁ = root₂ := Except.ok.inj (rootAccepted₁.symm.trans rootAccepted₂)
  have honest₁ := acceptRoot_honest policy publications selectedPoint root₁ honestRoot
    rootAccepted₁ correspondence
  have honest₂ := acceptRoot_honest policy publications selectedPoint root₂ honestRoot
    rootAccepted₂ correspondence
  have point₁ : session₁.selectedPoint = selectedPoint :=
    acquire_no_substitution selectedPoint provider₁ session₁ acquired₁
  have point₂ : session₂.selectedPoint = selectedPoint :=
    acquire_no_substitution selectedPoint provider₂ session₂ acquired₂
  obtain ⟨entry₁, _, _, datum₁, unique₁⟩ := verifyLedger_sound policy ledger honestRoot carries
    honestDatumRoot root₁ session₁ session₁.ledger appRoot₁ witnessSound encodingFaithful
    assetSound datumSound oneShot (honest₁.trans (congrArg honestRoot point₁.symm)) verified₁
  obtain ⟨entry₂, member₂, carried₂, datum₂, _⟩ := verifyLedger_sound policy ledger honestRoot
    carries honestDatumRoot root₂ session₂ session₂.ledger appRoot₂ witnessSound encodingFaithful
    assetSound datumSound oneShot (honest₂.trans (congrArg honestRoot point₂.symm)) verified₂
  rw [point₁] at unique₁
  rw [point₂] at member₂
  have sameEntry : entry₂ = entry₁ := unique₁ entry₂ member₂ carried₂
  rw [sameEntry, datum₁] at datum₂
  have sameApp : appRoot₁ = appRoot₂ := Option.some.inj datum₂
  rw [← sameApp] at chain₂
  obtain ⟨sameLinks, sameValue⟩ := verifyChain_functional policy selectedPoint builder₁ builder₂
    tree appSound functional policy.fuel appRoot₁ links₁ links₂ value₁ value₂ chain₁ chain₂
  rw [sameRoot, sameApp, sameLinks, sameValue]

end Lockness

import Lockness.CompletenessProofs
import Lockness.Counterexamples.CompletenessRefutation

namespace Lockness.Tests.Completeness
open Counterexamples Counterexamples.AppExamples Counterexamples.LedgerExamples
open Counterexamples.VerdictExamples Counterexamples.CompletenessExamples

-- Released declarations and signatures.
example (keyPrefix : Bytes) (entries : List Bytes) (proof : Bytes) : CompletenessAnswer :=
  ⟨keyPrefix, entries, proof⟩
example (answer : CompletenessAnswer) : Bytes × List Bytes × Bytes :=
  (answer.keyPrefix, answer.entries, answer.proof)
example (answer : LedgerAnswer) : Option CompletenessAnswer := answer.completeness
example (policy : Policy) : Bytes → Root → Bytes → List Bytes → Bool := policy.checkCompleteness
example (policy : Policy) : Asset → Bytes := policy.assetPrefix
example (policy : Policy) : Bool := policy.requireCompleteness
example : IndexKey = Bytes := rfl
example : KeyLayout = ((TxIn × TxOut) → Set IndexKey) := rfl
example (point : Chainpoint) (ledgerRoot : Root) (keyPrefix : Bytes)
    (entries : List (TxIn × TxOut)) : EntriesClaim := ⟨point, ledgerRoot, keyPrefix, entries⟩
example : Policy → Root → Session → Bytes → Except Refusal (List (TxIn × TxOut)) := verifyEntries
example : Policy → List Publication → Chainpoint → Bytes → Provider → Except Refusal EntriesClaim :=
  acceptEntries

-- Ruled definitions, ascribed in full so that any change to one fails here.
example (layout : KeyLayout) (keyPrefix : Bytes) (entry : TxIn × TxOut) :
    UnderPrefix layout keyPrefix entry ↔ ∃ key ∈ layout entry, keyPrefix <+: key := Iff.rfl
example (policy : Policy) (ledger : Ledger) (honestRoot : Chainpoint → Root) (layout : KeyLayout) :
    CompletenessSound policy ledger honestRoot layout ↔
      ∀ p proof root keyPrefix listed, root = honestRoot p →
        policy.checkCompleteness proof root keyPrefix listed = true →
        ∀ bytes, bytes ∈ listed ↔
          ∃ entry ∈ ledger p, UnderPrefix layout keyPrefix entry ∧ policy.objectBytes entry = bytes :=
  Iff.rfl
example (policy : Policy) (carries : TxOut → Asset → Prop) (layout : KeyLayout) :
    AssetKeyLayout policy carries layout ↔
      ∀ entry, carries entry.2 policy.asset →
        UnderPrefix layout (policy.assetPrefix policy.asset) entry := Iff.rfl
example (operation : Policy → List Publication → Chainpoint → Bytes → Provider →
      Except Refusal EntriesClaim) :
    EntriesSoundness operation ↔
      ∀ policy publications selectedPoint keyPrefix provider claim (ledger : Ledger) honestRoot
        layout,
        HonestRootCorrespondence policy publications honestRoot →
        CompletenessSound policy ledger honestRoot layout → ObjectEncodingFaithful policy →
        operation policy publications selectedPoint keyPrefix provider = .ok claim →
        claim.point = selectedPoint ∧ claim.ledgerRoot = honestRoot selectedPoint ∧
          claim.keyPrefix = keyPrefix ∧
          ∀ entry, entry ∈ claim.entries ↔
            entry ∈ ledger selectedPoint ∧ UnderPrefix layout keyPrefix entry := Iff.rfl
example (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root) :
    CompleteLedgerSoundness operation ↔
      ∀ policy ledger honestRoot carries honestDatumRoot layout acceptedRoot session answer appRoot
        completeness,
        ObjectEncodingFaithful policy → AssetObservationSound policy carries →
        DatumObservationSound policy honestDatumRoot →
        CompletenessSound policy ledger honestRoot layout →
        AssetKeyLayout policy carries layout → acceptedRoot = honestRoot session.selectedPoint →
        answer.completeness = some completeness →
        operation policy acceptedRoot session answer = .ok appRoot →
        ∃ entry : TxIn × TxOut,
          entry ∈ ledger session.selectedPoint ∧ carries entry.2 policy.asset ∧
          honestDatumRoot policy.schema entry.2 = some appRoot ∧
          ∀ other ∈ ledger session.selectedPoint, carries other.2 policy.asset → other = entry :=
  Iff.rfl
example (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root) :
    RequiredCompleteLedgerSoundness operation ↔
      ∀ policy ledger honestRoot carries honestDatumRoot layout acceptedRoot session answer appRoot,
        ObjectEncodingFaithful policy → AssetObservationSound policy carries →
        DatumObservationSound policy honestDatumRoot →
        CompletenessSound policy ledger honestRoot layout →
        AssetKeyLayout policy carries layout → acceptedRoot = honestRoot session.selectedPoint →
        policy.requireCompleteness = true →
        operation policy acceptedRoot session answer = .ok appRoot →
        ∃ entry : TxIn × TxOut,
          entry ∈ ledger session.selectedPoint ∧ carries entry.2 policy.asset ∧
          honestDatumRoot policy.schema entry.2 = some appRoot ∧
          ∀ other ∈ ledger session.selectedPoint, carries other.2 policy.asset → other = entry :=
  Iff.rfl

-- The guard order of verifyEntries and the classification change, ascribed in full.
example (policy : Policy) (acceptedRoot : Root) (session : Session) (keyPrefix : Bytes) :
    verifyEntries policy acceptedRoot session keyPrefix =
      if session.ledger.point = session.selectedPoint then
        if session.binding = .bound session.selectedPoint then
          match session.ledger.completeness with
          | none => .error (.evidenceFailure session.selectedPoint)
          | some answer =>
            if answer.keyPrefix = keyPrefix then
              if policy.checkCompleteness answer.proof acceptedRoot keyPrefix answer.entries = true
              then
                match answer.entries.mapM policy.decodeObject with
                | none => .error (.evidenceFailure session.selectedPoint)
                | some decoded =>
                  if decoded.map policy.objectBytes = answer.entries then .ok decoded
                  else .error (.evidenceFailure session.selectedPoint)
              else .error (.evidenceFailure session.selectedPoint)
            else .error (.evidenceFailure session.selectedPoint)
        else .error (.evidenceFailure session.selectedPoint)
      else .error (.evidenceFailure session.selectedPoint) := rfl
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (keyPrefix : Bytes) (provider : Provider) :
    acceptEntries policy publications selectedPoint keyPrefix provider =
      match acceptContextRoot policy publications selectedPoint with
      | .error refusal => .error refusal
      | .ok root =>
        match acquire selectedPoint provider with
        | .error refusal => .error refusal
        | .ok session =>
          match verifyEntries policy root session keyPrefix with
          | .error refusal => .error refusal
          | .ok entries => .ok ⟨selectedPoint, root, keyPrefix, entries⟩ := rfl
example (selectedPoint : Chainpoint) (provider : Provider) :
    unverifiedReason selectedPoint provider =
      match acquire selectedPoint provider with
      | .error _ => none
      | .ok session =>
        if session.binding = .unbound then some .unboundSession
        else if session.binding = .bound selectedPoint then
          if session.ledger.witness = none then
            if session.ledger.completeness = none then some .noWitness else none
          else none
        else none := rfl

-- Ruled statements, ascribed in full and bound to their theorem names.
example (policy : Policy) (acceptedRoot : Root) (session : Session) (keyPrefix : Bytes)
    (decoded : List (TxIn × TxOut))
    (success : verifyEntries policy acceptedRoot session keyPrefix = .ok decoded) :
    session.ledger.point = session.selectedPoint ∧
    session.binding = .bound session.selectedPoint ∧
    ∃ answer, session.ledger.completeness = some answer ∧ answer.keyPrefix = keyPrefix ∧
      policy.checkCompleteness answer.proof acceptedRoot keyPrefix answer.entries = true ∧
      answer.entries.mapM policy.decodeObject = some decoded ∧
      decoded.map policy.objectBytes = answer.entries :=
  verifyEntries_observations policy acceptedRoot session keyPrefix decoded success
example (policy : Policy) (acceptedRoot : Root) (session : Session) (keyPrefix : Bytes)
    (refusal : Refusal)
    (failure : verifyEntries policy acceptedRoot session keyPrefix = .error refusal) :
    refusal = .evidenceFailure session.selectedPoint :=
  verifyEntries_refusal policy acceptedRoot session keyPrefix refusal failure
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (keyPrefix : Bytes) (provider : Provider) (claim : EntriesClaim)
    (success : acceptEntries policy publications selectedPoint keyPrefix provider = .ok claim) :
    ∃ root session, acceptRoot policy publications selectedPoint = .ok root ∧
      acquire selectedPoint provider = .ok session ∧
      verifyEntries policy root session keyPrefix = .ok claim.entries ∧
      claim = ⟨selectedPoint, root, keyPrefix, claim.entries⟩ :=
  acceptEntries_observations policy publications selectedPoint keyPrefix provider claim success
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (keyPrefix : Bytes) (provider : Provider) (refusal : Refusal)
    (failure : acceptEntries policy publications selectedPoint keyPrefix provider = .error refusal) :
    refusal.selectedPoint = selectedPoint :=
  acceptEntries_refusal policy publications selectedPoint keyPrefix provider refusal failure
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (keyPrefix : Bytes) (provider : Provider) (claim : EntriesClaim)
    (success : acceptEntries policy publications selectedPoint keyPrefix provider = .ok claim) :
    claim.point = selectedPoint :=
  acceptEntries_never_adopts policy publications selectedPoint keyPrefix provider claim success
example : EntriesSoundness acceptEntries := accept_entries_sound
example (policy : Policy) (acceptedRoot : Root) (session : Session) (answer : LedgerAnswer)
    (appRoot : Root) (completeness : CompletenessAnswer)
    (offered : answer.completeness = some completeness)
    (success : verifyLedger policy acceptedRoot session answer = .ok appRoot) :
    completeness.keyPrefix = policy.assetPrefix policy.asset ∧
    completeness.entries = [answer.object] ∧
    policy.checkCompleteness completeness.proof acceptedRoot completeness.keyPrefix
      completeness.entries = true :=
  verifyLedger_completeness policy acceptedRoot session answer appRoot completeness offered success
example (policy : Policy) (acceptedRoot : Root) (session : Session) (answer : LedgerAnswer)
    (appRoot : Root) (required : policy.requireCompleteness = true)
    (success : verifyLedger policy acceptedRoot session answer = .ok appRoot) :
    ∃ completeness, answer.completeness = some completeness :=
  verifyLedger_required policy acceptedRoot session answer appRoot required success
example : CompleteLedgerSoundness verifyLedger := verifyLedger_complete_sound
example : RequiredCompleteLedgerSoundness verifyLedger := verifyLedger_required_complete_sound
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (session : Session)
    (completeness : CompletenessAnswer) (configured : policy.verifier = true)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (bound : session.binding = .bound selectedPoint)
    (present : session.ledger.completeness = some completeness) :
    ∀ reason, verdict policy publications selectedPoint provider builder ≠ .unverified reason :=
  completeness_never_unverified policy publications selectedPoint provider builder session
    completeness configured offered samePoint bound present
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (session : Session)
    (completeness : CompletenessAnswer) (root : Root) (configured : policy.verifier = true)
    (rootAccepted : acceptContextRoot policy publications selectedPoint = .ok root)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (bound : session.binding = .bound selectedPoint)
    (present : session.ledger.completeness = some completeness)
    (wrong : ¬ (completeness.keyPrefix = policy.assetPrefix policy.asset ∧
      completeness.entries = [session.ledger.object] ∧
      policy.checkCompleteness completeness.proof root completeness.keyPrefix
        completeness.entries = true)) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) :=
  completeness_wrong_refused policy publications selectedPoint provider builder session
    completeness root configured rootAccepted offered samePoint bound present wrong
example (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (session : Session) (root : Root)
    (witness : Witness) (configured : policy.verifier = true)
    (required : policy.requireCompleteness = true)
    (rootAccepted : acceptContextRoot policy publications selectedPoint = .ok root)
    (offered : provider selectedPoint = some session)
    (samePoint : session.selectedPoint = selectedPoint)
    (bound : session.binding = .bound selectedPoint)
    (absent : session.ledger.completeness = none)
    (witnessed : session.ledger.witness = some witness) :
    verdict policy publications selectedPoint provider builder =
      .refused (.evidenceFailure selectedPoint) :=
  required_absent_refused policy publications selectedPoint provider builder session root
    witness configured required rootAccepted offered samePoint bound absent witnessed
-- The OneShot path keeps its statements.
example : LedgerSoundness verifyLedger := verifyLedger_sound
example : AcceptSoundness accept := accept_sound
example : VerdictSoundness verdict := verdict_sound

-- Refutations, ascribed in full.
example (operation : Policy → List Publication → Chainpoint → Bytes → Provider →
      Except Refusal EntriesClaim)
    (accepted : operation (completePolicy false) publications selected prefixA
      (offer (answerOf prefixA [entry₁])) = .ok ⟨selected, acceptedRoot, prefixA, [entry₁]⟩) :
    ¬ EntriesSoundness operation := omitted_refutes_entries operation accepted
example (operation : Policy → List Publication → Chainpoint → Bytes → Provider →
      Except Refusal EntriesClaim)
    (accepted : operation (completePolicy false) publications selected prefixA
      (offer (answerOf narrowPrefix [entry₁])) = .ok ⟨selected, acceptedRoot, prefixA, [entry₁]⟩) :
    ¬ EntriesSoundness operation := narrowed_refutes_entries operation accepted
example (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root)
    (accepted : operation (completePolicy true) acceptedRoot (offerVia providerRootA) omittingAnswer =
      .ok appRoot₁) :
    ¬ CompleteLedgerSoundness operation := omitted_asset_refutes operation accepted
example (operation : Policy → Root → Session → LedgerAnswer → Except Refusal Root)
    (accepted : operation (requiredPolicy true) acceptedRoot (offerVia providerRootA)
      (offerVia providerRootA).ledger = .ok appRoot₁) :
    ¬ RequiredCompleteLedgerSoundness operation := bare_required_refutes operation accepted
example : ¬ EntriesSoundnessWithoutCompleteness acceptEntries := unsound_refutes

-- Fixture contracts: the honest listings come from the ledger and the layout.
example : honestEntries false prefixA = [entry₁, entry₃] := by decide
example : honestEntries false [] = ledgerList false := by decide
example : honestEntries false absentPrefix = [] := by decide
example : honestEntries false narrowPrefix = [entry₁] := by decide
example : honestEntries false (assetKeyPrefix asset) = [entry₁] := by decide
example : honestEntries true (assetKeyPrefix asset) = [entry₁, entry₂] := by decide
example : impostor ∉ ledgerOf false selected ∧ impostor ∉ ledgerOf true selected := by decide
example : narrowPrefix ≠ prefixA := by decide
-- The provider root admits the omitting listing; the accepted root does not.
example : CompletenessExamples.checkFor false completenessProof providerRoot prefixA
    [objectBytes entry₁] = true := by decide
example : CompletenessExamples.checkFor false completenessProof acceptedRoot prefixA
    [objectBytes entry₁] = false := by decide
-- The narrower answer is a valid proof for its own prefix; only the prefix binding refuses it.
example : CompletenessExamples.checkFor false completenessProof acceptedRoot narrowPrefix
    [objectBytes entry₁] = true := by decide
-- The neutral values on the inherited fixture policy.
example : VerdictExamples.policy.checkCompleteness completenessProof acceptedRoot prefixA [] = false :=
  by decide
example : VerdictExamples.policy.assetPrefix asset = [] := by decide
example : VerdictExamples.policy.requireCompleteness = false := by decide
example : (offerVia providerRootA).ledger.completeness = none := by decide

-- All-entries acceptance on the real model.
example : acceptEntries (completePolicy false) publications selected prefixA
    (offer (answerOf prefixA [entry₁, entry₃])) =
      .ok ⟨selected, acceptedRoot, prefixA, [entry₁, entry₃]⟩ := by decide
-- Listing order is the provider's; a reordered honest listing is the same set.
example : acceptEntries (completePolicy false) publications selected prefixA
    (offer (answerOf prefixA [entry₃, entry₁])) =
      .ok ⟨selected, acceptedRoot, prefixA, [entry₃, entry₁]⟩ := by decide
example : acceptEntries (completePolicy false) publications selected prefixA
    (offer (answerOf prefixA [entry₁])) = .error (.evidenceFailure selected) := by decide
example : acceptEntries (completePolicy false) publications selected prefixA
    (offer (answerOf prefixA [entry₁, entry₃, impostor])) =
      .error (.evidenceFailure selected) := by decide
example : acceptEntries (completePolicy false) publications selected prefixA
    (offer (answerOf narrowPrefix [entry₁])) = .error (.evidenceFailure selected) := by decide
example : acceptEntries (completePolicy false) publications selected []
    (offer (answerOf [] [entry₁, entry₃, entry₄])) =
      .ok ⟨selected, acceptedRoot, [], [entry₁, entry₃, entry₄]⟩ := by decide
example : acceptEntries (completePolicy false) publications selected absentPrefix
    (offer (answerOf absentPrefix [])) = .ok ⟨selected, acceptedRoot, absentPrefix, []⟩ := by decide
example : acceptEntries (completePolicy false) publications selected prefixA
    (offer (answerOf prefixA [])) = .error (.evidenceFailure selected) := by decide
example : acceptEntries permissivePolicy publications selected prefixA
    (offer (answerOf prefixA [entry₁])) = .ok ⟨selected, acceptedRoot, prefixA, [entry₁]⟩ := by
  decide

-- Every verifyEntries guard refuses at the selected point.
example : verifyEntries (completePolicy false) acceptedRoot
    { withCompleteness (some (answerOf prefixA [entry₁, entry₃])) (offerVia providerRootA) with
      ledger := { (withCompleteness (some (answerOf prefixA [entry₁, entry₃]))
        (offerVia providerRootA)).ledger with point := otherPoint } } prefixA =
      .error (.evidenceFailure selected) := by decide
example : verifyEntries (completePolicy false) acceptedRoot
    (withCompleteness (some (answerOf prefixA [entry₁, entry₃])) unboundSession) prefixA =
      .error (.evidenceFailure selected) := by decide
example : verifyEntries (completePolicy false) acceptedRoot
    (withCompleteness (some (answerOf prefixA [entry₁, entry₃])) misboundSession) prefixA =
      .error (.evidenceFailure selected) := by decide
example : verifyEntries (completePolicy false) acceptedRoot (offerVia providerRootA) prefixA =
    .error (.evidenceFailure selected) := by decide
example : verifyEntries (completePolicy false) acceptedRoot
    (withCompleteness (some (answerOf absentPrefix [])) (offerVia providerRootA)) prefixA =
      .error (.evidenceFailure selected) := by decide
example : verifyEntries (completePolicy false) acceptedRoot
    (withCompleteness (some ⟨prefixA, [objectBytes entry₁, objectBytes entry₃], [1]⟩)
      (offerVia providerRootA)) prefixA = .error (.evidenceFailure selected) := by decide
-- Undecodable listed bytes, under a check that passes everything.
example : verifyEntries permissivePolicy acceptedRoot
    (withCompleteness (some ⟨prefixA, [[]], completenessProof⟩) (offerVia providerRootA)) prefixA =
      .error (.evidenceFailure selected) := by decide
-- Listed bytes that decode but do not re-encode to themselves.
example : verifyEntries { permissivePolicy with decodeObject := fun _ => some entry₁ } acceptedRoot
    (withCompleteness (some ⟨prefixA, [objectBytes entry₃], completenessProof⟩)
      (offerVia providerRootA)) prefixA = .error (.evidenceFailure selected) := by decide

-- Provider roots and the answer's prefix are never authority.
example : acceptEntries (completePolicy false) publications selected prefixA
    (offering (withCompleteness (some (answerOf prefixA [entry₁, entry₃])) (offerVia providerRootB))) =
      acceptEntries (completePolicy false) publications selected prefixA
        (offer (answerOf prefixA [entry₁, entry₃])) := by decide
example : verifyEntries (completePolicy false) providerRoot
    (withCompleteness (some (answerOf prefixA [entry₁])) (offerVia providerRootA)) prefixA =
      .ok [entry₁] := by decide
example : (offerVia providerRootA).acceptedRoot = providerRoot ∧
    (offerVia providerRootA).ledger.root = providerRoot := by decide

-- The state output, through the real verdict.
example : verdict (completePolicy false) publications selected
    (offer (answerOf (assetKeyPrefix asset) [entry₁])) builder = .verified oneLinkClaim := by decide
example : verdict (completePolicy true) publications selected
    (offer (answerOf (assetKeyPrefix asset) [entry₁, entry₂])) builder =
      .refused (.evidenceFailure selected) := by decide
example : verdict (completePolicy true) publications selected
    (offer (answerOf (assetKeyPrefix asset) [entry₁])) builder =
      .refused (.evidenceFailure selected) := by decide
example : verdict (completePolicy true) publications selected verifiedProvider builder =
    .verified oneLinkClaim := by decide
example : verdict (requiredPolicy true) publications selected verifiedProvider builder =
    .refused (.evidenceFailure selected) := by decide
example : verdict (requiredPolicy false) publications selected
    (offer (answerOf (assetKeyPrefix asset) [entry₁])) builder = .verified oneLinkClaim := by decide
example : verdict (completePolicy false) publications selected wrongWithoutWitness builder =
    .refused (.evidenceFailure selected) := by decide
example : verdict (completePolicy false) publications selected noWitnessProvider builder =
    .unverified .noWitness := by decide
-- A completeness answer for another prefix than the asset's is refused at the ledger step.
example : verdict (completePolicy false) publications selected
    (offer (answerOf prefixA [entry₁, entry₃])) builder = .refused (.evidenceFailure selected) := by
  decide
-- The ledger step directly, with the refutation inputs.
example : verifyLedger (completePolicy true) acceptedRoot (offerVia providerRootA) omittingAnswer =
    .error (.evidenceFailure selected) := by decide
example : verifyLedger (requiredPolicy true) acceptedRoot (offerVia providerRootA)
    (offerVia providerRootA).ledger = .error (.evidenceFailure selected) := by decide
example : verifyLedger (completePolicy true) acceptedRoot (offerVia providerRootA)
    (offerVia providerRootA).ledger = .ok appRoot₁ := by decide

-- Reachability: each theorem's premises hold together with an accepting input.
example : ∃ claim, acceptEntries (completePolicy false) publications selected prefixA
      (offer (answerOf prefixA [entry₁, entry₃])) = .ok claim ∧
    ∀ entry, entry ∈ claim.entries ↔ entry ∈ ledgerOf false selected ∧
      UnderPrefix layout prefixA entry := by
  refine ⟨⟨selected, acceptedRoot, prefixA, [entry₁, entry₃]⟩, by decide, ?_⟩
  obtain ⟨correspondence, complete, faithful, _⟩ := completeness_premises_inhabited false
  exact (accept_entries_sound (completePolicy false) publications selected prefixA
    (offer (answerOf prefixA [entry₁, entry₃])) _ (ledgerOf false) honestRoot layout correspondence
    complete faithful (by decide)).2.2.2
example : ∃ entry : TxIn × TxOut,
    entry ∈ ledgerOf false selected ∧ carries entry.2 asset ∧
    honestDatumRoot schema entry.2 = some appRoot₁ ∧
    ∀ other ∈ ledgerOf false selected, carries other.2 asset → other = entry := by
  obtain ⟨_, complete, faithful, assetSound, datumSound, layoutSound, correspondence⟩ :=
    completeness_premises_inhabited false
  exact verifyLedger_complete_sound (completePolicy false) (ledgerOf false) honestRoot carries
    honestDatumRoot layout acceptedRoot (offerVia providerRootA)
    { (offerVia providerRootA).ledger with
      completeness := some (answerOf (assetKeyPrefix asset) [entry₁]) } appRoot₁ _ faithful
    assetSound datumSound complete layoutSound correspondence rfl (by decide)
example : ∃ entry : TxIn × TxOut,
    entry ∈ ledgerOf false selected ∧ carries entry.2 asset ∧
    honestDatumRoot schema entry.2 = some appRoot₁ ∧
    ∀ other ∈ ledgerOf false selected, carries other.2 asset → other = entry := by
  obtain ⟨_, complete, faithful, assetSound, datumSound, layoutSound, required⟩ :=
    required_premises_inhabited false
  exact verifyLedger_required_complete_sound (requiredPolicy false) (ledgerOf false) honestRoot
    carries honestDatumRoot layout acceptedRoot (offerVia providerRootA)
    { (offerVia providerRootA).ledger with
      completeness := some (answerOf (assetKeyPrefix asset) [entry₁]) } appRoot₁ faithful
    assetSound datumSound complete layoutSound rfl required (by decide)
-- The duplicate ledger is reachable: two holders of the asset.
example : entry₁ ∈ ledgerOf true selected ∧ entry₂ ∈ ledgerOf true selected ∧
    carries entry₁.2 asset ∧ carries entry₂.2 asset ∧ entry₁ ≠ entry₂ := by decide
-- The K2 and C1 classification theorems at the fixture.
example : ∀ reason, verdict (completePolicy false) publications selected wrongWithoutWitness builder ≠
    .unverified reason :=
  completeness_never_unverified (completePolicy false) publications selected wrongWithoutWitness
    builder _ (answerOf (assetKeyPrefix asset) [entry₃]) rfl rfl rfl rfl rfl
example : verdict (requiredPolicy true) publications selected verifiedProvider builder =
    .refused (.evidenceFailure selected) :=
  required_absent_refused (requiredPolicy true) publications selected verifiedProvider builder _
    acceptedRoot LedgerExamples.witness rfl rfl (by decide) rfl rfl rfl rfl rfl

end Lockness.Tests.Completeness

#print axioms Lockness.verifyEntries_observations
#print axioms Lockness.verifyEntries_refusal
#print axioms Lockness.acceptEntries_observations
#print axioms Lockness.acceptEntries_refusal
#print axioms Lockness.acceptEntries_never_adopts
#print axioms Lockness.accept_entries_sound
#print axioms Lockness.verifyLedger_completeness
#print axioms Lockness.verifyLedger_required
#print axioms Lockness.verifyLedger_complete_sound
#print axioms Lockness.verifyLedger_required_complete_sound
#print axioms Lockness.completeness_never_unverified
#print axioms Lockness.completeness_wrong_refused
#print axioms Lockness.required_absent_refused
#print axioms Lockness.Counterexamples.CompletenessExamples.fixture_completeness_sound
#print axioms Lockness.Counterexamples.CompletenessExamples.fixture_asset_layout
#print axioms Lockness.Counterexamples.CompletenessExamples.completeness_premises_inhabited
#print axioms Lockness.Counterexamples.CompletenessExamples.required_premises_inhabited
#print axioms Lockness.Counterexamples.CompletenessExamples.omitted_refutes_entries
#print axioms Lockness.Counterexamples.CompletenessExamples.narrowed_refutes_entries
#print axioms Lockness.Counterexamples.CompletenessExamples.omitted_asset_refutes
#print axioms Lockness.Counterexamples.CompletenessExamples.bare_required_refutes
#print axioms Lockness.Counterexamples.CompletenessExamples.unsound_refutes

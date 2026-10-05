import Lockness.Verdict
import Lockness.Counterexamples.AppFixtures

namespace Lockness.Counterexamples.VerdictExamples
open AppExamples

-- The #9 fixture: one policy, the honest publications, the selected point and one honest builder.
def policy : Policy := appPolicy false finalQuery
def noVerifierPolicy : Policy := { appPolicy false finalQuery with verifier := false }
def builder : Builder := honestBuilder false proofA finalQuery

-- Material for rebuilding a transaction; carried by the verified offer and never evidence.
def reconstruction : Reconstruction := ⟨[7, 0, 255], [LedgerExamples.entry₁]⟩
def badWitness : Witness := [99]
-- A point other than the selected one, which a misbound session declares.
def otherPoint : Chainpoint := { selected with slot := selected.slot + 1 }

-- Bound to the selected point, honest object and witness, carrying a reconstruction.
def verifiedSession : Session :=
  { offerVia providerRootA with
    ledger := { (offerVia providerRootA).ledger with reconstruction := some reconstruction } }
def noWitnessSession : Session :=
  { offerVia providerRootA with ledger := { (offerVia providerRootA).ledger with witness := none } }
def unboundSession : Session := { offerVia providerRootA with binding := .unbound }
def wrongWitnessSession : Session :=
  { offerVia providerRootA with
    ledger := { (offerVia providerRootA).ledger with witness := some badWitness } }
def misboundSession : Session := { offerVia providerRootA with binding := .bound otherPoint }
-- The #8 impostor object, bound to the selected point, offered without a witness.
def promotedSession : Session :=
  { selectedPoint := selected
    acceptedRoot := LedgerExamples.providerRoot
    ledger := { LedgerExamples.substitutedAnswer with witness := none }
    binding := .bound selected }

def offering (session : Session) : Provider := fun _ => some session
def verifiedProvider : Provider := offering verifiedSession
def noWitnessProvider : Provider := offering noWitnessSession
def unboundProvider : Provider := offering unboundSession
def wrongWitnessProvider : Provider := offering wrongWitnessSession
def misboundProvider : Provider := offering misboundSession
def promotingProvider : Provider := offering promotedSession

-- The verified input is the only concrete outcome asserted here; no verdict mutant changes it,
-- so this module rebuilds against every mutant on the witness path.
-- One jointly inhabited honest input: every AcceptSoundness premise for this policy, the
-- verified verdict carrying accept's claim, and the NoPromotion conclusion at that input.
theorem honest_verified_inhabited :
    HonestRootCorrespondence policy publications LedgerExamples.honestRoot ∧
    WitnessSound policy (LedgerExamples.ledgerFor false) LedgerExamples.honestRoot ∧
    ObjectEncodingFaithful policy ∧
    AssetObservationSound policy LedgerExamples.carries ∧
    DatumObservationSound policy LedgerExamples.honestDatumRoot ∧
    OneShot (LedgerExamples.ledgerFor false) policy.asset LedgerExamples.carries ∧
    AppSound policy (treeFor false) ∧
    NestingInterpretationFaithful policy honestNext ∧
    verdict policy publications selected verifiedProvider builder = .verified oneLinkClaim ∧
    (policy.verifier = true ∧
      ∃ session witness, verifiedProvider selected = some session ∧
        session.selectedPoint = selected ∧ session.binding = .bound selected ∧
        session.ledger.witness = some witness ∧
        accept policy publications selected verifiedProvider builder = .ok oneLinkClaim) :=
  ⟨fixture_correspondence false finalQuery, fixture_witness_sound false finalQuery,
    fixture_encoding_faithful false finalQuery, fixture_asset_sound false finalQuery,
    fixture_datum_sound false finalQuery, fixture_one_shot false finalQuery,
    fixture_app_sound false finalQuery, fixture_nesting false finalQuery, by decide,
    by decide, verifiedSession, LedgerExamples.witness, rfl, by decide, by decide, rfl, by decide⟩

end Lockness.Counterexamples.VerdictExamples

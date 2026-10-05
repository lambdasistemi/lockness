import Lockness.Root
import Lockness.Context
import Lockness.Session
import Lockness.Ledger
import Lockness.App

namespace Lockness

-- The root bound by root acceptance is the only ledger checking root; session and answer
-- roots are provider data and are never read as authority.
def accept (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) : Except Refusal Claim :=
  match acceptContextRoot policy publications selectedPoint with
  | .error refusal => .error refusal
  | .ok root =>
    match acquire selectedPoint provider with
    | .error refusal => .error refusal
    | .ok session =>
      match verifyLedger policy root session session.ledger with
      | .error refusal => .error refusal
      | .ok appRoot =>
        match verifyChain policy selectedPoint builder policy.fuel appRoot with
        | .error refusal => .error refusal
        | .ok (links, value) =>
          .ok { point := selectedPoint, ledgerRoot := root, query := policy.query,
                appRoot := appRoot, links := links, value := value }

-- The semantic claim over a ledger's entries; never defined from accept or a guard.
def holds (policy : Policy) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (tree : AppTree)
    (honestNext : AppValue → Option Root) (entries : Finset (TxIn × TxOut)) (claim : Claim) :
    Prop :=
  claim.query = policy.query ∧
    ∃ entry ∈ entries, carries entry.2 policy.asset ∧
      (∀ other ∈ entries, carries other.2 policy.asset → other = entry) ∧
      honestDatumRoot policy.schema entry.2 = some claim.appRoot ∧
      ChainHolds tree honestNext claim.query claim.appRoot claim.links claim.value

def AcceptSoundness
    (operation : Policy → List Publication → Chainpoint → Provider → Builder →
      Except Refusal Claim) : Prop :=
  ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider : Provider) (builder : Builder) (claim : Claim) (ledger : Ledger)
    (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (tree : AppTree)
    (honestNext : AppValue → Option Root),
    HonestRootCorrespondence policy publications honestRoot →
    WitnessSound policy ledger honestRoot → ObjectEncodingFaithful policy →
    AssetObservationSound policy carries → DatumObservationSound policy honestDatumRoot →
    OneShot ledger policy.asset carries → AppSound policy tree →
    NestingInterpretationFaithful policy honestNext →
    operation policy publications selectedPoint provider builder = .ok claim →
    claim.point = selectedPoint ∧ claim.ledgerRoot = honestRoot selectedPoint ∧
      holds policy carries honestDatumRoot tree honestNext (ledger selectedPoint) claim

-- Relative to AcceptSoundness: adds AppFunctional and drops NestingInterpretationFaithful,
-- since nextRoot is one deterministic function; availability and refusals may differ.
def ProviderInvariance
    (operation : Policy → List Publication → Chainpoint → Provider → Builder →
      Except Refusal Claim) : Prop :=
  ∀ (policy : Policy) (publications : List Publication) (selectedPoint : Chainpoint)
    (provider₁ provider₂ : Provider) (builder₁ builder₂ : Builder) (claim₁ claim₂ : Claim)
    (ledger : Ledger) (honestRoot : Chainpoint → Root) (carries : TxOut → Asset → Prop)
    (honestDatumRoot : Schema → TxOut → Option Root) (tree : AppTree),
    HonestRootCorrespondence policy publications honestRoot →
    WitnessSound policy ledger honestRoot → ObjectEncodingFaithful policy →
    AssetObservationSound policy carries → DatumObservationSound policy honestDatumRoot →
    OneShot ledger policy.asset carries → AppSound policy tree → AppFunctional tree →
    operation policy publications selectedPoint provider₁ builder₁ = .ok claim₁ →
    operation policy publications selectedPoint provider₂ builder₂ = .ok claim₂ →
    claim₁ = claim₂

end Lockness

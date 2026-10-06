import Lockness.Counterexamples.CompletenessFixtures

namespace Lockness.Sim
open Counterexamples Counterexamples.AppExamples Counterexamples.LedgerExamples
open Counterexamples.VerdictExamples Counterexamples.CompletenessExamples

-- One line per value, whatever its size.
private def line {α : Type} [Repr α] (value : α) : String := (repr value).pretty 1000000

private def expectEntries (label : String) (actual expected : Except Refusal EntriesClaim) :
    IO Bool := do
  if decide (actual = expected) then return true
  IO.eprintln s!"unexpected completeness outcome: {label} {line actual}; expected {line expected}"
  return false

private def expectVerdict (label : String) (actual expected : Verdict) : IO Bool := do
  if decide (actual = expected) then return true
  IO.eprintln s!"unexpected completeness outcome: {label} verdict {line actual}; expected {line expected}"
  return false

private def expectFact (label : String) (holds : Bool) : IO Bool := do
  if holds then return true
  IO.eprintln s!"unexpected completeness outcome: {label} does not hold"
  return false

def completenessScenario (scenario : String) : IO UInt32 := do
  -- Root provenance comes from root acceptance, separately from every provider.
  let .ok independentRoot := acceptRoot (completePolicy false) publications selected
    | IO.eprintln "unexpected completeness outcome: no independently accepted root"; return 1
  unless ← expectFact "accepted root is the honest root"
      (decide (independentRoot = honestRoot selected)) do return 1
  -- Expected entries come from the fixture ledger and layout, expected claims from honest
  -- semantics; none is read from acceptEntries, verifyLedger or verdict.
  let some honest := semanticClaim false entry₁ finalQuery
    | IO.eprintln "unexpected completeness outcome: honest semantics produced no claim"; return 1
  let claimFor (keyPrefix : Bytes) (entries : List (TxIn × TxOut)) : Except Refusal EntriesClaim :=
    .ok ⟨selected, honestRoot selected, keyPrefix, entries⟩
  let refusedEntries : Except Refusal EntriesClaim := .error (.evidenceFailure selected)
  let refused : Verdict := .refused (.evidenceFailure selected)
  let entriesFor (policy : Policy) (keyPrefix : Bytes) (provider : Provider) :=
    acceptEntries policy publications selected keyPrefix provider
  let verdictFor (policy : Policy) (provider : Provider) :=
    verdict policy publications selected provider builder
  match scenario with
  | "address-prefix" =>
    let expected := honestEntries false prefixA
    let honestResult := entriesFor (completePolicy false) prefixA (offer (answerOf prefixA expected))
    unless ← expectEntries "honest listing" honestResult (claimFor prefixA expected) do return 1
    -- The omitting listing checks only under the provider root, which is never consulted.
    unless ← expectFact "omitting listing valid under the provider root"
        (CompletenessExamples.checkFor false completenessProof providerRoot prefixA
          [objectBytes entry₁]) do return 1
    let omitted := entriesFor (completePolicy false) prefixA (offer (answerOf prefixA [entry₁]))
    unless ← expectEntries "listing valid only under the provider root" omitted refusedEntries do
      return 1
    -- A valid proof for a narrower prefix is not a proof for the requested one.
    let narrowExpected := honestEntries false narrowPrefix
    unless ← expectFact "narrower answer valid for its own prefix"
        (CompletenessExamples.checkFor false completenessProof (honestRoot selected) narrowPrefix
          (narrowExpected.map objectBytes)) do return 1
    let narrower := entriesFor (completePolicy false) prefixA
      (offer (answerOf narrowPrefix narrowExpected))
    unless ← expectEntries "answer for the narrower prefix" narrower refusedEntries do return 1
    let absent := entriesFor (completePolicy false) prefixA verifiedProvider
    unless ← expectEntries "no completeness answer" absent refusedEntries do return 1
    IO.println s!"completeness scenario=address-prefix honest={line honestResult} honest-entries={line expected} provider-root-listing={line omitted} narrower-prefix={line narrower} absent={line absent} selected={line selected}"
    return 0
  | "asset-unique" =>
    let single := honestEntries false (assetKeyPrefix asset)
    let both := honestEntries true (assetKeyPrefix asset)
    unless ← expectFact "two holders on the duplicate ledger" (decide (both.length = 2)) do return 1
    let one := verdictFor (completePolicy false) (offer (answerOf (assetKeyPrefix asset) single))
    unless ← expectVerdict "one holder" one (.verified honest) do return 1
    let duplicateHonest :=
      verdictFor (completePolicy true) (offer (answerOf (assetKeyPrefix asset) both))
    unless ← expectVerdict "duplicate, honest listing" duplicateHonest refused do return 1
    let duplicateOmitting :=
      verdictFor (completePolicy true) (offer (answerOf (assetKeyPrefix asset) single))
    unless ← expectVerdict "duplicate, listing omitting a holder" duplicateOmitting refused do
      return 1
    -- The OneShot path: a terminal that trusts the minting policy.
    let oneShot := verdictFor (completePolicy true) verifiedProvider
    unless ← expectVerdict "duplicate, no completeness answer" oneShot (.verified honest) do return 1
    -- A terminal that requires completeness refuses the same answer.
    let required := verdictFor (requiredPolicy true) verifiedProvider
    unless ← expectVerdict "required, no completeness answer" required refused do return 1
    let requiredOne := verdictFor (requiredPolicy false) (offer (answerOf (assetKeyPrefix asset) single))
    unless ← expectVerdict "required, one holder" requiredOne (.verified honest) do return 1
    -- Present evidence is never unverified; a declared absence of all evidence is.
    let wrong := verdictFor (completePolicy false) wrongWithoutWitness
    unless ← expectVerdict "wrong listing without a witness" wrong refused do return 1
    let bare := verdictFor (completePolicy false) noWitnessProvider
    unless ← expectVerdict "no witness and no listing" bare (.unverified .noWitness) do return 1
    IO.println s!"completeness scenario=asset-unique one-holder={line one} duplicate-honest-listing={line duplicateHonest} duplicate-omitting-listing={line duplicateOmitting} duplicate-no-completeness={line oneShot} required-no-completeness={line required} required-one-holder={line requiredOne} wrong-without-witness={line wrong} no-evidence={line bare} selected={line selected}"
    return 0
  | "omitted-entry" =>
    unless ← expectFact "entry₃ is an honest member under prefixA"
        (decide (entry₃ ∈ honestEntries false prefixA)) do return 1
    let omitted := entriesFor (completePolicy false) prefixA (offer (answerOf prefixA [entry₁]))
    unless ← expectEntries "listing omitting entry₃" omitted refusedEntries do return 1
    IO.println s!"completeness scenario=omitted-entry omitted={line omitted} honest-entries={line (honestEntries false prefixA)} selected={line selected}"
    return 0
  | "extra-entry" =>
    unless ← expectFact "impostor is not in the ledger" (decide (impostor ∉ ledgerOf false selected)) do
      return 1
    let extra := entriesFor (completePolicy false) prefixA
      (offer (answerOf prefixA (honestEntries false prefixA ++ [impostor])))
    unless ← expectEntries "listing with an impostor" extra refusedEntries do return 1
    IO.println s!"completeness scenario=extra-entry extra={line extra} impostor={line impostor} selected={line selected}"
    return 0
  | "empty-prefix" =>
    let whole := honestEntries false []
    unless ← expectFact "the zero-length prefix lists the whole ledger"
        (decide (whole = ledgerList false)) do return 1
    let wholeResult := entriesFor (completePolicy false) [] (offer (answerOf [] whole))
    unless ← expectEntries "zero-length prefix" wholeResult (claimFor [] whole) do return 1
    let nothing := honestEntries false absentPrefix
    unless ← expectFact "no entry under the absent prefix" (decide (nothing = [])) do return 1
    let absentResult := entriesFor (completePolicy false) absentPrefix
      (offer (answerOf absentPrefix nothing))
    unless ← expectEntries "absent prefix, empty listing" absentResult
        (claimFor absentPrefix nothing) do return 1
    unless ← expectFact "prefixA is populated" (decide (honestEntries false prefixA ≠ [])) do
      return 1
    let populated := entriesFor (completePolicy false) prefixA (offer (answerOf prefixA []))
    unless ← expectEntries "empty listing for prefixA" populated refusedEntries do return 1
    IO.println s!"completeness scenario=empty-prefix whole={line wholeResult} absent-prefix={line absentResult} empty-listing-for-populated={line populated} selected={line selected}"
    return 0
  | "unsound-proof" =>
    -- A check that violates CompletenessSound: the listing omitting entry₃ checks under the
    -- accepted root although it is not the honest listing.
    unless ← expectFact "the permissive check accepts a listing that is not the honest one"
        (permissivePolicy.checkCompleteness completenessProof (honestRoot selected) prefixA
            [objectBytes entry₁] &&
          !sameSet [objectBytes entry₁] (honestList false prefixA)) do return 1
    let accepted := entriesFor permissivePolicy prefixA (offer (answerOf prefixA [entry₁]))
    unless ← expectEntries "permissive check" accepted (claimFor prefixA [entry₁]) do return 1
    unless ← expectFact "the accepted claim lacks the honest member entry₃"
        (decide (entry₃ ∈ honestEntries false prefixA) &&
          match accepted with
          | .ok claim => decide (entry₃ ∉ claim.entries)
          | .error _ => false) do return 1
    IO.println s!"completeness scenario=unsound-proof accepted={line accepted} missing={line entry₃} selected={line selected}"
    return 0
  | _ =>
    IO.eprintln "unknown completeness scenario; choose address-prefix, asset-unique, omitted-entry, extra-entry, empty-prefix or unsound-proof"
    return 64

end Lockness.Sim

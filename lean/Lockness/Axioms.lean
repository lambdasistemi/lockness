import Lean
import Lockness

open Lean Elab Command

-- Inventory comes from elaborated declarations, including private theorems.
elab "#audit_lockness" : command => do
  let environment ← getEnv
  let mut theorems := 0
  let mut declarations := 0
  for (name, info) in environment.constants.toList do
    let owned := match environment.getModuleIdxFor? name with
      | some index => (environment.header.moduleNames[index.toNat]!).toString.startsWith "Lockness"
      | none => (name.toString.splitOn "Lockness").length > 1
    if owned then
      declarations := declarations + 1
      if info.isAxiom then
        throwError "custom model axiom: {name}"
      let axioms ← collectAxioms name
      for axiomName in axioms do
        unless [``propext, ``Classical.choice, ``Quot.sound].contains axiomName do
          throwError "unapproved axiom {axiomName} in {name}"
      if info matches .thmInfo _ then
        theorems := theorems + 1
        logInfo m!"AXIOMS {name}: {axioms.toList}"
  if theorems == 0 then throwError "empty theorem inventory"
  logInfo m!"AXIOM-INVENTORY theorems={theorems} declarations={declarations}"

#audit_lockness

import Lockness.Sim.AcceptRoot
import Lockness.Sim.Session
import Lockness.Sim.Ledger

def main (arguments : List String) : IO UInt32 := do
  match arguments with
  | ["accept-root", scenario] => Lockness.Sim.acceptRootScenario scenario
  | ["session", scenario] => Lockness.Sim.sessionScenario scenario
  | ["ledger", scenario] => Lockness.Sim.ledgerScenario scenario
  | _ =>
    IO.eprintln "usage: lockness-sim accept-root <honest|untrusted-key|subset-mutation> | session <honest|absent-point|newer-point> | ledger <honest|substituted-root|duplicate-asset>"
    return 64

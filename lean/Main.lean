import Lockness.Sim.AcceptRoot
import Lockness.Sim.Session

def main (arguments : List String) : IO UInt32 := do
  match arguments with
  | ["accept-root", scenario] => Lockness.Sim.acceptRootScenario scenario
  | ["session", scenario] => Lockness.Sim.sessionScenario scenario
  | _ =>
    IO.eprintln "usage: lockness-sim accept-root <honest|untrusted-key|subset-mutation> | session <honest|absent-point|newer-point>"
    return 64

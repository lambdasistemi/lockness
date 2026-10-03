import Lockness.Sim.AcceptRoot

def main (arguments : List String) : IO UInt32 := do
  match arguments with
  | ["accept-root", scenario] => Lockness.Sim.acceptRootScenario scenario
  | _ =>
    IO.eprintln "usage: lockness-sim accept-root <honest|untrusted-key|subset-mutation>"
    return 64

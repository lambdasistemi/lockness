import Lockness.Sim.AcceptRoot
import Lockness.Sim.Session
import Lockness.Sim.Ledger
import Lockness.Sim.App
import Lockness.Sim.Verdict
import Lockness.Sim.Context

def main (arguments : List String) : IO UInt32 := do
  match arguments with
  | ["accept-root", scenario] => Lockness.Sim.acceptRootScenario scenario
  | ["session", scenario] => Lockness.Sim.sessionScenario scenario
  | ["ledger", scenario] => Lockness.Sim.ledgerScenario scenario
  | ["app", scenario] => Lockness.Sim.appScenario scenario
  | ["verdict", scenario] => Lockness.Sim.verdictScenario scenario
  | ["context", scenario] => Lockness.Sim.contextScenario scenario
  | _ =>
    IO.eprintln "usage: lockness-sim accept-root <honest|untrusted-key|subset-mutation> | session <honest|absent-point|newer-point> | ledger <honest|substituted-root|duplicate-asset> | app <honest|replaced-root|nested|ambiguous-value> | verdict <verified|no-witness|unbound-session|no-verifier|wrong-witness|misbound|promoted> | context <honest|wrong-network-point|wrong-network-publication|unaccepted-scheme|unbound-message>"
    return 64

# Responsibilities

| Surface | Responsibility and dependencies |
| --- | --- |
| Lean project | Pinned Lean/Lake library and executable; core/Std only |
| Lockness.Types | Shared exact protocol values and abstract boundary types |
| Lockness.Root | Authoritative acceptance and endorsement theorem; consumes Types |
| Proof/counterexample modules | Reachability, valid-signature witness, subset mutation, axiom inventory; consume Root |
| Sim.AcceptRoot and dispatcher | Reviewer scenarios execute model paths |
| tools/check-model.sh | Permanent build, holes/axioms, semantic mutation and scenarios |
| CI and just ci | Invoke model and documentation gates |
| docs/model/index.md | Reviewer commands, hypotheses, declaration links and evidence limits; curated speech companion |

Fields and signatures are owned by data-model.md and functions-model.md. Later protocol behavior is not implemented.

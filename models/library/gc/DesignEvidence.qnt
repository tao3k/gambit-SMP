// Finite evidence classification, not any collector's implementation.
module DesignEvidence {
  type State = { source: bool, finite: bool, counterexample: bool,
    native: bool, matched: bool, authorized: bool, stale: bool }
  var s: State
  action init = s' = { source: true, finite: false, counterexample: false,
    native: false, matched: false, authorized: false, stale: false }
  action finitePass = s' = { ...s, finite: true }
  action negative = s' = { ...s, counterexample: true }
  action withdraw = s' = { ...s, source: false, stale: true }
  action step = any { finitePass, negative, withdraw }
  val whyBound = s.source and s.finite and not(s.stale)
  val whyNotBound = s.source and s.counterexample and not(s.stale)
  val unknown = not(s.native)
  val adopt = s.source and s.native and s.matched and s.authorized and not(s.stale)
  val Safe = all { whyBound implies s.source, whyNotBound implies s.source,
    not(adopt), unknown }
  // Independent semantic mutations preserve reachable counterexamples.
  val FalseRefutationSafe = not(unknown and s.finite and not(s.counterexample))
  val FiniteAdmissionSafe = not(s.finite) or adopt
}

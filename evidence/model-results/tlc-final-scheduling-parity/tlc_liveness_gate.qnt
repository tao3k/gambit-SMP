module tlc_liveness_gate {
  var s: { policy: str, phase: int }
  action initTerminating = s' = { policy: "terminate", phase: 0 }
  action initCycle = s' = { policy: "cycle", phase: 0 }
  action step = s' = { ...s, phase:
    if (s.policy == "terminate") 1 else 1 - s.phase }
  val safe = s.phase == 0 or s.phase == 1
  val zero = s.phase == 0
  // Cycle mode is always safe and enabled, but never reaches the terminal goal.
  temporal progress = weakFair(step, Set(s)).implies(
    eventually(s.policy == "terminate" and s.phase == 1))
}

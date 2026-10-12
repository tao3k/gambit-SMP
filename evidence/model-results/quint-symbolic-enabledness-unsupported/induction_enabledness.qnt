module induction_enabledness {
  type ProbeState = { x: int }
  var s: ProbeState
  action initCandidate = {
    nondet x = 0.to(2).oneOf()
    s' = { x: x }
  }
  action step = all { s.x < 2, s' = { x: s.x + 1 } }
  action blockedStep = all { s.x < 1, s' = { x: s.x + 1 } }
  val terminal = s.x == 2
  val enabledCandidate = terminal or enabled(step)
  val rejectsBlocked = terminal or enabled(blockedStep)
}

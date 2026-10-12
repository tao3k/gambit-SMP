module induction_gate {
  var x: int
  action init = x' = 0
  action step = x' = if (x < 2) x + 1 else x
  action stepEscapesDomain = x' = x + 1
  val safe = x >= 0 and x <= 2
  // Membership provides Apalache's symbolic initializer, unlike inequalities.
  val inductive = x.in(0.to(2))
  val failsInitial = x.in(1.to(2))
  val failsPreservation = x.in(Set(0, 2))
  // Preserved even for negative states, but does not imply the safety goal.
  val failsImplication = x.in((-1).to(2))
}

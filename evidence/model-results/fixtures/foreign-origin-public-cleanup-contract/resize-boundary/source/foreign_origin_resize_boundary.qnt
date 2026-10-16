module foreign_origin_resize_boundary {
  // Two semantic slots expose both lower and upper bounds, not a CPU limit.
  type State = { checked: bool, requested: int, target: int, population: int,
    phase: str, gate: bool, busy: bool, badIndex: bool, badPopulation: bool }
  var s: State
  pure def initial(checked: bool, requested: int, population: int, busy: bool): State = {
    checked: checked, requested: requested, target: requested,
    population: population, phase: "entry", gate: false, busy: busy,
    badIndex: false, badPopulation: false }
  action init = {
    nondet requested = Set(-1, 0, 1, 2, 3).oneOf()
    nondet population = Set(1, 2).oneOf()
    nondet busy = Set(false, true).oneOf()
    s' = initial(true, requested, population, busy)
  }
  action initNegative = s' = initial(false, -1, 2, false)
  action initZero = s' = initial(false, 0, 2, false)
  action validate = all { s.phase == "entry",
    s' = if (s.checked and s.requested < 1) { ...s, phase: "rejected" }
      else { ...s, target: if (s.requested > 2) 2 else s.requested, phase: "scan" } }
  action scan = all { s.phase == "scan",
    s' = if (s.target < 0) { ...s, gate: true, badIndex: true, phase: "fault" }
      else if (s.busy and s.target < s.population) { ...s, phase: "busy" }
      else { ...s, gate: true, phase: "collective" } }
  action resize = all { s.phase == "collective",
    s' = { ...s, population: s.target, gate: false, phase: "done",
      badPopulation: s.target < 1 or s.target > 2 } }
  val terminal = Set("rejected", "busy", "done", "fault").contains(s.phase)
  action finished = all { terminal, s' = s }
  action step = any { validate, scan, resize, finished }
  val indexSafe = not(s.badIndex)
  val populationSafe = not(s.badPopulation)
  val rejectionAtomic = s.phase != "rejected" or
    (not(s.gate) and s.target == s.requested and Set(1, 2).contains(s.population))
  val safe = indexSafe and populationSafe and rejectionAtomic
  val noStall = terminal or enabled(step)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}

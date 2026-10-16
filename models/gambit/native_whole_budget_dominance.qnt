module native_whole_budget_dominance {
  // A whole deadline may dominate an old atomic cap only with complete
  // inventory and mode binding, including preparation in the same interval.
  // Atomic caps are never multiplied or treated as old whole-mode timings.
  type State = { original: Set[int], selected: Set[int], completed: Set[int],
    modeBound: bool, preparationBound: bool, nestedBound: bool, oldCap: int,
    wholeCap: int, elapsed: int, phase: str, admitted: bool, bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    original: Set(1, 2), selected: Set(1, 2, 3), completed: Set(),
    modeBound: true, preparationBound: true, nestedBound: true, oldCap: 3,
    wholeCap: 3, elapsed: 0, phase: "prepare", admitted: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  val coverage = s.original.subseteq(s.selected) and s.selected == s.completed
  val dominance = s.wholeCap <= s.oldCap and s.elapsed <= s.wholeCap
  val bound = coverage and dominance and s.modeBound and s.preparationBound and s.nestedBound
  action prepare = all { s.phase == "prepare", s' = { ...s, phase: "execute" } }
  action completeFile = all { s.phase == "execute",
    nondet file = s.selected.exclude(s.completed).oneOf()
    s' = { ...s, completed: s.completed.union(Set(file)) } }
  action finish = all { s.phase == "execute", s.selected == s.completed,
    s' = { ...s, phase: "review" } }
  action tick = all { not(s.admitted), s.elapsed < 5,
    s' = { ...s, elapsed: s.elapsed + 1 } }
  action omit = all { s.phase == "prepare", s.selected.contains(2),
    s' = { ...s, selected: s.selected.exclude(Set(2)) } }
  action expand = all { s.phase == "prepare", s.wholeCap == 3,
    s' = { ...s, wholeCap: 4 } }
  action detachPreparation = all { s.phase == "prepare", s.preparationBound,
    s' = { ...s, preparationBound: false } }
  action dropNested = all { s.phase == "prepare", s.nestedBound,
    s' = { ...s, nestedBound: false } }
  action changeMode = all { s.phase == "prepare", s.modeBound,
    s' = { ...s, modeBound: false } }
  action admit = all { s.phase == "review", bound or s.bypass,
    s' = { ...s, phase: "done", admitted: true } }
  action hold = s' = s
  action step = any { prepare, completeFile, finish, tick, omit, expand,
    detachPreparation, dropNested, changeMode, admit, hold }
  val safe = s.admitted implies bound
  run supersetWholeTest = init.then(prepare).then(completeFile).then(completeFile)
    .then(completeFile).then(finish).then(admit)
    .then(all { assert(s.admitted), assert(safe), s' = s })
  run omittedOriginalControlTest = initBypass.then(omit).then(prepare)
    .then(completeFile).then(completeFile).then(finish).then(admit)
    .then(all { assert(not(safe)), s' = s })
  run outsidePreparationControlTest = initBypass.then(detachPreparation)
    .then(prepare).then(completeFile).then(completeFile).then(completeFile)
    .then(finish).then(admit).then(all { assert(not(safe)), s' = s })
  run overrunControlTest = initBypass.then(prepare).then(completeFile)
    .then(completeFile).then(completeFile).then(finish)
    .then(tick).then(tick).then(tick).then(tick).then(admit)
    .then(all { assert(not(safe)), s' = s })
}

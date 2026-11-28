module source_core_progress_window {
  // The 600s whole wall kills source-core while objects are still being remade.
  // A progress idle window keeps the same 600s step budget and can finish the core.
  // Core completion is not the 90s numeric compile and not the GC/FFI inventory.
  // Milestone stays 8. Not a source patch and not 9/12.
  type State = {
    control: int, cap: int, stepBudget: int, objects: int,
    coreFinished: bool, numericDone: bool, inventoryDone: bool,
    closed: bool, milestone: int
  }
  var s: State
  pure def initial(control: int): State = {
    control: control, cap: 90, stepBudget: 600, objects: 0,
    coreFinished: false, numericDone: false, inventoryDone: false,
    closed: false, milestone: 8
  }
  action initProgress = s' = initial(1)
  action initRaised = s' = initial(2)
  action initCoreOnly = s' = initial(3)
  action remakeObject = all {
    s.control == 1, s.stepBudget == 600, s.cap == 90, s.objects < 3, not(s.coreFinished),
    s' = { ...s, objects: s.objects + 1 }
  }
  action finishCore = all {
    s.control == 1, s.objects == 3, s.stepBudget == 600, s.cap == 90, not(s.coreFinished),
    s' = { ...s, coreFinished: true }
  }
  action markCore = all {
    s.control == 3, not(s.coreFinished),
    s' = { ...s, coreFinished: true, objects: 3 }
  }
  action closeFromCore = all {
    s.control == 3, s.coreFinished, not(s.numericDone), not(s.inventoryDone), not(s.closed),
    s' = { ...s, closed: true }
  }
  action raiseCapAndClose = all {
    s.control == 2, not(s.closed),
    s' = { ...s, cap: 180, numericDone: true, inventoryDone: true, closed: true }
  }
  val terminal =
    s.control == 1 and s.coreFinished and s.stepBudget == 600 and s.cap == 90 and
    not(s.numericDone) and not(s.inventoryDone) and not(s.closed) and s.milestone == 8
  action done = all { terminal, s' = s }
  action step = any {
    remakeObject, finishCore, markCore, closeFromCore, raiseCapAndClose, done
  }
  val safe =
    s.milestone == 8 and s.stepBudget == 600 and
    (not(s.closed) or (s.cap == 90 and s.numericDone and s.inventoryDone)) and
    (s.control != 1 or not(s.closed))
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}

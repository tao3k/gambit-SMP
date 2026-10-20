module saved_stack_retirement_window {
  import saved_stack_root_closure.* from "./saved_stack_root_closure"

  // Queue classes are source-audit roles, not a machine processor count.
  val queueRoles = Set("current", "run", "timeout", "device", "interrupt")
  type Window = { fault: int, stage: int, frozen: bool, arrived: bool, reused: bool,
    pending: Set[str], checked: Set[str], transferred: Set[str],
    strongDone: bool, weakDone: bool, cleanupDone: bool }
  var w: Window
  var windowRank: int
  pure def windowInitial(fault: int): Window = { fault: fault,
    stage: 0, frozen: false, arrived: false, reused: false, pending: Set(), checked: Set(),
    transferred: Set(), strongDone: false, weakDone: false, cleanupDone: false }
  action initWindow = {
    nondet fault = Set(0, 1, 2, 3).oneOf()
    all { initClosure, w' = windowInitial(fault), windowRank' = 0 }
  }
  action keepGraph = all { keepA, g' = g }
  // No new runtime gate is prescribed. This is scoped producer quiescence,
  // which a real collective/ownership contract must independently establish.
  action freezeProducers = all { w.stage == 3, not(w.frozen), keepGraph,
    w' = { ...w, frozen: true } }
  action enqueueBeforeFreeze = all { w.stage == 3, not(w.frozen), not(w.arrived),
    keepGraph, w' = { ...w, arrived: true, pending: w.pending.union(Set("run")) } }
  action transferQueue = {
    nondet role = w.pending.oneOf()
    all { w.stage == 3, w.frozen, keepGraph,
      w' = { ...w, pending: w.pending.exclude(Set(role)),
        transferred: w.transferred.union(Set(role)) } }
  }
  // In the corrected cohort producers are frozen, so the order of individual
  // empty-field reads is irrelevant. Quotient those permutations into one
  // scoped snapshot; a pre-freeze snapshot still admits the stale-empty trace.
  action witnessQueue = all { w.stage == 3, w.pending == Set(),
    w.checked != queueRoles, w.frozen or w.fault == 1 or w.fault == 2,
    keepGraph, w' = { ...w, checked: queueRoles } }
  // Fault 1 trusts an old empty observation; fault 2 treats foreign-frame
  // admission as sufficient Scheme-queue quiescence. Neither is a source fix.
  val queueReady = w.checked == queueRoles and
    (w.pending == Set() or w.fault == 1) and
    (w.frozen or w.fault == 1 or w.fault == 2)
  // Before cleanup, retirePrefix has exactly save/detach/publish/retire/cleanup
  // in that order. This ghost projection excludes its optional later slot
  // reinitialization; it does not access an unexported component state.
  action admittedPrefix = all { w.stage < 5, retirePrefix,
    w.stage != 3 or queueReady, w' = { ...w, stage: w.stage + 1 } }
  action existingGraph = all {
    any { establishRoot, restoreHead, consumeHead, collect, forwardHead,
      retargetOrigin, drainTargetWork, resumeHead },
    w' = w }
  // The imported raw-origin set starts nonempty and can clear only after
  // forwardHead. No nested action-enabled expansion is needed here.
  action finishStrong = all { g.collection, g.rawOrigins == Set(),
    not(g.workPending), not(w.strongDone), keepGraph,
    w' = { ...w, strongDone: true } }
  action finishWeak = all { w.strongDone, not(w.weakDone), keepGraph,
    w' = { ...w, weakDone: true } }
  action finishCleanup = all { w.weakDone, not(w.cleanupDone), keepGraph,
    w' = { ...w, cleanupDone: true } }
  action closeFullCycle = all { closeCycle,
    w.cleanupDone or (w.fault == 3 and w.strongDone), w' = w }
  action reuseNextCycle = all { nextCycleReuse,
    w' = { ...w, reused: true } }

  val sourceCohort = g.fault == 0
  val retired = w.stage >= 4
  val queueCoverage = not(sourceCohort and w.fault == 1 and retired) or
    w.pending == Set()
  val admissionCoverage = not(sourceCohort and w.fault == 2 and retired) or
    w.frozen
  val fullPhaseCoverage = not(sourceCohort and w.fault == 3 and w.reused) or
    (w.strongDone and w.weakDone and w.cleanupDone)
  val windowSafe = not(sourceCohort and w.fault == 0) or
    (closureSafe and (not(retired) or
      (w.frozen and w.pending == Set() and w.checked == queueRoles)) and
      (not(w.reused) or (w.strongDone and w.weakDone and w.cleanupDone)))
  val noValidEmptyRetirement = not(sourceCohort and w.fault == 0 and
    closureTerminal and not(g.collection) and not(w.arrived) and w.transferred == Set() and
    w.frozen and w.checked == queueRoles)
  val noTransferredQueueReturn = not(sourceCohort and w.fault == 0 and
    closureTerminal and not(g.collection) and w.transferred.contains("run"))
  // Other g cohorts are previous component controls, not this investigation.
  // Their guarded assertions are vacuous here; retain them as stuttering
  // initial states instead of exploring already-qualified failure paths.
  action windowFinished = all { closureTerminal or not(sourceCohort), keepGraph, w' = w,
    windowRank' = windowRank }
  action windowStep = any { windowFinished, all { sourceCohort, not(closureTerminal),
    any { admittedPrefix, existingGraph,
      freezeProducers, enqueueBeforeFreeze, transferQueue, witnessQueue,
      finishStrong, finishWeak, finishCleanup, closeFullCycle, reuseNextCycle },
    windowRank' = windowRank + 1 } }
  temporal windowCompletion = always(not(sourceCohort and w.fault == 0)) or
    (always(closureTerminal or enabled(windowStep)) and
      weakFair(windowStep, Set(windowRank)).implies(eventually(closureTerminal)))
}

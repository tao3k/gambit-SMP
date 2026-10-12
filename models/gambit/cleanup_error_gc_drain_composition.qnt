module cleanup_error_gc_drain_composition {
  import cleanup_resize_error_contract as C from "./cleanup_resize_error_contract"
  // One worker, processor 0, one error and explicit catcher/cleanup phases.
  // setup_state is not a catcher-lifetime token. All actions are atomic here.
  type Sh_State = { mode: int, phase: int, catcher: bool, sealed: bool,
    error: int, admitted: bool, outcome: int, invalidThrow: bool, lost: bool }
  var sh_s: Sh_State
  pure def sh_initial(mode: int): Sh_State = {
    mode: mode, phase: 0, catcher: true, sealed: false, error: 0,
    admitted: false, outcome: 0, invalidThrow: false, lost: false,
  }
  action sh_initOld = sh_s' = sh_initial(0)
  action sh_initSetupGuard = sh_s' = sh_initial(1)
  action sh_initCatcherGuard = sh_s' = sh_initial(3)
  action sh_initFixed = sh_s' = sh_initial(2)

  // Stronger candidate: close admission before withdrawing the catcher.
  // Previously admitted errors must be delivered; late errors receive an
  // explicit shutdown outcome, not an attempted nonlocal throw.
  action sh_sealAdmission = all {
    sh_s.phase == 0, not(sh_s.sealed), sh_s.mode == 2,
    sh_s' = { ...sh_s, sealed: true },
  }
  action sh_workerReports = all {
    sh_s.phase < 3, sh_s.error == 0,
    sh_s' = { ...sh_s, error: 1, admitted: not(sh_s.sealed) },
  }
  action sh_removeCatcher = all {
    sh_s.phase == 0,
    sh_s.mode != 2 or (sh_s.sealed and (sh_s.error != 1 or not(sh_s.admitted))),
    sh_s' = { ...sh_s, phase: 1, catcher: false },
  }
  action sh_beginCleanup = all {
    sh_s.phase == 1, sh_s' = { ...sh_s, phase: 2 },
  }
  val sh_throwing = if (sh_s.mode == 0) true else
    if (sh_s.mode == 1) sh_s.phase < 2 else
    if (sh_s.mode == 3) sh_s.catcher else sh_s.admitted
  action sh_serviceError = all {
    sh_s.error == 1,
    // The inspected cleanup path services operations after publishing cleanup.
    // Only the wider guard-only hypothesis admits pre-cleanup dispatch; its
    // source reachability must be established before alleging a PR793 defect.
    sh_s.phase != 1 or sh_s.mode == 1,
    sh_s' = { ...sh_s, error: 2, outcome: if (sh_throwing) 1 else 2,
      invalidThrow: sh_throwing and not(sh_s.catcher),
      lost: sh_s.admitted and not(sh_throwing) },
  }
  action sh_stopWorker = all {
    sh_s.phase == 2, sh_s.error != 1, sh_s' = { ...sh_s, phase: 3 },
  }
  action sh_reclaim = all {
    sh_s.phase == 3, sh_s' = { ...sh_s, phase: 4 },
  }
  action sh_finished = all { sh_s.phase == 4, sh_s' = sh_s }
  action sh_step = any { sh_sealAdmission, sh_workerReports, sh_removeCatcher,
    sh_beginCleanup, sh_serviceError, sh_stopWorker, sh_reclaim, sh_finished }

  val sh_throwSafe = not(sh_s.invalidThrow)
  val sh_guardSafe = sh_throwSafe
  val sh_noLossSafe = not(sh_s.lost)
  val sh_reclamationSafe = sh_s.phase != 4 or (not(sh_s.catcher) and sh_s.error != 1)
  val sh_safe = sh_throwSafe and sh_noLossSafe and sh_reclamationSafe
  // One admitted borrower and one publication tail: neither is an OS join.
  type Drain = { policy: int, borrower: bool, publisher: bool, badRelease: bool }
  var d: Drain
  action initFixed = all {
    d' = { policy: 0, borrower: true, publisher: true, badRelease: false },
    C::s' = { policy: 1, phase: 0, count: 2, join: 0, exited: false,
      setup: 1, freed: false, outcome: 0 },
    sh_s' = { mode: 2, phase: 0, catcher: true, sealed: false, error: 0,
      admitted: false, outcome: 0, invalidThrow: false, lost: false },
  }
  action initJoinOnlyBorrower = all {
    d' = { policy: 1, borrower: true, publisher: true, badRelease: false },
    C::s' = { policy: 1, phase: 0, count: 2, join: 0, exited: false,
      setup: 1, freed: false, outcome: 0 },
    sh_s' = { mode: 2, phase: 0, catcher: true, sealed: false, error: 0,
      admitted: false, outcome: 0, invalidThrow: false, lost: false },
  }
  action initJoinOnlyPublisher = all {
    d' = { policy: 2, borrower: true, publisher: true, badRelease: false },
    C::s' = { policy: 1, phase: 0, count: 2, join: 0, exited: false,
      setup: 1, freed: false, outcome: 0 },
    sh_s' = { mode: 2, phase: 0, catcher: true, sealed: false, error: 0,
      admitted: false, outcome: 0, invalidThrow: false, lost: false },
  }
  action errorStep = all {
    C::s.join != 1,
    any { sh_workerReports, sh_serviceError }, C::s' = C::s, d' = d,
  }
  action drainErrorAfterJoin = all {
    sh_serviceError, C::s' = C::s, d' = d,
  }
  action closeAdmission = all { sh_sealAdmission, C::s' = C::s, d' = d }
  action withdrawCatcher = all { sh_removeCatcher, C::s' = C::s, d' = d }
  action beginCleanup = all { sh_beginCleanup, C::publishCleanup, d' = d }
  action shrink = all { C::reducePopulation, sh_s' = sh_s, d' = d }
  action failJoin = all { C::joinFails, sh_s' = sh_s, d' = d }
  action successfulJoin = all {
    C::joinSucceeds, sh_stopWorker, d' = d,
  }
  action releaseBorrower = all {
    sh_s.sealed, d.borrower, C::s' = C::s, sh_s' = sh_s,
    d' = { ...d, borrower: false, badRelease: d.badRelease or C::s.freed },
  }
  action releasePublisher = all {
    sh_s.sealed, d.publisher, C::s' = C::s, sh_s' = sh_s,
    d' = { ...d, publisher: false, badRelease: d.badRelease or C::s.freed },
  }
  action reclaim = all {
    not(d.borrower) or d.policy == 1,
    not(d.publisher) or d.policy == 2,
    C::reclaim, sh_reclaim, d' = d,
  }
  action retainOnFailure = all {
    sh_s.error != 1, C::quarantine, sh_s' = sh_s, d' = d,
  }
  val terminal = C::s.phase == 4 and sh_s.error != 1 and
    not(d.borrower) and not(d.publisher)
  action finished = all { terminal, C::s' = C::s, sh_s' = sh_s, d' = d }
  action step = any { errorStep, drainErrorAfterJoin, closeAdmission,
    withdrawCatcher, beginCleanup, shrink, failJoin, successfulJoin,
    releaseBorrower, releasePublisher, reclaim, retainOnFailure, finished }
  val borrowerSafe = not(C::s.freed) or not(d.borrower)
  val publisherSafe = not(C::s.freed) or not(d.publisher)
  val safe = C::safe and sh_safe and borrowerSafe and publisherSafe and not(d.badRelease)
  temporal completion = weakFair(step, Set((C::s, sh_s, d))).implies(eventually(terminal))
}

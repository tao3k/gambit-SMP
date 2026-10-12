module shutdown_error_handoff {
  // One worker, processor 0, one error and explicit catcher/cleanup phases.
  // setup_state is not a catcher-lifetime token. All actions are atomic here.
  type State = { mode: int, phase: int, catcher: bool, sealed: bool,
    error: int, admitted: bool, outcome: int, invalidThrow: bool, lost: bool }
  var s: State
  pure def initial(mode: int): State = {
    mode: mode, phase: 0, catcher: true, sealed: false, error: 0,
    admitted: false, outcome: 0, invalidThrow: false, lost: false,
  }
  action initOld = s' = initial(0)
  action initSetupGuard = s' = initial(1)
  action initCatcherGuard = s' = initial(3)
  action initFixed = s' = initial(2)

  // Stronger candidate: close admission before withdrawing the catcher.
  // Previously admitted errors must be delivered; late errors receive an
  // explicit shutdown outcome, not an attempted nonlocal throw.
  action sealAdmission = all {
    s.phase == 0, not(s.sealed), s.mode == 2,
    s' = { ...s, sealed: true },
  }
  action workerReports = all {
    s.phase < 3, s.error == 0,
    s' = { ...s, error: 1, admitted: not(s.sealed) },
  }
  action removeCatcher = all {
    s.phase == 0,
    s.mode != 2 or (s.sealed and (s.error != 1 or not(s.admitted))),
    s' = { ...s, phase: 1, catcher: false },
  }
  action beginCleanup = all {
    s.phase == 1, s' = { ...s, phase: 2 },
  }
  val throwing = if (s.mode == 0) true else
    if (s.mode == 1) s.phase < 2 else
    if (s.mode == 3) s.catcher else s.admitted
  action serviceError = all {
    s.error == 1,
    // The inspected cleanup path services operations after publishing cleanup.
    // Only the wider guard-only hypothesis admits pre-cleanup dispatch; its
    // source reachability must be established before alleging a PR793 defect.
    s.phase != 1 or s.mode == 1,
    s' = { ...s, error: 2, outcome: if (throwing) 1 else 2,
      invalidThrow: throwing and not(s.catcher),
      lost: s.admitted and not(throwing) },
  }
  action stopWorker = all {
    s.phase == 2, s.error != 1, s' = { ...s, phase: 3 },
  }
  action reclaim = all {
    s.phase == 3, s' = { ...s, phase: 4 },
  }
  action finished = all { s.phase == 4, s' = s }
  action step = any { sealAdmission, workerReports, removeCatcher,
    beginCleanup, serviceError, stopWorker, reclaim, finished }

  val throwSafe = not(s.invalidThrow)
  val guardSafe = throwSafe
  val noLossSafe = not(s.lost)
  val reclamationSafe = s.phase != 4 or (not(s.catcher) and s.error != 1)
  val safe = throwSafe and noLossSafe and reclamationSafe
}

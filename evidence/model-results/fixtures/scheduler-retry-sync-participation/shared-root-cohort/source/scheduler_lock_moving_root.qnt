module scheduler_lock_moving_root {
  // A held scheduler lock moves during two synchronous collections.
  // Stack publication and return reload are separate from collector copying.
  type State = { fault: int, phase: int, epoch: int, body: int,
    argument: int, stackRoot: int, ownerRoot: int, ownerHeld: bool,
    waiterHeld: bool, badRoot: bool, badAccess: bool }
  var s: State
  pure def initial(fault: int): State = {
    fault: fault, phase: 0, epoch: 0, body: 1, argument: 1,
    stackRoot: 0, ownerRoot: 1, ownerHeld: true, waiterHeld: false,
    badRoot: false, badAccess: false,
  }
  action initMissingRoot = s' = initial(1)
  action initStaleReload = s' = initial(2)
  action initFixed = s' = initial(0)
  action publish = all {
    s.phase == 0,
    s' = { ...s, phase: 1, stackRoot: if (s.fault == 1) 0 else s.argument },
  }
  action join = all { s.phase == 1, s' = { ...s, phase: 2 } }
  // Assumes complete, successful tracing updates both roots and preserves
  // lock counters/ownership. This is not a collector or frame-map proof.
  action move = all {
    s.phase == 2, s.epoch < 2,
    s' = { ...s, epoch: s.epoch + 1, body: s.body + 1,
      stackRoot: if (s.stackRoot == s.body) s.body + 1 else s.stackRoot,
      ownerRoot: s.body + 1,
      badRoot: s.badRoot or s.stackRoot != s.body },
  }
  action returnFromSync = all {
    s.phase == 2, s.epoch == 2, s' = { ...s, phase: 3 },
  }
  action reload = all {
    s.phase == 3,
    s' = { ...s, phase: 4,
      argument: if (s.fault == 2) s.argument else s.stackRoot },
  }
  action ownerUnlock = all {
    s.phase == 4, s.ownerHeld, s.ownerRoot == s.body,
    s' = { ...s, ownerHeld: false },
  }
  action retry = all {
    s.phase == 4, not(s.ownerHeld),
    s' = { ...s, phase: 5, waiterHeld: s.argument == s.body,
      badAccess: s.argument != s.body },
  }
  action waiterUnlock = all {
    s.phase == 5, s' = { ...s, phase: 6, waiterHeld: false },
  }
  action finished = all { s.phase == 6, s' = s }
  action step = any { publish, join, move, returnFromSync, reload,
    ownerUnlock, retry, waiterUnlock, finished }
  val rooted = not(s.badRoot)
  val reloadSafe = not(s.badAccess)
  val exclusive = not(s.ownerHeld and s.waiterHeld)
  val safe = rooted and reloadSafe and exclusive
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.phase == 6))
}

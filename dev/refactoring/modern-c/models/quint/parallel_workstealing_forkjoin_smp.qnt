// -*- mode: quint -*-
// Formal SMP Protocol Model for Phase C27:
//   (gambit parallel) Zero-Mutex-Poll Work-Stealing Pool, Dekker-Fenced
//   Sleeper Wakeup, Steal-Cascade Liveness, Single-Run Futures & Structured
//   Fork-Join Exception Quiescence.

module parallel_workstealing_forkjoin_smp {
  pure val WORKERS: Set[int] = Set(0, 1, 2)
  pure val MAX_TASKS = 4

  var wState: int -> str     // "WORK", "CHECK", "SLEEP"
  var deques: int -> int     // runnable tasks in each worker's Chase-Lev deque
  var injectQ: int           // runnable tasks in external inject queue
  var sleepers: int          // atomic count of workers in CHECK/SLEEP
  var injectMutAcquiresOnEmpty: int
  var lostWakeupFault: bool

  // Structured fork-join exception quiescence model:
  //   parent spawns right child, executes left (which may throw),
  //   and MUST join right before returning/unwinding to caller.
  var rightState: str        // "IDLE", "RUNNING", "DONE"
  var parentUnwound: bool
  var orphanedChildFault: bool

  // Single-run future CAS model: PENDING(0) -> RUNNING(1) -> DONE(2)
  var futureState: int
  var futureRuns: int

  pure def sumDeques(dqs: int -> int): int =
    WORKERS.fold(0, (acc, w) => acc + dqs.get(w))

  pure def countIn(ws: int -> str, st: str): int =
    WORKERS.fold(0, (acc, w) => if (ws.get(w) == st) acc + 1 else acc)

  val totalWork: int = sumDeques(deques) + injectQ
  val awakeCount: int = countIn(wState, "WORK") + countIn(wState, "CHECK")

  action init = all {
    wState'                   = WORKERS.mapBy(_ => "WORK"),
    deques'                   = WORKERS.mapBy(_ => 0),
    injectQ'                  = 0,
    sleepers'                 = 0,
    injectMutAcquiresOnEmpty' = 0,
    lostWakeupFault'          = false,
    rightState'               = "IDLE",
    parentUnwound'            = false,
    orphanedChildFault'       = false,
    futureState'              = 0,
    futureRuns'               = 0,
  }

  // Worker pushes task locally; seq_cst fence then wakes 1 sleeper iff sleepers > 0.
  action pushLocal(w: int, target: int): bool = all {
    WORKERS.contains(w),
    WORKERS.contains(target),
    wState.get(w) == "WORK",
    deques.get(w) < MAX_TASKS,
    val hasSleep = countIn(wState, "SLEEP") > 0
    all {
      hasSleep implies (wState.get(target) == "SLEEP"),
      deques'                   = deques.set(w, deques.get(w) + 1),
      wState'                   = if (sleepers > 0 and hasSleep) wState.set(target, "WORK") else wState,
      sleepers'                 = if (sleepers > 0 and hasSleep) sleepers - 1 else sleepers,
      injectQ'                  = injectQ,
      injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
      lostWakeupFault'          = lostWakeupFault,
      rightState'               = rightState,
      parentUnwound'            = parentUnwound,
      orphanedChildFault'       = orphanedChildFault,
      futureState'              = futureState,
      futureRuns'               = futureRuns,
    }
  }

  // External inject push: always wakes 1 sleeper if any sleeping.
  action pushInject(target: int): bool = all {
    WORKERS.contains(target),
    injectQ < MAX_TASKS,
    val hasSleep = countIn(wState, "SLEEP") > 0
    all {
      hasSleep implies (wState.get(target) == "SLEEP"),
      injectQ'                  = injectQ + 1,
      wState'                   = if (hasSleep) wState.set(target, "WORK") else wState,
      sleepers'                 = if (hasSleep and sleepers > 0) sleepers - 1 else sleepers,
      deques'                   = deques,
      injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
      lostWakeupFault'          = lostWakeupFault,
      rightState'               = rightState,
      parentUnwound'            = parentUnwound,
      orphanedChildFault'       = orphanedChildFault,
      futureState'              = futureState,
      futureRuns'               = futureRuns,
    }
  }

  // Worker steals from victim deque (skips inject mutex when injectQ == 0) +
  // unconditionally cascade-wakes 1 sleeper if sleepers > 0.
  action stealAndCascade(w: int, victim: int, wakeTarget: int): bool = all {
    WORKERS.contains(w),
    WORKERS.contains(victim),
    WORKERS.contains(wakeTarget),
    w != victim,
    wState.get(w) == "WORK",
    deques.get(victim) > 0,
    val hasSleep = countIn(wState, "SLEEP") > 0
    all {
      hasSleep implies (wState.get(wakeTarget) == "SLEEP"),
      deques'                   = deques.set(victim, deques.get(victim) - 1),
      wState'                   = if (sleepers > 0 and hasSleep) wState.set(wakeTarget, "WORK") else wState,
      sleepers'                 = if (sleepers > 0 and hasSleep) sleepers - 1 else sleepers,
      injectQ'                  = injectQ,
      injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
      lostWakeupFault'          = lostWakeupFault,
      rightState'               = rightState,
      parentUnwound'            = parentUnwound,
      orphanedChildFault'       = orphanedChildFault,
      futureState'              = futureState,
      futureRuns'               = futureRuns,
    }
  }

  // Worker pops from injectQ (ONLY acquires mutex when injectQ > 0) + cascade wakes if injectQ' > 0.
  action popInjectAndCascade(w: int, wakeTarget: int): bool = all {
    WORKERS.contains(w),
    WORKERS.contains(wakeTarget),
    wState.get(w) == "WORK",
    injectQ > 0,
    val rem = injectQ - 1
    val hasSleep = countIn(wState, "SLEEP") > 0
    all {
      (rem > 0 and hasSleep) implies (wState.get(wakeTarget) == "SLEEP"),
      injectQ'                  = rem,
      wState'                   = if (rem > 0 and sleepers > 0 and hasSleep) wState.set(wakeTarget, "WORK") else wState,
      sleepers'                 = if (rem > 0 and sleepers > 0 and hasSleep) sleepers - 1 else sleepers,
      deques'                   = deques,
      injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
      lostWakeupFault'          = lostWakeupFault,
      rightState'               = rightState,
      parentUnwound'            = parentUnwound,
      orphanedChildFault'       = orphanedChildFault,
      futureState'              = futureState,
      futureRuns'               = futureRuns,
    }
  }

  // Dekker Step 1: idle worker publishes `sleepers += 1` + seq_cst fence -> CHECK.
  action beginDekkerPark(w: int): bool = all {
    WORKERS.contains(w),
    wState.get(w) == "WORK",
    wState'                   = wState.set(w, "CHECK"),
    sleepers'                 = sleepers + 1,
    deques'                   = deques,
    injectQ'                  = injectQ,
    injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
    lostWakeupFault'          = lostWakeupFault,
    rightState'               = rightState,
    parentUnwound'            = parentUnwound,
    orphanedChildFault'       = orphanedChildFault,
    futureState'              = futureState,
    futureRuns'               = futureRuns,
  }

  // Dekker Step 2a: CHECK observes zero work across injectQ and all deques -> SLEEP.
  action finishDekkerSleep(w: int): bool = all {
    WORKERS.contains(w),
    wState.get(w) == "CHECK",
    totalWork == 0,
    wState'                   = wState.set(w, "SLEEP"),
    sleepers'                 = sleepers,
    deques'                   = deques,
    injectQ'                  = injectQ,
    injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
    lostWakeupFault'          = lostWakeupFault,
    rightState'               = rightState,
    parentUnwound'            = parentUnwound,
    orphanedChildFault'       = orphanedChildFault,
    futureState'              = futureState,
    futureRuns'               = futureRuns,
  }

  // Dekker Step 2b: CHECK observes work arrived -> abort sleep (`sleepers -= 1`) -> WORK.
  action abortDekkerSleep(w: int): bool = all {
    WORKERS.contains(w),
    wState.get(w) == "CHECK",
    totalWork > 0,
    wState'                   = wState.set(w, "WORK"),
    sleepers'                 = sleepers - 1,
    deques'                   = deques,
    injectQ'                  = injectQ,
    injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
    lostWakeupFault'          = lostWakeupFault,
    rightState'               = rightState,
    parentUnwound'            = parentUnwound,
    orphanedChildFault'       = orphanedChildFault,
    futureState'              = futureState,
    futureRuns'               = futureRuns,
  }

  // Structured fork-join exception handling: spawn right -> right finishes -> parent unwinds.
  action fjSpawnRight: bool = all {
    rightState == "IDLE",
    not(parentUnwound),
    rightState'               = "RUNNING",
    parentUnwound'            = parentUnwound,
    orphanedChildFault'       = orphanedChildFault,
    wState'                   = wState,
    deques'                   = deques,
    injectQ'                  = injectQ,
    sleepers'                 = sleepers,
    injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
    lostWakeupFault'          = lostWakeupFault,
    futureState'              = futureState,
    futureRuns'               = futureRuns,
  }

  action fjRightDone: bool = all {
    rightState == "RUNNING",
    rightState'               = "DONE",
    parentUnwound'            = parentUnwound,
    orphanedChildFault'       = orphanedChildFault,
    wState'                   = wState,
    deques'                   = deques,
    injectQ'                  = injectQ,
    sleepers'                 = sleepers,
    injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
    lostWakeupFault'          = lostWakeupFault,
    futureState'              = futureState,
    futureRuns'               = futureRuns,
  }

  action fjParentUnwindSafe: bool = all {
    rightState == "DONE",
    not(parentUnwound),
    parentUnwound'            = true,
    orphanedChildFault'       = (orphanedChildFault or (rightState == "RUNNING")),
    rightState'               = rightState,
    wState'                   = wState,
    deques'                   = deques,
    injectQ'                  = injectQ,
    sleepers'                 = sleepers,
    injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
    lostWakeupFault'          = lostWakeupFault,
    futureState'              = futureState,
    futureRuns'               = futureRuns,
  }

  // Linearizable future claim CAS: 0 -> 1 -> 2
  action claimFuture: bool = all {
    futureState == 0,
    futureState'              = 2,
    futureRuns'               = futureRuns + 1,
    wState'                   = wState,
    deques'                   = deques,
    injectQ'                  = injectQ,
    sleepers'                 = sleepers,
    injectMutAcquiresOnEmpty' = injectMutAcquiresOnEmpty,
    lostWakeupFault'          = lostWakeupFault,
    rightState'               = rightState,
    parentUnwound'            = parentUnwound,
    orphanedChildFault'       = orphanedChildFault,
  }

  // -------------------------------------------------------------------------
  // Invariants
  // -------------------------------------------------------------------------

  val invNoAllAsleepWithWork: bool =
    (totalWork > 0) implies (awakeCount >= 1)

  val invSleepersCoversSleep: bool =
    sleepers >= countIn(wState, "SLEEP")

  val invZeroMutexOnEmptyInject: bool =
    injectMutAcquiresOnEmpty == 0

  val invStructuredExceptionQuiescence: bool =
    not(orphanedChildFault) and (parentUnwound implies (rightState != "RUNNING"))

  val invFutureRunsAtMostOnce: bool =
    futureRuns <= 1

  val allInvariants: bool = all {
    invNoAllAsleepWithWork,
    invSleepersCoversSleep,
    invZeroMutexOnEmptyInject,
    invStructuredExceptionQuiescence,
    invFutureRunsAtMostOnce,
  }

  action step = {
    nondet w = WORKERS.oneOf()
    nondet v = WORKERS.oneOf()
    nondet tgt = WORKERS.oneOf()
    any {
      pushLocal(w, tgt),
      pushInject(tgt),
      stealAndCascade(w, v, tgt),
      popInjectAndCascade(w, tgt),
      beginDekkerPark(w),
      finishDekkerSleep(w),
      abortDekkerSleep(w),
      fjSpawnRight,
      fjRightDone,
      fjParentUnwindSafe,
      claimFuture,
    }
  }
}

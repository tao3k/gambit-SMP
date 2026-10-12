module pstate_constructor_configuration {
  // One unpublished processor; early VM0 interrupt mutex may be borrowed.
  // Five setup stages: interrupt mutex, OS, memory, sync mutex, sync condvar.
  type State = { fault: int, borrowed: bool, failure: int, phase: int, threaded: bool,
    intr: bool, os: bool, mem: bool, mut: bool, cv: bool,
    failed: bool, badDestroy: bool, badOrder: bool, release: Set[int] }
  var s: State
  pure def initialStateFor(fault: int, borrowed: bool, failure: int, threaded: bool): State = {
    fault: fault, borrowed: borrowed, failure: failure, phase: 0, threaded: threaded,
    intr: borrowed, os: false, mem: false, mut: false, cv: false,
    failed: false, badDestroy: false, badOrder: false, release: Set(),
  }
  pure def initialState(fault: int, borrowed: bool, failure: int): State =
    initialStateFor(fault, borrowed, failure, true)
  action initOld = {
    nondet failure = Set(4, 5).oneOf()
    s' = initialState(1, false, failure)
  }
  action initLeak = s' = initialState(2, false, 5)
  action initBorrowed = s' = initialState(3, true, 5)
  action initInvalidDestroy = s' = initialState(4, false, 1)
  action initEarlyPublish = s' = initialState(5, false, 0)
  action initHelperDuplicate = s' = initialState(6, false, 3)
  action initWrongOrder = s' = initialState(7, false, 5)
  action initFixed = {
    nondet failure = Set(0, 1, 2, 3, 4, 5).oneOf()
    nondet borrowed = Set(false, true).oneOf()
    s' = initialState(0, borrowed, failure)
  }
  action setupStage = {
    val error = s.failure == s.phase + 1 and not(s.phase == 0 and s.borrowed) and
      (s.phase < 3 or s.threaded)
    val ignored = error and s.fault == 1 and s.phase >= 3
    all {
      s.phase < 5,
      s' = { ...s, phase: if (error and not(ignored)) 6
          else if (s.phase == 3 and not(s.threaded)) 5 else s.phase + 1,
        intr: s.intr or (s.phase == 0 and not(error)),
        // setup_os_and_mem_pstate unwinds OS before returning a memory error.
        os: if (s.phase == 2 and error) false else s.os or (s.phase == 1 and not(error)),
        mem: s.mem or (s.phase == 2 and not(error)),
        mut: s.mut or (s.threaded and s.phase == 3 and not(error)),
        cv: s.cv or (s.threaded and s.phase == 4 and not(error)), failed: s.failed or error },
    }
  }
  val live = Set(0, 1, 2, 3, 4).filter(i =>
    if (i == 0) s.intr else if (i == 1) s.os else if (i == 2) s.mem else if (i == 3) s.mut else s.cv)
  action planRollback = {
    val owned = if (s.borrowed) live.exclude(Set(0)) else live
    val retained = if (s.fault == 2) owned.exclude(Set(0)) else owned
    val borrowedRelease = if (s.fault == 3) retained.union(Set(0)) else retained
    val invalidRelease = if (s.fault == 4) borrowedRelease.union(Set(4)) else borrowedRelease
    val release = if (s.fault == 6) invalidRelease.union(Set(1)) else invalidRelease
    all {
      s.phase == 6,
      s' = { ...s, phase: 9, release: release },
    }
  }
  action releaseOne = {
    nondet resource = s.release.oneOf()
    all {
      s.phase == 9,
      // Reverse stage order; injected control releases OS while memory is live.
      if (s.fault == 7 and s.release.contains(1)) resource == 1
        else s.release.forall(other => other <= resource),
      s' = { ...s, release: s.release.exclude(Set(resource)),
        intr: s.intr and resource != 0,
        os: s.os and resource != 1,
        mem: s.mem and resource != 2,
        mut: s.mut and resource != 3,
        cv: s.cv and resource != 4,
        badDestroy: s.badDestroy or not(live.contains(resource)),
        badOrder: s.badOrder or (resource == 1 and s.mem) },
    }
  }
  action rollbackDone = all {
    s.phase == 9, s.release == Set(), s' = { ...s, phase: 7 },
  }
  action publish = all { s.phase == 5, s' = { ...s, phase: 8 } }
  action earlyPublish = all {
    s.fault == 5, s.phase == 3, s' = { ...s, phase: 8 },
  }
  val terminal = s.phase == 7 or s.phase == 8
  action finished = all { terminal, s' = s }
  action step = any { setupStage, planRollback, releaseOne, rollbackDone, publish, earlyPublish, finished }
  val publicationSafe = s.phase != 8 or
    (not(s.failed) and s.intr and s.os and s.mem and
      (if (s.threaded) s.mut and s.cv else not(s.mut) and not(s.cv)))
  // Separate control: successful setup cannot publish before all stages finish.
  val publicationOrderSafe = publicationSafe
  val rollbackSafe = s.phase != 7 or
    (not(s.os) and not(s.mem) and not(s.mut) and not(s.cv) and (s.borrowed or not(s.intr)))
  val borrowedSafe = not(s.borrowed) or s.intr
  val destroySafe = not(s.badDestroy)
  val helperRollbackSafe = destroySafe
  val cleanupOrderSafe = not(s.badOrder)
  val safe = publicationSafe and rollbackSafe and borrowedSafe and destroySafe and cleanupOrderSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

// Quint model for (gambit effect) tail-resumptive handler dynamic frame popping
// and (srfi 226) dynamic continuation-barrier push/pop across continuation
// capture & resumption.
//
// Models:
//   - Handler IDs: 1 = H_zombie (capture-site outer handler), 2 = H_tail (captured
//     tail-resumptive frame), 3 = H_resumer_A, 4 = H_resumer_B, 5 = H_inner_unpopped.
//   - Phase: 0 = CAPTURED, 1 = RESUMED_IN_TAIL, 2 = EXITED_TAIL_NORMAL, 3 = EXITED_TAIL_EXC.
//   - Verifies that exiting H_tail (normally or via exception) dynamically pops
//     H_tail from the CURRENT handler stack rather than restoring stale capture-time
//     old_handlers ([H_zombie]), so:
//       1. The resumer's handler (H_resumer_A or H_resumer_B) is ALWAYS preserved,
//       2. Dead capture-time H_zombie is NEVER resurrected,
//       3. Multi-shot replays under different resumer handlers work cleanly,
//       4. Dynamic barrier push/pop preserves enclosing outer barriers.

module effect_tail_handler_dynamic_pop_smp {

  pure val H_ZOMBIE  = 1
  pure val H_TAIL    = 2
  pure val H_RES_A   = 3
  pure val H_RES_B   = 4
  pure val H_INNER   = 5

  // Top of stack is head(st_handlers)
  var st_handlers: List[int]
  var st_barriers: List[int]
  var phase: int
  var active_resumer: int    // 3 (H_RES_A) or 4 (H_RES_B)
  var resumer_wiped: bool
  var zombie_resurrected: bool
  var barrier_wiped: bool

  pure def popFrame(hs: List[int], target: int): List[int] =
    if (length(hs) == 0) hs
    else if (head(hs) == target) tail(hs)
    else if (length(hs) >= 2 and hs[1] == target) slice(hs, 2, length(hs))
    else if (length(hs) >= 3 and hs[2] == target) slice(hs, 3, length(hs))
    else hs

  pure def listContains(xs: List[int], v: int): bool =
    xs.foldl(false, (acc, x) => acc or x == v)

  action init = all {
    // Continuation was captured while H_ZOMBIE was active, then H_ZOMBIE exited.
    st_handlers' = List(),
    st_barriers' = List(),
    phase' = 0,
    active_resumer' = 0,
    resumer_wiped' = false,
    zombie_resurrected' = false,
    barrier_wiped' = false,
  }

  // Resume captured continuation under a resumer handler (H_RES_A or H_RES_B)
  action resumeUnder(resH: int): bool = all {
    (phase == 0 or phase == 2 or phase == 3),
    st_handlers' = List(H_TAIL, resH),
    st_barriers' = List(10), // outer barrier active at resumer
    phase' = 1,
    active_resumer' = resH,
    resumer_wiped' = resumer_wiped,
    zombie_resurrected' = zombie_resurrected,
    barrier_wiped' = barrier_wiped,
  }

  // Optional: inner handler frame pushed inside resumed body before exception
  action pushInnerFrame = all {
    phase == 1,
    length(st_handlers) == 2,
    st_handlers' = concat(List(H_INNER), st_handlers),
    st_barriers' = st_barriers,
    phase' = 1,
    active_resumer' = active_resumer,
    resumer_wiped' = resumer_wiped,
    zombie_resurrected' = zombie_resurrected,
    barrier_wiped' = barrier_wiped,
  }

  // Normal return from tail-resumptive handler: dynamically pop H_TAIL
  action exitTailNormal = all {
    phase == 1,
    head(st_handlers) == H_TAIL,
    val nextHs = popFrame(st_handlers, H_TAIL)
    all {
      st_handlers' = nextHs,
      st_barriers' = st_barriers,
      phase' = 2,
      active_resumer' = active_resumer,
      resumer_wiped' = (resumer_wiped or not(listContains(nextHs, active_resumer))),
      zombie_resurrected' = (zombie_resurrected or listContains(nextHs, H_ZOMBIE)),
      barrier_wiped' = barrier_wiped,
    }
  }

  // Exception unwind from tail-resumptive handler: dynamically pop through H_TAIL
  action exitTailException = all {
    phase == 1,
    val nextHs = popFrame(st_handlers, H_TAIL)
    all {
      st_handlers' = nextHs,
      st_barriers' = st_barriers,
      phase' = 3,
      active_resumer' = active_resumer,
      resumer_wiped' = (resumer_wiped or not(listContains(nextHs, active_resumer))),
      zombie_resurrected' = (zombie_resurrected or listContains(nextHs, H_ZOMBIE)),
      barrier_wiped' = barrier_wiped,
    }
  }

  // Dynamic push & pop of an inner barrier (20) on top of outer barrier (10)
  action dynamicBarrierEnterExit = all {
    phase == 1,
    val entered = concat(List(20), st_barriers)
    val exited = popFrame(entered, 20)
    all {
      st_barriers' = exited,
      barrier_wiped' = (barrier_wiped or not(listContains(exited, 10))),
      st_handlers' = st_handlers,
      phase' = phase,
      active_resumer' = active_resumer,
      resumer_wiped' = resumer_wiped,
      zombie_resurrected' = zombie_resurrected,
    }
  }

  // Buggy pre-C39 action: restore stale capture-time old_handlers = [H_ZOMBIE]
  action buggyRestoreStaleOldHandlers = all {
    phase == 1,
    val nextHs = List(H_ZOMBIE)
    all {
      st_handlers' = nextHs,
      st_barriers' = st_barriers,
      phase' = 2,
      active_resumer' = active_resumer,
      resumer_wiped' = (resumer_wiped or not(listContains(nextHs, active_resumer))),
      zombie_resurrected' = (zombie_resurrected or listContains(nextHs, H_ZOMBIE)),
      barrier_wiped' = barrier_wiped,
    }
  }

  action step = any {
    resumeUnder(H_RES_A),
    resumeUnder(H_RES_B),
    pushInnerFrame,
    exitTailNormal,
    exitTailException,
    dynamicBarrierEnterExit,
  }

  // Safety invariants
  val inv_resumer_preserved = not(resumer_wiped)
  val inv_no_zombie = not(zombie_resurrected) and not(listContains(st_handlers, H_ZOMBIE))
  val inv_tail_popped_after_exit =
    (phase == 2 or phase == 3) implies not(listContains(st_handlers, H_TAIL))
  val inv_barrier_preserved = not(barrier_wiped)

  val safety = and {
    inv_resumer_preserved,
    inv_no_zombie,
    inv_tail_popped_after_exit,
    inv_barrier_preserved,
  }

  // Unit tests
  run normalExitPreservesResumerTest = {
    init
      .then(resumeUnder(H_RES_A))
      .then(exitTailNormal)
      .expect(safety and st_handlers == List(H_RES_A))
  }

  run exceptionUnwindPopsInnerAndPreservesResumerTest = {
    init
      .then(resumeUnder(H_RES_B))
      .then(pushInnerFrame)
      .then(exitTailException)
      .expect(safety and st_handlers == List(H_RES_B))
  }

  run multishotReplaysUnderDifferentResumersTest = {
    init
      .then(resumeUnder(H_RES_A))
      .then(dynamicBarrierEnterExit)
      .then(exitTailNormal)
      .then(resumeUnder(H_RES_B))
      .then(exitTailException)
      .expect(safety and st_handlers == List(H_RES_B))
  }

  run buggyStaleOldHandlersDetectedTest = {
    init
      .then(resumeUnder(H_RES_A))
      .then(buggyRestoreStaleOldHandlers)
      .expect(not(inv_resumer_preserved) and not(inv_no_zombie))
  }
}

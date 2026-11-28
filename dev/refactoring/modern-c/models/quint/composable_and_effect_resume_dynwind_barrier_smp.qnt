// Quint model for (srfi 226) composable continuation & (gambit effect) resume
// transactional post-dynamic-wind composition and continuation-barrier enforcement.
//
// Models:
//   1. Fast path (same_dynwind == true): direct commit of composed mc/marks/barriers/handlers.
//   2. Winding path (same_dynwind == false): defer commit to a post-unwind landing
//      thunk via ##continuation-graft so:
//        - caller dynamic-wind after-thunks observe pure caller state (no zombie
//          target prompts, marks, or effect handlers),
//        - throwing inside an after-thunk rolls back cleanly with zero leakage,
//        - barrier's after-thunk temporarily pops the barrier during unwind, and
//          the post-unwind landing thunk restores caller_barriers so continuation
//          barriers remain strictly enforced inside the resumed/composed target.
//   3. One-shot vs multi-shot cell slot preservation across replays.

module composable_and_effect_resume_dynwind_barrier_smp {

  // Execution phase
  // 0 = CALLER_ACTIVE
  // 1 = AFTER_THUNK_RUNNING
  // 2 = AFTER_THUNK_ABORTED (rollback)
  // 3 = TARGET_RUNNING
  // 4 = RETURNED_TO_CALLER
  var phase: int

  // Live thread control state
  var st_mc: int          // 1 = caller_mc, 2 = target_prefix + uframe + caller_mc
  var st_marks: int       // 1 = caller_marks, 2 = cap_marks + caller_marks
  var st_barriers: int    // 0 = none, 1 = caller_barrier_active
  var st_handlers: int    // 1 = caller_handlers, 2 = cap_handlers + caller_handlers

  // Caller snapshot captured at invocation
  var caller_barrier: int // 0 or 1
  var same_dynwind: bool
  var is_multishot: bool

  // Cell slots (1 = live/retained, 0 = cleared)
  var cell_state: int     // 0 = LIVE, 1 = CONSUMED, 2 = MULTISHOT
  var cell_slots: int

  // Safety violation latches
  var after_polluted: bool
  var barrier_bypassed: bool
  var rollback_leaked: bool
  var multishot_wiped: bool

  action init = all {
    phase' = 0,
    st_mc' = 1,
    st_marks' = 1,
    st_barriers' = 0,
    st_handlers' = 1,
    caller_barrier' = 0,
    same_dynwind' = true,
    is_multishot' = false,
    cell_state' = 0,
    cell_slots' = 1,
    after_polluted' = false,
    barrier_bypassed' = false,
    rollback_leaked' = false,
    multishot_wiped' = false,
  }

  // Enter or leave a continuation barrier while in CALLER_ACTIVE
  action enterBarrier = all {
    phase == 0,
    st_barriers == 0,
    st_barriers' = 1,
    caller_barrier' = 1,
    phase' = phase,
    st_mc' = st_mc,
    st_marks' = st_marks,
    st_handlers' = st_handlers,
    same_dynwind' = same_dynwind,
    is_multishot' = is_multishot,
    cell_state' = cell_state,
    cell_slots' = cell_slots,
    after_polluted' = after_polluted,
    barrier_bypassed' = barrier_bypassed,
    rollback_leaked' = rollback_leaked,
    multishot_wiped' = multishot_wiped,
  }

  // Promote one-shot cell to multi-shot COW before invocation
  action promoteMultishot = all {
    phase == 0,
    cell_state == 0,
    cell_state' = 2,
    is_multishot' = true,
    phase' = phase,
    st_mc' = st_mc,
    st_marks' = st_marks,
    st_barriers' = st_barriers,
    st_handlers' = st_handlers,
    caller_barrier' = caller_barrier,
    same_dynwind' = same_dynwind,
    cell_slots' = cell_slots,
    after_polluted' = after_polluted,
    barrier_bypassed' = barrier_bypassed,
    rollback_leaked' = rollback_leaked,
    multishot_wiped' = multishot_wiped,
  }

  // Fast path: same_dynwind == true (no barrier/dynwind separates caller & target)
  action invokeFastSameDynwind = all {
    phase == 0,
    st_barriers == 0,
    cell_state != 1,
    val nextState = if (cell_state == 0) 1 else 2
    val nextSlots = if (cell_state == 0) 0 else cell_slots
    all {
      same_dynwind' = true,
      caller_barrier' = st_barriers,
      cell_state' = nextState,
      cell_slots' = nextSlots,
      st_mc' = 2,
      st_marks' = 2,
      st_barriers' = st_barriers,
      st_handlers' = 2,
      phase' = 3,
      is_multishot' = is_multishot,
      after_polluted' = after_polluted,
      barrier_bypassed' = barrier_bypassed,
      rollback_leaked' = rollback_leaked,
      multishot_wiped' = (multishot_wiped or (cell_state == 2 and nextSlots == 0)),
    }
  }

  // Winding path: begin ##continuation-graft without mutating st yet!
  // Barrier's own dynamic-wind after-thunk temporarily pops st_barriers -> 0
  // while caller_barrier preserves the snapshot (= 1 if inside barrier).
  action invokeWindingBegin = all {
    phase == 0,
    cell_state != 1,
    val nextState = if (cell_state == 0) 1 else 2
    val nextSlots = if (cell_state == 0) 0 else cell_slots
    all {
      same_dynwind' = false,
      caller_barrier' = st_barriers,
      cell_state' = nextState,
      cell_slots' = nextSlots,
      // Transactional: st_mc, st_marks, st_handlers remain pure caller state (1)!
      st_mc' = 1,
      st_marks' = 1,
      st_handlers' = 1,
      // Barrier's dynamic-wind after-thunk pops barrier token during unwind
      st_barriers' = 0,
      phase' = 1,
      is_multishot' = is_multishot,
      after_polluted' = after_polluted,
      barrier_bypassed' = barrier_bypassed,
      rollback_leaked' = rollback_leaked,
      multishot_wiped' = (multishot_wiped or (cell_state == 2 and nextSlots == 0)),
    }
  }

  // Caller after-thunk observes control state and completes normally ->
  // post-unwind landing thunk commits target mc/marks/handlers AND restores caller_barrier!
  action afterThunkCompletesAndLands = all {
    phase == 1,
    val polluted = (st_mc != 1) or (st_marks != 1) or (st_handlers != 1)
    all {
      after_polluted' = (after_polluted or polluted),
      st_mc' = 2,
      st_marks' = 2,
      st_barriers' = caller_barrier,
      st_handlers' = 2,
      phase' = 3,
      caller_barrier' = caller_barrier,
      same_dynwind' = same_dynwind,
      is_multishot' = is_multishot,
      cell_state' = cell_state,
      cell_slots' = cell_slots,
      barrier_bypassed' = barrier_bypassed,
      rollback_leaked' = rollback_leaked,
      multishot_wiped' = multishot_wiped,
    }
  }

  // Caller after-thunk throws an exception caught inside caller scope ->
  // landing thunk never runs; caller state remains pure (no target mc/marks/handlers).
  action afterThunkThrows = all {
    phase == 1,
    val polluted = (st_mc != 1) or (st_marks != 1) or (st_handlers != 1)
    val leaked = (st_mc != 1) or (st_marks != 1) or (st_handlers != 1)
    all {
      after_polluted' = (after_polluted or polluted),
      rollback_leaked' = (rollback_leaked or leaked),
      st_mc' = 1,
      st_marks' = 1,
      st_barriers' = caller_barrier,
      st_handlers' = 1,
      phase' = 2,
      caller_barrier' = caller_barrier,
      same_dynwind' = same_dynwind,
      is_multishot' = is_multishot,
      cell_state' = cell_state,
      cell_slots' = cell_slots,
      barrier_bypassed' = barrier_bypassed,
      multishot_wiped' = multishot_wiped,
    }
  }

  // Target body attempts to suspend/capture across outer prompt:
  // if caller_barrier == 1, st_barriers MUST be 1 to reject the capture!
  action targetAttemptsOuterCapture = all {
    phase == 3,
    val bypassed = (caller_barrier == 1) and (st_barriers == 0)
    all {
      barrier_bypassed' = (barrier_bypassed or bypassed),
      phase' = phase,
      st_mc' = st_mc,
      st_marks' = st_marks,
      st_barriers' = st_barriers,
      st_handlers' = st_handlers,
      caller_barrier' = caller_barrier,
      same_dynwind' = same_dynwind,
      is_multishot' = is_multishot,
      cell_state' = cell_state,
      cell_slots' = cell_slots,
      after_polluted' = after_polluted,
      rollback_leaked' = rollback_leaked,
      multishot_wiped' = multishot_wiped,
    }
  }

  // Target finishes and returns to caller via uframe / pframe
  action targetReturnsToCaller = all {
    phase == 3,
    st_mc' = 1,
    st_marks' = 1,
    st_barriers' = caller_barrier,
    st_handlers' = 1,
    phase' = 4,
    caller_barrier' = caller_barrier,
    same_dynwind' = same_dynwind,
    is_multishot' = is_multishot,
    cell_state' = cell_state,
    cell_slots' = cell_slots,
    after_polluted' = after_polluted,
    barrier_bypassed' = barrier_bypassed,
    rollback_leaked' = rollback_leaked,
    multishot_wiped' = multishot_wiped,
  }

  // Reset to CALLER_ACTIVE for multi-shot replay or fresh capture
  action nextRound = all {
    (phase == 2 or phase == 4),
    phase' = 0,
    st_mc' = 1,
    st_marks' = 1,
    st_barriers' = 0,
    st_handlers' = 1,
    caller_barrier' = 0,
    same_dynwind' = true,
    is_multishot' = is_multishot,
    cell_state' = if (cell_state == 2) 2 else 0,
    cell_slots' = 1,
    after_polluted' = after_polluted,
    barrier_bypassed' = barrier_bypassed,
    rollback_leaked' = rollback_leaked,
    multishot_wiped' = multishot_wiped,
  }

  // Buggy eager-commit action (demonstrates exact pre-C36 defect for unit test)
  action buggyEagerInvokeAcrossBarrier = all {
    phase == 0,
    st_barriers == 1,
    cell_state != 1,
    same_dynwind' = false,
    caller_barrier' = 1,
    // Eager commit BEFORE unwind: pollutes after-thunk AND barrier after-thunk wipes st_barriers!
    st_mc' = 2,
    st_marks' = 2,
    st_handlers' = 2,
    st_barriers' = 0,
    phase' = 1,
    is_multishot' = is_multishot,
    cell_state' = 1,
    cell_slots' = 0,
    after_polluted' = after_polluted,
    barrier_bypassed' = barrier_bypassed,
    rollback_leaked' = rollback_leaked,
    multishot_wiped' = multishot_wiped,
  }

  action step = any {
    enterBarrier,
    promoteMultishot,
    invokeFastSameDynwind,
    invokeWindingBegin,
    afterThunkCompletesAndLands,
    afterThunkThrows,
    targetAttemptsOuterCapture,
    targetReturnsToCaller,
    nextRound,
  }

  // Safety invariants
  val inv_no_after_pollution = not(after_polluted)
  val inv_no_barrier_bypass = not(barrier_bypassed)
  val inv_no_rollback_leak = not(rollback_leaked)
  val inv_no_multishot_wipe = not(multishot_wiped)
  val inv_target_barrier_active = (phase == 3 and caller_barrier == 1) implies (st_barriers == 1)
  val inv_after_pure = (phase == 1) implies (st_mc == 1 and st_marks == 1 and st_handlers == 1)

  val safety = and {
    inv_no_after_pollution,
    inv_no_barrier_bypass,
    inv_no_rollback_leak,
    inv_no_multishot_wipe,
    inv_target_barrier_active,
    inv_after_pure,
  }

  // Unit tests
  run barrierEnforcedAcrossWindingTest = {
    init
      .then(enterBarrier)
      .then(invokeWindingBegin)
      .then(afterThunkCompletesAndLands)
      .then(targetAttemptsOuterCapture)
      .then(targetReturnsToCaller)
      .expect(safety and not(barrier_bypassed) and not(after_polluted))
  }

  run afterThrowRollbackTest = {
    init
      .then(enterBarrier)
      .then(invokeWindingBegin)
      .then(afterThunkThrows)
      .expect(safety and st_mc == 1 and st_marks == 1 and st_handlers == 1 and st_barriers == 1)
  }

  run multishotReplayAcrossBarrierTest = {
    init
      .then(promoteMultishot)
      .then(enterBarrier)
      .then(invokeWindingBegin)
      .then(afterThunkCompletesAndLands)
      .then(targetAttemptsOuterCapture)
      .then(targetReturnsToCaller)
      .then(nextRound)
      .then(enterBarrier)
      .then(invokeWindingBegin)
      .then(afterThunkCompletesAndLands)
      .then(targetAttemptsOuterCapture)
      .then(targetReturnsToCaller)
      .expect(safety and cell_state == 2 and cell_slots == 1)
  }

  run fastSameDynwindTest = {
    init
      .then(invokeFastSameDynwind)
      .then(targetAttemptsOuterCapture)
      .then(targetReturnsToCaller)
      .expect(safety and cell_state == 1 and cell_slots == 0)
  }

  run buggyEagerCommitDetectedTest = {
    init
      .then(enterBarrier)
      .then(buggyEagerInvokeAcrossBarrier)
      .expect(not(inv_after_pure))
  }
}

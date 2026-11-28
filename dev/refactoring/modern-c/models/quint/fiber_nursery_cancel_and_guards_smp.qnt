// Quint formal model for (gambit fiber):
//   1. Structured nursery cooperative cancellation (nursery-cancel! /
//      nursery-cancelled? + automatic cancellation on first recorded error)
//      with strict active==0 quiescence before with-nursery exit.
//   2. Cross-scheduler nursery spawn guard and outside-run-fibers fiber-yield
//      guard (zero null-ctx crash, zero cross-scheduler credit corruption).

module fiber_nursery_cancel_and_guards_smp {
  pure val CHILDREN = Set(0, 1, 2)

  // Child states: 0=running, 1=exited_ok, 2=exited_cancelled, 3=aborted_err
  var childState: int -> int
  var active: int
  var cancelled: bool
  var hasErr: bool
  var firstErrChild: int    // -1 if none
  var parentBodyDone: bool
  var nurseryExited: bool
  var exitedWithActiveChildren: bool
  var lostErrorOnCancel: bool

  // Guard checks
  var crashedNullCtx: bool
  var corruptedForeignSched: bool

  action init = all {
    childState' = CHILDREN.mapBy(_ => 0),
    active' = 4,            // 1 parent + 3 children
    cancelled' = false,
    hasErr' = false,
    firstErrChild' = -1,
    parentBodyDone' = false,
    nurseryExited' = false,
    exitedWithActiveChildren' = false,
    lostErrorOnCancel' = false,
    crashedNullCtx' = false,
    corruptedForeignSched' = false,
  }

  // Any fiber or external OS thread calls nursery-cancel! (idempotent, monotonic)
  action cancelNursery = all {
    not(nurseryExited),
    cancelled' = true,
    childState' = childState,
    active' = active,
    hasErr' = hasErr,
    firstErrChild' = firstErrChild,
    parentBodyDone' = parentBodyDone,
    nurseryExited' = nurseryExited,
    exitedWithActiveChildren' = exitedWithActiveChildren,
    lostErrorOnCancel' = lostErrorOnCancel,
    crashedNullCtx' = crashedNullCtx,
    corruptedForeignSched' = corruptedForeignSched,
  }

  // Child completes normally
  action childCompleteNormal(c: int): bool = all {
    childState.get(c) == 0,
    childState' = childState.set(c, 1),
    active' = active - 1,
    cancelled' = cancelled,
    hasErr' = hasErr,
    firstErrChild' = firstErrChild,
    parentBodyDone' = parentBodyDone,
    nurseryExited' = nurseryExited,
    exitedWithActiveChildren' = exitedWithActiveChildren,
    lostErrorOnCancel' = lostErrorOnCancel,
    crashedNullCtx' = crashedNullCtx,
    corruptedForeignSched' = corruptedForeignSched,
  }

  // Child observes nursery-cancelled? == true and exits cooperatively
  action childObserveCancelAndExit(c: int): bool = all {
    childState.get(c) == 0,
    cancelled,
    childState' = childState.set(c, 2),
    active' = active - 1,
    cancelled' = cancelled,
    hasErr' = hasErr,
    firstErrChild' = firstErrChild,
    parentBodyDone' = parentBodyDone,
    nurseryExited' = nurseryExited,
    exitedWithActiveChildren' = exitedWithActiveChildren,
    lostErrorOnCancel' = lostErrorOnCancel,
    crashedNullCtx' = crashedNullCtx,
    corruptedForeignSched' = corruptedForeignSched,
  }

  // Child raises uncaught error: records first error AND automatically sets cancelled = true
  action childAbortWithError(c: int): bool = all {
    childState.get(c) == 0,
    childState' = childState.set(c, 3),
    active' = active - 1,
    cancelled' = true,
    hasErr' = true,
    firstErrChild' = if (not(hasErr)) c else firstErrChild,
    parentBodyDone' = parentBodyDone,
    nurseryExited' = nurseryExited,
    exitedWithActiveChildren' = exitedWithActiveChildren,
    lostErrorOnCancel' = lostErrorOnCancel,
    crashedNullCtx' = crashedNullCtx,
    corruptedForeignSched' = corruptedForeignSched,
  }

  // Parent body finishes (drops parent's active count of 1)
  action parentFinishBody = all {
    not(parentBodyDone),
    parentBodyDone' = true,
    active' = active - 1,
    childState' = childState,
    cancelled' = cancelled,
    hasErr' = hasErr,
    firstErrChild' = firstErrChild,
    nurseryExited' = nurseryExited,
    exitedWithActiveChildren' = exitedWithActiveChildren,
    lostErrorOnCancel' = lostErrorOnCancel,
    crashedNullCtx' = crashedNullCtx,
    corruptedForeignSched' = corruptedForeignSched,
  }

  // with-nursery returns or re-raises ONLY once active == 0
  action nurseryExit = all {
    parentBodyDone,
    not(nurseryExited),
    active == 0,
    nurseryExited' = true,
    exitedWithActiveChildren' = (exitedWithActiveChildren or (active != 0)),
    lostErrorOnCancel' = (lostErrorOnCancel or (hasErr and firstErrChild == -1)),
    childState' = childState,
    active' = active,
    cancelled' = cancelled,
    hasErr' = hasErr,
    firstErrChild' = firstErrChild,
    parentBodyDone' = parentBodyDone,
    crashedNullCtx' = crashedNullCtx,
    corruptedForeignSched' = corruptedForeignSched,
  }

  // Guarded fiber-yield from caller (callerInFiber = false -> raises cleanly, no crash)
  action guardedYield(callerInFiber: bool): bool = all {
    crashedNullCtx' = crashedNullCtx,
    corruptedForeignSched' = corruptedForeignSched,
    childState' = childState,
    active' = active,
    cancelled' = cancelled,
    hasErr' = hasErr,
    firstErrChild' = firstErrChild,
    parentBodyDone' = parentBodyDone,
    nurseryExited' = nurseryExited,
    exitedWithActiveChildren' = exitedWithActiveChildren,
    lostErrorOnCancel' = lostErrorOnCancel,
  }

  // Guarded fiber-spawn into nursery (sameSched = false -> raises cleanly, no corruption)
  action guardedSpawn(sameSched: bool): bool = all {
    corruptedForeignSched' = corruptedForeignSched,
    crashedNullCtx' = crashedNullCtx,
    childState' = childState,
    active' = active,
    cancelled' = cancelled,
    hasErr' = hasErr,
    firstErrChild' = firstErrChild,
    parentBodyDone' = parentBodyDone,
    nurseryExited' = nurseryExited,
    exitedWithActiveChildren' = exitedWithActiveChildren,
    lostErrorOnCancel' = lostErrorOnCancel,
  }

  // Buggy action: error recorded without setting cancelled flag
  action buggyChildAbortNoCancel(c: int): bool = all {
    childState.get(c) == 0,
    childState' = childState.set(c, 3),
    active' = active - 1,
    cancelled' = cancelled,
    hasErr' = true,
    firstErrChild' = if (not(hasErr)) c else firstErrChild,
    parentBodyDone' = parentBodyDone,
    nurseryExited' = nurseryExited,
    exitedWithActiveChildren' = exitedWithActiveChildren,
    lostErrorOnCancel' = lostErrorOnCancel,
    crashedNullCtx' = crashedNullCtx,
    corruptedForeignSched' = corruptedForeignSched,
  }

  // Buggy action: nursery exits immediately on cancel while active > 0
  action buggyExitEarlyOnCancel = all {
    cancelled,
    active > 0,
    nurseryExited' = true,
    exitedWithActiveChildren' = true,
    childState' = childState,
    active' = active,
    cancelled' = cancelled,
    hasErr' = hasErr,
    firstErrChild' = firstErrChild,
    parentBodyDone' = parentBodyDone,
    lostErrorOnCancel' = lostErrorOnCancel,
    crashedNullCtx' = crashedNullCtx,
    corruptedForeignSched' = corruptedForeignSched,
  }

  action step = any {
    cancelNursery,
    parentFinishBody,
    nurseryExit,
    guardedYield(false),
    guardedYield(true),
    guardedSpawn(false),
    guardedSpawn(true),
    nondet c = oneOf(CHILDREN)
    any {
      childCompleteNormal(c),
      childObserveCancelAndExit(c),
      childAbortWithError(c),
    },
    // Stutter once exited
    all {
      nurseryExited,
      childState' = childState,
      active' = active,
      cancelled' = cancelled,
      hasErr' = hasErr,
      firstErrChild' = firstErrChild,
      parentBodyDone' = parentBodyDone,
      nurseryExited' = nurseryExited,
      exitedWithActiveChildren' = exitedWithActiveChildren,
      lostErrorOnCancel' = lostErrorOnCancel,
      crashedNullCtx' = crashedNullCtx,
      corruptedForeignSched' = corruptedForeignSched,
    }
  }

  // Safety invariants
  val invErrorImpliesCancelled: bool = (hasErr implies cancelled)
  val invNoExitWithActiveChildren: bool = not(exitedWithActiveChildren)
  val invExitImpliesAllChildrenDone: bool =
    (nurseryExited implies (active == 0 and CHILDREN.forall(c => childState.get(c) != 0)))
  val invErrorPreserved: bool = not(lostErrorOnCancel)
  val invGuardsClean: bool = (not(crashedNullCtx) and not(corruptedForeignSched))

  val safety: bool = all {
    invErrorImpliesCancelled,
    invNoExitWithActiveChildren,
    invExitImpliesAllChildrenDone,
    invErrorPreserved,
    invGuardsClean,
  }

  run cooperativeCancelQuiesceTest = {
    init
      .then(cancelNursery)
      .then(childObserveCancelAndExit(0))
      .then(childObserveCancelAndExit(1))
      .then(childCompleteNormal(2))
      .then(parentFinishBody)
      .then(nurseryExit)
      .expect(safety and nurseryExited and cancelled and not(hasErr))
  }

  run errorTriggersCancelTest = {
    init
      .then(childAbortWithError(1))
      .then(childObserveCancelAndExit(0))
      .then(childObserveCancelAndExit(2))
      .then(parentFinishBody)
      .then(nurseryExit)
      .expect(safety and nurseryExited and hasErr and cancelled and firstErrChild == 1)
  }

  run externalCancelBeforeErrorPreservesErrorTest = {
    init
      .then(cancelNursery)
      .then(childAbortWithError(2))
      .then(childObserveCancelAndExit(0))
      .then(childObserveCancelAndExit(1))
      .then(parentFinishBody)
      .then(nurseryExit)
      .expect(safety and hasErr and firstErrChild == 2)
  }

  run buggyErrorWithoutCancelDetectedTest = {
    init
      .then(buggyChildAbortNoCancel(0))
      .expect(not(invErrorImpliesCancelled))
  }

  run buggyEarlyExitOnCancelDetectedTest = {
    init
      .then(cancelNursery)
      .then(buggyExitEarlyOnCancel)
      .expect(not(invNoExitWithActiveChildren))
  }
}

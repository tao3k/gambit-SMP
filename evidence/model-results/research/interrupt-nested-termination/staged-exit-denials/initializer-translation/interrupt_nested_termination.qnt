module interrupt_nested_termination {
  // Suffix entry: A's callback runs; its synchronous requester is canceled.
  // Result: 0 absent, 1 target-owned, 2 abandoned, 3 returned.
  // Exit: 0 live, 1 draining under target lock, 2 unlocked, 3 signaled.
  type State = { policy: str, callback: int, resultA: int, resultT: int,
    termination: int, exit: int, rootA: bool, rootT: bool,
    collections: int, deliveries: int, joined: bool, joinQueued: bool, earlyJoin: bool,
    lateRequester: bool }
  var s: State
  var previousProgress: int
  // Ghost monitor only: it never disables a protocol transition.
  pure def progress(st: State): int = st.callback + st.resultA + st.resultT +
    st.termination + st.exit + st.collections + st.deliveries +
    (if (st.joined) 1 else 0) + (if (st.joinQueued) 1 else 0)
  pure def initial(policy: str): State = {
    policy: policy, callback: 1, resultA: 1, resultT: 0,
    termination: 0, exit: 0, rootA: true, rootT: true,
    collections: 0, deliveries: 0, joined: false, joinQueued: false, earlyJoin: false,
    lateRequester: false,
  }
  action initialize(policy: str): bool = all {
    s' = initial(policy), previousProgress' = -1,
  }
  action update(newState: State): bool = all {
    s' = newState, previousProgress' = progress(s),
  }
  action initFixed = initialize("complete")
  action initEarlyUnlock = initialize("early-unlock")
  action initEarlyJoin = initialize("early-join")
  action initLostWakeRoot = initialize("lost-wake-root")
  action initLostRoot = initialize("lost-root")
  action initDeadWake = initialize("dead-wake")
  action initRetainedResult = initialize("retain-result")
  action initLostSignal = initialize("lost-join-signal")
  action requestTermination = all {
    s.termination == 0,
    // Inactive-state inspection takes the target lock, not a raw flag read.
    s.exit != 1,
    update(if (s.exit > 0) { ...s, termination: 4 } else
      { ...s, termination: 1, resultT: 1, rootT: s.policy != "lost-root" }),
  }
  action extractTermination = all {
    s.termination == 1, s.exit == 0, update({ ...s, termination: 2 }),
  }
  pure def beginExit(old: State): State = {
    ...old, exit: 1, callback: if (old.callback == 1) 3 else old.callback,
  }
  action dispatchTermination = all {
    s.termination == 2, s.exit == 0,
    update({ ...beginExit(s), deliveries: s.deliveries + 1 }),
  }
  action throwCallback = all {
    s.callback == 1, s.exit == 0, update(beginExit(s)),
  }
  action returnCallback = all {
    s.callback == 1, s.exit == 0,
    update({ ...s, callback: 2, resultA: 3, lateRequester: s.policy == "dead-wake" }),
  }
  // Both orders are permitted as an overapproximation of the owned deque.
  action abandonA = all {
    s.exit == 1, s.resultA == 1, update({ ...s, resultA: 2 }),
  }
  action abandonT = all {
    s.exit == 1, s.resultT == 1, s.policy != "retain-result",
    update({ ...s, resultT: 2, termination: 3,
      rootT: s.policy != "lost-wake-root" }),
  }
  // Wakeup may happen during drain; it does not certify target join.
  action recoverTerminator = all {
    s.termination == 3, s.resultT == 2,
    update({ ...s, termination: 4 }),
  }
  action releaseTarget = all {
    s.exit == 1,
    (s.resultA != 1 and s.resultT != 1) or s.policy == "early-unlock",
    update({ ...s, exit: 2 }),
  }
  action queueJoin = all {
    s.exit == 0, not(s.joinQueued), not(s.joined),
    update({ ...s, joinQueued: true }),
  }
  action signalJoin = all {
    s.exit == 2, s.policy != "lost-join-signal", update({ ...s, exit: 3 }),
  }
  action observeJoin = all {
    not(s.joined), s.exit > 0,
    s.exit >= 2 or s.policy == "early-join",
    not(s.joinQueued) or s.exit == 3,
    update({ ...s, joined: true, earlyJoin: s.exit == 1 }),
  }
  action collect = all {
    s.collections < 2, update({ ...s, collections: s.collections + 1 }),
  }
  val terminal = s.exit == 3 and s.joined and s.termination == 4 and
    s.resultA != 1 and s.resultT != 1
  action finished = all { terminal, update(s) }
  action step = any { requestTermination, extractTermination, dispatchTermination,
    throwCallback, returnCallback, abandonA, abandonT, recoverTerminator,
    releaseTarget, queueJoin, signalJoin, observeJoin, collect, finished }
  val unlockedIsDrained = s.exit < 2 or (s.resultA != 1 and s.resultT != 1)
  val joinIsSynchronized = not(s.earlyJoin)
  val drainServiceable = terminal or enabled(step)
  val rootsRetained = (s.resultA != 1 or s.rootA) and
    ((s.resultT != 1 and not(s.resultT == 2 and s.termination == 3)) or s.rootT)
  val safe = unlockedIsDrained and joinIsSynchronized and rootsRetained and
    not(s.lateRequester) and s.deliveries <= 1
  val rankBounded = 0 <= progress(s) and progress(s) <= 20
  val rankStrict = terminal or progress(s) > previousProgress
  val checked = safe and rankBounded and rankStrict
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))

  run nestedTerminationTest = initFixed.then(collect).then(requestTermination)
    .then(extractTermination).then(collect).then(dispatchTermination)
    .then(abandonA).then(abandonT).then(recoverTerminator).then(releaseTarget)
    .then(signalJoin).then(observeJoin).expect(checked and terminal and s.resultA == 2)
  run returnBeforeTerminationTest = initFixed.then(requestTermination)
    .then(returnCallback).then(extractTermination).then(dispatchTermination)
    .then(abandonT).then(recoverTerminator).then(releaseTarget).then(signalJoin)
    .then(observeJoin).expect(checked and terminal and s.resultA == 3)
  run throwBeforeDispatchTest = initFixed.then(requestTermination).then(throwCallback)
    .then(abandonA).then(abandonT).then(recoverTerminator).then(releaseTarget)
    .then(signalJoin).then(observeJoin).expect(checked and terminal and s.deliveries == 0)
  run inactiveBeforeRequestTest = initFixed.then(throwCallback).then(abandonA)
    .then(releaseTarget).then(requestTermination).then(signalJoin).then(observeJoin)
    .expect(checked and terminal and s.resultT == 0)
  run lostRootControlTest = initLostRoot.then(requestTermination).then(collect)
    .expect(not(rootsRetained))
  run deadWakeControlTest = initDeadWake.then(returnCallback).expect(not(safe))
  run partialDrainTest = initFixed.then(requestTermination).then(extractTermination)
    .then(dispatchTermination).then(abandonT).then(recoverTerminator)
    .expect(checked and s.exit == 1 and s.resultA == 1 and not(s.joined))
  run gcDuringWakeTest = initFixed.then(requestTermination).then(extractTermination)
    .then(dispatchTermination).then(abandonT).then(collect).then(abandonA)
    .then(releaseTarget).then(observeJoin).then(recoverTerminator).then(signalJoin)
    .expect(checked and terminal)
  run joinBeforeSignalTest = initFixed.then(requestTermination).then(extractTermination)
    .then(dispatchTermination).then(abandonA).then(abandonT).then(releaseTarget)
    .then(observeJoin).then(recoverTerminator).then(signalJoin).expect(checked and terminal)
  run waitingJoinTest = initFixed.then(queueJoin).then(requestTermination)
    .then(extractTermination).then(dispatchTermination).then(abandonA).then(abandonT)
    .then(releaseTarget).then(recoverTerminator).then(signalJoin).then(observeJoin)
    .expect(checked and terminal)
  run inactiveAfterThrowTest = initFixed.then(throwCallback).then(abandonA)
    .then(releaseTarget).then(requestTermination).then(signalJoin).then(observeJoin)
    .expect(checked and terminal and s.resultT == 0)
  run finishedMonitorTest = initFixed.then(throwCallback).then(abandonA)
    .then(releaseTarget).then(requestTermination).then(signalJoin).then(observeJoin)
    .then(finished).expect(checked and terminal)
  run earlyUnlockControlTest = initEarlyUnlock.then(requestTermination)
    .then(extractTermination).then(dispatchTermination).then(releaseTarget)
    .expect(not(unlockedIsDrained))
  run earlyJoinControlTest = initEarlyJoin.then(throwCallback).then(observeJoin)
    .expect(not(joinIsSynchronized))
  run lostWakeRootControlTest = initLostWakeRoot.then(requestTermination)
    .then(extractTermination).then(dispatchTermination).then(abandonT).then(collect)
    .expect(not(rootsRetained))
  run retainedResultControlTest = initRetainedResult.then(requestTermination)
    .then(extractTermination).then(dispatchTermination).then(abandonA)
    .then(collect).then(collect)
    .expect(safe and not(terminal) and s.exit == 1 and s.resultT == 1)
  run lostSignalControlTest = initLostSignal.then(queueJoin).then(requestTermination)
    .then(extractTermination).then(dispatchTermination).then(abandonA).then(abandonT)
    .then(recoverTerminator).then(releaseTarget).then(collect).then(collect)
    .expect(safe and not(terminal) and s.exit == 2 and not(s.joined))
}

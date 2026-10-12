module interrupt_nested_termination {
  // Entry: A's callback is running and its synchronous requester has been
  // canceled. This suffix does not reprove the preceding delivery/unlink path.
  // Result: 0=absent, 1=target-owned, 2=abandoned, 3=returned.
  type State = { policy: str, callback: int, ended: bool, resultA: int,
    termination: int, resultT: int, rootA: bool, rootT: bool,
    collections: int, lateRequester: bool, deliveries: int }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, callback: 1, ended: false, resultA: 1,
    termination: 0, resultT: 0, rootA: true, rootT: true,
    collections: 0, lateRequester: false, deliveries: 0,
  }
  action initFixed = s' = initial("complete")
  action initRetainedResult = s' = initial("retain-result")
  action initLostRoot = s' = initial("lost-root")
  action initDeadWake = s' = initial("dead-wake")
  action requestTermination = all {
    s.termination == 0,
    s' = if (s.ended) { ...s, termination: 4 } else
      { ...s, termination: 1, resultT: 1, rootT: s.policy != "lost-root" },
  }
  action extractTermination = all {
    s.termination == 1, not(s.ended), s' = { ...s, termination: 2 },
  }
  // Exiting abandons every target-owned result mutex, including T's own.
  pure def ended(old: State): State = {
    ...old, ended: true,
    callback: if (old.callback == 1) 3 else old.callback,
    resultA: if (old.resultA == 1) 2 else old.resultA,
    termination: if (Set(1, 2).contains(old.termination)) 3 else old.termination,
    resultT: if (old.resultT == 1 and old.policy != "retain-result") 2 else old.resultT,
  }
  action dispatchTermination = all {
    s.termination == 2, not(s.ended),
    s' = { ...ended(s), deliveries: s.deliveries + 1 },
  }
  action throwCallback = all { s.callback == 1, not(s.ended), s' = ended(s) }
  action returnCallback = all {
    s.callback == 1, not(s.ended),
    s' = { ...s, callback: 2, resultA: 3, lateRequester: s.policy == "dead-wake" },
  }
  action recoverTerminator = all {
    s.termination == 3, s.resultT == 2, s' = { ...s, termination: 4 },
  }
  action collect = all { s.collections < 2, s' = { ...s, collections: s.collections + 1 } }
  val terminal = s.ended and s.termination == 4 and s.resultA != 1
  action finished = all { terminal, s' = s }
  action step = any { requestTermination, extractTermination, dispatchTermination,
    throwCallback, returnCallback, recoverTerminator, collect, finished }
  val terminationReleasesResult = not(s.ended) or s.resultT != 1
  val rootsRetained = (s.resultA != 1 or s.rootA) and (s.resultT != 1 or s.rootT)
  val canceledRequesterNeverResumes = not(s.lateRequester)
  val safe = terminationReleasesResult and rootsRetained and
    canceledRequesterNeverResumes and s.deliveries <= 1
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))

  run nestedTerminationTest = initFixed.then(collect).then(requestTermination)
    .then(extractTermination).then(collect).then(dispatchTermination)
    .then(recoverTerminator).expect(safe and terminal and s.resultA == 2)
  run returnBeforeTerminationTest = initFixed.then(requestTermination)
    .then(returnCallback).then(extractTermination).then(dispatchTermination)
    .then(recoverTerminator).expect(safe and terminal and s.resultA == 3)
  run throwBeforeDispatchTest = initFixed.then(requestTermination).then(throwCallback)
    .then(recoverTerminator).expect(safe and terminal and s.deliveries == 0)
  run inactiveBeforeRequestTest = initFixed.then(throwCallback).then(requestTermination)
    .expect(safe and terminal and s.resultT == 0)
  run retainedResultControlTest = initRetainedResult.then(requestTermination)
    .then(extractTermination).then(dispatchTermination)
    .expect(not(terminationReleasesResult) and not(terminal))
  run lostRootControlTest = initLostRoot.then(requestTermination).then(collect)
    .expect(not(rootsRetained))
  run deadWakeControlTest = initDeadWake.then(returnCallback)
    .expect(not(canceledRequesterNeverResumes))
}

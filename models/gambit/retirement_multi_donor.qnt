module retirement_multi_donor {
  // P0 + donors A/B; two moving collections; epoch 2 rejects epoch-1 acks.
  // Policies: 1 early failed return; 2 local-ready source drop;
  // 3 stale GC arrivals; 4 stale abort epoch; 5 early error-root release;
  // 6 callback replay; 7 premature decision with unfinished P0 preparation.
  type State = { policy: int, willFail: bool, phase: int, cohort: int,
    a: int, b: int, aCalls: int, bCalls: int,
    aSource: bool, aVersion: int, bSource: bool, bVersion: int,
    aReceiver: bool, aReceiverVersion: int, bReceiver: bool, bReceiverVersion: int, version: int,
    gc: bool, round: int, p0Arrival: int, aArrival: int, bArrival: int,
    staleGCUsed: bool, staleAbortUsed: bool,
    p0Prepared: bool, error: bool, errorRoot: bool, errorVersion: int,
    consumed: bool, p0Ack: int, aAck: int, bAck: int,
    p0Left: bool, aLeft: bool, bLeft: bool, replayed: bool }
  var s: State
  pure def initial(policy: int, willFail: bool): State = {
    policy: policy, willFail: willFail, phase: 1, cohort: 3,
    a: 0, b: 0, aCalls: 0, bCalls: 0,
    aSource: true, aVersion: 0, bSource: true, bVersion: 0,
    aReceiver: false, aReceiverVersion: -1, bReceiver: false, bReceiverVersion: -1, version: 0,
    gc: false, round: 0, p0Arrival: 0, aArrival: 0, bArrival: 0,
    staleGCUsed: false, staleAbortUsed: false,
    p0Prepared: false, error: false, errorRoot: false, errorVersion: -1,
    consumed: false, p0Ack: 1, aAck: 1, bAck: 1,
    p0Left: false, aLeft: false, bLeft: false, replayed: false }
  action initAbort = s' = initial(0,true)
  action initSuccess = s' = initial(0,false)
  action initEarlyReturn = s' = initial(1,true)
  action initEarlySourceDrop = s' = initial(2,true)
  action initStaleGC = s' = initial(3,true)
  action initStaleAbort = s' = initial(4,true)
  action initEarlyErrorRelease = s' = initial(5,true)
  action initReplay = s' = initial(6,true)
  action initEarlyDecision = s' = initial(7,true)
  action startA = all { s.phase == 1, s.a == 0,
    s' = { ...s, a: 1, aCalls: s.aCalls + 1 } }
  action readyA = all { s.phase == 1, s.a == 1, not(s.gc),
    s' = { ...s, a: 2, aReceiver: true, aReceiverVersion: s.version,
      aSource: s.policy != 2 } }
  action startB = all { s.phase == 1, s.b == 0,
    s' = { ...s, b: 1, bCalls: s.bCalls + 1 } }
  action requestFirstGC = all { s.phase == 1, s.b == 1, s.round == 0,
    s' = { ...s, gc: true, round: 1 } }
  action finishB = all { s.phase == 1, s.a == 2, s.b == 1,
    s.round == 1, not(s.gc),
    s' = { ...s, b: if(s.willFail) 3 else 2, error: s.willFail,
      errorRoot: s.willFail, errorVersion: if(s.willFail) s.version else -1 } }
  // P0's remaining fallible/root preparation may collect after first error.
  // It is not yet allowed to announce the no-more-allocation frontier.
  action requestSecondGC = all { s.phase == 1, s.b >= 2,
    s.round == 1, not(s.gc),
    s' = { ...s, gc: true, round: 2 } }
  action arriveP0 = all { s.phase == 1, s.gc, not(s.p0Left), s.p0Arrival != s.round,
    s' = { ...s, p0Arrival: s.round } }
  action arriveA = all { s.phase == 1, s.gc, not(s.aLeft), s.aArrival != s.round,
    s' = { ...s, aArrival: s.round } }
  action arriveB = all { s.phase == 1, s.gc, not(s.bLeft), s.bArrival != s.round,
    s' = { ...s, bArrival: s.round } }
  action finishGC = all { s.phase == 1, s.gc,
    (s.p0Arrival == s.round and s.aArrival == s.round and s.bArrival == s.round) or
      (s.policy == 3 and s.round == 2 and s.p0Arrival >= 1 and s.aArrival >= 1 and s.bArrival >= 1),
    s' = { ...s, gc: false, version: s.version + 1,
      aVersion: if(s.aSource) s.version + 1 else s.aVersion,
      bVersion: if(s.bSource) s.version + 1 else s.bVersion,
      aReceiverVersion: if(s.aReceiver) s.version + 1 else s.aReceiverVersion,
      errorVersion: if(s.errorRoot) s.version + 1 else s.errorVersion,
      staleGCUsed: s.staleGCUsed or not(s.p0Arrival == s.round and s.aArrival == s.round and s.bArrival == s.round) } }
  action finishP0Preparation = all { s.phase == 1, s.round == 2, not(s.gc), not(s.p0Prepared),
    s' = { ...s, p0Prepared: true } }
  action earlyFailedReturn = all { s.policy == 1, s.phase == 1, s.error, not(s.bLeft),
    s' = { ...s, bLeft: true } }
  action releaseErrorEarly = all { s.policy == 5, s.errorRoot, not(s.consumed),
    s' = { ...s, errorRoot: false } }
  action replayCallback = all { s.policy == 6, s.phase == 1, s.error, not(s.replayed),
    s' = { ...s, bCalls: s.bCalls + 1, replayed: true } }
  action decide = all { s.phase == 1, s.a == 2, s.b >= 2, not(s.gc),
    s.p0Prepared or s.policy == 7,
    s' = { ...s, phase: if(s.error) 2 else 4,
      cohort: if(s.error) 3 else 1,
      aSource: if(s.error) s.aSource else false, bSource: if(s.error) s.bSource else false,
      bReceiver: not(s.error), bReceiverVersion: if(s.error) -1 else s.version } }
  action ackP0 = all { s.phase == 2, s.p0Ack != 2, s' = { ...s, p0Ack: 2 } }
  action ackA = all { s.phase == 2, s.aAck != 2, s' = { ...s, aAck: 2 } }
  action ackB = all { s.phase == 2, s.bAck != 2, s' = { ...s, bAck: 2 } }
  action finishAbort = all { s.phase == 2,
    (s.p0Ack == 2 and s.aAck == 2 and s.bAck == 2) or s.policy == 4,
    s' = { ...s, phase: 3, aReceiver: false,
      staleAbortUsed: not(s.p0Ack == 2 and s.aAck == 2 and s.bAck == 2) } }
  action leaveP0 = all { s.phase == 3 or s.phase == 4, not(s.p0Left), s' = { ...s, p0Left: true } }
  action leaveA = all { s.phase == 3 or s.phase == 4, not(s.aLeft), s' = { ...s, aLeft: true } }
  action leaveB = all { s.phase == 3 or s.phase == 4, not(s.bLeft), s' = { ...s, bLeft: true } }
  action consumeResult = all { s.p0Left, s.aLeft, s.bLeft, not(s.consumed),
    s.phase == 3 or s.phase == 4, s' = { ...s, consumed: true } }
  action releaseResultRoot = all { s.consumed, s.errorRoot, s' = { ...s, errorRoot: false } }
  val terminal = s.consumed and not(s.errorRoot)
  action done = all { terminal, s' = s }
  action step = any { startA, readyA, startB, requestFirstGC, finishB, requestSecondGC,
    arriveP0, arriveA, arriveB, finishGC, finishP0Preparation, earlyFailedReturn,
    releaseErrorEarly, replayCallback, decide, ackP0, ackA, ackB, finishAbort,
    leaveP0, leaveA, leaveB, consumeResult, releaseResultRoot, done }
  val rootsCovered = ((s.aSource and s.cohort == 3 and s.aVersion == s.version) or
    (s.aReceiver and s.aReceiverVersion == s.version)) and
    ((s.bSource and s.cohort == 3 and s.bVersion == s.version) or
      (s.bReceiver and s.bReceiverVersion == s.version)) and
    (not(s.error) or s.consumed or (s.errorRoot and s.errorVersion == s.version))
  val cohortServing = (s.phase >= 3) or (s.cohort == 3 and not(s.p0Left) and not(s.aLeft) and not(s.bLeft))
  val closedDecision = s.phase == 1 or (s.p0Prepared and s.round == 2 and not(s.gc))
  val exactAcknowledgements = not(s.staleGCUsed) and not(s.staleAbortUsed)
  val abortKeepsSources = s.phase != 3 or (s.cohort == 3 and s.aSource and s.bSource)
  val safe = rootsCovered and cohortServing and closedDecision and exactAcknowledgements and
    abortKeepsSources and s.aCalls <= 1 and s.bCalls <= 1
  temporal completion = weakFair(step,Set(s)).implies(eventually(terminal))
  run readyThenFailureAndSecondGC = initAbort.then(startA).then(readyA).then(startB)
    .then(requestFirstGC).then(arriveA).then(arriveB).then(arriveP0).then(finishGC)
    .then(finishB).expect(s.a == 2 and s.error and s.cohort == 3 and safe)
    .then(requestSecondGC).then(arriveB).then(arriveP0).then(arriveA).then(finishGC)
    .expect(s.version == 2 and s.aVersion == 2 and s.bVersion == 2 and s.errorVersion == 2 and safe)
    .then(finishP0Preparation).then(decide).then(ackA).then(ackB).then(ackP0).then(finishAbort)
    .then(leaveB).then(leaveA).then(leaveP0).then(consumeResult).then(releaseResultRoot)
    .expect(terminal and s.cohort == 3 and s.aCalls == 1 and s.bCalls == 1 and safe)
}

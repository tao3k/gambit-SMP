module retirement_last_consumers {
  // Two local mechanism slices. Not proof they overlap in legal native retire.
  // owner is the external/origin lifetime contract, not sfun_frame_count.
  type State = { policy: int, queued: bool, scanning: bool, producer: bool,
    heapLive: bool, frameCounted: bool, tail: bool, owner: bool, contextLive: bool }
  var s: State
  pure def initial(policy: int): State = { policy: policy, queued: true,
    scanning: false, producer: true, heapLive: true, frameCounted: true,
    tail: true, owner: true, contextLive: true }
  action initOwnerCut = s' = initial(0)
  action initQueueOnly = s' = initial(1)
  action initFrameCountOnly = s' = initial(2)
  action initIgnoreProducer = s' = initial(3)
  action dequeue = all { s.queued, not(s.scanning),
    s' = { ...s, queued: false, scanning: true } }
  action scanReturn = all { s.scanning, s' = { ...s, scanning: false } }
  action producerFinish = all { s.producer, not(s.queued),
    s' = { ...s, producer: false, queued: true } }
  action leaveFrame = all { s.frameCounted, s' = { ...s, frameCounted: false } }
  // Abstract complete return/unwind, not just kill_marker or propagate entry.
  action finishTail = all { not(s.frameCounted), s.tail,
    s' = { ...s, tail: false } }
  action releaseOrigin = all { not(s.tail), s.owner,
    s' = { ...s, owner: false } }
  action retireHeap = all { s.heapLive, not(s.queued),
    not(s.scanning) or s.policy == 1,
    not(s.producer) or s.policy == 3,
    s' = { ...s, heapLive: false } }
  action retireContext = all { s.contextLive, not(s.frameCounted),
    not(s.owner) or s.policy == 2,
    s' = { ...s, contextLive: false } }
  val terminal = not(s.heapLive) and not(s.contextLive) and not(s.owner)
    and not(s.tail) and not(s.scanning) and not(s.queued) and not(s.producer)
  action done = all { terminal, s' = s }
  action step = any { dequeue, scanReturn, producerFinish, leaveFrame,
    finishTail, releaseOrigin, retireHeap, retireContext, done }
  val heapCut = s.heapLive or not(s.queued or s.scanning or s.producer)
  val tailCovered = s.contextLive or not(s.tail)
  val safe = heapCut and tailCovered
  temporal completion = weakFair(dequeue, Set(s))
    .and(weakFair(scanReturn, Set(s))).and(weakFair(producerFinish, Set(s)))
    .and(weakFair(leaveFrame, Set(s))).and(weakFair(finishTail, Set(s)))
    .and(weakFair(releaseOrigin, Set(s))).and(weakFair(retireHeap, Set(s)))
    .and(weakFair(retireContext, Set(s))).implies(eventually(terminal))
  run tailAfterCountIsSafeWithOwner = initOwnerCut.then(leaveFrame)
    .expect(not(s.frameCounted) and s.tail and s.owner and safe)
    .then(finishTail).then(releaseOrigin).then(retireContext).expect(safe)
  run dequeuedWorkStillBorrows = initOwnerCut.then(dequeue).then(producerFinish)
    .then(scanReturn).then(dequeue)
    .expect(not(s.queued) and s.scanning and s.heapLive and safe)
    .then(scanReturn).then(retireHeap).expect(safe)
}

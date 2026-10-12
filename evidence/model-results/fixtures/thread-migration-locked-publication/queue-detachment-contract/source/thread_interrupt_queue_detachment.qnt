module thread_interrupt_queue_detachment {
  // A and B are request identities, not processor cardinality.
  // A is forwarded to its target thread; B belongs to the source processor.
  type State = { fixed: bool, phase: int, processorHead: int, threadHead: int,
    nextA: int, nextB: int, inFlight: int, deliveredA: int, deliveredB: int,
    wrongRecipientB: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, phase: 0, processorHead: 0, threadHead: -1,
    nextA: 1, nextB: -1, inFlight: -1,
    deliveredA: 0, deliveredB: 0, wrongRecipientB: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  // Dequeue is protected by the source processor lock. Only A is removed.
  action processorExtractA = all {
    s.phase == 0,
    s' = { ...s, phase: 1, processorHead: s.nextA, inFlight: 0,
      nextA: if (s.fixed) -1 else s.nextA },
  }
  // Thread queue insertion assumes the incoming request is detached.
  action forwardA = all {
    s.phase == 1,
    s' = { ...s, phase: 2, inFlight: -1, threadHead: 0 },
  }
  action processorDispatchB = all {
    s.processorHead == 1,
    s' = { ...s, processorHead: s.nextB, nextB: -1,
      deliveredB: s.deliveredB + 1 },
  }
  action threadDispatchA = all {
    s.threadHead == 0,
    s' = { ...s, threadHead: s.nextA, nextA: -1,
      deliveredA: s.deliveredA + 1 },
  }
  action threadDispatchB = all {
    s.threadHead == 1,
    s' = { ...s, threadHead: s.nextB, nextB: -1,
      deliveredB: s.deliveredB + 1, wrongRecipientB: true },
  }
  val drained = s.phase == 2 and s.processorHead == -1 and s.threadHead == -1
  action finished = all { drained, s' = s }
  action step = any { processorExtractA, forwardA, processorDispatchB,
    threadDispatchA, threadDispatchB, finished }
  val singleDelivery = s.deliveredA <= 1 and s.deliveredB <= 1
  val recipientSafe = not(s.wrongRecipientB)
  val detachedHandoff = s.phase != 1 or s.nextA == -1
  val safe = singleDelivery and recipientSafe and detachedHandoff
  temporal completion = weakFair(step, Set(s)).implies(
    eventually(drained and s.deliveredA == 1 and s.deliveredB == 1))
}

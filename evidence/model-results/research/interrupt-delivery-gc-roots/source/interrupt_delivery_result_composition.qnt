module interrupt_delivery_result_composition {
  // Two registered requests: A targets the forwarded thread; B the processor.
  // Queue and target-lock operations are abstract atomic source projections.
  // resultA: 1=target-owned, 2=abandoned, 3=delivered; outcomeA: 0=waiting.
  type State = { policy: str, phase: int, processorHead: int, threadHead: int,
    nextA: int, nextB: int, locked: bool, ended: bool, resultA: int,
    outcomeA: int, deliveredA: int, deliveredB: int, wrongRecipientB: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, phase: 0, processorHead: 0, threadHead: -1,
    nextA: 1, nextB: -1, locked: false, ended: false, resultA: 1,
    outcomeA: 0, deliveredA: 0, deliveredB: 0, wrongRecipientB: false,
  }
  action initFixed = s' = initial("combined")
  action initLinkedTransfer = s' = initial("linked-transfer")
  action initLeakedTargetLock = s' = initial("leaked-target-lock")
  action initLostAbandonedOutcome = s' = initial("lost-abandoned-outcome")
  action processorExtractA = all {
    s.phase == 0,
    s' = { ...s, phase: 1, processorHead: s.nextA,
      nextA: if (s.policy == "linked-transfer") s.nextA else -1 },
  }
  action acquireTarget = all {
    s.phase == 1, not(s.locked), s' = { ...s, phase: 2, locked: true },
  }
  action propagateA = all {
    s.phase == 2, s.locked,
    s' = { ...s, phase: 3,
      locked: s.ended and s.policy == "leaked-target-lock",
      threadHead: if (s.ended) -1 else 0 },
  }
  action terminateTarget = all {
    not(s.ended), not(s.locked),
    s' = { ...s, ended: true, resultA: if (s.resultA == 1) 2 else s.resultA },
  }
  action processorDispatchB = all {
    s.processorHead == 1,
    s' = { ...s, processorHead: s.nextB, nextB: -1,
      deliveredB: s.deliveredB + 1 },
  }
  action threadDispatchA = all {
    s.threadHead == 0, not(s.ended),
    s' = { ...s, threadHead: s.nextA, nextA: -1,
      deliveredA: s.deliveredA + 1, resultA: 3 },
  }
  action threadDispatchB = all {
    s.threadHead == 1, not(s.ended),
    s' = { ...s, threadHead: s.nextB, nextB: -1,
      deliveredB: s.deliveredB + 1, wrongRecipientB: true },
  }
  action observeResult = all {
    s.phase == 3, s.outcomeA == 0, Set(2, 3).contains(s.resultA),
    s' = { ...s, outcomeA:
      if (s.resultA == 2 and s.policy == "lost-abandoned-outcome") 3 else s.resultA },
  }
  val terminal = s.phase == 3 and s.outcomeA != 0 and s.deliveredB == 1
  action finished = all { terminal, s' = s }
  action step = any { processorExtractA, acquireTarget, propagateA, terminateTarget,
    processorDispatchB, threadDispatchA, threadDispatchB, observeResult, finished }
  val detachedHandoff = s.phase != 1 or s.nextA == -1
  val deliverySafe = s.deliveredA <= 1 and s.deliveredB <= 1 and not(s.wrongRecipientB)
  val releaseSafe = s.phase != 3 or not(s.locked)
  val outcomeSafe = s.outcomeA == 0 or s.outcomeA == s.resultA
  val abandonmentSafe = not(s.ended) or s.resultA != 1
  val safe = detachedHandoff and deliverySafe and releaseSafe and outcomeSafe and abandonmentSafe
  // Terminal does not mean a dead target's retained queue was physically drained.
  // Fair scheduling and terminating primitive operations remain assumptions.
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

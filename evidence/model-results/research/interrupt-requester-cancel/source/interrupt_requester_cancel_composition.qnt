module interrupt_requester_cancel_composition {
  import interrupt_delivery_result_composition as I from "./interrupt_delivery_result_composition"
  type Requester = { policy: str, canceled: bool, woken: bool,
                     resultLive: bool, wrongOwner: bool, callback: int, collected: bool,
                     cancelPhase: int, badWake: bool }
  var requester: Requester
  pure def initial(policy: str): Requester = {
    policy: policy, canceled: false, woken: false,
    resultLive: true, wrongOwner: false, callback: 0, collected: false,
    cancelPhase: 0, badWake: false,
  }
  action initFixed = all { I::s' = I::initial("combined"), requester' = initial("complete") }
  action initLostLifetime = all { I::s' = I::initial("combined"), requester' = initial("lost-lifetime") }
  action initDeadWake = all { I::s' = I::initial("combined"), requester' = initial("dead-wake") }
  action initWrongOwner = all { I::s' = I::initial("combined"), requester' = initial("wrong-owner") }
  action requestCancel = all {
    requester.cancelPhase == 0, not(requester.woken), I::s' = I::s,
    requester' = { ...requester, cancelPhase: 1 },
  }
  action unlinkWaiter = all {
    requester.cancelPhase == 1, I::s' = I::s,
    requester' = { ...requester, cancelPhase: 2 },
  }
  action commitCancel = all {
    requester.cancelPhase == 2,
    I::s' = if (requester.policy == "wrong-owner")
      { ...I::s, resultA: 2 } else I::s,
    requester' = { ...requester, canceled: true, cancelPhase: 3,
      resultLive: requester.policy != "lost-lifetime",
      wrongOwner: requester.policy == "wrong-owner" },
  }
  action observeResult = all {
    requester.cancelPhase < 2 or requester.policy == "dead-wake",
    I::observeResult,
    requester' = { ...requester, woken: true,
                   badWake: requester.cancelPhase >= 2 },
  }
  action protocol = all {
    any { I::processorExtractA, I::acquireTarget, I::propagateA,
          I::processorDispatchB, I::threadDispatchB },
    requester' = requester,
  }
  action beginCallback = all {
    I::s.threadHead == 0, not(I::s.ended), requester.callback == 0,
    I::s' = { ...I::s, threadHead: I::s.nextA, nextA: -1,
              deliveredA: I::s.deliveredA + 1 },
    requester' = { ...requester, callback: 1 },
  }
  action returnCallback = all {
    requester.callback == 1, not(I::s.ended),
    I::s' = { ...I::s, resultA: 3 }, requester' = { ...requester, callback: 2 },
  }
  action throwCallback = all {
    requester.callback == 1, not(I::s.ended),
    I::s' = { ...I::s, ended: true, resultA: 2 },
    requester' = { ...requester, callback: 3 },
  }
  action terminateTarget = all {
    I::terminateTarget,
    requester' = if (requester.callback == 1) { ...requester, callback: 3 } else requester,
  }
  action collect = all {
    requester.callback == 1, not(requester.collected), I::s' = I::s,
    requester' = { ...requester, collected: true },
  }
  val terminal = I::s.phase == 3 and I::s.resultA != 1 and
    I::s.deliveredB == 1 and requester.callback != 1 and
    (requester.canceled or requester.woken) and
    Set(0, 3).contains(requester.cancelPhase)
  action finished = all {
    terminal, I::s' = I::s, requester' = requester,
  }
  action step = any { requestCancel, unlinkWaiter, commitCancel, observeResult, protocol, beginCallback,
    returnCallback, throwCallback, terminateTarget, collect, finished }
  val resultLifetime = I::s.resultA != 1 or requester.resultLive
  val noDeadWake = not(requester.badWake)
  val ownerPreserved = not(requester.wrongOwner)
  val noEarlySuccess = I::s.outcomeA != 3 or requester.callback == 2
  val exceptionOutcome = requester.callback != 3 or I::s.resultA == 2
  val safe = I::safe and resultLifetime and noDeadWake and ownerPreserved and
    noEarlySuccess and exceptionOutcome
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set((I::s, requester))).implies(eventually(terminal))

  action extractStep = all { I::processorExtractA, requester' = requester }
  action acquireStep = all { I::acquireTarget, requester' = requester }
  action propagateStep = all { I::propagateA, requester' = requester }
  run canceledOwnerRetainedTest = initFixed.then(requestCancel).then(unlinkWaiter)
    .then(commitCancel).expect(safe and requester.canceled and requester.resultLive)
  run resultBeforeUnlinkTest = initFixed.then(extractStep).then(acquireStep)
    .then(propagateStep).then(beginCallback).then(requestCancel)
    .then(returnCallback).then(observeResult).then(unlinkWaiter).then(commitCancel)
    .expect(safe and requester.woken and requester.canceled and not(requester.badWake))
  run deadWakeControlTest = initDeadWake.then(extractStep).then(acquireStep)
    .then(propagateStep).then(beginCallback).then(requestCancel)
    .then(unlinkWaiter).then(commitCancel).then(returnCallback).then(observeResult)
    .expect(not(noDeadWake) and requester.badWake)
  run unlinkedWakeControlTest = initDeadWake.then(extractStep).then(acquireStep)
    .then(propagateStep).then(beginCallback).then(requestCancel)
    .then(unlinkWaiter).then(returnCallback).then(observeResult)
    .expect(not(noDeadWake) and requester.badWake and not(requester.canceled))
  run lostLifetimeControlTest = initLostLifetime.then(requestCancel).then(unlinkWaiter)
    .then(commitCancel).expect(not(resultLifetime))
  run wrongOwnerControlTest = initWrongOwner.then(requestCancel).then(unlinkWaiter)
    .then(commitCancel).expect(not(ownerPreserved))
}

module interrupt_callback_gc_exit {
  import interrupt_delivery_result_composition as I from "./interrupt_delivery_result_composition"
  type Callback = { phase: int, policy: str, collected: bool, lost: bool }
  var cb: Callback
  pure def initial(policy: str): Callback = {
    phase: 0, policy: policy, collected: false, lost: false,
  }
  action initFixed = all { I::s' = I::initial("combined"), cb' = initial("complete") }
  action initMissingCallbackRoot = all {
    I::s' = I::initial("combined"), cb' = initial("missing-root"),
  }
  action initEarlySuccess = all {
    I::s' = I::initial("combined"), cb' = initial("early-success"),
  }
  action initLostException = all {
    I::s' = I::initial("combined"), cb' = initial("lost-exception"),
  }
  action beginCallback = all {
    I::s.threadHead == 0, not(I::s.ended), cb.phase == 0,
    I::s' = { ...I::s, threadHead: I::s.nextA, nextA: -1,
      deliveredA: I::s.deliveredA + 1,
      resultA: if (cb.policy == "early-success") 3 else I::s.resultA },
    cb' = { ...cb, phase: 1 },
  }
  action returnCallback = all {
    cb.phase == 1, not(I::s.ended),
    I::s' = { ...I::s, resultA: 3 }, cb' = { ...cb, phase: 2 },
  }
  action throwCallback = all {
    cb.phase == 1, not(I::s.ended),
    I::s' = { ...I::s, ended: true,
      resultA: if (cb.policy == "lost-exception") 3 else 2 },
    cb' = { ...cb, phase: 3 },
  }
  action terminateTarget = all {
    I::terminateTarget,
    cb' = if (cb.phase == 1) { ...cb, phase: 3 } else cb,
  }
  action collectDuringCallback = all {
    cb.phase == 1, not(cb.collected), I::s' = I::s,
    cb' = { ...cb, collected: true, lost: cb.policy == "missing-root" },
  }
  action protocol = all {
    any { I::processorExtractA, I::acquireTarget, I::propagateA,
          I::processorDispatchB, I::threadDispatchB, I::observeResult },
    cb' = cb,
  }
  val terminal = I::terminal and cb.phase != 1
  action finished = all { terminal, I::s' = I::s, cb' = cb }
  action step = any { protocol, beginCallback, returnCallback, throwCallback,
    terminateTarget, collectDuringCallback, finished }
  val callbackRoot = not(cb.lost)
  val noEarlySuccess = I::s.outcomeA != 3 or cb.phase == 2
  val exceptionOutcome = cb.phase != 3 or I::s.resultA == 2
  val safe = I::safe and callbackRoot and noEarlySuccess and exceptionOutcome
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set((I::s, cb))).implies(eventually(terminal))
}

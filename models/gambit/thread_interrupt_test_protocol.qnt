module thread_interrupt_test_protocol {
  // The runtime honors interrupt delivery and canonical thread completion.
  // Main and worker busy-loop work have no inter-thread ordering effect.
  type State = { gate: bool, allowFinish: bool, worker: int, main: int,
    value: int, saved: int, pending: bool, invalidRecipient: bool, badAssertion: bool }
  var s: State
  pure def initial(gate: bool): State = {
    gate: gate, allowFinish: not(gate), worker: 0, main: 0,
    value: 0, saved: 0, pending: false, invalidRecipient: false, badAssertion: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action firstInterrupt = all {
    s.main == 0,
    s' = { ...s, main: if (s.worker == 3) 6 else 1,
      invalidRecipient: s.worker == 3 },
  }
  action saveValue = all { s.main == 1, s' = { ...s, saved: s.value, main: 2 } }
  action mainWork = all { s.main == 2, s' = { ...s, main: 3 } }
  action lastInterrupt = all {
    s.main == 3,
    s' = { ...s, main: if (s.worker == 3) 6 else 4,
      pending: s.worker != 3, invalidRecipient: s.worker == 3 },
  }
  action deliverInterrupt = all {
    s.pending, s.worker != 3,
    s' = { ...s, pending: false, value: s.value + 1 },
  }
  action workerWork = all { s.worker < 2, s' = { ...s, worker: s.worker + 1 } }
  action workerFinish = all {
    s.worker == 2, s.allowFinish, not(s.pending),
    s' = { ...s, worker: 3, value: s.value + 10 },
  }
  action observe = all {
    s.main == 4, s.value > s.saved,
    s' = { ...s, main: 5, allowFinish: true },
  }
  action assertValue = all {
    s.main == 5, not(s.gate) or s.worker == 3,
    s' = { ...s, main: 6, badAssertion: s.value != 11 },
  }
  action finished = all { s.main == 6, s' = s }
  action step = any { firstInterrupt, saveValue, mainWork, lastInterrupt,
    deliverInterrupt, workerWork, workerFinish, observe, assertValue, finished }
  val recipientSafe = not(s.invalidRecipient)
  val assertSafe = not(s.badAssertion)
  val safe = recipientSafe and assertSafe
}

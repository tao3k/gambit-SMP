module idle_processor_retirement_reuse {
  // VM sentinel=0, reusable processor=1. Roles do not limit host CPUs.
  type State = { fixed: bool, phase: int, parked: bool,
    vmNext: int, vmPrev: int, processorNext: int, processorPrev: int }
  var s: State
  pure def initial(fixed: bool, parked: bool): State = {
    fixed: fixed, phase: 0, parked: parked,
    vmNext: if (parked) 1 else 0, vmPrev: if (parked) 1 else 0,
    processorNext: if (parked) 0 else 1, processorPrev: if (parked) 0 else 1,
  }
  action initOld = s' = initial(false, true)
  action initFixed = {
    nondet parked = Set(false, true).oneOf()
    s' = initial(true, parked)
  }
  // Direct OS exit bypasses the Scheme wait helper's post-select removal.
  action retire = all {
    s.phase == 0,
    s' = if (s.fixed) { ...s, phase: 1, parked: false,
      vmNext: 0, vmPrev: 0, processorNext: 1, processorPrev: 1 }
      else { ...s, phase: 1 },
  }
  // The permanent processor object is reset, then its deque links initialized.
  action reuse = all {
    s.phase == 1,
    s' = { ...s, phase: 2, processorNext: 1, processorPrev: 1 },
  }
  action parkAgain = all {
    s.phase == 2,
    s' = { ...s, phase: 3, parked: true,
      vmNext: 1, vmPrev: 1, processorNext: 0, processorPrev: 0 },
  }
  action finished = all { s.phase == 3, s' = s }
  action step = any { retire, reuse, parkAgain, finished }
  val ringValid = (s.vmNext == 0 and s.vmPrev == 0 and
    s.processorNext == 1 and s.processorPrev == 1) or
    (s.vmNext == 1 and s.vmPrev == 1 and
     s.processorNext == 0 and s.processorPrev == 0)
  val reuseDetached = s.phase != 1 or
    (s.vmNext == 0 and s.vmPrev == 0)
  val safe = ringValid and reuseDetached
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.phase == 3))
}

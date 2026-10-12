module current_processor_gc_wait {
  // Owner requests GC while the production yield path waits for its lock.
  // Two protocol roles are not a native processor-population limit.
  type State = { participates: bool, requested: bool, joined: bool,
    gcDone: bool, processorLocked: bool, threadLocked: bool, returned: bool }
  var s: State
  pure def initial(participates: bool): State = {
    participates: participates, requested: false, joined: false,
    gcDone: false, processorLocked: true, threadLocked: true, returned: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action request = all {
    not(s.requested), s' = { ...s, requested: true },
  }
  action participate = all {
    s.requested, s.participates, not(s.joined),
    s' = { ...s, joined: true },
  }
  action finishGc = all {
    s.joined, not(s.gcDone), s' = { ...s, gcDone: true },
  }
  action releaseProcessor = all {
    s.gcDone, s.processorLocked, s' = { ...s, processorLocked: false },
  }
  action finishYield = all {
    not(s.processorLocked), not(s.returned),
    s' = { ...s, threadLocked: false, returned: true },
  }
  val terminal = s.returned
  action finished = all { terminal, s' = s }
  action step = any { request, participate, finishGc,
    releaseProcessor, finishYield, finished }
  val progressPossible = terminal or not(s.requested) or
    (s.participates and not(s.joined)) or (s.joined and not(s.gcDone)) or
    (s.gcDone and s.processorLocked) or
    (not(s.processorLocked) and not(s.returned))
  val lockOrder = (not(s.processorLocked) implies s.gcDone) and
    (not(s.threadLocked) implies s.returned)
  val safe = progressPossible and lockOrder
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}

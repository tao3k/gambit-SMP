module resize_startup_generation_failure {
  // Two generation tokens bound reuse; they are not processor/worker counts.
  type State = { policy: int, generation: int, outcomeGeneration: int,
    status: int, fails: bool, startupDone: bool, requesterDone: bool,
    observedGeneration: int, admitted: bool }
  var s: State
  pure def initial(policy: int, fails: bool): State = {
    policy: policy, generation: 2, outcomeGeneration: 1, status: 1,
    fails: fails, startupDone: false, requesterDone: false,
    observedGeneration: 0, admitted: false,
  }
  action initOldGeneration = s' = initial(1, false)
  action initMissingFailure = s' = initial(2, true)
  action initFixed = {
    nondet fails = Set(false, true).oneOf()
    s' = initial(0, fails)
  }
  // Design abstraction: publish a terminal outcome only after startup settles.
  // Actual cleanup/quarantine and C publication are separate source obligations.
  action settleStartup = all {
    not(s.startupDone),
    s' = if (s.policy == 2 and s.fails) { ...s, startupDone: true }
      else { ...s, startupDone: true, outcomeGeneration: s.generation,
        status: if (s.fails) 2 else 1 },
  }
  action returnResize = all {
    not(s.requesterDone), s.status != 0,
    s.policy == 1 or s.outcomeGeneration == s.generation,
    s' = { ...s, requesterDone: true,
      observedGeneration: s.outcomeGeneration, admitted: s.status == 1 },
  }
  val generationSafe = not(s.requesterDone) or
    s.observedGeneration == s.generation
  val failurePublished = not(s.startupDone and s.fails) or
    (s.outcomeGeneration == s.generation and s.status == 2)
  val failedNotAdmitted = not(s.startupDone and s.fails and s.admitted)
  val safe = generationSafe and failurePublished and failedNotAdmitted
  val terminal = s.startupDone and s.requesterDone
  action finished = all { terminal, s' = s }
  action step = any { settleStartup, returnResize, finished }
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}

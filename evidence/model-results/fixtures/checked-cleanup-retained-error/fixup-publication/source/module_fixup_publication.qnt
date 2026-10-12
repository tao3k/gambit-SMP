module module_fixup_publication {
  // Abstract exclusive owner claim; actual C atomicity is an open refinement.
  // phase: 0 cold, 1 claimed, 2 validated, 3 committed, 4 failed.
  // observation: 0 not attempted, 1 waiting, 2 success, 3 typed error.
  type State = { policy: int, phase: int, invalid: bool,
    failPayload: bool, done: bool, payloadReady: bool, error: int,
    observation: int }
  var s: State
  action initFixed = {
    nondet invalid = Set(false, true).oneOf()
    nondet failPayload = Set(false, true).oneOf()
    s' = { policy: 0, phase: 0, invalid: invalid, failPayload: failPayload,
      done: false, payloadReady: false, error: 0, observation: 0 }
  }
  action initEarlyDone = s' = { policy: 1, phase: 0, invalid: false,
    failPayload: false, done: false, payloadReady: false,
    error: 0, observation: 0 }
  action initFailedRetry = s' = { policy: 2, phase: 0, invalid: true,
    failPayload: false, done: false, payloadReady: false,
    error: 0, observation: 0 }
  action claim = all {
    s.phase == 0,
    s' = { ...s, phase: 1, done: s.policy != 0 },
  }
  action validate = all {
    s.phase == 1,
    s' = if (s.invalid) { ...s, phase: 4, error: 1 }
      else { ...s, phase: 2 },
  }
  action prepare = all {
    s.phase == 2,
    s' = if (s.failPayload) { ...s, phase: 4, error: 2 }
      else { ...s, phase: 3, payloadReady: true, done: true },
  }
  action observe = all {
    s.observation == 0,
    s.phase > 0,
    s.policy != 2 or s.phase == 4,
    s' = { ...s, observation: if (s.done) 2
      else if (s.phase == 4) 3 else 1 },
  }
  action resumeObserver = all {
    s.observation == 1,
    s.phase == 3 or s.phase == 4,
    s' = { ...s, observation: if (s.phase == 3) 2 else 3 },
  }
  val terminal = (s.phase == 3 or s.phase == 4) and s.observation >= 2
  action finished = all { terminal, s' = s }
  action step = any { claim, validate, prepare, observe, resumeObserver, finished }
  val publicationSafe = s.observation != 2 or s.payloadReady
  val rejectionStable = s.phase != 4 or s.observation != 2
  val errorExplicit = s.observation != 3 or s.error != 0
  val safe = publicationSafe and rejectionStable and errorExplicit
  temporal completion = weakFair(step, s).implies(eventually(terminal))
}

module completed_work_watchdog {
  // Finite work: two phases per attempt, two files per phase, one retry.
  // Clocks count abstract time, not CPU use or output bytes.
  type State = { phase: int, attempt: int, files: int, audit: int,
    idle: int, observedIdle: int, spent: int, stopped: bool, done: bool, policy: int }
  var s: State
  pure def initial(policy: int): State = {
    phase: 0, attempt: 0, files: 0, audit: 0, idle: 0, observedIdle: 0,
    spent: 0, stopped: false, done: false, policy: policy,
  }
  action init = s' = initial(0)
  action initNoise = s' = initial(1)
  action initWallQuota = s' = initial(2)
  val active = not(s.stopped) and not(s.done)
  action tick = all {
    active, s.idle < 3,
    s' = { ...s, idle: s.idle + 1, observedIdle: s.observedIdle + 1, spent: s.spent + 1 },
  }
  action completedFile = all {
    active, s.idle < 3, s.files < 2,
    s' = { ...s, files: s.files + 1, audit: s.audit + 1, idle: 0, observedIdle: 0 },
  }
  action noise = all {
    active,
    s' = if (s.policy == 1) { ...s, observedIdle: 0 } else s,
  }
  action expire = all {
    active, s.observedIdle >= 3 or (s.policy == 2 and s.spent >= 3),
    s' = { ...s, stopped: true },
  }
  action nextPhase = all {
    active, s.files == 2,
    if (s.phase == 0)
      s' = { ...s, phase: 1, files: 0, idle: 0, observedIdle: 0 }
    else s' = { ...s, done: true },
  }
  action retry = all {
    s.stopped, s.attempt == 0,
    s' = { ...s, attempt: 1, phase: 0, files: 0, idle: 0, observedIdle: 0, stopped: false },
  }
  action advance = any { tick, completedFile, expire, nextPhase, retry }
  action step = any { advance, noise, s' = s }
  val truthfulClock = s.idle == s.observedIdle
  val noFalseTimeout = not(s.stopped) or s.idle >= 3
  val terminal = s.done or (s.stopped and s.attempt == 1)
  temporal completion = weakFair(advance, s).implies(eventually(terminal))
}

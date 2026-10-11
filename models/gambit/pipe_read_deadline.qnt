module pipe_read_deadline {
  // Test policy: ten seconds bounds each read, not the entire conversation.
  // Abstract two-tick interval and three reads; no fairness/latency guarantee.
  type State = { fixed: bool, now: int, deadline: int, started: int,
                 reads: int, reading: bool, timedOut: bool, stale: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, now: 0, deadline: 2, started: 0, reads: 0,
    reading: false, timedOut: false, stale: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action beginRead = all {
    not(s.reading), not(s.timedOut), s.reads < 3,
    s' = { ...s, reading: true, started: s.now,
           deadline: if (s.fixed) s.now + 2 else s.deadline },
  }
  action tick = all {
    s.reading, s.now < 6, s' = { ...s, now: s.now + 1 },
  }
  action completeRead = all {
    s.reading, s.now < s.deadline,
    s' = { ...s, reading: false, reads: s.reads + 1 },
  }
  action expire = all {
    s.reading, s.now >= s.deadline,
    s' = { ...s, reading: false, timedOut: true,
           stale: s.now - s.started < 2 },
  }
  action finished = all { s.timedOut or s.reads == 3, s' = s }
  action step = any { beginRead, tick, completeRead, expire, finished }
  val safe = not(s.stale)
}

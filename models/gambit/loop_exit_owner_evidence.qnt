module loop_exit_owner_evidence {
  // Source correspondence: ___TICKETLOCK_LOCK2 reserves with fetch-add, spins
  // until ___TICKETLOCK_READ_CURRENT equals that thread-local ticket, then the
  // macro ends. The comparison is the only owner evidence the candidate source
  // performs. It is not stored in a shared owner field. A later stack word
  // equal to current is not that comparison.
  type State = {
    next: int, current: int,
    t1: int, t2: int, p1: int, p2: int, e1: int, e2: int,
    w1: int, w2: int, ext: int, scanned: bool
  }
  var s: State
  pure def initial(seed: int): State = {
    next: seed, current: seed,
    t1: -1, t2: -1, p1: 0, p2: 0, e1: -1, e2: -1,
    w1: -1, w2: 0, ext: -1, scanned: false
  }
  action initLocal = s' = initial(0)
  action reserve1 = all {
    s.p1 == 0,
    s' = { ...s, t1: s.next, next: s.next + 1, p1: 1 },
  }
  action reserve2 = all {
    s.p2 == 0,
    s' = { ...s, t2: s.next, next: s.next + 1, p2: 1 },
  }
  action acquire1 = all {
    s.p1 == 1, s.current == s.t1,
    s' = { ...s, p1: 2, e1: s.t1 },
  }
  action acquire2 = all {
    s.p2 == 1, s.current == s.t2,
    s' = { ...s, p2: 2, e2: s.t2 },
  }
  action unlock1 = all {
    s.p1 == 2, s' = { ...s, p1: 3, current: s.current + 1 },
  }
  action unlock2 = all {
    s.p2 == 2, s' = { ...s, p2: 3, current: s.current + 1 },
  }
  action externalScan = all {
    not(s.scanned),
    val match1 = s.w1 >= 0 and s.w1 == s.current
    val match2 = s.w2 >= 0 and s.w2 == s.current
    s' = { ...s, scanned: true,
      ext: if (match1 and not(match2)) 1
        else if (match2 and not(match1)) 2 else 0 },
  }
  val terminal = s.p1 == 3 and s.p2 == 3
  action finished = all { terminal, s' = s }
  action step = any {
    reserve1, reserve2, acquire1, acquire2, unlock1, unlock2,
    externalScan, finished
  }
  val localEvidence =
    not(s.p1 == 2 and s.p2 == 2) and
    (s.p1 != 2 or (s.e1 == s.current and s.e1 == s.t1 and s.e1 >= 0)) and
    (s.p2 != 2 or (s.e2 == s.current and s.e2 == s.t2 and s.e2 >= 0))
  val externalSound = s.ext < 0 or s.ext == 0 or
    (s.ext == 1 and s.p1 == 2) or (s.ext == 2 and s.p2 == 2)
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}

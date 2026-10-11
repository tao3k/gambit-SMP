module promise_publication {
  // Two forces of one promise, distinct thunk results, optional one failure and
  // one nested force. State lock is abstract VM-local mutual exclusion. Thunks
  // run unlocked; commit rechecks the state after evaluation. Not exactly-once
  // thunk evaluation: duplicate evaluation is permitted, returned identity is not.
  type State = { repair: bool, retainLock: bool, lock: int, cache: int,
                 pc: int -> int, observed: int -> int, returned: int -> int,
                 failed: int -> bool, nested: bool }
  var s: State
  pure def initialState(repair: bool, retainLock: bool): State = {
    repair: repair, retainLock: retainLock, lock: 0, cache: 0,
    pc: Map(1 -> 0, 2 -> 0), observed: Map(1 -> 0, 2 -> 0),
    returned: Map(1 -> 0, 2 -> 0), failed: Map(1 -> false, 2 -> false), nested: false,
  }
  action initOld = s' = initialState(false, false)
  // Independent anti-regression control, not a claimed defect of PR1039.
  action initRetainedLock = s' = initialState(true, true)
  action initFixed = s' = initialState(true, false)

  action readLock(w: int): bool = all {
    s.pc.get(w) == 0, s.lock == 0,
    s' = { ...s, pc: s.pc.set(w, 1), lock: if (s.repair) w else 0 },
  }
  action readState(w: int): bool = all {
    s.pc.get(w) == 1,
    s' = { ...s, pc: s.pc.set(w, if (s.cache == 0) 2 else 4),
           returned: s.returned.set(w, s.cache),
           lock: if (s.cache == 0 and s.retainLock) s.lock else 0 },
  }
  action evaluate(w: int): bool = all {
    s.pc.get(w) == 2, s' = { ...s, pc: s.pc.set(w, 3) },
  }
  action exceptionRetry(w: int): bool = all {
    s.pc.get(w) == 2, not(s.failed.get(w)), s.lock != w,
    s' = { ...s, pc: s.pc.set(w, 0), failed: s.failed.set(w, true) },
  }
  // Abstract a nested force that determines the same state while the outer
  // thunk runs. It is not a proof of arbitrary recursion or delay-force linking.
  action nestedForce(w: int): bool = all {
    s.pc.get(w) == 2, s.lock == 0, s.cache == 0, not(s.nested),
    s' = { ...s, cache: w + 2, nested: true },
  }
  action commitLock(w: int): bool = all {
    s.pc.get(w) == 3, s.lock == 0,
    s' = { ...s, pc: s.pc.set(w, 5), lock: if (s.repair) w else 0 },
  }
  action commitCheck(w: int): bool = all {
    s.pc.get(w) == 5,
    s' = { ...s, pc: s.pc.set(w, 6), observed: s.observed.set(w, s.cache) },
  }
  action commit(w: int): bool = all {
    s.pc.get(w) == 6,
    val selected = if (s.observed.get(w) == 0) w else s.observed.get(w)
    s' = { ...s, pc: s.pc.set(w, 4), cache: selected,
           returned: s.returned.set(w, selected), lock: 0 },
  }
  action finished = all { s.pc.get(1) == 4, s.pc.get(2) == 4, s' = s }
  action step = any { readLock(1), readLock(2), readState(1), readState(2),
    evaluate(1), evaluate(2), exceptionRetry(1), exceptionRetry(2),
    nestedForce(1), nestedForce(2), commitLock(1), commitLock(2),
    commitCheck(1), commitCheck(2), commit(1), commit(2), finished }
  val identitySafe = s.pc.get(1) != 4 or s.pc.get(2) != 4 or
    (s.returned.get(1) == s.returned.get(2) and s.returned.get(1) == s.cache)
  val callbackSafe = (s.pc.get(1) != 2 or s.lock != 1) and
                     (s.pc.get(2) != 2 or s.lock != 2)
  val safe = identitySafe and callbackSafe
}

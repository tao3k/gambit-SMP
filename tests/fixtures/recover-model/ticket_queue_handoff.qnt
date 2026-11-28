module ticket_queue_handoff {
  // One completed chunk, two lock holders, one ticket handoff. The previous
  // holder releases after updating head. A full fence when reserving a future
  // ticket does not acquire writes made later, before that ticket is served.
  // Cached head abstracts a read reordered before the volatile ticket poll;
  // this is not a complete C/ARM weak-memory or spinlock refinement proof.
  type State = { acquire: bool, head: int, cached: int, reserved: bool,
    firstClaimed: bool, released: bool, observed: bool, consumed: bool,
    duplicate: bool }
  var s: State
  pure def initialState(acquire: bool): State = {
    acquire: acquire, head: 0, cached: -1, reserved: false,
    firstClaimed: false, released: false, observed: false,
    consumed: false, duplicate: false,
  }
  action initOld = s' = initialState(false)
  action initFixed = s' = initialState(true)
  action reserveTicket = all {
    not(s.reserved), s' = { ...s, reserved: true },
  }
  action prefetchHead = all {
    s.reserved, not(s.observed), s.cached == -1,
    s' = { ...s, cached: s.head },
  }
  action firstClaim = all {
    not(s.firstClaimed), s' = { ...s, head: 1, firstClaimed: true },
  }
  action releaseTicket = all {
    s.firstClaimed, not(s.released), s' = { ...s, released: true },
  }
  action observeTicket = all {
    s.reserved, s.released, not(s.observed), s.cached != -1,
    s' = { ...s, observed: true, cached: if (s.acquire) s.head else s.cached },
  }
  action consumeHead = all {
    s.observed, not(s.consumed),
    s' = { ...s, consumed: true,
      duplicate: s.firstClaimed and s.cached == 0 },
  }
  action idle = all { s.consumed, s' = s }
  action step = any { reserveTicket, prefetchHead, firstClaim, releaseTicket,
    observeTicket, consumeHead, idle }
  val safe = not(s.duplicate)
}

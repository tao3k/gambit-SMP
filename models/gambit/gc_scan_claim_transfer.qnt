module gc_scan_claim_transfer {
  // Two physical slots alias one logical object. Two GC epochs reuse addresses.
  // Frontier is a copy-ready boundary, not the forwarding identity. Queue
  // release/acquire is assumed; this model checks ownership above that boundary.
  type State = { fault: int, epoch: int, copied: int, local: bool,
    cursor: int, queued: bool, queueStart: int, thief: bool, thiefCursor: int,
    claimEpoch: int, spaces: int -> int, visits: int -> int,
    forwarded: bool, copies: int, rewound: bool,
    badInput: bool, badReady: bool, badEpoch: bool }
  var s: State
  pure def initialState(fault: int): State = {
    fault: fault, epoch: 1, copied: 0, local: true, cursor: 0,
    queued: false, queueStart: 0, thief: false, thiefCursor: 0, claimEpoch: 1,
    spaces: Map(1 -> 0, 2 -> 0), visits: Map(1 -> 0, 2 -> 0),
    forwarded: false, copies: 0, rewound: false,
    badInput: false, badReady: false, badEpoch: false,
  }
  action initFixed = s' = initialState(0)
  action initRetainedOwner = s' = initialState(1)
  action initEarlyFrontier = s' = initialState(2)
  action initRevisitedSlot = s' = initialState(3)
  action initStaleClaim = s' = initialState(4)
  action copyWord = all { s.copied < 2, s' = { ...s, copied: s.copied + 1 } }
  action exportTail = all {
    s.local, not(s.queued), not(s.thief), s.cursor < 2,
    s.copied == 2 or s.fault == 2,
    s' = { ...s, local: s.fault == 1, queued: true, queueStart: s.cursor },
  }
  action acquire = all {
    s.queued, not(s.thief),
    s' = { ...s, queued: false, thief: true, thiefCursor: s.queueStart,
      claimEpoch: s.epoch },
  }
  action staleAcquire = all {
    s.fault == 4, s.epoch == 2, s.queued, not(s.thief),
    s' = { ...s, queued: false, thief: true, thiefCursor: s.queueStart,
      claimEpoch: 1, badEpoch: true },
  }
  action scan(localOwner: bool): bool = {
    val cursor = if (localOwner) s.cursor else s.thiefCursor
    val slot = cursor + 1
    all {
    cursor < 2,
    if (localOwner) s.local and slot <= s.copied else s.thief,
    s' = { ...s,
      cursor: if (localOwner) slot else s.cursor,
      thiefCursor: if (localOwner) s.thiefCursor else slot,
      visits: s.visits.set(slot, s.visits.get(slot) + 1),
      spaces: s.spaces.set(slot, 1), forwarded: true,
      copies: if (s.forwarded) s.copies else s.copies + 1,
      badInput: s.badInput or s.spaces.get(slot) != 0,
      badReady: s.badReady or slot > s.copied,
      badEpoch: s.badEpoch or (not(localOwner) and s.claimEpoch != s.epoch) },
    }
  }
  action rewind = all {
    s.fault == 3, s.local, s.cursor == 1, not(s.rewound),
    s' = { ...s, cursor: 0, rewound: true },
  }
  action releaseLocal = all { s.local, s.cursor == 2, s' = { ...s, local: false } }
  action releaseThief = all { s.thief, s.thiefCursor == 2, s' = { ...s, thief: false } }
  val drained = s.copied == 2 and not(s.local) and not(s.queued) and not(s.thief)
  action nextEpoch = all {
    drained, s.epoch == 1,
    s' = { ...initialState(s.fault), epoch: 2, claimEpoch: 2,
      badInput: s.badInput, badReady: s.badReady, badEpoch: s.badEpoch },
  }
  action finished = all { drained, s.epoch == 2, s' = s }
  action step = any { copyWord, exportTail, acquire, staleAcquire, scan(true),
    scan(false), rewind, releaseLocal, releaseThief, nextEpoch, finished }
  val ownershipSafe = not(s.local and (s.queued or s.thief))
  val inputSafe = not(s.badInput) and Set(1, 2).forall(i => s.visits.get(i) <= 1)
  val readySafe = not(s.badReady)
  val epochSafe = not(s.badEpoch)
  val identitySafe = s.copies <= 1
  val completionSafe = not(drained) or Set(1, 2).forall(i => s.visits.get(i) == 1)
  val safe = ownershipSafe and inputSafe and readySafe and epochSafe and identitySafe and completionSafe
  temporal progress = always((drained and s.epoch == 2) or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(drained and s.epoch == 2))
}

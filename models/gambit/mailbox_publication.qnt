module mailbox_publication {
  // Two senders, one destination thread, at most two message identities.
  // Final mailbox install is atomic under the thread lock in the repair.
  // FIFO mutation is atomic under a distinct mailbox mutex. Allocation happens
  // before thread locking. GC, lock implementation, waiting and failures omitted.
  type State = { repair: bool, scenario: int, box: int, local: int -> int,
                 pc: int -> int, messages: int -> int, rx: int, snapshot: int }
  var s: State
  pure def initialState(repair: bool, scenario: int): State = {
    repair: repair, scenario: scenario, box: if (scenario == 1) 1 else 0,
    local: if (scenario == 1) Map(1 -> 1, 2 -> 1) else Map(1 -> 0, 2 -> 0),
    pc: if (scenario == 1) Map(1 -> 4, 2 -> 3) else Map(1 -> 0, 2 -> 0),
    messages: Map(1 -> (if (scenario == 1) 1 else 0), 2 -> 0),
    rx: if (scenario == 1) 0 else -1, snapshot: 0,
  }
  action initOld = s' = initialState(false, 0)
  action initUnsafeReceive = s' = initialState(false, 1)
  action initFixed = s' = initialState(true, -1)
  action choose(which: int): bool = all {
    s.scenario == -1, s' = initialState(true, which),
  }
  action allocate(w: int): bool = all {
    s.scenario == 0, s.pc.get(w) == 0,
    s' = { ...s, pc: s.pc.set(w, 1) },
  }
  action checkOld(w: int): bool = all {
    s.scenario == 0, not(s.repair), s.pc.get(w) == 1,
    s' = { ...s, pc: s.pc.set(w, 2), local: s.local.set(w, s.box) },
  }
  action install(w: int): bool = all {
    s.scenario == 0,
    (s.repair and s.pc.get(w) == 1) or (not(s.repair) and s.pc.get(w) == 2),
    val observed = if (s.repair) s.box else s.local.get(w)
    val selected = if (observed == 0) w else observed
    s' = { ...s, box: selected, local: s.local.set(w, selected), pc: s.pc.set(w, 3) },
  }
  // Sender 1 contributes bit 1, sender 2 bit 2, each exactly once.
  action send(w: int): bool = all {
    s.pc.get(w) == 3,
    val box = s.local.get(w)
    s' = { ...s, messages: s.messages.set(box, s.messages.get(box) + w),
           pc: s.pc.set(w, 4) },
  }
  action readReceive = all {
    s.scenario == 1, not(s.repair), s.rx == 0,
    s' = { ...s, rx: 1, snapshot: s.messages.get(1) },
  }
  action removeReceive = all {
    s.scenario == 1, (s.repair and s.rx == 0) or (not(s.repair) and s.rx == 1),
    val observed = if (s.repair) s.messages.get(1) else s.snapshot
    s' = { ...s, rx: 2, messages: s.messages.set(1, observed - 1) },
  }
  action finished = all {
    s.pc.get(1) == 4, s.pc.get(2) == 4, s.scenario == 0 or s.rx == 2, s' = s,
  }
  action step = any { choose(0), choose(1), allocate(1), allocate(2),
    checkOld(1), checkOld(2), install(1), install(2), send(1), send(2),
    readReceive, removeReceive, finished }
  val publicationSafe = s.scenario != 0 or s.pc.get(1) != 4 or s.pc.get(2) != 4 or
                        (s.box != 0 and s.messages.get(s.box) == 3)
  val receiveSafe = s.scenario != 1 or s.rx != 2 or s.pc.get(2) != 4 or s.messages.get(1) == 2
  val safe = publicationSafe and receiveSafe
}

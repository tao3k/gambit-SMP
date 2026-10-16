module vm_registry_interrupt_admission {
  // Proposal, not source refinement. Atomic admission joins the closed bit and
  // reader reference count. Signal readers never wait for the writer mutex.
  // Two independent interrupt bits, one retirement and one live registry anchor.
  type State = { policy: str, open: bool, writer: str, alive: bool,
    readers: Set[int], phase: int -> str, captured: Set[int],
    pending: Set[int], delivered: Set[int], badRead: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, open: true, writer: "close", alive: true,
    readers: Set(), phase: Map(1 -> "new", 2 -> "new"), captured: Set(),
    pending: Set(), delivered: Set(), badRead: false,
  }
  action init = s' = initial("atomic-admit-recheck")
  action initWriterOnly = s' = initial("writer-only")
  action initEarlyReplay = s' = initial("early-replay-no-recheck")
  action request(id: int): bool = all {
    s.phase.get(id) == "new",
    s' = if (s.open) { ...s, readers: s.readers.union(Set(id)),
        captured: if (s.alive) s.captured.union(Set(id)) else s.captured,
        phase: s.phase.set(id, "use") }
      else { ...s, phase: s.phase.set(id, "record") },
  }
  action use(id: int): bool = all {
    s.phase.get(id) == "use",
    s' = { ...s, badRead: s.badRead or (s.captured.contains(id) and not(s.alive)),
      delivered: s.delivered.union(Set(id)), phase: s.phase.set(id, "exit") },
  }
  action leave(id: int): bool = all {
    s.phase.get(id) == "exit", s.readers.contains(id),
    s' = { ...s, readers: s.readers.exclude(Set(id)), phase: s.phase.set(id, "done") },
  }
  action record(id: int): bool = all {
    s.phase.get(id) == "record",
    s' = { ...s, pending: s.pending.union(Set(id)),
      phase: s.phase.set(id, if (s.policy == "early-replay-no-recheck") "done" else "recheck") },
  }
  action recheck(id: int): bool = all {
    s.phase.get(id) == "recheck",
    // If reopen raced with recording, this reader must drain the mailbox.
    s' = if (s.open) { ...s, delivered: s.delivered.union(s.pending),
        pending: Set(), phase: s.phase.set(id, "done") }
      else { ...s, phase: s.phase.set(id, "done") },
  }
  action close = all {
    s.writer == "close", s' = { ...s, open: false, writer: "drain" },
  }
  action unlink = all {
    s.writer == "drain", s.policy == "writer-only" or s.readers == Set(),
    s' = { ...s, alive: false, writer: "open" },
  }
  action reopen = all {
    s.writer == "open", s' = { ...s, open: true, writer: "replay" },
  }
  action replay = all {
    s.writer == "replay",
    // Atomic exchange owns each coalesced bit once; no old VM pointer is queued.
    s' = { ...s, delivered: s.delivered.union(s.pending), pending: Set(), writer: "done" },
  }
  val callersDone = Set(1, 2).forall(id => s.phase.get(id) == "done")
  val quiescent = s.writer == "done" and callersDone and s.readers == Set()
  val terminal = quiescent and s.pending == Set()
  action finished = all { terminal, s' = s }
  action step = {
    nondet id = Set(1, 2).oneOf()
    any { request(id), use(id), leave(id), record(id), recheck(id),
      close, unlink, reopen, replay, finished }
  }
  val lifetimeSafe = s.alive or s.readers.intersect(s.captured) == Set()
  val deliverySafe = not(quiescent) or s.delivered == Set(1, 2)
  val safe = not(s.badRead) and lifetimeSafe and deliverySafe
  // Finite acyclic participants; this does not prove unbounded fairness.
  val noStall = terminal or enabled(step)
  run admittedReaderDrainTest = init.then(request(1)).then(close)
    .then(use(1)).then(leave(1)).then(unlink).then(reopen).then(replay)
    .then(request(2)).then(use(2)).then(leave(2))
    .then(all { assert(terminal), assert(safe), s' = s })
  run lateDeferredPublicationTest = init.then(close).then(unlink)
    .then(request(1)).then(reopen).then(replay).then(record(1)).then(recheck(1))
    .then(request(2)).then(use(2)).then(leave(2))
    .then(all { assert(terminal), assert(safe), s' = s })
  run signalDuringWriterTest = init.then(close).then(request(1)).then(record(1))
    .then(recheck(1)).then(unlink).then(reopen).then(replay)
    .then(request(2)).then(use(2)).then(leave(2))
    .then(all { assert(terminal), assert(safe), s' = s })
  run writerMutexOnlyControlTest = initWriterOnly.then(request(1)).then(close).then(unlink)
    .then(use(1)).then(all { assert(not(safe)), s' = s })
  run lostDeferredInterruptControlTest = initEarlyReplay.then(close).then(unlink)
    .then(request(1)).then(reopen).then(replay).then(record(1))
    .then(request(2)).then(use(2)).then(leave(2))
    .then(all { assert(not(safe)), assert(quiescent), assert(s.pending == Set(1)), s' = s })
}

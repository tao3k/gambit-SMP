module vm_registry_repeated_retirement {
  // Two registry mutations, not a processor-count bound. Replayed signals are
  // registry readers too: reopening does not grant a permanent lifetime lease.
  type State = { policy: str, open: bool, writer: str, generation: int,
    retired: Set[int], readers: Set[int], phase: int -> str,
    captured: int -> int, pending: Set[int], delivered: Set[int], badRead: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, open: true, writer: "close", generation: 1,
    retired: Set(), readers: Set(), phase: Map(1 -> "new", 2 -> "new"),
    captured: Map(1 -> 0, 2 -> 0), pending: Set(), delivered: Set(), badRead: false,
  }
  action init = s' = initial("atomic-admission")
  action initSplitAdmission = s' = initial("split-admission")
  action initReplayBypass = s' = initial("replay-bypass")
  action request(id: int): bool = all {
    s.phase.get(id) == "new",
    s' = if (s.open) { ...s,
      readers: if (s.policy == "split-admission") s.readers else s.readers.union(Set(id)),
      captured: s.captured.set(id, s.generation),
      phase: s.phase.set(id, if (s.policy == "split-admission") "checked" else "use") }
    else { ...s, phase: s.phase.set(id, "record") },
  }
  action lateAdmission(id: int): bool = all {
    s.phase.get(id) == "checked",
    s' = { ...s, readers: s.readers.union(Set(id)), phase: s.phase.set(id, "use") },
  }
  action record(id: int): bool = all {
    s.phase.get(id) == "record",
    s' = { ...s, pending: s.pending.union(Set(id)), phase: s.phase.set(id, "pending") },
  }
  action replay(id: int): bool = all {
    s.open, s.phase.get(id) == "pending", s.pending.contains(id),
    s' = { ...s,
      readers: if (s.policy == "replay-bypass") s.readers else s.readers.union(Set(id)),
      captured: s.captured.set(id, s.generation), pending: s.pending.exclude(Set(id)),
      phase: s.phase.set(id, "use") },
  }
  action use(id: int): bool = all {
    s.phase.get(id) == "use",
    s' = { ...s, badRead: s.badRead or s.retired.contains(s.captured.get(id)),
      delivered: s.delivered.union(Set(id)), phase: s.phase.set(id, "exit") },
  }
  action leave(id: int): bool = all {
    s.phase.get(id) == "exit",
    s' = { ...s, readers: s.readers.exclude(Set(id)), phase: s.phase.set(id, "done") },
  }
  action close = all {
    s.writer == "close", s' = { ...s, open: false, writer: "drain" },
  }
  action retire = all {
    s.writer == "drain", s.readers == Set(),
    s' = { ...s, retired: s.retired.union(Set(s.generation)),
      generation: s.generation + 1, writer: "open" },
  }
  action reopen = all {
    s.writer == "open",
    s' = { ...s, open: true, writer: if (s.generation == 3) "done" else "close" },
  }
  val terminal = s.writer == "done" and s.pending == Set() and s.readers == Set()
    and Set(1, 2).forall(id => s.phase.get(id) == "done")
  action finished = all { terminal, s' = s }
  action step = {
    nondet id = Set(1, 2).oneOf()
    any { request(id), lateAdmission(id), record(id), replay(id), use(id), leave(id),
      close, retire, reopen, finished }
  }
  val safe = not(s.badRead)
  val admissionSafe = safe
  val replaySafe = safe
  val deliverySafe = not(terminal) or s.delivered == Set(1, 2)
  val noStall = terminal or enabled(step)
  run splitAdmissionControlTest = initSplitAdmission.then(request(1)).then(close)
    .then(retire).then(lateAdmission(1)).then(use(1))
    .then(all { assert(not(safe)), s' = s })
  run replayBypassControlTest = initReplayBypass.then(close).then(request(1))
    .then(record(1)).then(retire).then(reopen).then(replay(1))
    .then(close).then(retire).then(use(1))
    .then(all { assert(not(safe)), s' = s })
  run replayDrainTest = init.then(close).then(request(1)).then(record(1))
    .then(retire).then(reopen).then(replay(1)).then(close).then(use(1)).then(leave(1))
    .then(retire).then(reopen).then(request(2)).then(use(2)).then(leave(2))
    .then(all { assert(terminal), assert(safe), assert(deliverySafe), s' = s })
}

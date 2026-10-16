module registry_capacity_writer_replay {
  // Two slots model a capacity boundary, not a machine processor count.
  // One coalesced interrupt; no terminal shutdown or fairness assumption.
  type State = { policy: str, holders: Set[int], gate: bool, writer: str,
    signal: str, pending: bool, delivered: bool, flush: str, resource: bool,
    badRead: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, holders: Set(1, 2), gate: true, writer: "new",
    signal: "new", pending: false, delivered: false, flush: "idle",
    resource: true, badRead: false,
  }
  action init = s' = initial("release-and-record-recheck")
  action initNoReleaseReplay = s' = initial("no-release-replay")
  action initNoRecordRecheck = s' = initial("no-record-recheck")
  action request = all { s.signal == "new",
    s' = { ...s, signal: "record" } }
  action record = all { s.signal == "record",
    s' = { ...s, signal: "done", pending: true,
      flush: if (s.policy == "no-record-recheck") s.flush
        else if (s.flush == "idle") "check" else s.flush } }
  action leave(id: int): bool = all { s.holders.contains(id), id != 3,
    s' = { ...s, holders: s.holders.exclude(Set(id)),
      flush: if (s.pending and s.policy != "no-release-replay" and s.flush == "idle")
        "check" else s.flush } }
  action check = all { s.flush == "check",
    s' = if (s.pending and s.gate and s.holders.size() < 2)
      { ...s, holders: s.holders.union(Set(3)), flush: "leased" }
    else { ...s, flush: "idle" } }
  action deliver = all { s.flush == "leased",
    s' = { ...s, delivered: s.delivered or s.pending, pending: false,
      badRead: s.badRead or not(s.resource), flush: "release" } }
  action rawRelease = all { s.flush == "release",
    s' = { ...s, holders: s.holders.exclude(Set(3)), flush: "check" } }
  action close = all { s.writer == "new",
    s' = { ...s, gate: false, writer: "drain" } }
  action noMutation = all { s.writer == "new",
    s' = { ...s, writer: "done" } }
  action replace = all { s.writer == "drain", s.holders == Set(),
    s' = { ...s, resource: false, writer: "replace" } }
  action reopen = all { s.writer == "replace",
    s' = { ...s, resource: true, gate: true, writer: "done",
      flush: if (s.flush == "idle") "check" else s.flush } }
  val settled = s.writer == "done" and s.signal == "done"
    and s.holders == Set() and s.flush == "idle"
  val terminal = settled and not(s.pending)
  action finished = all { terminal, s' = s }
  action step = {
    nondet id = Set(1, 2).oneOf()
    any { request, record, leave(id), check, deliver, rawRelease,
      close, noMutation, replace, reopen, finished }
  }
  val safe = not(s.badRead) and (not(settled) or s.delivered)
    and (not(s.holders.contains(3)) or s.resource)
  val noStall = terminal or enabled(step)
  run lateRecordControlTest = initNoRecordRecheck.then(request).then(leave(1))
    .then(leave(2)).then(close).then(replace).then(reopen).then(check).then(record)
    .then(all { assert(settled), assert(not(safe)), s' = s })
  run releaseControlTest = initNoReleaseReplay.then(noMutation).then(request).then(record)
    .then(check).then(leave(1)).then(leave(2))
    .then(all { assert(settled), assert(not(safe)), s' = s })
  run lateRecordReplayTest = init.then(request).then(leave(1)).then(leave(2))
    .then(close).then(replace).then(reopen).then(check).then(record)
    .then(check).then(deliver).then(rawRelease).then(check)
    .then(all { assert(terminal), assert(safe), s' = s })
}

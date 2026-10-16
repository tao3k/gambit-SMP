module vm_registry_resize_grace {
  // Two processors, one global interrupt reader, one shrinking barrier.
  // Sequentially consistent lease operations; direct embedding users are
  // externally owned. This does not prove the C memory-model refinement.
  type State = { policy: str, gate: bool, lease: bool, reader: str,
    snapshot: int, count: int, resource: bool, worker: str, owner: str,
    pending: bool, badUse: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, gate: true, lease: false, reader: "new", snapshot: 0,
    count: 2, resource: true, worker: "need-interrupt", owner: "collect",
    pending: false, badUse: false,
  }
  action init = s' = initial("barrier-grace")
  action initCountOnly = s' = initial("count-only")
  action initEarlyClose = s' = initial("early-close")
  action enter = all { s.reader == "new", s.gate,
    s' = { ...s, reader: "snapshot", lease: true } }
  action snapshot = all { s.reader == "snapshot",
    s' = { ...s, reader: "use", snapshot: s.count } }
  action use = all { s.reader == "use",
    s' = { ...s, reader: "leave",
      badUse: s.badUse or (s.snapshot == 2 and not(s.resource)) } }
  action leave = all { s.reader == "leave",
    s' = { ...s, reader: "done", lease: false } }
  action sendInterrupt = all { s.worker == "need-interrupt", s.gate,
    s' = { ...s, worker: "arrived", pending: false } }
  action deferInterrupt = all { s.worker == "need-interrupt", not(s.gate),
    not(s.pending), s' = { ...s, pending: true } }
  action closeTooEarly = all { s.owner == "collect", s.policy == "early-close",
    s.worker == "need-interrupt",
    s' = { ...s, gate: false, owner: "await-arrival" } }
  action collected = all { s.owner == "collect", s.worker == "arrived",
    s.policy != "early-close",
    s' = { ...s, owner: if (s.policy == "count-only") "publish" else "close" } }
  action close = all { s.owner == "close", s.worker == "arrived",
    s' = { ...s, gate: false, owner: "drain" } }
  action drained = all { s.owner == "drain", not(s.lease),
    s' = { ...s, owner: "publish" } }
  action publish = all { s.owner == "publish",
    s' = { ...s, count: 1,
      owner: if (s.policy == "count-only") "reply" else "open" } }
  action reopen = all { s.owner == "open",
    s' = { ...s, gate: true, owner: "reply" } }
  action reply = all { s.owner == "reply", s.worker == "arrived",
    s' = { ...s, worker: "released", owner: "join" } }
  action retire = all { s.worker == "released",
    s' = { ...s, resource: false, worker: "exited" } }
  action joined = all { s.owner == "join", s.worker == "exited",
    s' = { ...s, owner: "done" } }
  val terminal = s.owner == "done" and s.reader == "done"
  action finished = all { terminal, s' = s }
  action step = any { enter, snapshot, use, leave, sendInterrupt, deferInterrupt,
    closeTooEarly, collected, close, drained, publish, reopen, reply, retire,
    joined, finished }
  val safe = not(s.badUse) and
    (not(s.lease and s.snapshot == 2) or s.resource)
  val noStall = terminal or enabled(step)
  val contract = safe and noStall
  // The test interpreter lacks enabled(); TLC checks noStall independently.
  val earlyCloseBlocked = s.owner == "await-arrival" and
    s.worker == "need-interrupt" and not(s.gate) and s.pending and
    s.reader == "new" and not(s.lease)
  run cachedCountControlTest = initCountOnly.then(enter).then(snapshot)
    .then(sendInterrupt).then(collected).then(publish).then(reply).then(retire)
    .then(use).then(all { assert(not(safe)), assert(s.badUse), s' = s })
  run earlyCloseControlTest = initEarlyClose.then(closeTooEarly)
    .then(deferInterrupt).then(all { assert(earlyCloseBlocked), s' = s })
  run admittedReaderTest = init.then(enter).then(snapshot).then(sendInterrupt)
    .then(collected).then(close).then(use).then(leave).then(drained)
    .then(publish).then(reopen).then(reply).then(retire).then(joined)
    .then(all { assert(contract), assert(terminal), s' = s })
  run lateReaderTest = init.then(sendInterrupt).then(collected).then(close)
    .then(drained).then(publish).then(reopen).then(enter).then(snapshot)
    .then(reply).then(retire).then(use).then(leave).then(joined)
    .then(all { assert(contract), assert(terminal), s' = s })
}

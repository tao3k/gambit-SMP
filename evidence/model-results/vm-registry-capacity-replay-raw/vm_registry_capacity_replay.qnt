module vm_registry_capacity_replay {
  // One-slot abstraction of a saturated unsigned reader counter. This is a
  // capacity boundary, not a host CPU limit or a claim of 64-bit exhaustion.
  type State = { policy: str, owner: str, signal: str, pending: bool,
    delivered: bool, flushing: bool, overflow: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, owner: "active", signal: "new", pending: false,
    delivered: false, flushing: false, overflow: false,
  }
  action init = s' = initial("release-rechecks")
  action initOld = s' = initial("release-without-replay")
  action initOverflow = s' = initial("overflow-admits")
  action request = all {
    s.signal == "new",
    s' = if (s.owner == "active") {
      ...s, signal: "record", overflow: s.policy == "overflow-admits" }
    else { ...s, signal: "delivered", delivered: true },
  }
  action record = all {
    s.signal == "record", s' = { ...s, signal: "recheck", pending: true },
  }
  action recheck = all {
    s.signal == "recheck",
    s' = if (s.owner == "released") {
      ...s, signal: "done", delivered: true, pending: false }
    else { ...s, signal: "done" },
  }
  action signalDone = all {
    s.signal == "delivered", s' = { ...s, signal: "done" },
  }
  action release = all {
    s.owner == "active",
    s' = { ...s, owner: "released", flushing: s.policy != "release-without-replay" },
  }
  action flush = all {
    s.flushing, s' = { ...s, flushing: false,
      delivered: s.delivered or s.pending, pending: false },
  }
  val quiescent = s.owner == "released" and s.signal == "done" and not(s.flushing)
  val terminal = quiescent and not(s.pending)
  action finished = all { terminal, s' = s }
  action step = any { request, record, recheck, signalDone, release, flush, finished }
  val deliverySafe = not(quiescent) or s.delivered
  val overflowSafe = not(s.overflow)
  val safe = deliverySafe and overflowSafe
  val noStall = terminal or enabled(step)
  run strandedMailboxControlTest = initOld.then(request).then(record).then(recheck)
    .then(release).then(all { assert(quiescent), assert(not(safe)), s' = s })
  run releaseReplayTest = init.then(request).then(record).then(recheck)
    .then(release).then(flush)
    .then(all { assert(terminal), assert(safe), s' = s })
  run lateRecordTest = init.then(request).then(release).then(flush)
    .then(record).then(recheck)
    .then(all { assert(terminal), assert(safe), s' = s })
  run overflowControlTest = initOverflow.then(request)
    .then(all { assert(not(overflowSafe)), s' = s })
}

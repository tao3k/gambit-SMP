module retired_rc_gc_visibility {
  // One RC root in a retired slot. GC generations are abstract equality tokens.
  // OS join ownership and donor memory quiescence are different obligations.
  type State = { policy: str, phase: str, count: int, pending: bool,
    joined: bool, donorQuiescent: bool, storage: bool, rootAtOwner: bool,
    rootEpoch: int, gcEpoch: int, returned: bool, gcDone: bool,
    badTransfer: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, phase: "active", count: 2, pending: false,
    joined: false, donorQuiescent: false, storage: true, rootAtOwner: false,
    rootEpoch: 0, gcEpoch: 0, returned: false, gcDone: false,
    badTransfer: false,
  }
  action init = s' = initial("ack-transfer-before-resume")
  action initCurrentRetention = s' = initial("retain-unscanned")
  action initTransferWithoutAck = s' = initial("transfer-without-ack")
  action shrink = all { s.phase == "active",
    s' = { ...s, count: 1, pending: true, phase: "join" } }
  action donorStops = all { s.phase != "active", not(s.donorQuiescent),
    s' = { ...s, donorQuiescent: true } }
  action joinFails = all { s.phase == "join",
    s' = { ...s, phase: "failed" } }
  action joinSucceeds = all { s.phase == "join" or s.phase == "retry",
    s.donorQuiescent,
    s' = { ...s, joined: true, pending: false, phase: "handoff" } }
  action transfer = all { not(s.rootAtOwner),
    s.phase == "handoff" or
      (s.phase == "failed" and s.policy != "retain-unscanned"),
    s.donorQuiescent or s.policy == "transfer-without-ack",
    s' = { ...s, rootAtOwner: true,
      badTransfer: s.badTransfer or not(s.donorQuiescent) } }
  action returnResult = all { not(s.returned),
    (s.phase == "failed" and
      (s.policy == "retain-unscanned" or s.rootAtOwner)) or
      (s.phase == "handoff" and s.rootAtOwner),
    s' = { ...s, returned: true, phase: "running" } }
  action collect = all { s.returned, not(s.gcDone),
    s' = { ...s, gcEpoch: 1, gcDone: true,
      rootEpoch: if (s.rootAtOwner or s.count == 2) 1 else s.rootEpoch } }
  action retry = all { s.phase == "running", s.pending, s.gcDone,
    s' = { ...s, phase: "retry" } }
  action recovered = all { s.phase == "handoff", s.returned, s.rootAtOwner,
    s' = { ...s, phase: "running" } }
  action reclaim = all { s.phase == "running", s.joined, s.gcDone,
    s' = { ...s, storage: false, phase: "done" } }
  val terminal = s.phase == "done"
  action finished = all { terminal, s' = s }
  action step = any { shrink, donorStops, joinFails, joinSucceeds, transfer,
    returnResult, collect, retry, recovered, reclaim, finished }
  val rootsVisible = not(s.gcDone) or s.rootEpoch == s.gcEpoch
  val ownershipSafe = not(s.badTransfer) and (not(s.pending) or s.storage)
  val safe = rootsVisible and ownershipSafe
  val noStall = terminal or enabled(step)
  run retainedButUnscannedControlTest = initCurrentRetention.then(shrink)
    .then(joinFails).then(donorStops).then(returnResult).then(collect)
    .then(all { assert(s.storage), assert(s.pending), assert(not(rootsVisible)), s' = s })
  run transferWithoutAckControlTest = initTransferWithoutAck.then(shrink)
    .then(joinFails).then(transfer)
    .then(all { assert(not(ownershipSafe)), s' = s })
  run failedJoinVisibleRootsTest = init.then(shrink).then(joinFails)
    .then(donorStops).then(transfer).then(returnResult).then(collect)
    .then(all { assert(safe), assert(s.pending), assert(s.storage), s' = s })
  run failedJoinRecoveryTest = init.then(shrink).then(joinFails).then(donorStops)
    .then(transfer).then(returnResult).then(collect).then(retry).then(joinSucceeds)
    .then(recovered).then(reclaim)
    .then(all { assert(safe), assert(terminal), s' = s })
  run successfulJoinTest = init.then(shrink).then(donorStops).then(joinSucceeds)
    .then(transfer).then(returnResult).then(collect).then(reclaim)
    .then(all { assert(safe), assert(terminal), s' = s })
}

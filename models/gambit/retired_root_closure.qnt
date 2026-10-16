module retired_root_closure {
  import retired_rc_gc_visibility as R from "./retired_rc_gc_visibility"
  // RC and still lists are separate roots. Accounting is conserved by handoff.
  // Donor quiescence is inherited, not implemented by a pre-exit checkpoint.
  var policy: str
  var stillAtOwner: bool
  var childEpoch: int
  var donorWords: int
  var ownerWords: int
  var donorDeferred: int
  var ownerDeferred: int
  action init = all {
    R::s' = R::initial("ack-transfer-before-resume"), policy' = "complete",
    stillAtOwner' = false, childEpoch' = 0,
    donorWords' = 3, ownerWords' = 2, donorDeferred' = 5, ownerDeferred' = 1 }
  action initRcOnly = all {
    R::s' = R::initial("ack-transfer-before-resume"), policy' = "rc-only",
    stillAtOwner' = false, childEpoch' = 0,
    donorWords' = 3, ownerWords' = 2, donorDeferred' = 5, ownerDeferred' = 1 }
  action initDroppedDeferred = all {
    R::s' = R::initial("ack-transfer-before-resume"), policy' = "drop-deferred",
    stillAtOwner' = false, childEpoch' = 0,
    donorWords' = 3, ownerWords' = 2, donorDeferred' = 5, ownerDeferred' = 1 }
  action keep = all { policy' = policy, stillAtOwner' = stillAtOwner,
    childEpoch' = childEpoch, donorWords' = donorWords, ownerWords' = ownerWords,
    donorDeferred' = donorDeferred, ownerDeferred' = ownerDeferred }
  action shrink = all { R::shrink, keep }
  action stop = all { R::donorStops, keep }
  action failJoin = all { R::joinFails, keep }
  action join = all { R::joinSucceeds, keep }
  action handoff = all { R::transfer, policy' = policy,
    stillAtOwner' = policy != "rc-only", childEpoch' = childEpoch,
    donorWords' = 0, ownerWords' = ownerWords + donorWords,
    donorDeferred' = 0,
    ownerDeferred' = if (policy == "drop-deferred") ownerDeferred
                     else ownerDeferred + donorDeferred }
  action resume = all { R::returnResult, keep }
  action collect = all { R::collect, policy' = policy,
    stillAtOwner' = stillAtOwner,
    childEpoch' = if (stillAtOwner) 1 else childEpoch,
    donorWords' = donorWords, ownerWords' = ownerWords,
    donorDeferred' = donorDeferred, ownerDeferred' = ownerDeferred }
  action recover = all { any { R::retry, R::recovered, R::reclaim }, keep }
  action finished = all { R::terminal, R::s' = R::s, keep }
  action step = any { shrink, stop, failJoin, join, handoff, resume, collect,
    recover, finished }
  val accounting = donorWords + ownerWords == 5 and
    donorDeferred + ownerDeferred == 6
  val stillClosure = not(R::s.gcDone) or (stillAtOwner and childEpoch == R::s.gcEpoch)
  val safe = R::safe and accounting and stillClosure
  val noStall = R::terminal or enabled(step)
  action observe = all { R::s' = R::s, keep }
  run successfulClosureTest = init.then(shrink).then(stop).then(join)
    .then(handoff).then(resume).then(collect)
    .then(all { assert(safe), observe })
  run pendingClosureTest = init.then(shrink).then(failJoin).then(stop)
    .then(handoff).then(resume).then(collect)
    .then(all { assert(safe), assert(R::s.pending), observe })
  run rcOnlyControlTest = initRcOnly.then(shrink).then(stop).then(join)
    .then(handoff).then(resume).then(collect)
    .then(all { assert(R::safe), assert(not(stillClosure)), observe })
  run droppedDeferredControlTest = initDroppedDeferred.then(shrink).then(stop)
    .then(join).then(handoff)
    .then(all { assert(not(accounting)), observe })
}

module vm_registry_failed_join_retention {
  // Exclusive owner; active membership is distinct from OS-thread ownership.
  type State = { policy: str, active: int, pendingJoin: bool,
    resource: bool, phase: str, rejected: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, active: 2, pendingJoin: false,
    resource: true, phase: "active", rejected: false,
  }
  action init = s' = initial("join-owned")
  action initCountOnly = s' = initial("count-only")
  action shrinkPublication = all { s.phase == "active",
    s' = { ...s, active: 1, pendingJoin: true, phase: "join" } }
  action joinFailure = all { s.phase == "join",
    s' = { ...s, phase: "failed" } }
  action joinSuccess = all { s.phase == "join" or s.phase == "retry",
    s' = { ...s, pendingJoin: false, phase: "joined" } }
  action rejectCleanup = all { s.phase == "failed", s.policy == "join-owned",
    s' = { ...s, rejected: true, phase: "retained" } }
  action retryJoin = all { s.phase == "retained",
    s' = { ...s, phase: "retry" } }
  action cleanup = all { s.active == 1, s.resource,
    s.phase == "joined" or (s.phase == "failed" and s.policy == "count-only"),
    s' = { ...s, resource: false, phase: "done" } }
  action hold = s' = s
  action step = any { shrinkPublication, joinFailure, joinSuccess,
    rejectCleanup, retryJoin, cleanup, hold }
  val safe = not(s.pendingJoin) or s.resource
  run countOnlyControlTest = initCountOnly.then(shrinkPublication).then(joinFailure)
    .then(cleanup).then(all { assert(not(safe)), s' = s })
  run failedJoinRetainsTest = init.then(shrinkPublication).then(joinFailure)
    .then(rejectCleanup).then(all { assert(safe), assert(s.resource),
      assert(s.pendingJoin), assert(s.rejected), s' = s })
  run retryBeforeCleanupTest = init.then(shrinkPublication).then(joinFailure)
    .then(rejectCleanup).then(retryJoin).then(joinSuccess).then(cleanup)
    .then(all { assert(safe), assert(not(s.resource)), assert(not(s.pendingJoin)), s' = s })
  run normalJoinTest = init.then(shrinkPublication).then(joinSuccess).then(cleanup)
    .then(all { assert(safe), assert(s.phase == "done"), s' = s })
}

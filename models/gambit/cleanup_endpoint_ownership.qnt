module cleanup_endpoint_ownership {
  // One semantic VM and one foreign frame, independent of host CPU capacity.
  type State = { policy: str, busy: bool, endpoint: str, phase: str,
    gateClosed: bool, ownsAdmission: bool, storageAlive: bool,
    destroyed: bool, returned: bool, fatal: bool }
  var s: State
  pure def initial(policy: str): State = { policy: policy, busy: false,
    endpoint: "none", phase: "ready", gateClosed: false,
    ownsAdmission: false, storageAlive: true, destroyed: false,
    returned: false, fatal: false }
  action init = s' = initial("owned")
  action initReacquire = s' = initial("reacquire")
  action initLegacyReturns = s' = initial("legacy-returns")
  action enterFrame = all { s.phase == "ready", not(s.busy),
    s' = { ...s, busy: true } }
  action request(endpoint: str): bool = all { s.phase == "ready",
    Set("checked", "legacy").contains(endpoint),
    s' = if (s.busy) { ...s, endpoint: endpoint, phase: "busy" }
    else { ...s, endpoint: endpoint, phase: "owned",
      gateClosed: true, ownsAdmission: true } }
  action busyReply = all { s.phase == "busy",
    s' = if (s.endpoint == "checked" or s.policy == "legacy-returns")
      { ...s, phase: "done", returned: true }
    else { ...s, phase: "done", fatal: true } }
  action destroyOwned = all { s.phase == "owned", s.ownsAdmission,
    s' = if (s.policy == "reacquire" and s.gateClosed)
      { ...s, phase: "finalize" }
    else { ...s, phase: "finalize", storageAlive: false, destroyed: true } }
  action finish = all { s.phase == "finalize",
    s' = { ...s, phase: "done", returned: true } }
  action observe = s' = s
  action terminal = all { s.phase == "done", observe }
  action chooseRequest = { nondet endpoint = Set("checked", "legacy").oneOf()
    request(endpoint) }
  action step = any { enterFrame, chooseRequest, busyReply, destroyOwned, finish, terminal }
  val safe = (s.busy.implies(s.storageAlive)) and
    ((s.phase == "done" and not(s.busy)).implies(s.destroyed)) and
    ((s.phase == "done" and s.busy and s.endpoint == "legacy").implies(s.fatal and not(s.returned))) and
    (s.destroyed.implies(s.ownsAdmission and s.gateClosed))
  val noStall = enabled(step)
  run singleVmOwnedCleanupTest = (s' = initial("owned"))
    .then(request("legacy")).then(destroyOwned).then(finish)
    .then(all { assert(safe), assert(s.destroyed), assert(s.returned), observe })
  run checkedBusyReturnTest = (s' = initial("owned"))
    .then(enterFrame).then(request("checked")).then(busyReply)
    .then(all { assert(safe), assert(s.returned), assert(s.storageAlive), observe })
  run legacyBusyFatalTest = (s' = initial("owned"))
    .then(enterFrame).then(request("legacy")).then(busyReply)
    .then(all { assert(safe), assert(s.fatal), assert(not(s.returned)), observe })
  run reacquireClosedGateControlTest = (s' = initial("reacquire"))
    .then(request("legacy")).then(destroyOwned).then(finish)
    .then(all { assert(not(safe)), assert(s.storageAlive), observe })
  run legacyReturnControlTest = (s' = initial("legacy-returns"))
    .then(enterFrame).then(request("legacy")).then(busyReply)
    .then(all { assert(not(safe)), observe })
}

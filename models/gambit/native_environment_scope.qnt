module native_environment_scope {
  // Finite exact-scope projection; probe provenance remains a separate contract.
  type State = { scope: str, operation: str, sourceBound: bool,
    reviewed: bool, used: bool, bypass: bool }
  var s: State
  pure def requirement(scope: str): str =
    if (scope == "11-network" or scope == "11-network/udp_close.scm") "udp-open"
    else if (scope == "12-os/user_info.scm") "user-info"
    else if (scope == "13-modules/prim_port.scm") "process-pipe-sort"
    else "unknown"
  pure def initial(bypass: bool): State = {
    scope: "11-network", operation: "udp-open", sourceBound: true,
    reviewed: true, used: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  action chooseScope = all { not(s.used), any {
    s' = { ...s, scope: "11-network/udp_close.scm" },
    s' = { ...s, scope: "11-network/udp_io.scm" },
    s' = { ...s, scope: "12-os/user_info.scm" },
    s' = { ...s, scope: "13-modules/prim_port.scm" }
  } }
  action chooseOperation = all { not(s.used), any {
    s' = { ...s, operation: "udp-open" },
    s' = { ...s, operation: "user-info" },
    s' = { ...s, operation: "process-pipe-sort" }
  } }
  action invalidate = all { not(s.used), any {
    s' = { ...s, sourceBound: false }, s' = { ...s, reviewed: false }
  } }
  val bound = requirement(s.scope) != "unknown" and
    requirement(s.scope) == s.operation and s.sourceBound and s.reviewed
  action use = all { not(s.used), bound or s.bypass, s' = { ...s, used: true } }
  action hold = s' = s
  action step = any { chooseScope, chooseOperation, invalidate, use, hold }
  val safe = not(s.used) or bound
  run udpCloseTest = init.then(s' = { ...s, scope: "11-network/udp_close.scm" })
    .then(use).then(all { assert(safe), assert(s.used), s' = s })
  run unrelatedFileControlTest = initBypass
    .then(s' = { ...s, scope: "11-network/udp_io.scm" }).then(use)
    .then(all { assert(not(safe)), s' = s })
  run wrongOperationControlTest = initBypass
    .then(s' = { ...s, scope: "11-network/udp_close.scm", operation: "user-info" })
    .then(use).then(all { assert(not(safe)), s' = s })
  run unboundSourceControlTest = initBypass
    .then(s' = { ...s, sourceBound: false }).then(use)
    .then(all { assert(not(safe)), s' = s })
}

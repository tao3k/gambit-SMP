module vm_registry_global_cleanup_preflight {
  // Host lifecycle ownership is exclusive. One secondary VM stands for each
  // member checked under the list mutex; direct users have already joined.
  type State = { policy: str, childActive: bool, childPending: bool,
    childResource: bool, sealed: bool, setupReady: bool, phase: str }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, childActive: true, childPending: false,
    childResource: true, sealed: false, setupReady: true, phase: "request",
  }
  action init = s' = initial("preflight")
  action initRootOnly = s' = initial("root-only")
  action shrinkChild = all { s.childActive, s.childResource, not(s.sealed),
    s' = { ...s, childActive: false, childPending: true } }
  action joinChild = all { s.childPending, not(s.sealed),
    s' = { ...s, childPending: false } }
  val ready = not(s.childActive) and not(s.childPending)
  action reject = all { s.phase == "request", s.policy == "preflight", not(ready),
    s' = { ...s, phase: "rejected" } }
  action retry = all { s.phase == "rejected", s.setupReady, not(s.sealed),
    s' = { ...s, phase: "request" } }
  action seal = all { s.phase == "request", ready or s.policy == "root-only",
    s' = { ...s, sealed: true, setupReady: false, phase: "cleanup" } }
  action free = all { s.phase == "cleanup",
    s' = { ...s, childResource: false, phase: "done" } }
  action hold = s' = s
  action step = any { shrinkChild, joinChild, reject, retry, seal, free, hold }
  val safe = (s.childResource or ready) and
    (s.phase != "rejected" or (s.setupReady and not(s.sealed)))
  run activeChildControlTest = initRootOnly.then(seal).then(free)
    .then(all { assert(not(safe)), s' = s })
  run pendingChildControlTest = initRootOnly.then(shrinkChild).then(seal).then(free)
    .then(all { assert(not(safe)), s' = s })
  run rejectionPreservesRecoveryTest = init.then(reject).then(shrinkChild)
    .then(joinChild).then(retry).then(seal).then(free)
    .then(all { assert(safe), assert(s.phase == "done"), s' = s })
  run pendingJoinRejectTest = init.then(shrinkChild).then(reject)
    .then(all { assert(safe), assert(s.setupReady), assert(not(s.sealed)), s' = s })
}

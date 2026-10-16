module public_cleanup_resource_ownership {
  // Root and child are semantic ownership roles, not a host CPU bound.
  // Successful startup, joined direct users and retired cohorts are premises.
  type State = { policy: str, phase: str, gate: bool, reader: str,
    lease: bool, rootReady: bool, childReady: bool, childMemory: bool,
    rootReleases: int, childReleases: int, badUse: bool }
  var s: State
  pure def initial(policy: str, childAlreadyClean: bool): State = {
    policy: policy, phase: "close", gate: true, reader: "new", lease: false,
    rootReady: true, childReady: not(childAlreadyClean), childMemory: true,
    rootReleases: 0, childReleases: if (childAlreadyClean) 1 else 0,
    badUse: false }
  action init = {
    nondet prior = Set(false, true).oneOf()
    s' = initial("owned-readiness", prior)
  }
  action initMissingChild = s' = initial("skip-child", false)
  // A proposed unconditional extra close, not the current implementation.
  action initBlindClose = s' = initial("blind-close", true)
  action enter = all { s.reader == "new", s.gate,
    s' = { ...s, reader: "use", lease: true } }
  action use = all { s.reader == "use",
    // Proposed readiness dispatch skips the retired child's OS resource.
    // The old policy has no such dispatch check.
    s' = { ...s, reader: "leave", badUse: s.badUse or not(s.childMemory) or
      (not(s.childReady) and s.policy != "owned-readiness") } }
  action leave = all { s.reader == "leave",
    s' = { ...s, reader: "done", lease: false } }
  action cancel = all { s.reader == "new", not(s.gate),
    s' = { ...s, reader: "done" } }
  action close = all { s.phase == "close",
    s' = { ...s, gate: false, phase: "drain" } }
  action drain = all { s.phase == "drain", not(s.lease),
    s' = { ...s, phase: "root" } }
  action cleanRoot = all { s.phase == "root", not(s.lease),
    s' = { ...s, rootReady: false, rootReleases: s.rootReleases + 1,
      phase: "child" } }
  action cleanChild = all { s.phase == "child", not(s.lease),
    s' = if (s.policy == "skip-child") { ...s, phase: "memory" }
      else if (s.policy == "blind-close" or s.childReady)
        { ...s, phase: "memory", childReady: false,
          childReleases: s.childReleases + 1 }
      else { ...s, phase: "memory" } }
  action cleanMemory = all { s.phase == "memory", not(s.lease),
    s' = { ...s, phase: "done", childMemory: false } }
  val terminal = s.phase == "done" and s.reader == "done"
  action finished = all { terminal, s' = s }
  action step = any { enter, use, leave, cancel, close, drain, cleanRoot,
    cleanChild, cleanMemory, finished }
  val resourceComplete = s.childMemory or not(s.childReady)
  val exactlyOnce = s.rootReleases <= 1 and s.childReleases <= 1
  val safe = resourceComplete and exactlyOnce and not(s.badUse) and
    (s.lease.implies(s.childMemory)) and
    ((s.phase == "done").implies(s.rootReleases == 1 and s.childReleases == 1))
  val noStall = terminal or enabled(step)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}

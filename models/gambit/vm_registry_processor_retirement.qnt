module vm_registry_processor_retirement {
  // One published VM, one registry reader and an already joining cohort.
  // Global lifecycle ownership is exclusive; direct PSTATE users must join.
  type State = { policy: str, gate: bool, published: bool, resource: bool,
    reader: str, lease: bool, cohort: str, owner: str, badUse: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, gate: true, published: true, resource: true,
    reader: "new", lease: false, cohort: "joining", owner: "join",
    badUse: false,
  }
  action init = s' = initial("close-before-resource")
  action initEarlyCleanup = s' = initial("resource-before-close")
  action enter = all { s.reader == "new", s.gate,
    s' = { ...s, reader: "use", lease: true } }
  action use = all { s.reader == "use",
    s' = { ...s, reader: "leave",
      badUse: s.badUse or (s.published and not(s.resource)) } }
  action leave = all { s.reader == "leave",
    s' = { ...s, reader: "done", lease: false } }
  action cancel = all { s.reader == "new", not(s.published),
    s' = { ...s, reader: "done" } }
  action cohortJoined = all { s.cohort == "joining",
    s' = { ...s, cohort: "done" } }
  action join = all { s.owner == "join", s.cohort == "done",
    s' = { ...s, owner: if (s.policy == "resource-before-close") "free" else "close" } }
  action close = all { s.owner == "close",
    s' = { ...s, gate: false, owner: "drain" } }
  action drain = all { s.owner == "drain", not(s.lease),
    s' = { ...s, owner: if (s.resource) "free" else "unlink" } }
  action freeResource = all { s.owner == "free",
    s' = { ...s, resource: false,
      owner: if (s.policy == "resource-before-close") "close" else "unlink" } }
  action unlink = all { s.owner == "unlink", not(s.lease),
    s' = { ...s, published: false, owner: "open" } }
  action reopen = all { s.owner == "open",
    s' = { ...s, gate: true, owner: "done" } }
  val terminal = s.reader == "done" and s.owner == "done"
  action finished = all { terminal, s' = s }
  action step = any { enter, use, leave, cancel, cohortJoined, join, close,
    drain, freeResource, unlink, reopen, finished }
  val safe = not(s.badUse) and
    (not(s.lease and s.published) or s.resource) and
    (s.resource or not(s.gate and s.published))
  val noStall = terminal or enabled(step)
  run earlyCleanupControlTest = initEarlyCleanup.then(cohortJoined).then(join)
    .then(freeResource).then(enter).then(use)
    .then(all { assert(s.badUse), assert(not(safe)), s' = s })
  run leaseDrainTest = init.then(enter).then(cohortJoined).then(join).then(close)
    .then(use).then(leave).then(drain).then(freeResource).then(unlink).then(reopen)
    .then(all { assert(safe), assert(terminal), s' = s })
  run lateReaderTest = init.then(cohortJoined).then(join).then(close).then(drain)
    .then(freeResource).then(unlink).then(reopen).then(enter).then(use).then(leave)
    .then(all { assert(safe), assert(terminal), s' = s })
}

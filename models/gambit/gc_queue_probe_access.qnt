module gc_queue_probe_access {
  // Source access-discipline abstraction, not a C memory-model proof.
  type State = { policy: str, writer: bool, probed: bool, conflict: bool,
    queueHasWork: bool, hintEmpty: bool, checked: bool, retired: bool }
  var s: State
  pure def initial(policy: str): State = { policy: policy, writer: false,
    probed: false, conflict: false, queueHasWork: false, hintEmpty: true,
    checked: false, retired: false }
  action init = s' = initial("atomic-hint")
  action initPlain = s' = initial("plain-hint")
  action initMixed = s' = initial("atomic-load-only")
  action initTrust = s' = initial("trust-hint")
  action startWrite = all { not(s.writer), not(s.checked), not(s.retired),
    s' = { ...s, writer: true } }
  // An advisory snapshot may be stale or observe different endpoint moments.
  action probe = {
    nondet empty = Set(false, true).oneOf()
    all { s.writer, not(s.probed),
      s' = { ...s, probed: true, hintEmpty: empty,
        conflict: s.policy == "plain-hint" or s.policy == "atomic-load-only" } }
  }
  action publish = all { s.writer,
    s' = { ...s, writer: false, queueHasWork: true } }
  action recheck = all { not(s.writer), s.queueHasWork, not(s.checked),
    s' = { ...s, checked: true } }
  action retire = all { not(s.writer), s.hintEmpty, not(s.retired),
    s.policy == "trust-hint",
    s' = { ...s, retired: true } }
  action hold = s' = s
  action step = any { startWrite, probe, publish, recheck, retire, hold }
  val raceFree = not(s.conflict)
  val hintIsNotAuthority = s.retired.implies(not(s.queueHasWork))
  val safe = raceFree and hintIsNotAuthority
  run advisoryProbeTest = init.then(startWrite).then(probe).then(publish).then(recheck)
    .then(all { assert(safe), assert(s.checked), s' = s })
  run plainReadControlTest = initPlain.then(startWrite).then(probe)
    .then(all { assert(not(raceFree)), s' = s })
  run loadOnlyControlTest = initMixed.then(startWrite).then(probe)
    .then(all { assert(not(raceFree)), s' = s })
  run staleHintControlTest = initTrust.then(startWrite).then(publish).then(retire)
    .then(all { assert(not(hintIsNotAuthority)), s' = s })
}

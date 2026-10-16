// One movable payload, a version-checked publication and one raw C lease.
// Atomic actions are assumptions; this is not a nonblocking implementation.
module ConcurrentCopyWrite {
  type State = { phase: str, policy: str, source: int, destination: int,
    version: int, copiedVersion: int, copiedValue: int,
    wrote: bool, lease: bool, foreignDone: bool }
  var s: State
  pure def initial(policy: str): State = {
    phase: "source", policy: policy, source: 0, destination: -1,
    version: 0, copiedVersion: -1, copiedValue: -1,
    wrote: false, lease: false, foreignDone: false
  }
  action init = s' = initial("checked")
  action initNoVersion = s' = initial("omit-version-check")
  action initNoBarrier = s' = initial("omit-reference-barrier")
  action initNoDrain = s' = initial("omit-lease-drain")
  action copy = all { s.phase == "source",
    s' = { ...s, phase: "copying", copiedValue: s.source, copiedVersion: s.version } }
  action write = all { not(s.wrote),
    s' = if ((s.phase == "published" or s.phase == "retired") and
             s.policy != "omit-reference-barrier")
      { ...s, wrote: true, destination: 1 }
    else { ...s, wrote: true, source: 1, version: s.version + 1 } }
  action retry = all { s.phase == "copying", s.version != s.copiedVersion,
    s' = { ...s, copiedValue: s.source, copiedVersion: s.version } }
  action publish = all { s.phase == "copying",
    s.version == s.copiedVersion or s.policy == "omit-version-check",
    s' = { ...s, phase: "published", destination: s.copiedValue } }
  action foreignEnter = all { not(s.foreignDone), not(s.lease),
    s.phase == "source" or s.phase == "copying",
    s' = { ...s, lease: true } }
  action foreignLeave = all { s.lease,
    s' = { ...s, lease: false, foreignDone: true } }
  action retire = all { s.phase == "published",
    not(s.lease) or s.policy == "omit-lease-drain",
    s' = { ...s, phase: "retired" } }
  action step = any { copy, write, retry, publish, foreignEnter, foreignLeave, retire }
  val noLostWrite = (s.phase == "published" or s.phase == "retired") and s.wrote
    implies s.destination == 1
  val foreignReferenceAlive = s.phase == "retired" implies not(s.lease)
  val Safe = noLostWrite and foreignReferenceAlive
}

// One borrowed foreign writer and a versioned copy with delayed visibility.
// No pointer tagging, allocator, data races or complete C memory semantics.
module ForeignPayloadPublication {
  type State = { policy: str, source: int, version: int, copied: int,
    copiedVersion: int, copying: bool, published: bool, lease: bool,
    wrote: bool, visible: bool, read: bool, wrong: bool }
  var s: State
  pure def initial(policy: str): State = { policy: policy, source: 0,
    version: 0, copied: -1, copiedVersion: -1, copying: false,
    published: false, lease: true, wrote: false, visible: false,
    read: false, wrong: false }
  action init = s' = initial("checked")
  action initNoVersion = s' = initial("no-version")
  action initNoLease = s' = initial("no-lease")
  action initNoAcquire = s' = initial("no-acquire")
  action copy = all { not(s.copying), not(s.published),
    s' = { ...s, copying: true, copied: s.source, copiedVersion: s.version } }
  action foreignWrite = all { s.lease, not(s.wrote),
    s' = { ...s, source: 1, version: 1, wrote: true } }
  action foreignReturn = all { s.lease, s.wrote,
    s' = { ...s, lease: false } }
  action refresh = all { s.copying, not(s.published),
    s.copiedVersion != s.version,
    s' = { ...s, copied: s.source, copiedVersion: s.version } }
  action publish = all { s.copying, not(s.published),
    not(s.lease) or s.policy == "no-lease",
    s.copiedVersion == s.version or s.policy == "no-version",
    s' = { ...s, published: true } }
  action propagate = all { s.published, not(s.visible),
    s' = { ...s, visible: true } }
  action load = all { s.published, not(s.read),
    s' = { ...s, read: true, wrong: s.copied != s.source or
      (s.policy == "no-acquire" and not(s.visible)) } }
  action step = any { copy, foreignWrite, foreignReturn, refresh, publish,
    propagate, load }
  val Safe = not(s.wrong) and (s.published and s.wrote implies s.copied == s.source)
}

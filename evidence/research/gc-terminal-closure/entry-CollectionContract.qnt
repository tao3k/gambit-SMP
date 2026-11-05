// One live object, two root slots, one optional re-scan. Mutators are stopped.
// Atomic transitions abstract visibility; this is not a C memory-model proof.
module CollectionContract {
  const Relocate: bool
  const Mutation: str
  type State = { claimed: bool, address: int, roots: int -> int,
    initialized: bool, privateWork: bool, queued: bool, scanning: bool,
    scanned: bool, rescans: int, staleRead: bool, done: bool }
  var s: State
  action init = s' = { claimed: false, address: 0,
    roots: Map(1 -> 0, 2 -> 0), initialized: false, privateWork: false,
    queued: false, scanning: false, scanned: false, rescans: 0,
    staleRead: false, done: false }

  action claim = all {
    not(s.done), not(s.claimed),
    s' = { ...s, claimed: true, address: if (Relocate) 1 else 0,
      privateWork: true },
  }
  action redirect(r: int): bool = all {
    not(s.done), s.claimed, s.roots.get(r) == 0,
    s' = { ...s, roots: s.roots.set(r,
      if (Mutation == "split-identity") 2 else s.address) },
  }
  action initialize = all {
    not(s.done), s.privateWork, not(s.initialized),
    s' = { ...s, initialized: true },
  }
  action publish = all {
    not(s.done), s.privateWork,
    s.initialized or Mutation == "early-publication",
    s' = { ...s, privateWork: false, queued: true },
  }
  action acquire = all {
    not(s.done), s.queued, not(s.scanning),
    s' = { ...s, queued: false, scanning: true,
      staleRead: s.staleRead or not(s.initialized) },
  }
  action scan = all {
    not(s.done), s.scanning,
    s' = { ...s, scanning: false, scanned: true },
  }
  // A bounded remote dependency may require another scan of the same object.
  action rescan = all {
    not(s.done), s.scanned, not(s.queued), not(s.scanning), s.rescans == 0,
    s' = { ...s, queued: true, scanned: false, rescans: 1 },
  }
  action finish = all {
    not(s.done), s.claimed,
    Set(1, 2).forall(r => s.roots.get(r) == s.address),
    (s.scanned and not(s.privateWork) and not(s.queued) and not(s.scanning))
      or Mutation == "early-termination",
    s' = { ...s, done: true },
  }
  action step = any { claim, redirect(1), redirect(2), initialize,
    publish, acquire, scan, rescan, finish }
  val identitySafe = Set(1, 2).forall(r =>
    s.roots.get(r) == 0 or (s.claimed and s.roots.get(r) == s.address))
  val publicationSafe = not(s.staleRead) and
    ((s.queued or s.scanning or s.scanned) implies s.initialized)
  val closureSafe = s.done implies (s.initialized and s.scanned and
    not(s.privateWork) and not(s.queued) and not(s.scanning) and
    Set(1, 2).forall(r => s.roots.get(r) == s.address))
  val Safe = identitySafe and publicationSafe and closureSafe
}

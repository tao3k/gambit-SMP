// ZGC-inspired relocation profile, NOT a model of the actual ZGC algorithm.
// Two roots, one relocation epoch, one logical object and an old-page reuse.
module ColoredReferenceRelocation {
  type State = { policy: str, epoch: int, metadata: bool, reused: bool,
    refs: int -> int, colors: int -> int, active: Set[int], finished: Set[int],
    localRefs: int -> int, localColors: int -> int, wrongObject: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, epoch: 0, metadata: false, reused: false,
    refs: Map(0 -> 0, 1 -> 0), colors: Map(0 -> 0, 1 -> 0),
    active: Set(), finished: Set(), localRefs: Map(0 -> 0, 1 -> 0),
    localColors: Map(0 -> 0, 1 -> 0), wrongObject: false
  }
  action init = s' = initial("checked")
  action initNoBarrier = s' = initial("omit-load-barrier")
  action initEarlyMetadata = s' = initial("early-metadata-retirement")
  action initNoActiveRoots = s' = initial("ignore-active-roots")
  // Payload initialization and forwarding publication are abstracted atomic.
  action relocate = all { s.epoch == 0,
    s' = { ...s, epoch: 1, metadata: true } }
  action heal(root: int): bool = all { s.epoch == 1, s.colors.get(root) == 0,
    s' = { ...s, refs: s.refs.set(root, 1), colors: s.colors.set(root, 1) } }
  action beginLoad(root: int): bool = all {
    not(s.active.contains(root)), not(s.finished.contains(root)),
    s' = { ...s, active: s.active.union(Set(root)),
      localRefs: s.localRefs.set(root, s.refs.get(root)),
      localColors: s.localColors.set(root, s.colors.get(root)) }
  }
  action finishLoad(root: int): bool = all { s.active.contains(root),
    val stale = s.localColors.get(root) != s.epoch
    val address = if (stale and s.metadata and s.policy != "omit-load-barrier")
      1 else s.localRefs.get(root)
    s' = { ...s, active: s.active.exclude(Set(root)), finished: s.finished.union(Set(root)),
      wrongObject: s.wrongObject or (address == 0 and s.reused) }
  }
  action reuseOldPage = all { s.epoch == 1, not(s.reused),
    s' = { ...s, reused: true } }
  action retireMetadata = all { s.epoch == 1, s.metadata,
    s.policy == "early-metadata-retirement" or all {
      Set(0, 1).forall(root => s.colors.get(root) == s.epoch),
      s.policy == "ignore-active-roots" or
        s.active.forall(root => s.localColors.get(root) == s.epoch)
    },
    s' = { ...s, metadata: false }
  }
  action step = any { relocate, heal(0), heal(1), beginLoad(0), beginLoad(1),
    finishLoad(0), finishLoad(1), reuseOldPage, retireMetadata }
  val Safe = not(s.wrongObject)
}

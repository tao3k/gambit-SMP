module interrupt_prefix_retained_composition {
  import sync_slot_retained_resources as S from "./sync_slot_retained_resources"
  // VM0 borrows an already initialized global P0 interrupt mutex. Private VMs
  // own P0. P1 retains its interrupt mutex across the imported sync-slot reuse.
  // External interrupt admission is closed before VM/global resource cleanup.
  type State = { policy: int, borrowed: bool, failure: str, phase: int,
    ready: Set[int], live: Set[int], initCount: int -> int, badBorrow: bool }
  var prefix: State
  pure def initial(policy: int, borrowed: bool, failure: str): State = {
    policy: policy, borrowed: borrowed, failure: failure, phase: 0,
    ready: if (borrowed) Set(0) else Set(),
    live: if (borrowed) Set(0) else Set(),
    initCount: Map(0 -> (if (borrowed) 1 else 0), 1 -> 0), badBorrow: false,
  }
  action initFixed = {
    nondet borrowed = Set(false, true).oneOf()
    nondet failure = Set("none", "private-init", "after-prefix").oneOf()
    all {
      prefix' = initial(0, borrowed, failure),
      S::s' = { ...S::initial(0), live: false, initCount: 0 },
    }
  }
  action initEraseBorrowed = all {
    prefix' = initial(1, true, "none"),
    S::s' = { ...S::initial(0), live: false, initCount: 0 },
  }
  action initReuseInterrupt = all {
    prefix' = initial(2, false, "none"),
    S::s' = { ...S::initial(0), live: false, initCount: 0 },
  }
  action initDestroyBorrowed = all {
    prefix' = initial(3, true, "none"),
    S::s' = { ...S::initial(0), live: false, initCount: 0 },
  }
  action freshMetadata = all {
    prefix.phase == 0,
    prefix' = { ...prefix, phase: 1,
      ready: if (prefix.policy == 1) Set() else prefix.ready },
    S::s' = S::s,
  }
  action prepareP0 = all {
    prefix.phase == 1,
    val failed = not(prefix.borrowed) and prefix.failure == "private-init"
    prefix' = { ...prefix, phase: if (failed) 4 else 2,
      ready: if (failed) prefix.ready else prefix.ready.union(Set(0)),
      live: if (failed) prefix.live else prefix.live.union(Set(0)),
      initCount: prefix.initCount.set(0,
        prefix.initCount.get(0) + (if (failed or prefix.borrowed) 0 else 1)) },
    S::s' = S::s,
  }
  action constructorHandoff = all {
    prefix.phase == 2,
    val failed = prefix.failure == "after-prefix"
    prefix' = { ...prefix, phase: if (failed) 4 else 3,
      ready: if (failed) prefix.ready else prefix.ready.union(Set(1)),
      live: if (failed) prefix.live else prefix.live.union(Set(1)),
      initCount: prefix.initCount.set(1, if (failed) 0 else 1) },
    S::s' = if (failed) S::s else S::initial(0),
  }
  action slotProtocol = all {
    prefix.phase == 3, not(S::terminal), S::step,
    prefix' = { ...prefix, initCount: prefix.initCount.set(1,
      prefix.initCount.get(1) +
        (if (prefix.policy == 2 and S::s.phase == 2 and S::s'.phase == 3) 1 else 0)) },
  }
  action receiveSlotClosure = all {
    prefix.phase == 3, S::terminal,
    prefix' = { ...prefix, phase: 4 }, S::s' = S::s,
  }
  action cleanupVm = all {
    prefix.phase == 4,
    val keep = if (prefix.borrowed and prefix.policy != 3) Set(0) else Set()
    prefix' = { ...prefix, phase: 5,
      ready: prefix.ready.intersect(keep), live: prefix.live.intersect(keep),
      badBorrow: prefix.badBorrow or (prefix.borrowed and prefix.policy == 3) },
    S::s' = S::s,
  }
  action cleanupGlobal = all {
    prefix.phase == 5,
    prefix' = { ...prefix, phase: 6, ready: Set(), live: Set() }, S::s' = S::s,
  }
  val bitmapSafe = prefix.ready == prefix.live
  val borrowedSafe = not(prefix.badBorrow) and
    (not(prefix.borrowed) or prefix.phase == 6 or prefix.live.contains(0))
  val reuseSafe = Set(0, 1).forall(slot => prefix.initCount.get(slot) <= 1)
  val syncSafe = prefix.phase != 3 or S::safe
  val cleanupSafe = prefix.phase != 6 or prefix.live == Set()
  val safe = bitmapSafe and borrowedSafe and reuseSafe and syncSafe and cleanupSafe
  val terminal = prefix.phase == 6
  action finished = all { terminal, prefix' = prefix, S::s' = S::s }
  action step = any { freshMetadata, prepareP0, constructorHandoff, slotProtocol,
    receiveSlotClosure, cleanupVm, cleanupGlobal, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(prefix, S::s)).implies(eventually(terminal))
}

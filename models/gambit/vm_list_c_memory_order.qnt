module vm_list_c_memory_order {
  // Publication litmus: two already-running threads, one fresh node, no other HB.
  // This is an abstraction of release/acquire, not a complete C memory checker.
  type State = { policy: str, writer: str, reader: str, initialized: bool,
    published: bool, initAtPublish: bool, seenInit: bool, acquiredInit: bool,
    mixedAccess: bool, payloadRace: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, writer: "initialize", reader: "load", initialized: false,
    published: false, initAtPublish: false, seenInit: false, acquiredInit: false,
    mixedAccess: false, payloadRace: false,
  }
  action initOld = s' = initial("volatile")
  action initRelaxed = s' = initial("relaxed")
  action initOneSided = s' = initial("release-only")
  action initEarly = s' = initial("early-release")
  action initMixed = s' = initial("mixed-atomic")
  action initFixed = s' = initial("release-acquire")
  val storeAtomic = s.policy != "volatile"
  val loadAtomic = not(Set("volatile", "mixed-atomic").contains(s.policy))
  val storeRelease = Set("release-acquire", "early-release", "release-only", "mixed-atomic").contains(s.policy)
  val loadAcquire = Set("release-acquire", "early-release").contains(s.policy)
  action publishEarly = all {
    s.policy == "early-release", s.writer == "initialize", not(s.published),
    s' = { ...s, published: true, initAtPublish: false },
  }
  action initialize = all {
    s.writer == "initialize", s' = { ...s, writer: "publish", initialized: true },
  }
  action publish = all {
    s.writer == "publish",
    // Only one pointer store: later initialization cannot strengthen its epoch.
    s' = { ...s, writer: "done", published: true,
      initAtPublish: if (s.published) s.initAtPublish else s.initialized },
  }
  action load = all {
    s.reader == "load", s.published,
    val ordered = storeRelease and loadAcquire and s.initAtPublish
    // With no synchronizes-with edge, initialization visibility is not promised.
    nondet visible = (if (ordered) Set(true) else Set(false, true)).oneOf()
    s' = { ...s, reader: "use", seenInit: visible, acquiredInit: ordered,
      mixedAccess: not(storeAtomic and loadAtomic) },
  }
  action use = all {
    s.reader == "use",
    // The node fields are ordinary/volatile, not separately atomic payload.
    s' = { ...s, reader: "done", payloadRace: not(s.acquiredInit) },
  }
  val terminal = s.writer == "done" and s.reader == "done"
  action finished = all { terminal, s' = s }
  action step = any { publishEarly, initialize, publish, load, use, finished }
  val atomicAccessSafe = not(s.mixedAccess)
  val orderingSafe = s.reader != "done" or s.acquiredInit
  val publicationSafe = s.reader != "done" or s.seenInit
  val raceFree = atomicAccessSafe and not(s.payloadRace)
  val safe = raceFree and orderingSafe and publicationSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

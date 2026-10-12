module resize_scheme_thread_drain {
  // Two processors and three thread roles are model bounds, not host limits.
  // OS joins succeed here; failed joins remain a separate unresolved contract.
  type State = { policy: str, phase: str, admission: bool, live: Set[int],
    location: int -> str, owner: int -> int, pinned: Set[int],
    roots: Set[int], executing: Set[int], joined: bool, returned: bool }
  var s: State
  val threads = Set(0, 1, 2)
  pure def initial(policy: str): State = {
    policy: policy, phase: "open", admission: true, live: Set(0, 1),
    location: Map(0 -> "running", 1 -> "queued", 2 -> "parked"),
    owner: threads.mapBy(_ => 1), pinned: Set(2), roots: threads,
    executing: Set(0), joined: false, returned: false,
  }
  action initFixed = s' = initial("drain")
  action initDropCaller = s' = initial("exit-local")
  action initPublishBeforeSave = s' = initial("publish-first")
  action initIgnorePin = s' = initial("ignore-pin")
  action closeAdmission = all { s.phase == "open",
    s' = { ...s, admission: false, phase: "drain" } }
  // Explicit cooperation: pinned threads are not silently retargeted.
  action releasePin = all { s.phase == "drain", s.pinned != Set(),
    s' = { ...s, pinned: Set() } }
  action save = {
    nondet t = threads.oneOf()
    all { s.phase == "drain", s.owner.get(t) == 1,
      s.location.get(t) != "saved", s.policy != "exit-local",
      not(s.pinned.contains(t)) or s.policy == "ignore-pin",
      s' = { ...s, location: s.location.set(t, "saved"),
        executing: s.executing.exclude(Set(t)) } }
  }
  action publish = {
    nondet t = threads.oneOf()
    all { s.phase == "drain", s.owner.get(t) == 1,
      s.location.get(t) == "saved" or s.policy == "publish-first",
      not(s.pinned.contains(t)) or s.policy == "ignore-pin",
      s' = { ...s, owner: s.owner.set(t, 0),
        location: s.location.set(t, "queued") } }
  }
  action retire = all { s.phase == "drain",
    s.policy == "exit-local" or threads.forall(t => s.owner.get(t) == 0),
    s' = { ...s, live: Set(0), phase: "retired" } }
  action join = all { s.phase == "retired", not(s.joined),
    s' = { ...s, joined: true } }
  action returnCaller = all { s.joined, not(s.returned), s.owner.get(0) == 0,
    s' = { ...s, returned: true, phase: "done" } }
  action finished = all { s.phase == "done", s' = s }
  action step = any { closeAdmission, releasePin, save, publish, retire,
    join, returnCaller, finished }
  val rootSafe = threads.forall(t => s.roots.contains(t) and s.live.contains(s.owner.get(t)))
  val executionSafe = s.executing.forall(t => s.owner.get(t) == 1 and s.location.get(t) == "running")
  val affinitySafe = s.pinned.forall(t => s.owner.get(t) == 1 and s.location.get(t) == "parked")
  val safe = rootSafe and executionSafe and affinitySafe
  // Progress assumes pin release and scheduling eventually occur; permanent
  // external pinning is not solved by fairness or an unconditional shrink.
  temporal progress = weakFair(step, Set(s)).implies(eventually(s.returned))
}

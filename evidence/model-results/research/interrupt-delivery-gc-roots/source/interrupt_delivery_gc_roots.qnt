module interrupt_delivery_gc_roots {
  import interrupt_delivery_result_composition as I from "./interrupt_delivery_result_composition"
  // Compose the actual queue/result actions; scanning remains an abstract
  // assumption requiring native/source refinement, not a C collector proof.
  type Roots = { policy: str, collected: bool, lost: bool }
  var roots: Roots
  pure def initial(policy: str): Roots = {
    policy: policy, collected: false, lost: false,
  }
  action initFixed = all {
    I::s' = I::initial("combined"), roots' = initial("complete"),
  }
  action initMissingProcessor = all {
    I::s' = I::initial("combined"), roots' = initial("omit-processor"),
  }
  action initMissingLocal = all {
    I::s' = I::initial("combined"), roots' = initial("omit-local"),
  }
  action initMissingThread = all {
    I::s' = I::initial("combined"), roots' = initial("omit-thread"),
  }
  val processorOwns = I::s.processorHead == 0
  val localOwns = Set(1, 2).contains(I::s.phase)
  val threadOwns = I::s.threadHead == 0
  val required = processorOwns or localOwns or threadOwns
  val traced = (processorOwns and roots.policy != "omit-processor") or
    (localOwns and roots.policy != "omit-local") or
    (threadOwns and roots.policy != "omit-thread")
  action collect = all {
    not(roots.collected),
    roots' = { ...roots, collected: true,
               lost: roots.lost or (required and not(traced)) },
    I::s' = I::s,
  }
  action queueAndResult = all { I::step, roots' = roots }
  action step = any { queueAndResult, collect }
  val reachable = not(roots.lost)
  val processorRoot = reachable
  val localRoot = reachable
  val threadRoot = reachable
  val safe = reachable and I::safe
  // One collection may interleave at any window. No weak/finalizer semantics,
  // raw-address forwarding or stop-the-world cohort agreement is represented.
  temporal completion = always(I::terminal or enabled(step)) and
    weakFair(queueAndResult, Set((I::s, roots))).implies(eventually(I::terminal))
  run queuedProcessorRootTest = initFixed.then(collect)
    .expect(safe and roots.collected and processorOwns)
  run localHandoffRootTest = initFixed.then(all { I::processorExtractA, roots' = roots })
    .then(collect).expect(safe and localOwns)
  run threadQueueRootTest = initFixed
    .then(all { I::processorExtractA, roots' = roots })
    .then(all { I::acquireTarget, roots' = roots })
    .then(all { I::propagateA, roots' = roots })
    .then(collect).expect(safe and threadOwns)
}

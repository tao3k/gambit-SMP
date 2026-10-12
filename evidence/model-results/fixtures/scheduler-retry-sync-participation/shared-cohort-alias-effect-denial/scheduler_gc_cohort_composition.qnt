module scheduler_gc_cohort_composition {
  import thread_processor_lock_gc_cycle as T from "./thread_processor_lock_gc_cycle"
  import current_processor_gc_wait as P from "./current_processor_gc_wait"
  import scheduler_retry_gc_participation as R from "./scheduler_retry_gc_participation"
  // Five protocol roles share one collective, not three independent GCs.
  // These role IDs and two epochs do not cap the native host population.
  type Cohort = { round: int, requested: bool, joined: Set[int], committed: bool,
    threadFixed: bool, processorFixed: bool, retryFixed: bool }
  var c: Cohort
  pure def initial(t: bool, p: bool, r: bool): Cohort = {
    round: 0, requested: false, joined: Set(), committed: false,
    threadFixed: t, processorFixed: p, retryFixed: r,
  }
  action initialize(t: bool, p: bool, r: bool): bool = all {
    c' = initial(t, p, r), T::s' = T::initial(t),
    P::s' = P::initial(p), R::s' = R::initial(r),
  }
  action initThreadOld = initialize(false, true, true)
  action initProcessorOld = initialize(true, false, true)
  action initRetryOld = initialize(true, true, false)
  action initFixed = initialize(true, true, true)
  action request = all {
    not(c.requested), T::requestGc, P::request, R::s' = R::s,
    c' = { ...c, requested: true, joined: Set(1) },
  }
  action joinThreadOwner = all {
    c.requested, T::joinA, P::s' = P::s, R::s' = R::s,
    c' = { ...c, joined: c.joined.union(Set(0)) },
  }
  action joinThreadReader = all {
    c.requested, T::joinC, P::s' = P::s, R::s' = R::s,
    c' = { ...c, joined: c.joined.union(Set(2)) },
  }
  action joinProcessorWaiter = all {
    c.requested, P::participate, T::s' = T::s, R::s' = R::s,
    c' = { ...c, joined: c.joined.union(Set(3)) },
  }
  action retryHead = all {
    c.requested, any { R::failedHeadTrylock, R::uncheckedRetry },
    T::s' = T::s, P::s' = P::s, c' = c,
  }
  action joinRetryWaiter = all {
    c.requested, R::joinAtUnlockedCheckpoint,
    T::s' = T::s, P::s' = P::s,
    c' = { ...c, joined: c.joined.union(Set(4)) },
  }
  action commitOneCollective = all {
    c.requested, not(c.committed), c.joined == Set(0, 1, 2, 3, 4),
    T::finishGc, P::finishGc, R::finishGc,
    c' = { ...c, committed: true },
  }
  action finishThreadPaths = all {
    c.committed, any { T::releaseProcessor, T::finishA, T::finishC },
    P::s' = P::s, R::s' = R::s, c' = c,
  }
  action finishProcessorPath = all {
    c.committed, any { P::releaseProcessor, P::finishYield },
    T::s' = T::s, R::s' = R::s, c' = c,
  }
  action finishRetryPath = all {
    c.committed, any { R::releaseQueued, R::resume },
    T::s' = T::s, P::s' = P::s, c' = c,
  }
  val roundDone = T::terminal and P::terminal and R::terminal
  action nextEpoch = all {
    c.round == 0, roundDone,
    c' = { ...initial(c.threadFixed, c.processorFixed, c.retryFixed), round: 1 },
    T::s' = T::initial(c.threadFixed), P::s' = P::initial(c.processorFixed),
    R::s' = R::initial(c.retryFixed),
  }
  val terminal = c.round == 1 and roundDone
  action finished = all { terminal, c' = c, T::s' = T::s, P::s' = P::s, R::s' = R::s }
  action step = any { request, joinThreadOwner, joinThreadReader,
    joinProcessorWaiter, retryHead, joinRetryWaiter, commitOneCollective,
    finishThreadPaths, finishProcessorPath, finishRetryPath, nextEpoch, finished }
  val threadServiceable = T::progressPossible
  val processorServiceable = P::progressPossible
  val retryServiceable = R::serviceable
  val lockSafety = T::locksPreserved and P::lockOrder and
    R::unlockedParticipation and R::ownerPreserved
  val sharedCommit = (T::s.gcDone == c.committed) and
    (P::s.gcDone == c.committed) and (R::s.gcDone == c.committed) and
    (c.committed implies c.joined == Set(0, 1, 2, 3, 4))
  val safe = threadServiceable and processorServiceable and retryServiceable and
    lockSafety and sharedCommit
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set((c, T::s, P::s, R::s))).implies(eventually(terminal))
}

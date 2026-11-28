module retirement_handoff_refinement {
  // Research only: source-operation refinement of joinable_error_same_owner.
  // Start after cohort withdrawal and worker exit. These entry premises are
  // NOT established here. Two slots/two incarnations are counterexample bounds.
  // producer/borrower represent resource-specific remote users, not OS joiners.
  type Worker = {
    generation: int, owner: int, phase: int, calls: int, lastJoinOwner: int,
    failureClass: int, error: bool, errorGeneration: int, errorOwner: int,
    claimed: bool, claimSlot: int, claimGeneration: int, claimOwner: int,
    sourceRoot: bool, targetPublished: bool, targetObserved: bool,
    borrower: bool, producer: bool, work: bool
  }
  type State = { policy: int, reuse: bool, a: Worker, b: Worker }
  var s: State
  // phase 2 exited/unjoined; 3 joined/untransferred; 4 transferred;
  // 5 reclaimed; 6 terminal retained error. failureClass 1 is an EXPLICIT
  // hypothetical retryable platform contract, never inferred from EDEADLK.
  pure def worker(failure: int, generation: int): Worker = {
    generation: generation, owner: 0, phase: 2, calls: 0, lastJoinOwner: 0,
    failureClass: failure, error: false, errorGeneration: 0, errorOwner: 0,
    claimed: false, claimSlot: -1, claimGeneration: 0, claimOwner: 0,
    sourceRoot: true, targetPublished: false, targetObserved: false,
    borrower: true, producer: true, work: false
  }
  pure def initial(policy: int, reuse: bool, failure: int): State = {
    policy: policy, reuse: reuse, a: worker(failure, 1), b: worker(0, 1)
  }
  pure def at(st: State, i: int): Worker = if (i == 0) st.a else st.b
  pure def replaceWorker(st: State, i: int, w: Worker): State =
    if (i == 0) { ...st, a: w } else { ...st, b: w }
  action initFixed = s' = initial(0, false, 0)
  action initRetained = s' = initial(0, false, 2)
  action initConditionalRetry = s' = initial(0, false, 1)
  action initReuse = s' = initial(0, true, 1)
  action initRepeatJoin = s' = initial(1, false, 0)
  action initCrossWorker = s' = initial(2, false, 2)
  action initStaleGeneration = s' = initial(3, true, 1)
  action initEarlyReclaim = s' = initial(4, false, 0)
  action initRootGap = s' = initial(5, false, 0)
  action initForgotProducer = s' = initial(6, false, 0)
  action initWrongOwner = s' = initial(7, false, 0)

  action joinError(i: int): bool = {
    val w = at(s, i)
    all {
      w.phase == 2, w.failureClass > 0, not(w.error),
      s' = replaceWorker(s, i, { ...w, error: true,
        errorGeneration: w.generation, errorOwner: w.owner,
        phase: if (w.failureClass == 2) 6 else 2 })
    }
  }
  action joinSuccess(i: int): bool = {
    val w = at(s, i)
    val crossClaim = s.policy == 2 and i == 1 and s.a.error
    val recovered = w.error or crossClaim
    val origin = if (crossClaim) s.a else w
    all {
      w.phase == 2,
      w.failureClass == 0 or (w.failureClass == 1 and w.error),
      s' = replaceWorker(s, i, { ...w, phase: 3, calls: w.calls + 1,
        lastJoinOwner: if (s.policy == 7) 1 else w.owner,
        claimed: recovered, claimSlot: if (crossClaim) 0 else i,
        claimGeneration: origin.errorGeneration, claimOwner: origin.errorOwner })
    }
  }
  action joinAgain(i: int): bool = {
    val w = at(s, i)
    all { s.policy == 1, w.phase == 3, w.calls == 1,
      s' = replaceWorker(s, i, { ...w, calls: 2 }) }
  }
  action publishRoot(i: int): bool = {
    val w = at(s, i)
    all { w.phase == 2 or w.phase == 3, not(w.targetPublished),
      s' = replaceWorker(s, i, { ...w, targetPublished: true }) }
  }
  action observeRoot(i: int): bool = {
    val w = at(s, i)
    all { w.phase == 2 or w.phase == 3, w.targetPublished,
      not(w.targetObserved),
      s' = replaceWorker(s, i, { ...w, targetObserved: true }) }
  }
  action borrowerReturns(i: int): bool = {
    val w = at(s, i)
    all { w.phase == 2 or w.phase == 3, w.borrower,
      s' = replaceWorker(s, i, { ...w, borrower: false }) }
  }
  // Finishing/orphaning a producer can CREATE work after an empty snapshot.
  action finishProducer(i: int): bool = {
    val w = at(s, i)
    all { w.phase == 2 or w.phase == 3, w.producer,
      s' = replaceWorker(s, i, { ...w, producer: false, work: true }) }
  }
  action scanWork(i: int): bool = {
    val w = at(s, i)
    all { w.phase == 2 or w.phase == 3, w.work,
      s' = replaceWorker(s, i, { ...w, work: false }) }
  }
  action transfer(i: int): bool = {
    val w = at(s, i)
    all {
      w.phase == 3, w.targetObserved, not(w.borrower), not(w.work),
      not(w.producer) or s.policy == 6,
      s' = replaceWorker(s, i, { ...w, phase: 4, sourceRoot: false })
    }
  }
  action reclaim(i: int): bool = {
    val w = at(s, i)
    all { w.phase == 4 or (s.policy == 4 and w.phase == 3),
      s' = replaceWorker(s, i, { ...w, phase: 5, sourceRoot: false }) }
  }
  action dropSourceEarly(i: int): bool = {
    val w = at(s, i)
    all { s.policy == 5, w.phase == 2, w.sourceRoot, not(w.targetObserved),
      s' = replaceWorker(s, i, { ...w, sourceRoot: false }) }
  }
  action reuseSlot = {
    val fresh = worker(0, 2)
    all { s.reuse, s.a.phase == 5, s.a.generation == 1,
      s' = { ...s, a: if (s.policy == 3)
        { ...fresh, error: s.a.error, errorGeneration: s.a.errorGeneration,
          errorOwner: s.a.errorOwner } else fresh } }
  }
  pure def ended(w: Worker): bool = w.phase == 5 or w.phase == 6
  val terminal = ended(s.a) and ended(s.b) and
    (not(s.reuse) or s.a.generation == 2)
  action done = all { terminal, s' = s }
  action workerStep = {
    nondet i = Set(0, 1).oneOf()
    any { joinError(i), joinSuccess(i), joinAgain(i), publishRoot(i),
      observeRoot(i), borrowerReturns(i), finishProducer(i), scanWork(i),
      transfer(i), reclaim(i), dropSourceEarly(i) }
  }
  action step = any { workerStep, reuseSlot, done }
  pure def rootsOk(w: Worker): bool =
    w.sourceRoot or w.targetObserved
  pure def closureOk(w: Worker): bool =
    (w.phase != 4 and w.phase != 5) or
    (w.targetObserved and not(w.sourceRoot) and
     not(w.borrower) and not(w.producer) and not(w.work))
  pure def claimOk(w: Worker, i: int): bool = not(w.claimed) or
    (w.error and w.claimSlot == i and w.claimGeneration == w.generation and
     w.claimGeneration == w.errorGeneration and w.claimOwner == w.owner and
     w.claimOwner == w.errorOwner)
  pure def ownerOk(w: Worker): bool =
    w.calls == 0 or w.lastJoinOwner == w.owner
  val noDoubleJoin = s.a.calls <= 1 and s.b.calls <= 1
  val exactRecovery = claimOk(s.a, 0) and claimOk(s.b, 1)
  val rootCoverage = rootsOk(s.a) and rootsOk(s.b)
  val resourceClosure = closureOk(s.a) and closureOk(s.b)
  val exclusiveOwner = ownerOk(s.a) and ownerOk(s.b)
  val retainedErrorSafe =
    (s.a.phase != 6 or (s.a.sourceRoot and s.a.calls == 0)) and
    (s.b.phase != 6 or (s.b.sourceRoot and s.b.calls == 0))
  val safe = noDoubleJoin and exactRecovery and rootCoverage and
    resourceClosure and exclusiveOwner and retainedErrorSafe
  // Finite environment and eventual completion of modeled producer/borrower
  // actions. No native OS/GC/weak-memory progress theorem is claimed.
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}

module performance_reliability_stability {
  // Two semantic workers and two generations; neither bounds host CPU capacity.
  val workers = Set(0, 1)
  val fixedCopyBudget = 2
  type State = { policy: int, generation: int, phase: int,
    status: int -> int, resultGeneration: int -> int, roots: Set[int],
    borrowed: Set[int], copies: int, useful: int, peak: int, errors: int,
    outcome: int, fault: int, smp: bool, multipleVms: bool,
    threadedVms: bool, copyBudget: int }
  var s: State

  pure def initial(policy: int, fault: int): State = {
    policy: policy, generation: 0, phase: 0,
    status: Map(0 -> 0, 1 -> 0), resultGeneration: Map(0 -> -1, 1 -> -1),
    roots: Set(), borrowed: Set(), copies: 0, useful: 0, peak: 0,
    errors: 0, outcome: -1, fault: fault, smp: policy != 7,
    multipleVms: true, threadedVms: true,
    copyBudget: if (policy == 8) 3 else fixedCopyBudget
  }
  action initFixed = {
    nondet fault = Set(-1, 0, 1).oneOf()
    s' = initial(0, fault)
  }
  action initSerialized = s' = initial(1, -1)
  action initRedundantCopy = s' = initial(2, -1)
  action initEarlyReclaim = s' = initial(3, -1)
  action initFalseSuccess = s' = initial(4, 0)
  action initStaleReuse = s' = initial(5, -1)
  action initDeadlock = s' = initial(6, -1)
  action initDisabledSmp = s' = initial(7, -1)
  action initRelaxedBudget = s' = initial(8, -1)

  // Publish both independent tasks before executing either. This is a protocol
  // overlap witness, not proof of simultaneous physical CPU execution.
  action launch = all {
    s.phase == 0,
    s' = { ...s, phase: if (s.policy == 6) 5 else 1,
      status: Map(0 -> 1, 1 -> (if (s.policy == 1) 0 else 1)),
      roots: if (s.policy == 3) Set() else workers,
      borrowed: workers, peak: if (s.policy == 1) 1 else 2 },
  }
  action copy = {
    nondet w = workers.oneOf()
    all {
      s.phase == 1, s.status.get(w) == 1,
      s' = { ...s, status: s.status.set(w, 2),
        copies: s.copies + (if (s.policy == 2 and w == 0) 2 else 1) },
    }
  }
  action scan = {
    nondet w = workers.oneOf()
    all {
      s.phase == 1, s.status.get(w) == 2,
      s' = { ...s, status: s.status.set(w, 3), useful: s.useful + 1,
        resultGeneration: s.resultGeneration.set(w,
          if (s.policy == 5 and s.generation == 1) 0 else s.generation) },
    }
  }
  // Failure may occur before or after copying; roots remain owned until join.
  action workerError = {
    nondet w = workers.oneOf()
    all {
      s.phase == 1, s.fault == w,
      Set(1, 2).contains(s.status.get(w)),
      s' = { ...s, status: s.status.set(w, 4), errors: s.errors + 1 },
    }
  }
  action serializedNext = all {
    s.phase == 1, s.policy == 1,
    s.status.get(0) == 3, s.status.get(1) == 0,
    s' = { ...s, status: s.status.set(1, 1) },
  }
  action drain = all {
    s.phase == 1, workers.forall(w => Set(3, 4).contains(s.status.get(w))),
    s' = { ...s, phase: 2,
      outcome: if (s.policy == 4 or s.errors == 0) 0 else 1 },
  }
  // Abstract successful join acknowledgement, not an OS join implementation.
  action join = all { s.phase == 2, s' = { ...s, phase: 3, borrowed: Set() } }
  action recycle = all {
    s.phase == 3, s.borrowed.size() == 0,
    s' = if (s.generation == 0) { ...s, generation: 1, phase: 0,
      status: Map(0 -> 0, 1 -> 0), resultGeneration: Map(0 -> -1, 1 -> -1),
      roots: Set(), copies: 0, useful: 0, peak: 0, outcome: -1, fault: -1 }
    else { ...s, phase: 4, roots: Set() },
  }
  val terminal = s.phase == 4
  action finished = all { terminal, s' = s }
  action step = any { launch, copy, scan, workerError, serializedNext, drain,
    join, recycle, finished }

  val budgetUnchanged = s.copyBudget == fixedCopyBudget
  val configurationFixed = s.smp and s.multipleVms and s.threadedVms
    and budgetUnchanged
  val boundedWork = s.copies <= fixedCopyBudget and s.useful <= s.copies
  val parallelPublication = (s.phase >= 1 and s.phase <= 3).implies(s.peak == 2)
  val rootsOwned = s.borrowed.subseteq(s.roots)
  val resultsCurrent = workers.forall(w => (s.status.get(w) == 3)
    .implies(s.resultGeneration.get(w) == s.generation))
  val honestOutcome = (s.outcome == 0).implies(s.errors == 0 and s.useful == 2)
  val reuseAfterJoin = (s.phase == 0 or terminal).implies(s.borrowed.size() == 0)
  val progressEnabled = terminal or enabled(step)
  val highPerformance = configurationFixed and boundedWork and parallelPublication
  val reliability = rootsOwned and resultsCurrent and honestOutcome
  val stability = reuseAfterJoin and progressEnabled
  val simultaneous = highPerformance and reliability and stability
  // Fair protocol scheduling is explicit; arbitrary OS starvation is not proved.
  temporal completion = weakFair(step, s).implies(eventually(terminal))
}

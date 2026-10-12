module pstate_retirement_generation {
  // One reusable slot witnesses two retirement rounds, not a CPU-count limit.
  type State = { policy: str, generation: int, round: int, phase: str,
    live: bool, resourceGeneration: int, pendingGeneration: int,
    threadLive: bool, senderDone: bool, closedRound: int, joined: str,
    failedRound: int, doubleInit: bool, wrongGeneration: bool,
    unsafeReclaim: bool }
  var s: State
  pure def initial(policy: str, failedRound: int): State = {
    policy: policy, generation: 1, round: 0, phase: "running", live: true,
    resourceGeneration: 1, pendingGeneration: 0, threadLive: true,
    senderDone: false, closedRound: 0, joined: "waiting",
    failedRound: failedRound, doubleInit: false, wrongGeneration: false,
    unsafeReclaim: false,
  }
  action initOld = s' = initial("missing-destroy", 0)
  action initStaleGeneration = s' = initial("stale-generation", 0)
  action initStaleRound = s' = initial("stale-round", 0)
  action initIgnoredJoin = s' = initial("ignored-join", 1)
  action initFixed = {
    nondet failedRound = Set(0, 1, 2).oneOf()
    s' = initial("fixed", failedRound)
  }
  action retire = all {
    s.phase == "running",
    s' = { ...s, phase: "retiring", round: s.round + 1,
      pendingGeneration: s.generation, senderDone: false, joined: "waiting" },
  }
  action senderCompletes = all {
    s.phase == "retiring", not(s.senderDone),
    s' = { ...s, senderDone: true },
  }
  action workerExits = all {
    s.phase == "retiring", s.threadLive,
    s' = { ...s, threadLive: false },
  }
  action join = all {
    s.phase == "retiring", s.joined == "waiting",
    not(s.threadLive) or s.failedRound == s.round,
    val failed = s.failedRound == s.round
    s' = { ...s, joined: if (failed) "failed" else "ok",
      phase: if (failed and s.policy != "ignored-join") "quarantined" else s.phase },
  }
  // Abstracts the source-derived next-round upward convergence contract.
  action closeRound = all {
    s.phase == "retiring", s.senderDone, s.closedRound < s.round,
    s' = { ...s, closedRound: s.round },
  }
  action reclaim = all {
    s.phase == "retiring",
    s.joined == "ok" or (s.policy == "ignored-join" and s.joined == "failed"),
    if (s.policy == "stale-round") s.closedRound > 0 else s.closedRound == s.round,
    s.pendingGeneration == s.generation,
    s' = { ...s, phase: if (s.generation == 1) "reclaimed" else "done",
      live: s.policy == "missing-destroy",
      pendingGeneration: if (s.policy == "stale-generation") s.pendingGeneration else 0,
      unsafeReclaim: s.unsafeReclaim or s.threadLive or not(s.senderDone)
        or s.joined != "ok" or s.closedRound != s.round },
  }
  action grow = all {
    s.phase == "reclaimed",
    s' = { ...s, phase: "running", generation: 2, resourceGeneration: 2,
      live: true, threadLive: true, doubleInit: s.doubleInit or s.live },
  }
  action staleCleanup = all {
    s.phase == "running", s.generation == 2,
    s.pendingGeneration != 0, s.pendingGeneration != s.resourceGeneration,
    s' = { ...s, live: false, wrongGeneration: true, pendingGeneration: 0 },
  }
  val terminal = s.phase == "done" or s.phase == "quarantined"
  action finished = all { terminal, s' = s }
  action step = any { retire, senderCompletes, workerExits, join, closeRound,
    reclaim, grow, staleCleanup, finished }
  val initializationSafe = not(s.doubleInit)
  val generationSafe = not(s.wrongGeneration)
  val roundSafe = not(s.unsafeReclaim)
  val failedJoinSafe = s.joined != "failed" or
    (s.phase == "quarantined" and s.live and s.pendingGeneration == s.generation)
  val safe = initializationSafe and generationSafe and roundSafe and failedJoinSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

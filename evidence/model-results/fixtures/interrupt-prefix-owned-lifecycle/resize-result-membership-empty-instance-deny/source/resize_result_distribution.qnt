module resize_result_distribution {
  // Two winning requests on a fixed retained population. Bounds are not CPU limits.
  type State = { policy: str, population: int, epoch: int,
    requester1: int, requester2: int, outcome1: int, outcome2: int,
    completed: Set[int], returned: Set[int], published: bool, ready: bool,
    resultEpoch: int, result: int, badResult: bool, badPublication: bool,
    badEpoch: bool, lostReply: bool }
  var s: State
  pure def initial(policy: str, population: int, requester1: int, requester2: int,
    outcome1: int, outcome2: int): State = {
    policy: policy, population: population, epoch: 1,
    requester1: requester1, requester2: requester2, outcome1: outcome1, outcome2: outcome2,
    completed: Set(), returned: Set(), published: false, ready: false,
    resultEpoch: 0, result: 0, badResult: false, badPublication: false,
    badEpoch: false, lostReply: false,
  }
  action initOld = s' = initial("local-result", 2, 1, 1, 1, 2)
  action initEarly = s' = initial("early-read", 2, 1, 1, 1, 2)
  action initStale = s' = initial("stale-epoch", 2, 1, 1, 0, 1)
  action initOverwrite = s' = initial("no-ack", 2, 1, 1, 1, 2)
  action initFixed = {
    nondet population = 2.to(4).oneOf()
    nondet requester1 = 0.to(population - 1).oneOf()
    nondet requester2 = 0.to(population - 1).oneOf()
    nondet outcome1 = Set(0, 1, 2).oneOf()
    nondet outcome2 = Set(0, 1, 2).oneOf()
    s' = initial("tagged-acknowledged", population, requester1, requester2, outcome1, outcome2)
  }
  val nodes = 0.to(s.population - 1)
  val requester = if (s.epoch == 1) s.requester1 else s.requester2
  val outcome = if (s.epoch == 1) s.outcome1 else s.outcome2
  action executeLocal = {
    nondet node = nodes.oneOf()
    all { not(s.completed.contains(node)),
      s' = { ...s, completed: s.completed.union(Set(node)) } }
  }
  // P0 owns the authoritative resize status; publication is a separate event.
  action publish = all {
    s.policy != "local-result", s.completed.contains(0), not(s.published),
    s' = { ...s, published: true, ready: true, resultEpoch: s.epoch, result: outcome },
  }
  action returnResult = {
    nondet node = nodes.oneOf()
    all {
      s.completed.contains(node), not(s.returned.contains(node)),
      if (s.policy == "local-result" or s.policy == "early-read") true
      else if (s.policy == "stale-epoch") s.ready
      else s.ready and s.resultEpoch == s.epoch,
      val local = s.policy == "local-result"
      val observed = if (local) (if (node == 0) outcome else 0) else s.result
      val observedEpoch = if (local) s.epoch else s.resultEpoch
      s' = { ...s, returned: s.returned.union(Set(node)),
        badResult: s.badResult or (node == requester and observed != outcome),
        badPublication: s.badPublication or (not(local) and not(s.ready)),
        badEpoch: s.badEpoch or (not(local) and observedEpoch != s.epoch),
      },
    }
  }
  action nextRequest = all {
    s.epoch == 1,
    s.completed == nodes,
    s.policy == "local-result" or s.published,
    if (s.policy == "no-ack") s.returned.contains(0) else s.returned == nodes,
    s' = { ...s, epoch: 2, completed: Set(), returned: Set(), published: false,
      ready: s.policy == "stale-epoch",
      lostReply: s.lostReply or s.returned != nodes },
  }
  val terminal = s.epoch == 2 and s.returned == nodes and
    (s.policy == "local-result" or s.published)
  action finished = all { terminal, s' = s }
  action step = any { executeLocal, publish, returnResult, nextRequest, finished }
  val resultSafe = not(s.badResult)
  val publicationSafe = not(s.badPublication)
  val epochSafe = not(s.badEpoch)
  val replySafe = not(s.lostReply)
  val safe = resultSafe and publicationSafe and epochSafe and replySafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

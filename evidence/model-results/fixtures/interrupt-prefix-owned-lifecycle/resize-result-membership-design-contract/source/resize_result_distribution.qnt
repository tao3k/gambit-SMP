module resize_result_distribution {
  // Two winning requests on a fixed retained population. Bounds are not CPU limits.
  type State = { policy: str, population: int, epoch: int,
    requester1: int, requester2: int, outcome1: int, outcome2: int,
    completed: Set[int], returned: Set[int], published: bool, ready: bool,
    resultEpoch: int, result: int, badResult: bool, badPublication: bool,
    badEpoch: bool, lostReply: bool }
  var reply: State
  pure def initial(policy: str, population: int, requester1: int, requester2: int,
    outcome1: int, outcome2: int): State = {
    policy: policy, population: population, epoch: 1,
    requester1: requester1, requester2: requester2, outcome1: outcome1, outcome2: outcome2,
    completed: Set(), returned: Set(), published: false, ready: false,
    resultEpoch: 0, result: 0, badResult: false, badPublication: false,
    badEpoch: false, lostReply: false,
  }
  action initOld = reply' = initial("local-result", 2, 1, 1, 1, 2)
  action initEarly = reply' = initial("early-read", 2, 1, 1, 1, 2)
  action initStale = reply' = initial("stale-epoch", 2, 1, 1, 0, 1)
  action initOverwrite = reply' = initial("no-ack", 2, 1, 1, 1, 2)
  action initFixed = {
    nondet population = 2.to(4).oneOf()
    nondet requester1 = 0.to(population - 1).oneOf()
    nondet requester2 = 0.to(population - 1).oneOf()
    nondet outcome1 = Set(0, 1, 2).oneOf()
    nondet outcome2 = Set(0, 1, 2).oneOf()
    reply' = initial("tagged-acknowledged", population, requester1, requester2, outcome1, outcome2)
  }
  val nodes = 0.to(reply.population - 1)
  val requester = if (reply.epoch == 1) reply.requester1 else reply.requester2
  val outcome = if (reply.epoch == 1) reply.outcome1 else reply.outcome2
  action executeLocal = {
    nondet node = nodes.oneOf()
    all { not(reply.completed.contains(node)),
      reply' = { ...reply, completed: reply.completed.union(Set(node)) } }
  }
  // P0 owns the authoritative resize status; publication is a separate event.
  action publish = all {
    reply.policy != "local-result", reply.completed.contains(0), not(reply.published),
    reply' = { ...reply, published: true, ready: true, resultEpoch: reply.epoch, result: outcome },
  }
  action returnResult = {
    nondet node = nodes.oneOf()
    all {
      reply.completed.contains(node), not(reply.returned.contains(node)),
      if (reply.policy == "local-result" or reply.policy == "early-read") true
      else if (reply.policy == "stale-epoch") reply.ready
      else reply.ready and reply.resultEpoch == reply.epoch,
      val local = reply.policy == "local-result"
      val observed = if (local) (if (node == 0) outcome else 0) else reply.result
      val observedEpoch = if (local) reply.epoch else reply.resultEpoch
      reply' = { ...reply, returned: reply.returned.union(Set(node)),
        badResult: reply.badResult or (node == requester and observed != outcome),
        badPublication: reply.badPublication or (not(local) and not(reply.ready)),
        badEpoch: reply.badEpoch or (not(local) and observedEpoch != reply.epoch),
      },
    }
  }
  action nextRequest = all {
    reply.epoch == 1,
    reply.completed == nodes,
    reply.policy == "local-result" or reply.published,
    if (reply.policy == "no-ack") reply.returned.contains(0) else reply.returned == nodes,
    reply' = { ...reply, epoch: 2, completed: Set(), returned: Set(), published: false,
      ready: reply.policy == "stale-epoch",
      lostReply: reply.lostReply or reply.returned != nodes },
  }
  val terminal = reply.epoch == 2 and reply.returned == nodes and
    (reply.policy == "local-result" or reply.published)
  action finished = all { terminal, reply' = reply }
  action step = any { executeLocal, publish, returnResult, nextRequest, finished }
  val resultSafe = not(reply.badResult)
  val publicationSafe = not(reply.badPublication)
  val epochSafe = not(reply.badEpoch)
  val replySafe = not(reply.lostReply)
  val safe = resultSafe and publicationSafe and epochSafe and replySafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(reply)).implies(eventually(terminal))
}

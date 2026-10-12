module resize_commit_startup_round {
  // Source-shaped nested result barrier. New members offer NOOP from startup;
  // retained old members enter the result barrier after local resize returns.
  // Joining/OS exit is a premise, not inferred from a returned error status.
  type State = { policy: int, epoch: int, growing: bool, count: int, requester: int,
    status: int, phase: int, executed: Set[int], offered: Set[int],
    consumed: Set[int], noop: Set[int], result: int,
    returned: bool, body: bool, badResult: bool, badBody: bool }
  var round: State
  pure def initial(policy: int, growing: bool, requester: int, status: int): State = {
    policy: policy, epoch: 1, growing: growing,
    count: if (growing) (if (status == 0) 3 else 2) else 2,
    requester: requester,
    status: status, phase: 0, executed: Set(), offered: Set(),
    consumed: Set(), noop: Set(), result: 0, returned: false,
    body: false, badResult: false, badBody: false,
  }
  val members = 0.to(round.count - 1)
  val oldMembers = if (round.epoch == 2) members
    else if (round.growing) Set(0, 1) else Set(0, 1, 2)
  val retained = oldMembers.intersect(members)
  val newMembers = members.exclude(oldMembers)
  action initFixed = {
    nondet growing = Set(false, true).oneOf()
    nondet requester = Set(0, 1).oneOf()
    nondet status = Set(0, 11, 22).oneOf()
    all { growing or status == 0, round' = initial(0, growing, requester, status) }
  }
  action initLocalResult = round' = initial(1, true, 1, 11)
  action initMissingStartup = round' = initial(2, true, 1, 0)
  action initEarlyBody = round' = initial(3, true, 1, 0)
  // Native shrink can retire the requester itself. The C exit path has no
  // modeled continuation transfer to a retained processor.
  action initRetiredCaller = round' = initial(0, false, 2, 0)
  action executeRetained = {
    nondet node = retained.oneOf()
    all { round.phase == 0, not(round.executed.contains(node)),
      round' = { ...round, executed: round.executed.union(Set(node)) } }
  }
  action offerCommit = {
    nondet node = members.oneOf()
    all { round.phase == 0, not(round.offered.contains(node)),
      if (retained.contains(node)) round.executed.contains(node)
      else round.policy != 2,
      round' = { ...round, offered: round.offered.union(Set(node)) } }
  }
  // Every member participates. P0 proposes the distinct result operation;
  // others propose NOOP. The existing minimum-priority tree selects P0.
  action broadcastCommit = all {
    round.phase == 0, round.offered == members,
    round' = { ...round, phase: 1, result: round.status },
  }
  action consumeCommit = {
    nondet node = members.oneOf()
    all { round.phase == 1, not(round.consumed.contains(node)),
      val observed = if (round.policy == 1 and node != 0) 0 else round.result
      round' = { ...round, consumed: round.consumed.union(Set(node)),
        returned: round.returned or node == round.requester,
        badResult: round.badResult or (node == round.requester and observed != round.status) },
    }
  }
  action offerNoop = {
    nondet node = members.oneOf()
    all { round.phase == 1, round.consumed.contains(node), not(round.noop.contains(node)),
      round' = { ...round, noop: round.noop.union(Set(node)) } }
  }
  action acknowledge = all {
    round.phase == 1, round.noop == members,
    round' = { ...round, phase: 2 },
  }
  action enterBody = all {
    not(round.body), newMembers != Set(),
    round.phase == 2 or (round.policy == 3 and round.phase == 1 and
      newMembers.subseteq(round.consumed)),
    round' = { ...round, body: true, badBody: round.badBody or round.phase != 2 },
  }
  action nextEpoch = all {
    round.phase == 2, round.epoch == 1,
    newMembers == Set() or round.body,
    round' = { ...round, epoch: 2, phase: 0, executed: Set(), offered: Set(),
      consumed: Set(), noop: Set(), result: 0, returned: false, body: false,
      status: if (round.status == 0) 22 else 0 },
  }
  val resultSafe = not(round.badResult)
  val startupSafe = not(round.badBody)
  val requesterCompletionSafe = round.phase != 2 or round.returned
  val terminal = round.epoch == 2 and round.phase == 2 and
    (newMembers == Set() or round.body) and round.returned
  action finished = all { terminal, round' = round }
  action step = any { executeRetained, offerCommit, broadcastCommit,
    consumeCommit, offerNoop, acknowledge, enterBody, nextEpoch, finished }
  val participationSafe = terminal or enabled(step)
  val safe = resultSafe and startupSafe and participationSafe
  temporal progress = always(participationSafe) and
    weakFair(step, Set(round)).implies(eventually(terminal))
}

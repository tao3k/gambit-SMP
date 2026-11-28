module retirement_repair_campaign {
  import retirement_exit_handoff.* from "./retirement_exit_handoff"

  // Test-workflow model over the real existing finite retirement protocol.
  // Two consecutive cohort incarnations are a nonvacuity bound, not native
  // inventory coverage or a CPU limit. No action grants native admission.
  type Campaign = { policy: int, phase: str, generation: int,
    source: int, built: int, runSource: int, changed: bool,
    observed: Set[int], credited: Set[int], receiptSource: int,
    receiptGeneration: int, erasedFailure: bool, priorCompleted: bool,
    receivedWork: Set[int], ownedWork: Set[int], completedWork: Set[int],
    receivedRoots: Set[int], ownedRoots: Set[int], completedRoots: Set[int] }
  var c: Campaign
  pure def campaignInitial(policy: int): Campaign = {
    policy: policy, phase: "build", generation: 0,
    source: 1, built: 0, runSource: 0, changed: false,
    observed: Set(), credited: Set(), receiptSource: 0,
    receiptGeneration: -1, erasedFailure: false, priorCompleted: false,
    receivedWork: Set(), ownedWork: Set(), completedWork: Set(),
    receivedRoots: Set(), ownedRoots: Set(), completedRoots: Set() }
  action init = {
    nondet policy = Set(0, 1, 2, 3, 4, 5, 6, 7, 8).oneOf()
    all { initFixed, c' = campaignInitial(policy) }
  }

  // The imported complete initializer preserves every elementary machine effect.
  // keepProtocol is the only intentional stutter outside the running stage.
  action keepProtocol = all { h' = h, keepC, keepS }
  action build = all { c.phase == "build", restartFixed,
    c' = { ...c, built: c.source, runSource: c.source, phase: "run" } }
  action execute = all { c.phase == "run", not(terminal), step, c' = c }
  action revise = all { c.phase == "run", (c.policy == 1 or c.policy == 6), not(c.changed),
    // Metadata change is not an execution/GC transition of the owned protocol.
    h' = h, keepC, keepS,
    c' = { ...c, source: 2, changed: true, credited: Set() } }
  action collect = all { c.phase == "run", terminal, finished,
    c' = if (h.joinFailed)
      { ...c, phase: "failed" }
    else { ...c, phase: "collected", observed: c.observed.union(Set(c.generation)),
      receiptSource: c.runSource, receiptGeneration: c.generation } }
  // Namespaced identities, not addresses: two bounded token/root roles per cohort.
  val deliveredWork = h.targetWork.map(token => 2 * c.generation + token)
  val deliveredRoots = h.targetRoots.map(root => 2 * c.generation +
    (if (root == "activation") 0 else 1))
  action credit = all { c.phase == "collected", finished,
    (c.built == c.source and c.receiptSource == c.source and
     c.receiptGeneration == c.generation) or c.policy == 1,
    c' = { ...c, phase: "next", credited: c.credited.union(Set(c.generation)),
      receivedWork: c.receivedWork.union(deliveredWork),
      ownedWork: c.ownedWork.union(deliveredWork),
      receivedRoots: c.receivedRoots.union(deliveredRoots),
      ownedRoots: c.ownedRoots.union(deliveredRoots) } }
  action rejectStale = all { c.phase == "collected", c.policy != 1,
    c.receiptSource != c.source, finished, c' = { ...c, phase: "failed" } }
  action nextCohort = all { c.phase == "next", c.generation == 0,
    restartFixed, c' = { ...c, generation: 1, phase: "build" } }
  action complete = all { c.phase == "next", c.generation == 1,
    c.credited == Set(0, 1), finished, c' = { ...c, phase: "done" } }
  action replay = all { c.phase == "build", c.generation == 1, c.policy == 2,
    // Bad collector counts the old incarnation without executing this one.
    restartFixed, c' = { ...c, credited: c.credited.union(Set(1)), phase: "done" } }
  action subset = all { c.phase == "next", c.generation == 0, c.policy == 3,
    finished, c' = { ...c, phase: "done" } }
  action failedAsPass = all { c.phase == "failed", c.policy == 4,
    finished, c' = { ...c, credited: c.credited.union(Set(c.generation)), phase: "done" } }
  action eraseFailure = all { c.phase == "failed", c.policy == 5,
    restartFixed, c' = { ...c, erasedFailure: true, phase: "build" } }
  // A living recipient may finish prior-cohort work independently of this
  // donor. Binding this event to an actual last consumer remains a source duty.
  action finishPriorRecipient = all { c.generation == 1, c.phase == "run",
    not(c.priorCompleted), keepProtocol,
    c' = { ...c, priorCompleted: true,
      ownedWork: c.ownedWork.filter(key => key >= 2),
      completedWork: c.completedWork.union(c.ownedWork.filter(key => key < 2)),
      ownedRoots: c.ownedRoots.filter(key => key >= 2),
      completedRoots: c.completedRoots.union(c.ownedRoots.filter(key => key < 2)) } }
  action dropRecipient = all { c.policy == 8, c.phase == "next", c.generation == 0,
    restartFixed, c' = { ...c, generation: 1, phase: "build",
      ownedWork: Set(), ownedRoots: Set() } }
  action cancel = all { c.phase == "run", c.policy == 7, keepProtocol,
    c' = { ...c, phase: "cancelled" } }
  action campaignFinished = all { c.phase == "cancelled" or c.phase == "done" or (c.phase == "failed" and c.policy != 4 and c.policy != 5),
    keepProtocol, c' = c }
  action campaignStep = any { build, execute, revise, collect, credit, rejectStale,
    nextCohort, complete, replay, subset, failedAsPass, eraseFailure, finishPriorRecipient, dropRecipient, cancel, campaignFinished }
  val recipientCovered = c.receivedWork.subseteq(c.ownedWork.union(c.completedWork)) and
    c.receivedRoots.subseteq(c.ownedRoots.union(c.completedRoots)) and
    c.ownedWork.intersect(c.completedWork) == Set() and
    c.ownedRoots.intersect(c.completedRoots) == Set()
  val campaignSafe = safe and recipientCovered and not(c.erasedFailure) and
    c.credited.subseteq(c.observed) and
    (c.credited.size() == 0 or c.built == c.source) and
    (c.phase != "done" or (c.credited == Set(0, 1) and
      terminal and not(h.joinFailed)))
  val noRepeatedSuccess = c.policy != 0 or not(c.phase == "done" and c.observed == Set(0, 1) and c.ownedWork.contains(0))
  val campaignNoRetainedFailure = c.policy != 0 or not(c.phase == "failed" and h.joinFailed and
    h.sourceRoots == roots and not(h.handed) and not(h.reclaimed))
  val noCancelled = c.policy != 7 or not(c.phase == "cancelled" and not(h.handed) and not(h.reclaimed))
  val noStaleRejected = c.policy != 6 or not(c.phase == "failed" and c.changed and
    c.source == 2 and c.built == 1 and c.credited.size() == 0)
  val noRecipientCompletion = c.policy != 0 or not(c.phase == "done" and
    c.completedWork.contains(0) and not(c.ownedWork.contains(0)) and recipientCovered)
  val rejectLostRecipient = c.policy != 8 or campaignSafe
  val correctedPolicy = Set(0, 6, 7).contains(c.policy)
  val fixedSafe = safe and (not(correctedPolicy) or campaignSafe)
  val rejectStaleBuild = c.policy != 1 or campaignSafe
  val rejectReplay = c.policy != 2 or campaignSafe
  val rejectPartialInventory = c.policy != 3 or campaignSafe
  val rejectFailedAsPass = c.policy != 4 or campaignSafe
  val rejectEraseFailure = c.policy != 5 or campaignSafe
  temporal campaignCompletion = correctedPolicy.implies( weakFair(campaignStep, Set((c, configuration)))
    .implies(eventually(c.phase == "done" or c.phase == "failed" or c.phase == "cancelled")))
}

module retirement_recovery_model {
  // Refinement of recovery evidence inside this existing campaign, not an OS
  // errno oracle. join-error-pending is a declared still-joinable premise.
  // The two consumer roles are a finite public/private witness population.
  type RecoveryKey = { source: int, configuration: int, vm: int,
    worker: int, generation: int, owner: int }
  type RecoveryState = { key: RecoveryKey, errorKey: RecoveryKey, joinKey: RecoveryKey,
    errno: int, phase: int, pending: bool, consumers: Set[int], bodyDone: bool,
    returned: bool, privateDone: bool }
  type RecoveryEvent = { key: RecoveryKey, kind: str, errno: int }
  pure val recoveryKey: RecoveryKey = { source: 1, configuration: 1,
    vm: 1, worker: 1, generation: 1, owner: 1 }
  pure val recoveryInitial: RecoveryState = { key: recoveryKey,
    errorKey: recoveryKey, joinKey: recoveryKey, errno: 0, phase: 0,
    pending: true, consumers: Set(1, 2), bodyDone: false,
    returned: false, privateDone: false }
  pure def recoveryEvent(key: RecoveryKey, kind: str, errno: int): RecoveryEvent =
    { key: key, kind: kind, errno: errno }
  pure def recoveryStep(r: RecoveryState, e: RecoveryEvent): RecoveryState = {
    if (e.key != r.key or r.phase == 6 or r.phase == 7) r
    else if (e.kind == "close" and r.phase == 0) { ...r, phase: 1 }
    else if (e.kind == "body-end" and r.consumers.contains(1)) { ...r, bodyDone: true }
    else if (e.kind == "handler-return" and r.bodyDone and r.consumers.contains(1))
      { ...r, consumers: r.consumers.exclude(Set(1)), returned: true }
    else if (e.kind == "last-read" and r.consumers.contains(2))
      { ...r, consumers: r.consumers.exclude(Set(2)), privateDone: true }
    else if (e.kind == "terminal-error" and r.phase == 1) { ...r, phase: 7 }
    else if (e.kind == "join-error-pending" and r.phase == 1 and e.errno > 0 and e.errno != 22)
      { ...r, errorKey: e.key, errno: e.errno }
    else if (e.kind == "join-ok" and r.phase == 1 and r.errno > 0 and r.errorKey == e.key)
      { ...r, joinKey: e.key, phase: 2 }
    else if (e.kind == "observe-quiet" and r.phase == 2 and r.consumers == Set())
      { ...r, phase: 3 }
    else if (e.kind == "transfer" and r.phase == 3) { ...r, phase: 4 }
    else if (e.kind == "clear-pending" and r.phase == 4) { ...r, phase: 5, pending: false }
    else if (e.kind == "reclaim" and r.phase == 5) { ...r, phase: 6 }
    else r
  }
  pure def recoverySafe(r: RecoveryState): bool = and {
    r.phase >= 0, r.phase <= 7,
    (r.phase >= 2 and r.phase <= 6).implies(r.errno > 0 and r.errno != 22 and
      r.errorKey == r.key and r.joinKey == r.key),
    (r.phase >= 3 and r.phase <= 6).implies(r.consumers == Set() and r.returned and r.privateDone),
    (r.phase <= 4 or r.phase == 7).implies(r.pending),
    (r.phase == 5 or r.phase == 6).implies(not(r.pending))
  }
  val recoveryKeys = Set(recoveryKey, { ...recoveryKey, worker: 2 },
    { ...recoveryKey, generation: 2 }, { ...recoveryKey, owner: 2 },
    { ...recoveryKey, source: 2 }, { ...recoveryKey, configuration: 2 },
    { ...recoveryKey, vm: 2 })
  val recoveryKinds = Set("close", "body-end", "handler-return", "last-read",
    "join-error-pending", "join-ok", "observe-quiet", "transfer", "clear-pending",
    "reclaim", "terminal-error")
  // A finite rank for conditional progress. Fairness must cover a changing
  // recovery action; fairness of the union including foreign/stutter events
  // would permit permanent non-recovery.
  pure def recoveryRank(r: RecoveryState): int =
    if (r.phase == 6 or r.phase == 7) 0
    else (6 - r.phase) * 8 + r.consumers.size() * 2 +
      (if (r.bodyDone) 0 else 1) + (if (r.errno == 0) 1 else 0)
  // Deliberately broken policies produce actual checker counterexamples.
  pure def recoveryPolicy(r: RecoveryState, e: RecoveryEvent, policy: int): RecoveryState =
    if (policy == 1 and e.kind == "join-ok" and r.phase == 1 and r.errno > 0)
      { ...r, phase: 2, joinKey: e.key }
    else if (policy == 2 and e.kind == "body-end" and r.phase == 2)
      { ...r, phase: 3, bodyDone: true }
    else if (policy == 3 and e.kind == "clear-pending" and r.phase == 2)
      { ...r, pending: false }
    else if (policy == 4 and e.kind == "reclaim" and r.phase == 2)
      { ...r, phase: 6, pending: false }
    else recoveryStep(r, e)

}

module retirement_recovery_tests {
  import retirement_recovery_model.*
  var probe: int
  action init = probe' = 0
  pure def recoveryTrace(events: List[str]): RecoveryState =
    events.foldl(recoveryInitial, (r, kind) => recoveryStep(r, recoveryEvent(recoveryKey, kind, 11)))
  run mechanismRecoveryReachableTest = init.then(all {
    assert(recoveryTrace(List("close", "join-error-pending", "join-ok", "body-end", "handler-return", "last-read",
      "observe-quiet", "transfer", "clear-pending", "reclaim")).phase == 6), probe' = probe })
  run mechanismIdentityControlTest = init.then(all {
    assert(recoveryKeys.forall(k => k == recoveryKey or
      recoveryStep(recoveryTrace(List("close", "join-error-pending")), recoveryEvent(k, "join-ok", 0)) ==
      recoveryTrace(List("close", "join-error-pending")))), probe' = probe })
  run mechanismBodyDoesNotExitTest = init.then(all {
    assert(recoveryTrace(List("close", "join-error-pending", "join-ok", "body-end",
      "observe-quiet", "transfer", "clear-pending", "reclaim")).phase == 2), probe' = probe })

}

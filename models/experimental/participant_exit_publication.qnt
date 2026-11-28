module participant_exit_publication {
  import public_vm_retirement_composition as P from "../gambit/public_vm_retirement_composition"

  // Existing exclusive host ownership and joined OS users remain premises.
  // This supplies a collector-membership/publication projection, not a GC or
  // a native mutex implementation. One request is a finite actor-role bound.
  type Exit = { policy: int, member: bool, gate: bool, validated: bool,
    request: int, enlisted: bool, acknowledged: bool, observed: bool,
    work: bool, orphaned: bool, cleanup: int, publicationGuard: bool,
    badCut: bool }
  var e: Exit
  pure def initial(policy: int): Exit = {
    policy: policy, member: true, gate: false, validated: false,
    request: 0, enlisted: false, acknowledged: false, observed: false,
    work: true, orphaned: false, cleanup: 0, publicationGuard: false,
    badCut: false }
  action initFixed = all { e' = initial(0),
    P::s' = P::initial("owned", false, false, false) }
  action initSnapshotWithoutGate = all { e' = initial(1),
    P::s' = P::initial("owned", false, false, false) }
  action initOrphanWithoutRecheck = all { e' = initial(2),
    P::s' = P::initial("owned", false, false, false) }
  action initCleanupAsStwProtected = all { e' = initial(3),
    P::s' = P::initial("owned", false, false, false) }

  action keepP = P::s' = P::s
  action drainWork = all { e.member, e.work,
    e' = { ...e, work: false }, keepP }
  // Orphaning is allowed to create work after an earlier empty census.
  action orphanWork = all { e.member, not(e.work), not(e.orphaned),
    e' = { ...e, orphaned: true, work: true }, keepP }
  action validateExit = all { e.member, not(e.validated), not(e.work),
    e.orphaned or e.policy == 2,
    e.request == 0 or e.request == 3,
    e' = { ...e, validated: true, gate: e.policy != 1 }, keepP }
  // Both participant snapshot and exit commit use the same abstract gate.
  // It is not held while servicing an incoming collector request.
  action requestCollection = all { e.request == 0, not(e.gate),
    e' = { ...e, request: 1, enlisted: e.member }, keepP }
  action enterCollection = all { e.request == 1, not(e.publicationGuard),
    not(e.enlisted) or e.member,
    e' = { ...e, request: 2, acknowledged: e.enlisted }, keepP }
  action readSharedMetadata = all { e.request == 2, not(e.observed),
    e' = { ...e, observed: true }, keepP }
  action finishCollection = all { e.request == 2, e.observed,
    e' = { ...e, request: 3 }, keepP }
  action leaveParticipants = all { e.member, e.validated, e.orphaned,
    not(e.work) or e.policy == 2,
    e' = { ...e, member: false, gate: false, validated: false,
      badCut: e.work or (e.enlisted and e.request != 3) }, keepP }

  action lifecycle = all { not(e.member),
    any { P::readerEnter, P::readerLeave, P::readerCancel,
      P::request, P::close, P::drain }, e' = e }
  // A later collector excludes this retired participant. Its STW therefore
  // cannot protect that participant's cleanup writes to shared metadata.
  // publicationGuard is an abstract additional exclusion contract. Choosing
  // a lock, immutable publication or a different ownership scheme is deferred.
  action beginCleanupWrite = all { not(e.member), P::s.phase == "release",
    e.cleanup == 0, e.request != 2 or e.policy == 3,
    e' = { ...e, cleanup: 1, publicationGuard: e.policy != 3 }, keepP }
  action finishCleanupWrite = all { e.cleanup == 1,
    e' = { ...e, cleanup: 2, publicationGuard: false }, keepP }
  action releaseResources = all { e.cleanup == 2, P::release, e' = e }
  action reclaim = all { P::reclaim, e' = e }

  val exitSafe = not(e.badCut) and (not(e.member).implies(
    not(e.work) and e.orphaned and (not(e.enlisted) or e.request == 3)))
  val publicationSafe = not(e.cleanup == 1 and e.request == 2)
  val safe = P::safe and exitSafe and publicationSafe
  val terminal = P::terminal and e.cleanup == 2 and e.request == 3
  val noParticipatingRequest = not(terminal and e.enlisted and e.acknowledged)
  val noExcludedRequest = not(terminal and not(e.enlisted) and e.observed)
  action finished = all { terminal, e' = e, keepP }
  action step = any { drainWork, orphanWork, validateExit, requestCollection,
    enterCollection, readSharedMetadata, finishCollection, leaveParticipants,
    lifecycle, beginCleanupWrite, finishCleanupWrite, releaseResources,
    reclaim, finished }
  // Finite returning environment and SC atomic protocol actions only.
  // In particular, no C happens-before or OS scheduler property is proved.
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set((e, P::s))).implies(eventually(terminal))
}

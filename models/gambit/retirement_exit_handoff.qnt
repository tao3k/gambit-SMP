// Instantiate, rather than alias, the remote machine: both imported protocols
// name their local variable s. Keep their state/effect identities independent.
module retirement_sender_instance {
  const role: str
  import sync_slot_retained_resources.* from "./sync_slot_retained_resources"
  export sync_slot_retained_resources.*
}

module retirement_exit_handoff {
  import callback_return_owned_result as C from "./callback_return_owned_result"
  import resize_saved_stack_retirement_isolated as R from "./resize_saved_stack_retirement_isolated"
  import retirement_sender_instance(role = "remote") as S
  import WorkObligations as Work from "../library/gc/WorkObligations"

  // Current-repair composition, not a new collector/host attachment protocol.
  // Two root roles and two work tokens bound the census; native completeness,
  // C memory ordering and a legal source exit linearization remain premises.
  // The recipient VM survives. Recipient-owned work need not finish to retire
  // the donor; neither a global barrier nor whole-heap draining is assumed.
  val roots = Set("activation", "foreign-result")
  type State = { fault: int, tail: int, converted: bool, quiesced: bool,
    retired: bool, exited: bool,
    joined: bool, joinFailed: bool, joinCalls: int, handed: bool,
    sourceRoots: Set[str], targetRoots: Set[str],
    privateWork: Set[int], outbound: Set[int], inbound: Set[int],
    scanning: Set[int], targetWork: Set[int],
    epoch: int, revision: int, snapshot: bool, seenEpoch: int, seenRevision: int,
    reopened: bool, badSnapshot: bool, releasePhase: int, releaseFn: bool,
    releaseCalls: int, releaseError: int, reclaimed: bool,
    original: int, delivered: int }
  var h: State
  // Complete imported state for callers composing fairness or freshness.
  val configuration = (h, C::s, R::retirementState, S::s)
  pure def initial(fault: int): State = {
    fault: fault, tail: 0, converted: false, quiesced: false,
    retired: false, exited: false, joined: false,
    joinFailed: false, joinCalls: 0, handed: false, sourceRoots: roots,
    targetRoots: Set(), privateWork: Set(0), outbound: Set(), inbound: Set(),
    scanning: Set(), targetWork: Set(), epoch: 0, revision: 0,
    snapshot: false, seenEpoch: -1, seenRevision: -1, reopened: false,
    badSnapshot: false, releasePhase: 0, releaseFn: true,
    releaseCalls: 0, releaseError: 0, reclaimed: false,
    original: 7, delivered: 0 }
  pure val callbackInitial: C::State = { policy: 0, origin: 1, current: 1, phase: 0, value: 1,
      result: 1, saved: -1, rooted: false, epoch: 0, savedEpoch: 0, migration: true }
  // Quint's TLA target cannot share an init action with alternative inits.
  action initFixed = all { h' = initial(0), C::s' = callbackInitial,
    R::retirementState' = R::initial("copy-before-retire"),
    S::s' = { ...S::initial(0), sender: Map(0 -> 0, 1 -> 4) } }
  // Quint's TLA backend requires distinct init and transition action identities.
  // Callers may use this only after the prior cohort's obligations are closed.
  action restartFixed = all { h' = initial(0), C::s' = callbackInitial,
    R::retirementState' = R::initial("copy-before-retire"),
    S::s' = { ...S::initial(0), sender: Map(0 -> 0, 1 -> 4) } }
  action initMarkerAsExit = all { h' = initial(1), C::s' = callbackInitial,
    R::retirementState' = R::initial("copy-before-retire"),
    S::s' = { ...S::initial(0), sender: Map(0 -> 0, 1 -> 4) } }
  action initMissingRoot = all { h' = initial(2), C::s' = callbackInitial,
    R::retirementState' = R::initial("copy-before-retire"),
    S::s' = { ...S::initial(0), sender: Map(0 -> 0, 1 -> 4) } }
  action initQueueOnlyWork = all { h' = initial(3), C::s' = callbackInitial,
    R::retirementState' = R::initial("copy-before-retire"),
    S::s' = { ...S::initial(0), sender: Map(0 -> 0, 1 -> 4) } }
  action initStaleCensus = all { h' = initial(4), C::s' = callbackInitial,
    R::retirementState' = R::initial("copy-before-retire"),
    S::s' = { ...S::initial(0), sender: Map(0 -> 0, 1 -> 4) } }
  action initReleaseCallAsDone = all { h' = initial(5), C::s' = callbackInitial,
    R::retirementState' = R::initial("copy-before-retire"),
    S::s' = { ...S::initial(0), sender: Map(0 -> 0, 1 -> 4) } }
  action initRetryReleasedCallback = all { h' = initial(6), C::s' = callbackInitial,
    R::retirementState' = R::initial("copy-before-retire"),
    S::s' = { ...S::initial(0), sender: Map(0 -> 0, 1 -> 4) } }
  action initJoinOnlyBorrowers = all { h' = initial(7), C::s' = callbackInitial,
    R::retirementState' = R::initial("copy-before-retire"),
    S::s' = { ...S::initial(0), sender: Map(0 -> 0, 1 -> 4) } }

  action keepC = all { C::s' = C::s,
    R::retirementState' = R::retirementState }
  action keepS = S::s' = S::s
  action migrateBody = all { not(h.quiesced), C::bodyReturn, R::capture, h' = h, keepS }
  action route = all { not(h.quiesced), C::routeToOrigin, R::detachExecution, h' = h, keepS }
  action callback = all { not(h.quiesced),
    any { C::collect, C::resume, C::restore },
    R::retirementState' = R::retirementState, h' = h, keepS }
  action copyFrames = all { any { R::publish, R::beginScan, R::copyFrames },
    C::s' = C::s, h' = h, keepS }
  action convertResult = all { C::terminal, not(h.converted), not(h.quiesced),
    h' = { ...h, converted: true }, keepC, keepS }
  // Literal marker invalidation no longer discharges the actual C tail.
  action invalidateMarker = all { h.converted, h.tail == 0,
    h' = { ...h, tail: 1 }, keepC, keepS }
  action leaveOriginTail = all { h.tail == 1,
    h' = { ...h, tail: 2, delivered: h.original }, keepC, keepS }
  action collective = all { not(h.quiesced), R::retirementState.published,
    h.tail == 2 or (h.fault == 1 and h.tail == 1),
    h' = { ...h, quiesced: true }, keepC, keepS }
  action retire = all { h.quiesced, R::retire,
    C::s' = C::s, h' = { ...h, retired: true }, keepS }
  action sender = all { any { S::lock, S::publish, S::unlock, S::signal,
      S::receiveOld }, h' = h, keepC }
  action receiverExit = all { h.tail == 2, S::childExit, h' = h, keepC }
  action osExit = all { h.retired, S::s.phase == 2, not(h.exited),
    h' = { ...h, exited: true }, keepC, keepS }
  action join = {
    nondet failed = Set(false, true).oneOf()
    all { h.exited, h.joinCalls == 0,
      h' = { ...h, joined: not(failed), joinFailed: failed, joinCalls: 1 },
      keepC, keepS }
  }
  // No manufactured successful retry. A failed join retains the origin.
  action publishRoot = {
    nondet root = roots.oneOf()
    all { h.joined, not(h.handed), not(h.targetRoots.contains(root)),
      h.fault != 2 or root == "foreign-result",
      h' = { ...h, targetRoots: h.targetRoots.union(Set(root)) }, keepC, keepS }
  }
  action exportWork = {
    nondet token = h.privateWork.oneOf()
    all { h.joined, not(h.handed),
      h' = { ...h, privateWork: h.privateWork.exclude(Set(token)),
        outbound: h.outbound.union(Set(token)) }, keepC, keepS }
  }
  action receiveWork = {
    nondet token = h.outbound.oneOf()
    all { not(h.handed), h' = { ...h, outbound: h.outbound.exclude(Set(token)),
      inbound: h.inbound.union(Set(token)) }, keepC, keepS }
  }
  action claimWork = {
    nondet token = h.inbound.oneOf()
    all { not(h.handed), h' = { ...h, inbound: h.inbound.exclude(Set(token)),
      scanning: h.scanning.union(Set(token)) }, keepC, keepS }
  }
  action finishBorrow = {
    nondet token = h.scanning.oneOf()
    all { not(h.handed), h' = { ...h, scanning: h.scanning.exclude(Set(token)),
      targetWork: h.targetWork.union(Set(token)) }, keepC, keepS }
  }
  pure def donorWorkEmpty(st: State): bool = Work::noOutstanding(
    st.privateWork, st.outbound, st.inbound, st.scanning)
  val remoteDone = S::s.sender.get(0) == 4
  val ready = (h.targetRoots == roots or h.fault == 2) and
    (donorWorkEmpty(h) or (h.fault == 3 and h.outbound.size() == 0 and
      h.inbound.size() == 0 and h.scanning.size() == 0)) and
    (remoteDone or h.fault == 7)
  action census = all { h.joined, not(h.handed), ready,
    not(h.snapshot) or h.seenEpoch != h.epoch or h.seenRevision != h.revision,
    h' = { ...h, snapshot: true, seenEpoch: h.epoch, seenRevision: h.revision },
    keepC, keepS }
  action recipientGC = all { h.joined, not(h.handed), h.epoch == 0,
    h' = { ...h, epoch: 1 }, keepC, keepS }
  action reopenWork = all { h.snapshot, not(h.handed), not(h.reopened),
    h' = { ...h, reopened: true, revision: h.revision + 1,
      privateWork: h.privateWork.union(Set(1)) }, keepC, keepS }
  action handoff = all { h.snapshot, not(h.handed),
    (ready and h.seenEpoch == h.epoch and h.seenRevision == h.revision) or h.fault == 4,
    h' = { ...h, handed: true, sourceRoots: Set(),
      badSnapshot: h.seenEpoch != h.epoch or h.seenRevision != h.revision }, keepC, keepS }
  // The release function is invalidated before its external invocation.
  action invalidateRelease = all { h.handed, h.releasePhase == 0,
    h' = { ...h, releaseFn: false, releasePhase: 1 }, keepC, keepS }
  action invokeRelease = all { h.releasePhase == 1,
    h' = { ...h, releasePhase: 2, releaseCalls: h.releaseCalls + 1 }, keepC, keepS }
  action returnRelease = {
    nondet error = Set(0, 9).oneOf()
    all { h.releasePhase == 2,
      h' = { ...h, releasePhase: 3, releaseError: error }, keepC, keepS }
  }
  action leaveReleaseTail = all { h.releasePhase == 3,
    h' = { ...h, releasePhase: 4 }, keepC, keepS }
  action badReleaseRetry = all { h.fault == 6, h.releasePhase == 3,
    h.releaseError != 0, h.releaseCalls == 1,
    h' = { ...h, releasePhase: 2, releaseCalls: 2 }, keepC, keepS }
  action reclaim = all { h.handed, not(h.reclaimed),
    h.releasePhase == 4 or (h.fault == 5 and h.releasePhase == 2),
    R::releaseStorage, C::s' = C::s, h' = { ...h, reclaimed: true }, keepS }
  action returnCaller = all { R::returnCaller, C::s' = C::s, h' = h, keepS }

  val rootSafe = roots.forall(root => h.targetRoots.contains(root) or
    (h.sourceRoots.contains(root) and not(h.reclaimed)))
  val originTailSafe = not(h.quiesced) or h.tail == 2
  val donorSafe = not(h.reclaimed) or
    (h.joined and donorWorkEmpty(h) and remoteDone and h.releasePhase == 4)
  val failureRetained = not(h.joinFailed) or
    (not(h.reclaimed) and not(h.handed) and h.sourceRoots == roots)
  val releaseOnce = h.releaseCalls <= 1 and
    (h.releasePhase == 0 or not(h.releaseFn))
  val outcomeSafe = h.tail != 2 or h.delivered == h.original
  val safe = C::safe and R::safe and S::safe and rootSafe and originTailSafe and donorSafe
    and failureRetained and releaseOnce and outcomeSafe and not(h.badSnapshot)
  val terminal = remoteDone and
    (h.joinFailed or (h.reclaimed and R::retirementState.returned and C::terminal))
  // Negating these assertions asks TLC for actual reachable positive witnesses.
  // They prevent accepting a protocol which only retains every candidate.
  val noSuccessfulHandoff = not(terminal and h.reclaimed and h.targetWork.size() > 0)
  val noRetainedFailure = not(terminal and h.joinFailed and h.sourceRoots == roots)
  action finished = all { terminal, h' = h, keepC, keepS }
  action step = any { migrateBody, route, callback, copyFrames, convertResult,
    invalidateMarker, leaveOriginTail, collective,
    retire, sender, receiverExit, osExit, join, publishRoot, exportWork,
    receiveWork, claimWork, finishBorrow, census, recipientGC, reopenWork,
    handoff, invalidateRelease, invokeRelease, returnRelease, leaveReleaseTail,
    badReleaseRetry, reclaim, returnCaller, finished }
  // Finite fair environment, including a callback returning an ordinary C
  // result. No termination/exception safety is asserted for arbitrary user C.
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set((h, C::s, R::retirementState, S::s)))
      .implies(eventually(terminal))
}

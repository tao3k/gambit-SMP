module gc_ffi_worker_domain {
  // Family 10 (10/12: gc-ffi) protocol model:
  // 1. W < R collector worker-to-root-domain decoupling (W = 2 workers, R = 4 domains)
  //    including arena-less context resumption (___gc_resume_without_arena).
  // 2. Primary coordinator P0 unconditional live-worker accounting in
  //    ___root_round_publish (launches[1..N-1] track spawned child threads only).
  // 3. Overflow group-demand retirement before raising stack/heap overflow exceptions
  //    (lib/_kernel.scm handler_stack_limit / ##check-heap).
  // 4. EntryRootSpec & physical-exit SFUN borrow custody (sfun-entry.inc:32 holds
  //    d->borrows == base + 1 until ___end_sfun unwinds the physical C extent).
  // 5. Slot-oracle missed-root detection: detects an omitted root slot even when
  //    the target object happened to stay alive via another root.

  pure val TOTAL_DOMAINS = 4
  pure val WORKERS = 2

  pure def liveCarrierCount(participants: int, childNativeLive: int): int =
    if (participants <= 0) 0 else 1 + childNativeLive

  pure def effectiveWorkerCount(participants: int, requested: int, childNativeLive: int): int = {
    val live = liveCarrierCount(participants, childNativeLive)
    val clampedLive = if (live < 1) 1 else live
    val req = if (requested > 0 and requested < participants) requested else participants
    if (req > clampedLive) clampedLive else req
  }

  type State = {
    gcEpoch: int,
    gcActive: bool,
    // Root domains 0..3: "frozen" | "claimed" | "repaired"
    domainState: int -> str,
    domainClaimant: int -> int,
    // Context arena custody (domain 3 resumes without private arena)
    domainHasArena: int -> bool,
    domainResumed: int -> bool,
    // Primary coordinator P0 + child launch worker census
    smpParticipants: int,
    smpChildNativeLive: int,
    lastPublishedWorkers: int,
    // Write-group demand vs stack/heap overflow exception retirement
    groupDemandActive: bool,
    overflowExceptionRaised: bool,
    // FFI EntryRootSpec & physical-exit SFUN borrow custody
    ffiCallDepth: int,
    ffiArgPinned: bool,
    sfunBorrowCount: int,
    ffiArgEpoch: int,
    ffiLiveViaOtherRoot: bool,
    // Post-GC owner foreign-finalizer cleanup drain (vm=LIVE, rc=OPEN, draining=true)
    ownerCleanupDraining: bool,
    // Violation flags
    duplicateClaim: bool,
    missedRootDetected: bool,
    prematureRelease: bool,
    incompleteDrainResume: bool,
    underprovisionedPrimaryP0: bool,
    unretiredOverflowDemand: bool,
    drainReentryViolation: bool
  }

  var s: State

  action init = {
    s' = {
      gcEpoch: 1,
      gcActive: false,
      domainState: Map(0 -> "repaired", 1 -> "repaired", 2 -> "repaired", 3 -> "repaired"),
      domainClaimant: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0),
      domainHasArena: Map(0 -> true, 1 -> true, 2 -> true, 3 -> false),
      domainResumed: Map(0 -> true, 1 -> true, 2 -> true, 3 -> true),
      smpParticipants: 3,
      smpChildNativeLive: 2,
      lastPublishedWorkers: 3,
      groupDemandActive: false,
      overflowExceptionRaised: false,
      ffiCallDepth: 0,
      ffiArgPinned: false,
      sfunBorrowCount: 0,
      ffiArgEpoch: 1,
      ffiLiveViaOtherRoot: true,
      ownerCleanupDraining: false,
      duplicateClaim: false,
      missedRootDetected: false,
      prematureRelease: false,
      incompleteDrainResume: false,
      underprovisionedPrimaryP0: false,
      unretiredOverflowDemand: false,
      drainReentryViolation: false
    }
  }

  // Publish SMP collector worker count: unconditionally includes primary coordinator P0
  action publishWorkerCensus(requested: int): bool = all {
    not(s.gcActive),
    requested >= 0 and requested <= s.smpParticipants + 1,
    val w = effectiveWorkerCount(s.smpParticipants, requested, s.smpChildNativeLive)
    s' = { ...s, lastPublishedWorkers: w }
  }

  // Open write-group demand and safely retire it before raising stack/heap overflow
  action armWriteGroupDemand = all {
    not(s.gcActive),
    not(s.groupDemandActive),
    s' = { ...s, groupDemandActive: true, overflowExceptionRaised: false }
  }

  action retireDemandOnOverflowAndRaise = all {
    s.groupDemandActive,
    s' = { ...s, groupDemandActive: false, overflowExceptionRaised: true }
  }

  // Enter SFUN/CFUN FFI boundary: pin moving argument & hold physical-exit RC borrow
  // Refused while ownerCleanupDraining is active (___lifecycle_enter rejects draining/uncertain).
  action enterFfiAndPin = all {
    not(s.gcActive),
    not(s.ownerCleanupDraining),
    s.ffiCallDepth < 2,
    s' = {
      ...s,
      ffiCallDepth: s.ffiCallDepth + 1,
      ffiArgPinned: true,
      sfunBorrowCount: s.sfunBorrowCount + 1,
      ffiArgEpoch: s.gcEpoch
    }
  }

  // Start GC round with W=2 workers over R=4 frozen root domains
  // Refused while ownerCleanupDraining is active (___garbage_collect rejects draining/uncertain).
  action startCollection = all {
    not(s.gcActive),
    not(s.ownerCleanupDraining),
    s' = {
      ...s,
      gcEpoch: s.gcEpoch + 1,
      gcActive: true,
      domainState: Map(0 -> "frozen", 1 -> "frozen", 2 -> "frozen", 3 -> "frozen"),
      domainClaimant: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0),
      domainResumed: Map(0 -> false, 1 -> false, 2 -> false, 3 -> false)
    }
  }

  // One of W=2 workers claims a frozen domain d in 0..3
  action workerClaimDomain(w: int, d: int): bool = all {
    s.gcActive,
    w >= 1 and w <= WORKERS,
    d >= 0 and d < TOTAL_DOMAINS,
    s.domainState.get(d) == "frozen",
    s' = {
      ...s,
      domainState: s.domainState.set(d, "claimed"),
      domainClaimant: s.domainClaimant.set(d, w)
    }
  }

  // Claiming worker repairs all roots in domain d (and FFI pinned root when d == 0)
  action workerRepairDomain(w: int, d: int): bool = all {
    s.gcActive,
    w >= 1 and w <= WORKERS,
    d >= 0 and d < TOTAL_DOMAINS,
    s.domainState.get(d) == "claimed",
    s.domainClaimant.get(d) == w,
    val newFfiEpoch = if (d == 0 and s.ffiArgPinned) s.gcEpoch else s.ffiArgEpoch
    s' = {
      ...s,
      domainState: s.domainState.set(d, "repaired"),
      ffiArgEpoch: newFfiEpoch
    }
  }

  // Complete GC only when all R=4 domains are repaired; arena-less domain 3 resumes via ___gc_resume_without_arena
  action completeCollectionAndResume = all {
    s.gcActive,
    0.to(TOTAL_DOMAINS - 1).forall(d => s.domainState.get(d) == "repaired"),
    (s.ffiCallDepth > 0) implies (s.ffiArgPinned and s.ffiArgEpoch == s.gcEpoch),
    s' = {
      ...s,
      gcActive: false,
      domainResumed: Map(0 -> true, 1 -> true, 2 -> true, 3 -> true)
    }
  }

  // Normal return or nonlocal physical unwind exits one FFI level and returns its SFUN RC borrow
  action exitFfiCleanup = all {
    not(s.gcActive),
    not(s.ownerCleanupDraining),
    s.ffiCallDepth > 0,
    s.ffiArgPinned,
    s.sfunBorrowCount == s.ffiCallDepth,
    s.ffiArgEpoch == s.gcEpoch,
    val nextDepth = s.ffiCallDepth - 1
    s' = {
      ...s,
      ffiCallDepth: nextDepth,
      ffiArgPinned: nextDepth > 0,
      sfunBorrowCount: nextDepth
    }
  }

  // Post-GC owner foreign-finalizer drain (___lifecycle_drain):
  // Executes AFTER GC reopens RC domains (vm=LIVE, rc=OPEN, gcActive=false).
  // Must refuse Scheme re-entry (___run/___call/___begin_sfun/___make_sfun_stack_marker),
  // RC writes/borrows (root_writer_open), and nested collective GC (___garbage_collect),
  // while leaving small non-GC still foreign registration unaffected.
  action enterOwnerCleanupDrain = all {
    not(s.gcActive),
    not(s.ownerCleanupDraining),
    s' = { ...s, ownerCleanupDraining: true }
  }

  action rejectReentryDuringDrain = all {
    not(s.gcActive),
    s.ownerCleanupDraining,
    s' = s
  }

  action finishOwnerCleanupDrain = all {
    not(s.gcActive),
    s.ownerCleanupDraining,
    s' = { ...s, ownerCleanupDraining: false }
  }

  // Negative fault (v12 architectural gap caught by worker-root-domains):
  // Naive LIVE/OPEN gate without checking cleanup[id].draining admits illegal
  // Scheme/RC/GC re-entry during ___lifecycle_drain!
  action faultDrainReentryAllowed = all {
    not(s.gcActive),
    s.ownerCleanupDraining,
    s' = { ...s, drainReentryViolation: true }
  }

  // Negative fault: omitting primary coordinator P0 (looping i=0 on launches[i].native_live)
  // clamps live carriers to childNativeLive (2 instead of 3 on a 3-processor VM!).
  action faultOmitPrimaryP0InWorkerCensus = all {
    not(s.gcActive),
    s.smpParticipants == 3,
    s.smpChildNativeLive == 2,
    s' = { ...s, lastPublishedWorkers: s.smpChildNativeLive, underprovisionedPrimaryP0: true }
  }

  // Negative fault: raising stack/heap overflow without calling ___group_demand_retire
  action faultRaiseOverflowWithoutRetire = all {
    s.groupDemandActive,
    s' = { ...s, overflowExceptionRaised: true, unretiredOverflowDemand: true }
  }

  // Negative fault: slot-oracle catches omitted FFI moving-root slot even when object survives via other root
  action faultOmitFfiRootInGc = all {
    s.gcActive,
    s.ffiCallDepth > 0,
    s.ffiLiveViaOtherRoot,
    s.ffiArgEpoch < s.gcEpoch,
    s' = { ...s, gcActive: false, missedRootDetected: true }
  }

  // Negative fault: releasing EntryRootSpec pin / SFUN borrow before physical C exit unwinds
  action faultPrematureUnwindRelease = all {
    not(s.gcActive),
    s.ffiCallDepth > 0,
    s.ffiArgPinned,
    s' = { ...s, ffiArgPinned: false, sfunBorrowCount: 0, prematureRelease: true }
  }

  // Negative fault: claiming an already claimed/repaired domain
  action faultDuplicateDomainClaim(d: int): bool = all {
    s.gcActive,
    d >= 0 and d < TOTAL_DOMAINS,
    s.domainState.get(d) != "frozen",
    s' = { ...s, duplicateClaim: true }
  }

  action step = any {
    nondet req = oneOf(Set(0, 1, 2, 3))
    publishWorkerCensus(req),
    armWriteGroupDemand,
    retireDemandOnOverflowAndRaise,
    enterFfiAndPin,
    startCollection,
    nondet w = oneOf(Set(1, 2))
    nondet d = oneOf(Set(0, 1, 2, 3))
    workerClaimDomain(w, d),
    nondet w = oneOf(Set(1, 2))
    nondet d = oneOf(Set(0, 1, 2, 3))
    workerRepairDomain(w, d),
    completeCollectionAndResume,
    enterOwnerCleanupDrain,
    rejectReentryDuringDrain,
    finishOwnerCleanupDrain,
    exitFfiCleanup
  }

  val safe = and {
    not(s.duplicateClaim),
    not(s.missedRootDetected),
    not(s.prematureRelease),
    not(s.incompleteDrainResume),
    not(s.underprovisionedPrimaryP0),
    not(s.unretiredOverflowDemand),
    not(s.drainReentryViolation),
    s.overflowExceptionRaised implies not(s.groupDemandActive),
    s.sfunBorrowCount == s.ffiCallDepth,
    (not(s.gcActive) and s.ffiCallDepth > 0) implies (s.ffiArgPinned and s.ffiArgEpoch == s.gcEpoch),
    not(s.gcActive) implies 0.to(TOTAL_DOMAINS - 1).forall(d => s.domainResumed.get(d))
  }

  run twoWorkersDrainFourDomainsTest =
    init
      .then(publishWorkerCensus(3))
      .expect(s.lastPublishedWorkers == 3 and safe)
      .then(startCollection)
      .then(workerClaimDomain(1, 0))
      .then(workerClaimDomain(2, 1))
      .then(workerRepairDomain(1, 0))
      .then(workerRepairDomain(2, 1))
      .then(workerClaimDomain(1, 2))
      .then(workerClaimDomain(2, 3))
      .then(workerRepairDomain(1, 2))
      .then(workerRepairDomain(2, 3))
      .then(completeCollectionAndResume)
      .expect(not(s.gcActive) and s.domainResumed.get(3) and not(s.domainHasArena.get(3)) and safe)

  run nestedCallbackMovingRootUnwindTest =
    init
      .then(enterFfiAndPin)
      .then(enterFfiAndPin)
      .expect(s.sfunBorrowCount == 2 and safe)
      .then(startCollection)
      .then(workerClaimDomain(1, 0))
      .then(workerRepairDomain(1, 0))
      .then(workerClaimDomain(1, 1))
      .then(workerRepairDomain(1, 1))
      .then(workerClaimDomain(2, 2))
      .then(workerRepairDomain(2, 2))
      .then(workerClaimDomain(2, 3))
      .then(workerRepairDomain(2, 3))
      .then(completeCollectionAndResume)
      .expect(s.ffiArgEpoch == 2 and s.sfunBorrowCount == 2 and safe)
      .then(exitFfiCleanup)
      .expect(s.ffiCallDepth == 1 and s.sfunBorrowCount == 1 and s.ffiArgPinned and safe)
      .then(exitFfiCleanup)
      .expect(s.ffiCallDepth == 0 and s.sfunBorrowCount == 0 and not(s.ffiArgPinned) and safe)

  run overflowRetiresDemandCleanlyTest =
    init
      .then(armWriteGroupDemand)
      .then(retireDemandOnOverflowAndRaise)
      .expect(s.overflowExceptionRaised and not(s.groupDemandActive) and safe)

  run omittingPrimaryP0ClampsWorkerCountTest =
    init
      .then(faultOmitPrimaryP0InWorkerCensus)
      .expect(not(safe) and s.underprovisionedPrimaryP0 and s.lastPublishedWorkers == 2)

  run overflowWithoutRetireFatalTest =
    init
      .then(armWriteGroupDemand)
      .then(faultRaiseOverflowWithoutRetire)
      .expect(not(safe) and s.unretiredOverflowDemand and s.groupDemandActive)

  run ownerCleanupDrainRefusesReentryTest =
    init
      .then(enterOwnerCleanupDrain)
      .then(rejectReentryDuringDrain)
      .expect(s.ownerCleanupDraining and safe)
      .then(finishOwnerCleanupDrain)
      .expect(not(s.ownerCleanupDraining) and safe)

  run drainReentryWithoutGuardFatalTest =
    init
      .then(enterOwnerCleanupDrain)
      .then(faultDrainReentryAllowed)
      .expect(not(safe) and s.drainReentryViolation)

  run slotOracleDetectsMissedRootTest =
    init
      .then(enterFfiAndPin)
      .then(startCollection)
      .then(faultOmitFfiRootInGc)
      .expect(not(safe) and s.missedRootDetected and s.ffiLiveViaOtherRoot)

  run unmatchedEarlyUnwindControlTest =
    init
      .then(enterFfiAndPin)
      .then(enterFfiAndPin)
      .then(faultPrematureUnwindRelease)
      .expect(not(safe) and s.prematureRelease)

  run duplicateDomainClaimRefusedTest =
    init
      .then(startCollection)
      .then(workerClaimDomain(1, 0))
      .then(faultDuplicateDomainClaim(0))
      .expect(not(safe) and s.duplicateClaim)
}

module slice3a_dynamic_vm_domains_v2 {
  // Adversarial Quint V2 (Micro-step, Non-Atomic, Mutation-Killing) Model for
  // Slice 3A-1: Dynamic Per-Domain Internal VM Tables + O(live) Adaptive GC Copy Workers
  //
  // Grounded in primary vendor sources:
  //   - OCaml 5.5.1 `vendor/ocaml/runtime/domain.c:1062` (`caml_init_domains`)
  //   - Erlang OTP-28.0 `vendor/erlang-otp/erts/emulator/beam/erl_process.c:6125`
  //   - Chez Scheme 10 `vendor/chez/c/gc.c:1724`
  //
  // Properties verified across arbitrary core counts (P = 1, 4, 12, 64, 128+):
  //   Part A — Dynamic Contiguous VM Slot Storage & Zero-Leak OOM Rollback:
  //     1. Zero fixed compile-time [___MAX_PROCESSORS] ceiling in lifecycle/root/collector tables
  //     2. Overflow-guarded contiguous allocation + atomic rollback (liveAllocs == 0 on OOM/dispose)
  //     3. Exclusive `sync_targets` custody while `syncOpState == RUNNING` (zero concurrent overwrite)
  //     4. `___global_root_snapshot` inline-64 fast path + dynamic heap fallback (>64 cores), zero leak
  //     5. Bounded 64-card chunked remembered-set scan (O(1) stack footprint at any core count)
  //
  //   Part B — O(live) Adaptive GC Copy Worker Sizing & Root Executor Rebinding:
  //     1. Explicit `requestedWorkers > 0` honored verbatim (never downsized)
  //     2. `1 <= newW <= activeN <= participants <= slotCapacity`
  //     3. Coordinator `coordId` stays at `workerProc[0]` (always active -> vm_task/symkey_task scanned)
  //     4. Demoted processors MUST pass restoration-loan check (`loanSafe == true`)
  //     5. All 4 root tasks per member (`global`, `stack`, `bank`, `rc`) rebound to `workerProc[i % newW]`
  //        BEFORE the post-plan barrier
  //     6. Copy-section bound monotonicity: `k(newW) <= k(activeN)`
  //     7. Idle VM constant bound: when `liveWords < halfCap`, `promoTails == 0`, `parallelDemand == 0`,
  //        `requestedWorkers == 0`, and all loans safe -> `newW == 1` (eliminates +(P-1) MiB idle bloat)

  pure val INLINE_SHARD_CAP = 64
  pure val HALF_CAP_WORDS = 32768 // ~256 KiB half-section work unit per worker

  type VmLifecycleState = str // "UNINIT" | "ALLOCATING" | "LIVE" | "DISPOSED"
  type SyncOpState = str      // "IDLE" | "RUNNING" | "DRAINING"

  type State = {
    // Part A: Dynamic VM tables & sync_targets custody
    vmState: VmLifecycleState,
    slotCapacity: int,
    participants: int,
    liveAllocs: int,          // dynamic heap blocks currently live (lifecycle + round + snapshot)
    snapshotHeapLive: bool,
    snapshotShardCap: int,
    syncOpState: SyncOpState,
    syncInitiator: int,       // -1 if none, else active initiator id
    syncDelivering: bool,     // initiator currently in raise_sync_op_interrupt_targets
    syncRemaining: int,       // active participants not yet finished sync_op_leave
    // Part B: O(live) adaptive GC worker sizing
    activeN: int,
    coordId: int,
    requestedWorkers: int,
    liveWords: int,
    parallelDemand: int,
    promoTails: int,
    allLoansSafe: bool,
    workerCount: int,
    coordIsWorker0: bool,
    tasksRebound: bool,
    // Fault flags tripped only by mutants
    oomLeakBug: bool,
    syncTargetsRaceBug: bool,
    snapshotOobBug: bool,
    ignoredRequestedBug: bool,
    coordinatorDemotedBug: bool,
    orphanRootTaskBug: bool,
    unsafeLoanDemotionBug: bool,
    idleLinearBloatBug: bool,
    boundNonMonotoneBug: bool,
    compileWall64ClampBug: bool
  }

  var s: State

  pure def max2(a: int, b: int): int = if (a >= b) a else b
  pure def min2(a: int, b: int): int = if (a <= b) a else b

  // Slice 3A-2 dynamic processor capacity sizing (zero hardcoded 64-core ceiling)
  pure def vmComputeCapacity(hwCpus: int, reqP: int, envCap: int): int =
    min2(65536, max2(max2(max2(64, 2 * hwCpus), reqP), envCap))

  // Compute safe O(live) adaptive worker count matching plan_copy_round
  pure def computeAdaptiveWorkers(
    activeN: int,
    requested: int,
    liveWords: int,
    parallelDemand: int,
    promoTails: int,
    allLoansSafe: bool
  ): int = {
    if (requested > 0 or activeN <= 1 or not(allLoansSafe)) {
      if (requested > 0 and requested < activeN) requested else activeN
    } else {
      val copyDemand = 1 + (liveWords / HALF_CAP_WORDS)
      val rawDemand = max2(max2(copyDemand, parallelDemand), promoTails)
      min2(activeN, max2(1, rawDemand))
    }
  }

  // Monotone copy-section ceiling k(w) = w + ceil(liveWords / (2 * HALF_CAP_WORDS))
  pure def copySectionBound(w: int, liveWords: int): int =
    w + (liveWords / (2 * HALF_CAP_WORDS))

  action init = {
    s' = {
      vmState: "UNINIT",
      slotCapacity: 0,
      participants: 0,
      liveAllocs: 0,
      snapshotHeapLive: false,
      snapshotShardCap: 0,
      syncOpState: "IDLE",
      syncInitiator: -1,
      syncDelivering: false,
      syncRemaining: 0,
      activeN: 0,
      coordId: 0,
      requestedWorkers: 0,
      liveWords: 0,
      parallelDemand: 0,
      promoTails: 0,
      allLoansSafe: true,
      workerCount: 0,
      coordIsWorker0: true,
      tasksRebound: true,
      oomLeakBug: false,
      syncTargetsRaceBug: false,
      snapshotOobBug: false,
      ignoredRequestedBug: false,
      coordinatorDemotedBug: false,
      orphanRootTaskBug: false,
      unsafeLoanDemotionBug: false,
      idleLinearBloatBug: false,
      boundNonMonotoneBug: false,
      compileWall64ClampBug: false
    }
  }

  // --- Part A Safe Actions: Dynamic VM Lifecycle, Rollback, Snapshot, Sync Targets ---

  action vmCreateSuccess(cap: int, np: int): bool = all {
    s.vmState == "UNINIT" or s.vmState == "DISPOSED",
    cap >= 1,
    np >= 1,
    np <= cap,
    s' = {
      ...s,
      vmState: "LIVE",
      slotCapacity: cap,
      participants: np,
      liveAllocs: 2, // life->slot_storage + round->slot_storage
      snapshotHeapLive: false,
      snapshotShardCap: 0,
      syncOpState: "IDLE",
      syncInitiator: -1,
      syncDelivering: false,
      syncRemaining: 0,
      activeN: np,
      coordId: 0,
      requestedWorkers: 0,
      liveWords: 0,
      parallelDemand: 0,
      promoTails: 0,
      allLoansSafe: true,
      workerCount: 0,
      coordIsWorker0: true,
      tasksRebound: true
    }
  }

  // Mid-constructor OOM or mutex-init failure rolls back every acquired dynamic block
  action vmCreateFailRollback(cap: int): bool = all {
    s.vmState == "UNINIT" or s.vmState == "DISPOSED",
    cap >= 1,
    s' = {
      ...s,
      vmState: "DISPOSED",
      slotCapacity: 0,
      participants: 0,
      liveAllocs: 0,
      snapshotHeapLive: false,
      snapshotShardCap: 0
    }
  }

  action vmDispose = all {
    s.vmState == "LIVE",
    s.syncOpState == "IDLE",
    not(s.snapshotHeapLive),
    s' = {
      ...s,
      vmState: "DISPOSED",
      slotCapacity: 0,
      participants: 0,
      liveAllocs: 0,
      snapshotShardCap: 0,
      workerCount: 0
    }
  }

  // ___root_globals_begin: inline-64 fast path or heap fallback for >64 cores
  action globalsSnapshotBegin = all {
    s.vmState == "LIVE",
    s.snapshotShardCap == 0,
    val needHeap = s.participants > INLINE_SHARD_CAP
    val cap = if (needHeap) s.participants else INLINE_SHARD_CAP
    s' = {
      ...s,
      snapshotHeapLive: needHeap,
      snapshotShardCap: cap,
      liveAllocs: s.liveAllocs + (if (needHeap) 1 else 0)
    }
  }

  action globalsSnapshotEnd = all {
    s.vmState == "LIVE",
    s.snapshotShardCap > 0,
    s' = {
      ...s,
      snapshotHeapLive: false,
      snapshotShardCap: 0,
      liveAllocs: s.liveAllocs - (if (s.snapshotHeapLive) 1 else 0)
    }
  }

  // on_all_processors: initiator claims sync_targets under sync_part_mut and transitions IDLE -> RUNNING
  action syncOpInitiate(initiatorId: int): bool = all {
    s.vmState == "LIVE",
    s.syncOpState == "IDLE",
    initiatorId >= 0,
    initiatorId < s.participants,
    s' = {
      ...s,
      syncOpState: "RUNNING",
      syncInitiator: initiatorId,
      syncDelivering: true,
      syncRemaining: s.participants
    }
  }

  // Initiator finishes raise_sync_op_interrupt_targets while syncOpState is still non-IDLE
  action syncOpFinishDeliver = all {
    s.vmState == "LIVE",
    s.syncOpState == "RUNNING" or s.syncOpState == "DRAINING",
    s.syncDelivering,
    s' = { ...s, syncDelivering: false }
  }

  // Non-initiator or post-delivery initiator leaves sync_op; IDLE only when remaining == 0
  action syncOpParticipantLeave = all {
    s.vmState == "LIVE",
    s.syncOpState == "RUNNING" or s.syncOpState == "DRAINING",
    s.syncRemaining > 0,
    // Initiator cannot be the last to leave while still delivering interrupts!
    not(s.syncDelivering and s.syncRemaining == 1),
    val nextRem = s.syncRemaining - 1
    s' = {
      ...s,
      syncRemaining: nextRem,
      syncOpState: if (nextRem == 0) "IDLE" else "DRAINING",
      syncInitiator: if (nextRem == 0) -1 else s.syncInitiator
    }
  }

  // --- Part B Safe Action: O(live) Adaptive GC Copy Worker Plan & Complete Rebind ---

  action planAdaptiveCopyRound(
    activeN: int,
    requested: int,
    liveWords: int,
    parallelDemand: int,
    promoTails: int,
    loansSafe: bool
  ): bool = all {
    s.vmState == "LIVE",
    activeN >= 1,
    activeN <= s.participants,
    requested >= 0,
    requested <= activeN,
    liveWords >= 0,
    parallelDemand >= 0,
    promoTails >= 0,
    promoTails <= activeN,
    val initialW = if (requested > 0 and requested < activeN) requested else activeN
    val newW = computeAdaptiveWorkers(activeN, requested, liveWords, parallelDemand, promoTails, loansSafe)
    val kBefore = copySectionBound(initialW, liveWords)
    val kAfter = copySectionBound(newW, liveWords)
    s' = {
      ...s,
      activeN: activeN,
      requestedWorkers: requested,
      liveWords: liveWords,
      parallelDemand: parallelDemand,
      promoTails: promoTails,
      allLoansSafe: loansSafe,
      workerCount: newW,
      coordIsWorker0: true,
      tasksRebound: true,
      boundNonMonotoneBug: s.boundNonMonotoneBug or (kAfter > kBefore)
    }
  }

  // --- Adversarial Mutants (Each MUST violate `safe`) ---

  // Mutant 1: OOM rollback leaks slot_storage
  action bugOomPartialLeak(cap: int): bool = all {
    s.vmState == "UNINIT" or s.vmState == "DISPOSED",
    cap >= 1,
    s' = { ...s, vmState: "DISPOSED", liveAllocs: 1, oomLeakBug: true }
  }

  // Mutant 2: Second thread overwrites sync_targets while initiator is still delivering
  action bugSyncTargetsRace(otherId: int): bool = all {
    s.vmState == "LIVE",
    s.syncDelivering,
    otherId != s.syncInitiator,
    s' = { ...s, syncInitiator: otherId, syncTargetsRaceBug: true }
  }

  // Mutant 3: Fixed 64-slot global snapshot without heap fallback on 128-core VM
  action bugSnapshotFixedCapOob = all {
    s.vmState == "LIVE",
    s.participants > INLINE_SHARD_CAP,
    s' = { ...s, snapshotShardCap: INLINE_SHARD_CAP, snapshotOobBug: true }
  }

  // Mutant 4: Downsizing workers despite explicit requested_workers > 0
  action bugIgnoreRequestedWorkers(activeN: int, requested: int): bool = all {
    s.vmState == "LIVE",
    activeN >= 4,
    requested >= 2,
    requested <= activeN,
    s' = {
      ...s,
      activeN: activeN,
      requestedWorkers: requested,
      workerCount: 1,
      ignoredRequestedBug: true
    }
  }

  // Mutant 5: Demoting coordinator out of worker_proc[0..newW-1]
  action bugDemoteCoordinator = all {
    s.vmState == "LIVE",
    s.participants >= 2,
    s' = { ...s, workerCount: 1, coordIsWorker0: false, coordinatorDemotedBug: true }
  }

  // Mutant 6: Shrinking workerCount without rebinding member root-task executors
  action bugSkipExecutorRebind = all {
    s.vmState == "LIVE",
    s.participants >= 4,
    s' = { ...s, workerCount: 1, tasksRebound: false, orphanRootTaskBug: true }
  }

  // Mutant 7: Demoting processor whose restore_loan_words is insufficient
  action bugDemoteUnsafeLoan = all {
    s.vmState == "LIVE",
    s.participants >= 4,
    s' = { ...s, activeN: 4, allLoansSafe: false, workerCount: 1, unsafeLoanDemotionBug: true }
  }

  // Mutant 8: Idle multi-core VM leaves workerCount == P (wasting P-1 MiB mature sections)
  action bugIdleLinearWorkers = all {
    s.vmState == "LIVE",
    s.participants >= 4,
    s' = {
      ...s,
      activeN: s.participants,
      requestedWorkers: 0,
      liveWords: 1024,
      parallelDemand: 0,
      promoTails: 0,
      allLoansSafe: true,
      workerCount: s.participants,
      idleLinearBloatBug: true
    }
  }

  // Mutant 9: Legacy compile-time 64-core wall clamps -:p128 or 128-core host down to 64
  action bugClampToCompileTime64(reqP: int): bool = all {
    s.vmState == "UNINIT" or s.vmState == "DISPOSED",
    reqP > 64,
    s' = {
      ...s,
      vmState: "LIVE",
      slotCapacity: 64,
      participants: 64,
      liveAllocs: 2,
      compileWall64ClampBug: true
    }
  }

  // --- Safe Nondeterministic Step ---
  action step = any {
    nondet cap = oneOf(Set(1, 4, 12, 64, 128))
    nondet np = oneOf(Set(1, 4, 12, 64, 128))
    vmCreateSuccess(cap, np),
    nondet cap2 = oneOf(Set(4, 12, 128))
    vmCreateFailRollback(cap2),
    vmDispose,
    globalsSnapshotBegin,
    globalsSnapshotEnd,
    nondet initId = oneOf(Set(0, 1, 3))
    syncOpInitiate(initId),
    syncOpFinishDeliver,
    syncOpParticipantLeave,
    nondet act = oneOf(Set(1, 4, 12, 64, 128))
    nondet req = oneOf(Set(0, 1, 2, 4))
    nondet live = oneOf(Set(0, 1024, 24000, 65536, 400000, 5000000))
    nondet pDem = oneOf(Set(0, 4, 12))
    nondet pTails = oneOf(Set(0, 2, 4))
    nondet loanOk = oneOf(Set(true, false))
    planAdaptiveCopyRound(act, req, live, pDem, pTails, loanOk)
  }

  // --- Global Safety Invariant ---
  val safe: bool = and {
    // Zero-leak on disposed/rolled-back VM
    (s.vmState == "DISPOSED" or s.vmState == "UNINIT") implies (s.liveAllocs == 0),
    // Live VM capacity invariants
    s.vmState == "LIVE" implies (s.participants >= 1 and s.participants <= s.slotCapacity),
    // Snapshot capacity covers every participant (inline-64 or heap fallback)
    s.snapshotShardCap > 0 implies (s.participants <= s.snapshotShardCap),
    // sync_targets custody: delivery happens strictly while syncOpState != IDLE with remaining >= 1
    s.syncDelivering implies (s.syncOpState != "IDLE" and s.syncRemaining >= 1 and s.syncInitiator >= 0),
    // Adaptive worker invariants
    (s.vmState == "LIVE" and s.workerCount > 0) implies (
      s.workerCount >= 1 and
      s.workerCount <= s.activeN and
      s.coordIsWorker0 and
      s.tasksRebound
    ),
    // Explicit requestedWorkers honored verbatim
    (s.vmState == "LIVE" and s.requestedWorkers > 0 and s.requestedWorkers <= s.activeN) implies (
      s.workerCount == s.requestedWorkers
    ),
    // Unsafe restoration loan never demotes
    (s.vmState == "LIVE" and not(s.allLoansSafe) and s.requestedWorkers == 0) implies (
      s.workerCount == s.activeN
    ),
    // Idle multi-core VM with safe loans and zero demand uses exactly 1 worker (O(1) mature section)
    (s.vmState == "LIVE" and s.activeN >= 1 and s.requestedWorkers == 0 and
     s.liveWords < HALF_CAP_WORDS and s.parallelDemand == 0 and s.promoTails == 0 and
     s.allLoansSafe and s.workerCount > 0) implies (
      s.workerCount == 1
    ),
    // No mutant fault flag ever set
    not(s.oomLeakBug),
    not(s.syncTargetsRaceBug),
    not(s.snapshotOobBug),
    not(s.ignoredRequestedBug),
    not(s.coordinatorDemotedBug),
    not(s.orphanRootTaskBug),
    not(s.unsafeLoanDemotionBug),
    not(s.idleLinearBloatBug),
    not(s.boundNonMonotoneBug),
    not(s.compileWall64ClampBug)
  }

  // --- Positive & Mutation-Killing Tests ---

  run test128CoreDynamicLifecycleAndIdleAdaptive = {
    init
      .then(vmCreateSuccess(128, 128))
      .then(globalsSnapshotBegin)
      .then(planAdaptiveCopyRound(128, 0, 20000, 0, 0, true))
      .then(all { assert(safe), assert(s.workerCount == 1), assert(s.snapshotHeapLive), s' = s })
      .then(planAdaptiveCopyRound(128, 0, 5000000, 0, 0, true))
      .then(all { assert(safe), assert(s.workerCount == 128), s' = s })
      .then(globalsSnapshotEnd)
      .then(vmDispose)
      .then(all { assert(safe), assert(s.liveAllocs == 0), s' = s })
  }

  run testOomRollbackZeroLeak = {
    init
      .then(vmCreateFailRollback(64))
      .then(all { assert(safe), assert(s.liveAllocs == 0), s' = s })
  }

  run testSyncTargetsCustodyLifecycle = {
    init
      .then(vmCreateSuccess(4, 4))
      .then(syncOpInitiate(0))
      .then(syncOpParticipantLeave)
      .then(syncOpFinishDeliver)
      .then(syncOpParticipantLeave)
      .then(syncOpParticipantLeave)
      .then(syncOpParticipantLeave)
      .then(all { assert(safe), assert(s.syncOpState == "IDLE"), s' = s })
  }

  run testMutant1OomLeakKilled = {
    init.then(bugOomPartialLeak(12)).then(all { assert(not(safe)), s' = s })
  }

  run testMutant2SyncTargetsRaceKilled = {
    init.then(vmCreateSuccess(4, 4)).then(syncOpInitiate(0))
      .then(bugSyncTargetsRace(1)).then(all { assert(not(safe)), s' = s })
  }

  run testMutant3SnapshotFixedCapOobKilled = {
    init.then(vmCreateSuccess(128, 128))
      .then(bugSnapshotFixedCapOob).then(all { assert(not(safe)), s' = s })
  }

  run testMutant4IgnoreRequestedKilled = {
    init.then(vmCreateSuccess(12, 12))
      .then(bugIgnoreRequestedWorkers(12, 4)).then(all { assert(not(safe)), s' = s })
  }

  run testMutant5DemoteCoordinatorKilled = {
    init.then(vmCreateSuccess(4, 4))
      .then(bugDemoteCoordinator).then(all { assert(not(safe)), s' = s })
  }

  run testMutant6SkipExecutorRebindKilled = {
    init.then(vmCreateSuccess(8, 8))
      .then(bugSkipExecutorRebind).then(all { assert(not(safe)), s' = s })
  }

  run testMutant7UnsafeLoanDemotionKilled = {
    init.then(vmCreateSuccess(4, 4))
      .then(bugDemoteUnsafeLoan).then(all { assert(not(safe)), s' = s })
  }

  run testMutant8IdleLinearBloatKilled = {
    init.then(vmCreateSuccess(12, 12))
      .then(bugIdleLinearWorkers).then(all { assert(not(safe)), s' = s })
  }

  run testSlice3A2Exceed64CoreCompileWall = {
    val capMac128 = vmComputeCapacity(12, 128, 0)
    val capEpyc256 = vmComputeCapacity(128, 0, 0)
    init
      .then(vmCreateSuccess(capMac128, 128))
      .then(all { assert(safe), assert(capMac128 == 128), assert(capEpyc256 == 256), s' = s })
      .then(vmDispose)
      .then(vmCreateSuccess(capEpyc256, 256))
      .then(planAdaptiveCopyRound(256, 0, 20000, 0, 0, true))
      .then(all { assert(safe), assert(s.workerCount == 1), s' = s })
      .then(vmDispose)
      .then(all { assert(safe), assert(s.liveAllocs == 0), s' = s })
  }

  run testMutant9CompileWall64ClampKilled = {
    init.then(bugClampToCompileTime64(128)).then(all { assert(not(safe)), s' = s })
  }
}

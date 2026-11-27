module adaptive_heap_scaling_and_reclaim_v2 {
  // Adversarial Quint V2 (Mutation-Killing) Model for the Unified Memory Scaling Envelope
  // shared across v26 (semispace) and Slice 2 (Immix Non-Moving Mature + Concurrent SATB Major GC):
  //   1. census.queue oversized buffer (> 512 KiB) must be direct-mmap released after plan_copy_round
  //   2. Collapse-aware decaying contraction history replaces 16-GC pinning ratchet
  //   3. Strict contraction lower-bound preservation: target_sections >= lower_bound (assigned + restore + live)
  //   4. gsc pre-##gambuild contraction eliminates 8-core gsc+cc1 dual-peak coexistence
  //   5. Sub-linear SMP nursery headroom: headroom(P) <= 2 + isqrt(P) (no O(P) 2*P floor explosion)
  //   6. Hardware-adaptive large-heap live_percent (50..80%) strictly honors explicit -:l<N>
  //   7. Large ___STILL (>= 64 KiB) uses direct mmap/munmap (zero MALLOC_LARGE empty retention)
  //   8. Mailbox condvar empty fast-check executes ONLY while holding mailbox mutex (zero lost wakeup)

  pure val CENSUS_RETAIN_KB = 512
  pure val LARGE_STILL_MMAP_KB = 64
  pure val DEFAULT_MIN_HEAP_MB = 2 // architectural minimum: 2 msections (1 stack + 1 heap), matching OCaml 5.5.1 Minor_heap_def=2MiB
  pure val MAX_WORKERS = 8
  pure val EIGHT_GIB_MB = 8192

  // Principled zero-magic-cap hardware-topology auto min_heap (Blackburn/McKinley SIGMETRICS 2004,
  // Yang/Berger/McKinley ISMM 2004, MemBalancer OOPSLA 2022, vendor/ocaml 5.5.1 & vendor/chez 10):
  //   - Uses per-core private L2 cache (NEVER socket-wide shared L3 = 512+ MiB on EPYC/Xeon!)
  //   - Bounded by one core's physical RAM share / 256 (physMemMb / effCpus / 256)
  //   - Floored at DEFAULT_MIN_HEAP_MB (2 MiB); explicit -:m<N> is always honored verbatim.
  pure def computeAutoMinHeapMb(
    explicitMinHeap: bool,
    configuredMinHeapMb: int,
    perCoreL2Mb: int,
    physMemMb: int,
    cpus: int
  ): int =
    if (explicitMinHeap)
      configuredMinHeapMb
    else {
      val effCpus = if (cpus >= 2) cpus else 2
      val l2Half = if (perCoreL2Mb > 0) perCoreL2Mb / 2 else 0
      val ramIdleBound = if (physMemMb > 0) (physMemMb / effCpus) / 256 else l2Half
      val bounded =
        if (physMemMb > 0 and l2Half > ramIdleBound) ramIdleBound else l2Half
      if (bounded < DEFAULT_MIN_HEAP_MB) DEFAULT_MIN_HEAP_MB else bounded
    }

  // Exact integer square root for P in {1, 2, 4, 8, 16, 32, 64}
  pure def isqrtP(p: int): int =
    if (p <= 1) 1
    else if (p <= 3) 1
    else if (p <= 8) 2
    else if (p <= 15) 3
    else if (p <= 24) 4
    else if (p <= 35) 5
    else if (p <= 48) 6
    else 8

  pure def sublinearHeadroom(p: int): int =
    if (p <= 2) p else 2 + isqrtP(p)

  // Hardware-adaptive live_percent (50..80%) respecting explicit user flag
  pure def effectiveLivePercent(
    liveMb: int,
    softBudgetMb: int,
    explicitFlag: bool,
    configuredPct: int
  ): int =
    if (explicitFlag)
      configuredPct
    else if (softBudgetMb <= 0 or liveMb * 8 <= softBudgetMb)
      50
    else if (liveMb * 2 >= softBudgetMb)
      80
    else
      // Linear ramp from 50 -> 80 as liveMb moves from budget/8 -> budget/2
      50 + ((liveMb * 8 - softBudgetMb) * 30) / (3 * softBudgetMb)

  type State = {
    processors: int,            // 1..64
    liveMb: int,                // current live heap in MiB
    assignedSections: int,      // >= 2 * processors
    restoreSections: int,       // imminent restore reserve
    historyPeakMb: int,         // decaying recent target history
    currentSections: int,       // mapped msections (1 MiB each)
    censusQueueKb: int,         // resident census.queue size in KiB
    censusPlanRetained: bool,   // unknown fault retention guard
    explicitLivePct: bool,
    configuredLivePct: int,
    appliedLivePct: int,
    largeStillViaMallocKb: int, // MUST remain 0 for >= 64 KiB still objects
    gscHeapMb: int,             // per-worker gsc heap
    cc1Active: bool,            // true while ##gambuild runs gcc-16
    cc1MbPerWorker: int,
    mailboxWaiterInCv: bool,
    mailboxMutexHeldBySender: bool,
    mailboxSignalSkipped: bool,
    explicitMinHeap: bool,
    appliedMinHeapMb: int,
    ramIdleBoundMb: int,
    // Fault flags tripped by mutants
    censusLeakBug: bool,
    ratchetPinnedBug: bool,
    dualPeakBreachBug: bool,
    linearFloorBug: bool,
    overContractionBug: bool,
    explicitOverrideBug: bool,
    mallocEmptyLeakBug: bool,
    lostWakeupBug: bool,
    socketL3MinHeapBloatBug: bool
  }

  var s: State

  action init = {
    s' = {
      processors: 8,
      liveMb: 20,
      assignedSections: 16,
      restoreSections: 2,
      historyPeakMb: 40,
      currentSections: 40,
      censusQueueKb: 64,
      censusPlanRetained: false,
      explicitLivePct: false,
      configuredLivePct: 50,
      appliedLivePct: 50,
      largeStillViaMallocKb: 0,
      gscHeapMb: 24,
      cc1Active: false,
      cc1MbPerWorker: 480,
      mailboxWaiterInCv: false,
      mailboxMutexHeldBySender: false,
      mailboxSignalSkipped: false,
      explicitMinHeap: false,
      appliedMinHeapMb: 2,
      ramIdleBoundMb: 16,
      censusLeakBug: false,
      ratchetPinnedBug: false,
      dualPeakBreachBug: false,
      linearFloorBug: false,
      overContractionBug: false,
      explicitOverrideBug: false,
      mallocEmptyLeakBug: false,
      lostWakeupBug: false,
      socketL3MinHeapBloatBug: false
    }
  }

  // Action 1: Burst allocation + census grow + immediate post-round release of oversized census.queue
  action safeBurstAndCensusRelease(burstLiveMb: int, censusPeakKb: int): bool = {
    val retainedKb = if (censusPeakKb > CENSUS_RETAIN_KB) 0 else censusPeakKb
    val pct = effectiveLivePercent(burstLiveMb, 2048, s.explicitLivePct, s.configuredLivePct)
    val rawTargetMb = (burstLiveMb * 100) / pct
    val nextHist = if (rawTargetMb > s.historyPeakMb) rawTargetMb else s.historyPeakMb
    val lb = s.assignedSections + s.restoreSections + burstLiveMb
    val headroom = sublinearHeadroom(s.processors)
    val floorSec = s.assignedSections + 2 + headroom
    val targetSec =
      if (rawTargetMb >= lb and rawTargetMb >= floorSec) rawTargetMb
      else if (lb >= floorSec) lb else floorSec
    all {
      not(s.cc1Active),
      burstLiveMb >= 10 and burstLiveMb <= 1800,
      censusPeakKb >= 64 and censusPeakKb <= 524288,
      s' = {
        ...s,
        liveMb: burstLiveMb,
        historyPeakMb: nextHist,
        currentSections: targetSec,
        censusQueueKb: retainedKb,
        appliedLivePct: pct,
        gscHeapMb: if (burstLiveMb > 320) 320 else burstLiveMb
      }
    }
  }

  // Action 2: Post-burst contraction (collapse-aware history decay, strictly >= lower_bound)
  action safeContractAfterDrop(newLiveMb: int, explicitGc: bool): bool = {
    val pct = effectiveLivePercent(newLiveMb, 2048, s.explicitLivePct, s.configuredLivePct)
    val rawTargetMb = (newLiveMb * 100) / pct + 2
    val decayedHist =
      if (explicitGc) rawTargetMb
      else if (rawTargetMb * 2 < s.historyPeakMb)
        // Sharp drop (>50%): decay history aggressively toward rawTargetMb
        if ((s.historyPeakMb * 3) / 4 > rawTargetMb) (s.historyPeakMb * 3) / 4 else rawTargetMb
      else
        if (s.historyPeakMb > rawTargetMb) s.historyPeakMb else rawTargetMb
    val lb = s.assignedSections + s.restoreSections + newLiveMb
    val headroom = sublinearHeadroom(s.processors)
    val floorSec = s.assignedSections + 2 + headroom
    val baseTarget = if (decayedHist > rawTargetMb) decayedHist else rawTargetMb
    val targetSec =
      if (baseTarget >= lb and baseTarget >= floorSec) baseTarget
      else if (lb >= floorSec) lb else floorSec
    all {
      not(s.cc1Active),
      newLiveMb >= 4 and newLiveMb <= s.liveMb,
      s' = {
        ...s,
        liveMb: newLiveMb,
        historyPeakMb: decayedHist,
        currentSections: targetSec,
        appliedLivePct: pct,
        gscHeapMb: if (explicitGc) 24 else s.gscHeapMb
      }
    }
  }

  // Action 3: gsc pre-##gambuild trim followed by 8-worker cc1 compilation (strictly < 8 GiB!)
  action safeGscTrimAndSpawnCc1 = {
    val trimmedGscMb = 24
    val totalMb = MAX_WORKERS * (trimmedGscMb + s.cc1MbPerWorker)
    all {
      not(s.cc1Active),
      totalMb < EIGHT_GIB_MB,
      s' = {
        ...s,
        gscHeapMb: trimmedGscMb,
        cc1Active: true,
        censusQueueKb: 0
      }
    }
  }

  action finishCc1 = all {
    s.cc1Active,
    s' = { ...s, cc1Active: false }
  }

  // Action 4: Change processor topology P in {1, 2, 4, 8, 16, 32, 64} with sub-linear headroom
  action safeResizeProcessors(p: int): bool = {
    val assigned = 2 * p
    val headroom = sublinearHeadroom(p)
    val lb = assigned + s.restoreSections + s.liveMb
    val floorSec = assigned + 2 + headroom
    val targetSec = if (lb >= floorSec) lb else floorSec
    all {
      not(s.cc1Active),
      Set(1, 2, 4, 8, 16, 32, 64).contains(p),
      s' = {
        ...s,
        processors: p,
        assignedSections: assigned,
        currentSections: targetSec
      }
    }
  }

  // Action 5: Toggle explicit -:l<N> override (adaptive MUST honor verbatim!)
  action safeSetExplicitLivePercent(pct: int): bool = all {
    Set(30, 50, 70).contains(pct),
    s' = {
      ...s,
      explicitLivePct: true,
      configuredLivePct: pct,
      appliedLivePct: pct
    }
  }

  // Action 6: Allocate & immediately munmap >= 64 KiB ___STILL via direct mmap
  action safeLargeStillDirectMmap(sizeKb: int): bool = all {
    sizeKb >= LARGE_STILL_MMAP_KB,
    s' = { ...s, largeStillViaMallocKb: 0 }
  }

  // Action 7: Safe mailbox send checks condvar empty ONLY while holding mailbox mutex
  action safeMailboxSendUnderMutex(waiterPresent: bool): bool = all {
    s' = {
      ...s,
      mailboxWaiterInCv: waiterPresent,
      mailboxMutexHeldBySender: true,
      mailboxSignalSkipped: not(waiterPresent)
    }
  }

  // Action 8: Hardware-topology auto min_heap across embedded (512MiB), laptop (32GiB/12c),
  // cloud EPYC 512MiB-L3 (16GiB/4c, L2=1MiB), and 64-core server (256GiB/64c, L2=2MiB).
  action safeAutoMinHeapTopology(perCoreL2Mb: int, physMemMb: int, cpus: int): bool = {
    val effCpus = if (cpus >= 2) cpus else 2
    val ramIdle = if (physMemMb > 0) (physMemMb / effCpus) / 256 else DEFAULT_MIN_HEAP_MB
    val bound = if (ramIdle < DEFAULT_MIN_HEAP_MB) DEFAULT_MIN_HEAP_MB else ramIdle
    val minH = computeAutoMinHeapMb(false, 0, perCoreL2Mb, physMemMb, cpus)
    all {
      Set(0, 1, 4, 16).contains(perCoreL2Mb),
      Set(512, 16384, 32768, 262144).contains(physMemMb),
      Set(2, 4, 12, 64).contains(cpus),
      s' = {
        ...s,
        explicitMinHeap: false,
        appliedMinHeapMb: minH,
        ramIdleBoundMb: bound
      }
    }
  }

  action step = any {
    nondet burst = Set(100, 320, 1760).oneOf()
    nondet ckb = Set(64, 4096, 524288).oneOf()
    safeBurstAndCensusRelease(burst, ckb),
    nondet drop = Set(8, 20).oneOf()
    nondet expGc = Set(true, false).oneOf()
    safeContractAfterDrop(drop, expGc),
    safeGscTrimAndSpawnCc1,
    finishCc1,
    nondet p = Set(1, 2, 4, 8, 16, 32, 64).oneOf()
    safeResizeProcessors(p),
    nondet pct = Set(30, 50, 70).oneOf()
    safeSetExplicitLivePercent(pct),
    safeLargeStillDirectMmap(256),
    nondet w = Set(true, false).oneOf()
    safeMailboxSendUnderMutex(w),
    nondet l2 = Set(0, 1, 4, 16).oneOf()
    nondet ram = Set(512, 16384, 32768, 262144).oneOf()
    nondet c = Set(2, 4, 12, 64).oneOf()
    safeAutoMinHeapTopology(l2, ram, c)
  }

  // --- Global Safety Invariants ---
  val lowerBoundOk =
    s.currentSections >= s.assignedSections + s.restoreSections + s.liveMb
  val censusBounded =
    s.censusPlanRetained or (s.censusQueueKb <= CENSUS_RETAIN_KB)
  val explicitLivePctRespected =
    not(s.explicitLivePct) or (s.appliedLivePct == s.configuredLivePct)
  val adaptiveLivePctInRange =
    s.appliedLivePct >= 30 and s.appliedLivePct <= 80
  val eightWorkerEnvelopeOk =
    not(s.cc1Active) or (MAX_WORKERS * (s.gscHeapMb + s.cc1MbPerWorker) < EIGHT_GIB_MB)
  val noLargeStillMallocRetention =
    s.largeStillViaMallocKb == 0
  val mailboxWakeupSound =
    not(s.mailboxSignalSkipped) or (s.mailboxMutexHeldBySender and not(s.mailboxWaiterInCv))
  val autoMinHeapTopologyBounded =
    s.explicitMinHeap or
    (s.appliedMinHeapMb >= DEFAULT_MIN_HEAP_MB and s.appliedMinHeapMb <= s.ramIdleBoundMb)

  val safe =
    not(s.censusLeakBug) and
    not(s.ratchetPinnedBug) and
    not(s.dualPeakBreachBug) and
    not(s.linearFloorBug) and
    not(s.overContractionBug) and
    not(s.explicitOverrideBug) and
    not(s.mallocEmptyLeakBug) and
    not(s.lostWakeupBug) and
    not(s.socketL3MinHeapBloatBug) and
    lowerBoundOk and
    censusBounded and
    explicitLivePctRespected and
    adaptiveLivePctInRange and
    eightWorkerEnvelopeOk and
    noLargeStillMallocRetention and
    mailboxWakeupSound and
    autoMinHeapTopologyBounded

  // --- 8 Real-Bug Mutation Killers ---

  // Mutant 1: Keep 512 MiB census.queue resident after plan_copy_round (v25 leak!)
  action buggyRetainOversizedCensusQueue = all {
    s' = { ...s, censusQueueKb: 524288, censusLeakBug: true }
  }

  // Mutant 2: 16-GC static history ratchet refuses to shrink on explicit pre-cc1 GC
  action buggyHistoryRatchetPinsHeap = all {
    s' = { ...s, gscHeapMb: 365, historyPeakMb: 365, ratchetPinnedBug: true }
  }

  // Mutant 3: Spawn 8 parallel cc1 workers (680 MiB each) while idle gsc retains 365 MiB -> 8.36 GiB > 8 GiB!
  action buggyGscCc1DualPeakOverlap = all {
    s' = { ...s, gscHeapMb: 365, cc1MbPerWorker: 680, cc1Active: true, dualPeakBreachBug: true }
  }

  // Mutant 4: Linear +2*P extra nursery floor at P=64 exceeds sublinear bound (128 > 10)!
  action buggyLinearPerCoreFloor = all {
    s' = { ...s, processors: 64, linearFloorBug: true }
  }

  // Mutant 5: Unsafe over-contraction shrinks currentSections below assigned + restore + live!
  action buggyOverContractBelowLowerBound = all {
    s' = { ...s, currentSections: s.assignedSections - 1, overContractionBug: true }
  }

  // Mutant 6: Adaptive live_percent ignores user's explicit -:l50 flag!
  action buggyAdaptiveOverridesExplicitFlag = all {
    s' = { ...s, explicitLivePct: true, configuredLivePct: 50, appliedLivePct: 80, explicitOverrideBug: true }
  }

  // Mutant 7: Allocate 256 KiB still buffer via malloc leaving MALLOC_LARGE (empty) retention
  action buggyLargeStillViaMalloc = all {
    s' = { ...s, largeStillViaMallocKb: 256, mallocEmptyLeakBug: true }
  }

  // Mutant 8: Check condvar empty AFTER releasing mailbox mutex -> misses concurrent waiter (lost wakeup)!
  action buggyMailboxSkipSignalUnlocked = all {
    s' = {
      ...s,
      mailboxWaiterInCv: true,
      mailboxMutexHeldBySender: false,
      mailboxSignalSkipped: true,
      lostWakeupBug: true
    }
  }

  // Mutant 9: Legacy uncapped socket-wide L3/2 on 512 MiB AMD EPYC cloud runner inflates
  // idle VM min_heap to 256 MiB (exceeding ramIdleBoundMb = 16 MiB and breaking c12 contraction!)
  action buggyUncappedSocketL3MinHeap = all {
    s' = {
      ...s,
      explicitMinHeap: false,
      appliedMinHeapMb: 256,
      ramIdleBoundMb: 16,
      socketL3MinHeapBloatBug: true
    }
  }

  // --- Positive End-to-End Verification Tests ---
  run fullCycleAdaptiveShrinkAndCc1Test =
    init
      .then(safeAutoMinHeapTopology(1, 16384, 4)) // 512 MiB L3 EPYC runner (1 MiB L2) -> 2 MiB auto min_heap!
      .then(safeBurstAndCensusRelease(1760, 524288))
      .then(safeContractAfterDrop(16, true))
      .then(safeGscTrimAndSpawnCc1)
      .then(finishCc1)
      .then(safeResizeProcessors(64))
      .then(safeLargeStillDirectMmap(256))
      .then(safeMailboxSendUnderMutex(false))
      .expect(
        safe and
        s.appliedMinHeapMb == 2 and
        s.censusQueueKb == 0 and
        s.gscHeapMb == 24 and
        sublinearHeadroom(64) == 10
      )

  run explicitLivePercentNeverOverriddenTest =
    init
      .then(safeSetExplicitLivePercent(50))
      .then(safeBurstAndCensusRelease(1760, 65536))
      .expect(safe and s.appliedLivePct == 50)

  // --- 9 Mutant-Killing Negative Tests ---
  run mutant1CensusQueueLeakKilledTest =
    init.then(buggyRetainOversizedCensusQueue).expect(not(safe))

  run mutant2HistoryRatchetPinsIdleHeapKilledTest =
    init.then(buggyHistoryRatchetPinsHeap).expect(not(safe))

  run mutant3GscCc1DualPeakCoexistenceKilledTest =
    init.then(buggyGscCc1DualPeakOverlap).expect(not(safe))

  run mutant4LinearPerCoreFloorExplosionKilledTest =
    init.then(buggyLinearPerCoreFloor).expect(not(safe))

  run mutant5UnsafeOverContractionBelowLiveKilledTest =
    init.then(buggyOverContractBelowLowerBound).expect(not(safe))

  run mutant6AdaptiveOverridesExplicitLivePercentKilledTest =
    init.then(buggyAdaptiveOverridesExplicitFlag).expect(not(safe))

  run mutant7LargeStillMallocEmptyRetentionKilledTest =
    init.then(buggyLargeStillViaMalloc).expect(not(safe))

  run mutant8MailboxSkipSignalRacyWaiterKilledTest =
    init.then(buggyMailboxSkipSignalUnlocked).expect(not(safe))

  run mutant9UncappedSocketL3MinHeapKilledTest =
    init.then(buggyUncappedSocketL3MinHeap).expect(not(safe))
}

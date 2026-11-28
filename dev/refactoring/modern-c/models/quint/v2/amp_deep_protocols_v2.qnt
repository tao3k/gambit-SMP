module amp_deep_protocols_v2 {
  // Deep Amp-1..Amp-3 Protocol & Adversarial Mutation-Killing Model (Hazards H1-H6, H8-H9):
  //   1. Amp-1 Local Nursery Escape: SATB black-allocation on local->mature promotion,
  //      Scheme eq? single-address forwarding across duplicate local roots, and
  //      escape-budget exhaustion -> global STW fallback.
  //   2. Amp-1 2-Level Radix Directory: L2 init before L1 publish + quiescent retirement.
  //   3. Amp-2 OCaml-5 Prefetch Ring + Compressed Overflow `addrmap`:
  //      forced mark-stack overflow (cap = 1) + 3-way termination closure.
  //   4. Amp-3 Chez GEN_STATIC Dirty-Card Barrier + Immix Demand-Driven Overflow Block.
  //
  // Eight explicit adversarial mutants below prove that dropping ANY guard violates `safe`.

  type NodeId = int // 0, 1, 2

  type State = {
    // --- 1. Amp-1 Local Escape: SATB Black-Alloc, Scheme eq?, Escape Budget ---
    satbActive: bool,
    localObjPromoted: bool,
    promotedBlackMarked: bool,
    localRootAAddr: int,      // 10 = young addr, 100 = promoted mature addr
    localRootBAddr: int,      // duplicate local root aliasing same Scheme object
    escapeCount: int,         // budget = 2
    globalStwFallback: bool,

    // --- 2. Amp-1 Two-Level Radix Directory Publication & Quiescent Retire ---
    l2Initialized: bool,
    l1Published: bool,
    activeRadixReaders: int,
    msectionRetired: bool,

    // --- 3. Amp-2 Prefetch Ring + Forced-Overflow `addrmap` Marking ---
    // Reachable graph: 0 -> 1 -> 2 (all 3 reachable from root 0)
    markStack: Set[NodeId],   // bounded capacity = 1 -> overflows into addrmap!
    prefetchRing: Set[NodeId],
    addrmap: Set[NodeId],
    marked: Set[NodeId],
    markTerminated: bool,

    // --- 4. Amp-3 Chez GEN_STATIC Dirty-Card Barrier + Immix Overflow ---
    staticPointsToNonStatic: bool,
    staticCardDirty: bool,
    nonStaticChildMarked: bool,
    majorSweepDone: bool,
    recycledLiveLines: Set[int],   // lines 0, 2 occupied / pinned
    overflowBlockLines: Set[int],  // clean dedicated overflow block uses lines 10, 11

    // --- Safety Violation Latches ---
    satbPromotedWhiteBug: bool,
    schemeEqBroken: bool,
    escapeBudgetOverflowNoFallback: bool,
    radixUninitRead: bool,
    radixRetireUaf: bool,
    prematureMarkTermination: bool,
    staticChildLostOnSweep: bool,
    immixOverflowCollision: bool
  }

  var s: State

  pure def childOf(n: NodeId): Set[NodeId] =
    if (n == 0) Set(1)
    else if (n == 1) Set(2)
    else Set()

  action init = {
    s' = {
      satbActive: true,
      localObjPromoted: false,
      promotedBlackMarked: false,
      localRootAAddr: 10,
      localRootBAddr: 10,
      escapeCount: 0,
      globalStwFallback: false,

      l2Initialized: false,
      l1Published: false,
      activeRadixReaders: 0,
      msectionRetired: false,

      markStack: Set(0),
      prefetchRing: Set(),
      addrmap: Set(),
      marked: Set(),
      markTerminated: false,

      staticPointsToNonStatic: false,
      staticCardDirty: false,
      nonStaticChildMarked: false,
      majorSweepDone: false,
      recycledLiveLines: Set(0, 2),
      overflowBlockLines: Set(),

      satbPromotedWhiteBug: false,
      schemeEqBroken: false,
      escapeBudgetOverflowNoFallback: false,
      radixUninitRead: false,
      radixRetireUaf: false,
      prematureMarkTermination: false,
      staticChildLostOnSweep: false,
      immixOverflowCollision: false
    }
  }

  // =========================================================================
  // 1. Amp-1 Local Escape: SATB Black-Alloc, Scheme eq?, Escape Budget
  // =========================================================================

  // Safe local->mature promotion:
  //   - Allocates BLACK if satbActive
  //   - Installs forwarding & rewrites BOTH localRootA and localRootB to mature addr 100
  //   - Increments escapeCount; if budget (2) reached, arms globalStwFallback.
  action promoteLocalEscapeSafe: bool = all {
    not(s.localObjPromoted),
    val nextEsc = s.escapeCount + 1
    s' = {
      ...s,
      localObjPromoted: true,
      promotedBlackMarked: s.satbActive,
      localRootAAddr: 100,
      localRootBAddr: 100,
      escapeCount: nextEsc,
      globalStwFallback: s.globalStwFallback or (nextEsc >= 2)
    }
  }

  action recordAdditionalEscapeSafe: bool = all {
    s.escapeCount < 3,
    val nextEsc = s.escapeCount + 1
    s' = {
      ...s,
      escapeCount: nextEsc,
      globalStwFallback: s.globalStwFallback or (nextEsc >= 2)
    }
  }

  // =========================================================================
  // 2. Amp-1 Two-Level Radix Directory Publish & Quiescent Retirement
  // =========================================================================

  action initL2RadixPage: bool = all {
    not(s.l2Initialized),
    s' = { ...s, l2Initialized: true }
  }

  // Publish L1 -> L2 ONLY after L2 is initialized.
  action publishL1RadixSafe: bool = all {
    s.l2Initialized,
    not(s.l1Published),
    s' = { ...s, l1Published: true }
  }

  action radixReaderEnter: bool = all {
    s.l1Published,
    not(s.msectionRetired),
    s.activeRadixReaders < 2,
    s' = {
      ...s,
      activeRadixReaders: s.activeRadixReaders + 1,
      radixUninitRead: s.radixUninitRead or not(s.l2Initialized)
    }
  }

  action radixReaderExit: bool = all {
    s.activeRadixReaders > 0,
    s' = { ...s, activeRadixReaders: s.activeRadixReaders - 1 }
  }

  // Retire msection descriptor ONLY when activeRadixReaders == 0 (quiescent!).
  action retireMsectionSafe: bool = all {
    s.l1Published,
    not(s.msectionRetired),
    s.activeRadixReaders == 0,
    s' = { ...s, msectionRetired: true }
  }

  // =========================================================================
  // 3. Amp-2 OCaml-5 Prefetch Ring + Forced-Overflow `addrmap` Marking
  // =========================================================================

  // Move node from explicit markStack into prefetchRing (prefetch_block).
  action moveStackToPrefetchRing(n: NodeId): bool = all {
    not(s.markTerminated),
    s.markStack.contains(n),
    s' = {
      ...s,
      markStack: s.markStack.exclude(Set(n)),
      prefetchRing: s.prefetchRing.union(Set(n))
    }
  }

  // Forced mark-stack overflow compression into `addrmap` bitset!
  action compressStackToAddrmap(n: NodeId): bool = all {
    not(s.markTerminated),
    s.markStack.contains(n),
    s' = {
      ...s,
      markStack: s.markStack.exclude(Set(n)),
      addrmap: s.addrmap.union(Set(n))
    }
  }

  // Drain a compressed entry from `addrmap` into prefetchRing.
  action drainAddrmapToRing(n: NodeId): bool = all {
    not(s.markTerminated),
    s.addrmap.contains(n),
    s' = {
      ...s,
      addrmap: s.addrmap.exclude(Set(n)),
      prefetchRing: s.prefetchRing.union(Set(n))
    }
  }

  // Scan node from prefetchRing: mark it and enqueue unmarked children (overflowing to addrmap if stack full!).
  action scanFromPrefetchRing(n: NodeId): bool = all {
    not(s.markTerminated),
    s.prefetchRing.contains(n),
    val newChildren = childOf(n).filter(c => not(s.marked.contains(c)))
    val nextMarked = s.marked.union(Set(n))
    val stackFull = s.markStack.size() >= 1
    s' = {
      ...s,
      prefetchRing: s.prefetchRing.exclude(Set(n)),
      marked: nextMarked,
      markStack: if (stackFull) s.markStack else s.markStack.union(newChildren),
      addrmap: if (stackFull) s.addrmap.union(newChildren) else s.addrmap
    }
  }

  // Safe 3-way mark termination: requires stack, prefetchRing, AND addrmap ALL empty!
  action terminateMarkingSafe: bool = all {
    not(s.markTerminated),
    s.markStack == Set(),
    s.prefetchRing == Set(),
    s.addrmap == Set(),
    s' = {
      ...s,
      markTerminated: true,
      prematureMarkTermination: s.prematureMarkTermination or (s.marked != Set(0, 1, 2))
    }
  }

  // =========================================================================
  // 4. Amp-3 Chez GEN_STATIC Dirty-Card Barrier + Immix Overflow Block
  // =========================================================================

  // Mutating GEN_STATIC to point to non-static mature object MUST dirty static card.
  action storeStaticToNonStaticSafe: bool = all {
    not(s.staticPointsToNonStatic),
    not(s.majorSweepDone),
    s' = {
      ...s,
      staticPointsToNonStatic: true,
      staticCardDirty: true
    }
  }

  // Major GC scans dirty static cards and marks referenced non-static children.
  action majorScanDirtyStaticCards: bool = all {
    s.staticCardDirty,
    not(s.nonStaticChildMarked),
    s' = {
      ...s,
      nonStaticChildMarked: true
    }
  }

  // Major sweep checks that if staticPointsToNonStatic holds, child MUST be marked.
  action finishMajorSweepSafe: bool = all {
    not(s.majorSweepDone),
    not(s.staticCardDirty) or s.nonStaticChildMarked,
    s' = {
      ...s,
      majorSweepDone: true,
      staticChildLostOnSweep: s.staticChildLostOnSweep or (s.staticPointsToNonStatic and not(s.nonStaticChildMarked))
    }
  }

  // Immix demand-driven overflow diverts medium object to clean overflow block (lines 10, 11).
  action allocateMediumToOverflowSafe(line: int): bool = all {
    line == 10 or line == 11,
    not(s.overflowBlockLines.contains(line)),
    s' = {
      ...s,
      overflowBlockLines: s.overflowBlockLines.union(Set(line)),
      immixOverflowCollision: s.immixOverflowCollision or s.recycledLiveLines.contains(line)
    }
  }

  // =========================================================================
  // Nondeterministic Step & Composite Safety Invariant
  // =========================================================================

  action step = any {
    promoteLocalEscapeSafe,
    recordAdditionalEscapeSafe,
    initL2RadixPage,
    publishL1RadixSafe,
    radixReaderEnter,
    radixReaderExit,
    retireMsectionSafe,
    nondet n = Set(0, 1, 2).oneOf()
    moveStackToPrefetchRing(n),
    nondet n = Set(0, 1, 2).oneOf()
    compressStackToAddrmap(n),
    nondet n = Set(0, 1, 2).oneOf()
    drainAddrmapToRing(n),
    nondet n = Set(0, 1, 2).oneOf()
    scanFromPrefetchRing(n),
    terminateMarkingSafe,
    storeStaticToNonStaticSafe,
    majorScanDirtyStaticCards,
    finishMajorSweepSafe,
    nondet l = Set(10, 11).oneOf()
    allocateMediumToOverflowSafe(l)
  }

  val safe = all {
    not(s.satbPromotedWhiteBug),
    not(s.schemeEqBroken),
    not(s.escapeBudgetOverflowNoFallback),
    not(s.radixUninitRead),
    not(s.radixRetireUaf),
    not(s.prematureMarkTermination),
    not(s.staticChildLostOnSweep),
    not(s.immixOverflowCollision),
    // Structural invariants:
    not(s.satbActive and s.localObjPromoted and not(s.promotedBlackMarked)),
    s.localRootAAddr == s.localRootBAddr,
    (s.escapeCount < 2) or s.globalStwFallback,
    not(s.l1Published) or s.l2Initialized,
    not(s.msectionRetired and s.activeRadixReaders > 0),
    not(s.markTerminated) or (s.marked == Set(0, 1, 2)),
    not(s.majorSweepDone and s.staticPointsToNonStatic and not(s.nonStaticChildMarked)),
    s.recycledLiveLines.intersect(s.overflowBlockLines) == Set()
  }

  // =========================================================================
  // Eight Adversarial Bug-Injected Mutants (All Must Violate `safe`)
  // =========================================================================

  // Mutant 1 (H1): Local->mature promotion during active SATB leaves object WHITE.
  action mutant1_promoteUnmarkedDuringSatb: bool = all {
    s.satbActive,
    not(s.localObjPromoted),
    s' = {
      ...s,
      localObjPromoted: true,
      promotedBlackMarked: false,
      localRootAAddr: 100,
      localRootBAddr: 100,
      satbPromotedWhiteBug: true
    }
  }

  // Mutant 2 (H2): Promote root A without forwarding/rewriting duplicate local root B -> breaks eq?!
  action mutant2_duplicateLocalRootBreaksEq: bool = all {
    not(s.localObjPromoted),
    s' = {
      ...s,
      localObjPromoted: true,
      promotedBlackMarked: true,
      localRootAAddr: 100,
      localRootBAddr: 10,
      schemeEqBroken: true
    }
  }

  // Mutant 3 (H3): Escape budget reaches limit (>= 2) WITHOUT arming globalStwFallback!
  action mutant3_escapeBudgetWithoutFallback: bool = all {
    s' = {
      ...s,
      escapeCount: 2,
      globalStwFallback: false,
      escapeBudgetOverflowNoFallback: true
    }
  }

  // Mutant 4 (H4): Publish L1 -> L2 BEFORE initializing L2!
  action mutant4_radixPublishBeforeL2Init: bool = all {
    not(s.l2Initialized),
    s' = {
      ...s,
      l1Published: true,
      radixUninitRead: true
    }
  }

  // Mutant 5 (H5): Retire msection descriptor while concurrent radix reader is still active!
  action mutant5_retireWithActiveReader: bool = all {
    s.activeRadixReaders > 0,
    s' = {
      ...s,
      msectionRetired: true,
      radixRetireUaf: true
    }
  }

  // Mutant 6 (H6): Terminate marking when markStack is empty while addrmap still has pending nodes!
  action mutant6_terminateIgnoringAddrmap: bool = all {
    s.markStack == Set(),
    s.addrmap != Set(),
    s' = {
      ...s,
      markTerminated: true,
      prematureMarkTermination: true
    }
  }

  // Mutant 7 (H8): Store into GEN_STATIC without dirtying static card -> child lost on sweep!
  action mutant7_staticStoreNoDirtyBarrier: bool = all {
    not(s.staticPointsToNonStatic),
    s' = {
      ...s,
      staticPointsToNonStatic: true,
      staticCardDirty: false
    }
  }

  // Mutant 8 (H9): Overflow allocator writes medium object into live/pinned recycled line 0!
  action mutant8_overflowWritesLiveLine: bool = all {
    s' = {
      ...s,
      overflowBlockLines: s.overflowBlockLines.union(Set(0)),
      immixOverflowCollision: true
    }
  }

  // =========================================================================
  // Executable Tests: 1 Complete Happy Path + 8 Adversarial Mutation-Killers
  // =========================================================================

  run happyPathDeepProtocolsTest = {
    init
    .then(promoteLocalEscapeSafe)
    .then(recordAdditionalEscapeSafe)
    .then(initL2RadixPage)
    .then(publishL1RadixSafe)
    .then(radixReaderEnter)
    .then(radixReaderExit)
    .then(retireMsectionSafe)
    // Force overflow through addrmap -> prefetchRing -> scan all 3 nodes 0 -> 1 -> 2
    .then(compressStackToAddrmap(0))
    .then(drainAddrmapToRing(0))
    .then(scanFromPrefetchRing(0))
    .then(compressStackToAddrmap(1))
    .then(drainAddrmapToRing(1))
    .then(scanFromPrefetchRing(1))
    .then(moveStackToPrefetchRing(2))
    .then(scanFromPrefetchRing(2))
    .then(terminateMarkingSafe)
    .then(storeStaticToNonStaticSafe)
    .then(majorScanDirtyStaticCards)
    .then(finishMajorSweepSafe)
    .then(allocateMediumToOverflowSafe(10))
    .then(all {
      assert(safe),
      assert(s.markTerminated),
      assert(s.marked == Set(0, 1, 2)),
      assert(s.msectionRetired),
      assert(s.globalStwFallback),
      assert(s.majorSweepDone),
      s' = s
    })
  }

  run mutant1LocalPromoteUnmarkedDuringSatbTest = {
    init
    .then(mutant1_promoteUnmarkedDuringSatb)
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant2DuplicateLocalRootBreaksEqTest = {
    init
    .then(mutant2_duplicateLocalRootBreaksEq)
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant3EscapeBudgetExhaustedWithoutFallbackTest = {
    init
    .then(mutant3_escapeBudgetWithoutFallback)
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant4RadixPublishWithoutInitTest = {
    init
    .then(mutant4_radixPublishBeforeL2Init)
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant5RetireMsectionWhileReaderActiveTest = {
    init
    .then(initL2RadixPage)
    .then(publishL1RadixSafe)
    .then(radixReaderEnter)
    .then(mutant5_retireWithActiveReader)
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant6MarkTerminatesWithNonEmptyAddrmapOrRingTest = {
    init
    .then(compressStackToAddrmap(0))
    .then(mutant6_terminateIgnoringAddrmap)
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant7StaticMutationWithoutDirtyBarrierTest = {
    init
    .then(mutant7_staticStoreNoDirtyBarrier)
    .then(finishMajorSweepSafe)
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant8OverflowOverwritesLiveOrPinnedLineTest = {
    init
    .then(mutant8_overflowWritesLiveLine)
    .then(all { assert(not(safe)), s' = s })
  }
}

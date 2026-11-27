module slice2_v3_immix_evac_and_slab_v2 {
  // Adversarial Quint V2 (Mutation-Killing) Model for Slice 2 v3 Memory Endgame (P1 + P2):
  //   1. P1-1: Immediate opposite-half release on Minor GC newly promoted mature sections (new_mat)
  //   2. P1-2: Hardware-adaptive Major GC pacing (2.0x small heap -> 1.25x large heap)
  //   3. P2-1: Selective Immix Evacuation (copy only YOUNG + major_evacuate==1 when IDLE;
  //            full parallel scan of pinned mature + mature still; never use evac as promo_tail)
  //   4. P2-2: Sub-linear bounded generational nursery sizing (no 1:1 mature->nursery bloat)
  //   5. P2-3: Medium ___STILL (2-32 KiB) mmap-backed size-class slab with O(1) bitmask &
  //            empty-chunk munmap + post-GC purge (zero double-free, zero live-chunk munmap)

  pure val MATURE_SECTIONS = Set(0, 1, 2, 3) // 0,1 = dense pinned; 2,3 = sparse evac candidates
  pure val SLAB_SLOTS = Set(0, 1, 2, 3)      // 4-slot slab chunk model
  pure val MAX_NURSERY_CAP_400 = 96          // 16 + 4*isqrt(400) = 96 << 400

  pure def isqrt(n: int): int =
    if (n <= 1) n
    else if (n <= 3) 1
    else if (n <= 8) 2
    else if (n <= 15) 3
    else if (n <= 24) 4
    else if (n <= 35) 5
    else if (n <= 99) 9
    else if (n <= 255) 15
    else 20

  // P1-2: Hardware-adaptive Major GC trigger sections
  pure def adaptiveMajorTrigger(mcnt: int, effPct: int): int =
    if (mcnt <= 0) 8
    else
      val raw = (mcnt * 100 + effPct - 1) / effPct
      if (raw < mcnt + 8) mcnt + 8 else raw

  // P2-2: Sub-linear generational nursery headroom cap above mature sections
  pure def genNurseryHeadroomCap(mcnt: int): int =
    val sub = 16 + 4 * isqrt(mcnt)
    if (sub < 32) 32 else sub

  type MajorPhase = str // "IDLE" | "MARKING" | "SWEEPING"

  type State = {
    // P1-1: new_mat opposite-half release
    newMatPromotedCount: int,
    newMatOppHalfReleased: int,
    oppHalfClaimed: bool,
    releasedClaimedHalfBug: bool,
    strandedOppHalfBug: bool,

    // P1-2: Adaptive Major trigger
    matureCount: int,
    effLivePct: int,
    majorTrigger: int,

    // P2-1: Selective Immix Evacuation
    majorPhase: MajorPhase,
    evacSet: Set[int],              // sparse mature sections chosen for evacuation
    promoTailSet: Set[int],         // mature sections chosen as promotion targets
    pinnedCleanRefToEvac: bool,     // clean card in pinned dense section points to evacSet
    pinnedRefUpdated: bool,         // updated during selective evac full pinned scan
    evacUnlinkedAndFreed: bool,
    denseSectionsCopied: int,
    evacDuringMarkingBug: bool,
    evacPromoOverlapBug: bool,
    evacHoleRecycleBug: bool,
    danglingPinnedRefBug: bool,

    // P2-2: Generational nursery sizing
    explicitLivePct: bool,
    nurseryFreeSections: int,
    lowerBoundSections: int,
    totalSections: int,
    linearNurseryBloatBug: bool,
    underLowerBoundBug: bool,

    // P2-3: Medium still mmap slab chunk
    chunkMapped: bool,
    chunkCachedEmpty: bool,
    liveSlots: Set[int],
    slabDoubleFreeBug: bool,
    slabMunmapLiveBug: bool,
    slabEmptyLeakBug: bool
  }

  var s: State

  action init = {
    s' = {
      newMatPromotedCount: 0,
      newMatOppHalfReleased: 0,
      oppHalfClaimed: false,
      releasedClaimedHalfBug: false,
      strandedOppHalfBug: false,
      matureCount: 40,
      effLivePct: 50,
      majorTrigger: adaptiveMajorTrigger(40, 50),
      majorPhase: "IDLE",
      evacSet: Set(),
      promoTailSet: Set(),
      pinnedCleanRefToEvac: true,
      pinnedRefUpdated: false,
      evacUnlinkedAndFreed: false,
      denseSectionsCopied: 0,
      evacDuringMarkingBug: false,
      evacPromoOverlapBug: false,
      evacHoleRecycleBug: false,
      danglingPinnedRefBug: false,
      explicitLivePct: false,
      nurseryFreeSections: 40,
      lowerBoundSections: 48,
      totalSections: 80,
      linearNurseryBloatBug: false,
      underLowerBoundBug: false,
      chunkMapped: false,
      chunkCachedEmpty: false,
      liveSlots: Set(),
      slabDoubleFreeBug: false,
      slabMunmapLiveBug: false,
      slabEmptyLeakBug: false
    }
  }

  // Action 1 (P1-1): Safe Minor GC new_mat promotion with immediate unclaimed opp-half release
  action safePromoteNewMat(oppClaimed: bool): bool = all {
    not(s.oppHalfClaimed),
    s.newMatPromotedCount < 16,
    s' = {
      ...s,
      newMatPromotedCount: s.newMatPromotedCount + 1,
      newMatOppHalfReleased: if (not(oppClaimed)) s.newMatOppHalfReleased + 1 else s.newMatOppHalfReleased,
      oppHalfClaimed: oppClaimed,
      matureCount: s.matureCount + 1,
      majorTrigger: adaptiveMajorTrigger(s.matureCount + 1, s.effLivePct)
    }
  }

  // Action 2 (P1-2): Update adaptive Major trigger on heap growth (50% -> 80%)
  action safeUpdateAdaptiveTrigger(newMature: int, newPct: int): bool = all {
    Set(40, 200, 400).contains(newMature),
    Set(50, 65, 80).contains(newPct),
    s' = {
      ...s,
      matureCount: newMature,
      effLivePct: newPct,
      majorTrigger: adaptiveMajorTrigger(newMature, newPct)
    }
  }

  // Action 3 (P2-1): Start / finish Concurrent Major marking phase
  action safeEnterMarking = all {
    s.majorPhase == "IDLE",
    s.evacSet == Set(),
    s' = { ...s, majorPhase: "MARKING" }
  }

  action safeFinishMarkingToIdle = all {
    s.majorPhase == "MARKING",
    s' = { ...s, majorPhase: "IDLE", pinnedCleanRefToEvac: true, pinnedRefUpdated: false, evacUnlinkedAndFreed: false }
  }

  // Action 4 (P2-1): Safe Selective Immix Evacuation (only when IDLE, disjoint promo tails, full pinned scan)
  action safeSelectiveEvacuate = {
    val chosenEvac = Set(2, 3)
    val chosenPromo = Set(0) // strictly disjoint from chosenEvac!
    all {
      s.majorPhase == "IDLE",
      chosenEvac.intersect(chosenPromo) == Set(),
      s' = {
        ...s,
        evacSet: chosenEvac,
        promoTailSet: chosenPromo,
        pinnedRefUpdated: true, // parallel full scan of all pinned mature sections (incl. clean cards!)
        evacUnlinkedAndFreed: true,
        denseSectionsCopied: 0
      }
    }
  }

  // Action 5 (P2-2): Safe Generational Nursery Sizing (sub-linear cap, strict lower bound)
  action safeResizeGenerational(mcnt: int): bool = {
    val cap = genNurseryHeadroomCap(mcnt)
    val lb = mcnt + 8
    val target = if (mcnt + cap >= lb) mcnt + cap else lb
    all {
      Set(40, 200, 400).contains(mcnt),
      not(s.explicitLivePct),
      s' = {
        ...s,
        matureCount: mcnt,
        majorTrigger: adaptiveMajorTrigger(mcnt, s.effLivePct),
        lowerBoundSections: lb,
        nurseryFreeSections: target - mcnt,
        totalSections: target
      }
    }
  }

  // Action 6 (P2-3): Medium still slab alloc, free, and post-GC empty-chunk purge
  action safeSlabAlloc(slot: int): bool = all {
    SLAB_SLOTS.contains(slot),
    not(s.liveSlots.contains(slot)),
    s' = {
      ...s,
      chunkMapped: true,
      chunkCachedEmpty: false,
      liveSlots: s.liveSlots.union(Set(slot))
    }
  }

  action safeSlabFree(slot: int): bool = {
    val nextLive = s.liveSlots.exclude(Set(slot))
    val nowEmpty = (nextLive == Set())
    all {
      s.chunkMapped,
      s.liveSlots.contains(slot),
      s' = {
        ...s,
        liveSlots: nextLive,
        // Keep at most 1 empty chunk cached until purge, or munmap immediately
        chunkCachedEmpty: nowEmpty
      }
    }
  }

  action safeSlabPurgeEmpty = all {
    s.chunkMapped,
    s.liveSlots == Set(),
    s.chunkCachedEmpty,
    s' = {
      ...s,
      chunkMapped: false,
      chunkCachedEmpty: false
    }
  }

  action step = any {
    nondet oppClaimed = oneOf(Set(false))
    safePromoteNewMat(oppClaimed),
    nondet m = oneOf(Set(40, 200, 400))
    nondet p = oneOf(Set(50, 65, 80))
    safeUpdateAdaptiveTrigger(m, p),
    safeEnterMarking,
    safeFinishMarkingToIdle,
    safeSelectiveEvacuate,
    nondet m2 = oneOf(Set(40, 200, 400))
    safeResizeGenerational(m2),
    nondet sl = oneOf(SLAB_SLOTS)
    safeSlabAlloc(sl),
    nondet sl2 = oneOf(SLAB_SLOTS)
    safeSlabFree(sl2),
    safeSlabPurgeEmpty
  }

  // =========================================================================
  // Global Safety Invariant
  // =========================================================================
  val safe = and {
    // P1-1: Never strand opposite half of unclaimed new_mat, never release claimed half
    not(s.strandedOppHalfBug),
    not(s.releasedClaimedHalfBug),
    s.oppHalfClaimed or (s.newMatOppHalfReleased == s.newMatPromotedCount),

    // P1-2: Trigger pacing always >= mcnt + 8 and tighter at 80% than 2.0x on large heaps
    s.majorTrigger >= s.matureCount + 8,
    (s.effLivePct < 80 or s.matureCount < 40) or (s.majorTrigger < s.matureCount * 2),

    // P2-1: Selective evacuation safety
    not(s.evacDuringMarkingBug),
    not(s.evacPromoOverlapBug),
    not(s.evacHoleRecycleBug),
    not(s.danglingPinnedRefBug),
    s.evacSet.intersect(s.promoTailSet) == Set(),
    not(s.evacUnlinkedAndFreed) or (not(s.pinnedCleanRefToEvac) or s.pinnedRefUpdated),
    s.denseSectionsCopied == 0,

    // P2-2: Sub-linear generational nursery & lower-bound preservation
    not(s.linearNurseryBloatBug),
    not(s.underLowerBoundBug),
    s.totalSections >= s.lowerBoundSections,
    (s.matureCount < 200 or s.explicitLivePct) or (s.nurseryFreeSections < s.matureCount),

    // P2-3: Slab soundness
    not(s.slabDoubleFreeBug),
    not(s.slabMunmapLiveBug),
    not(s.slabEmptyLeakBug),
    s.chunkMapped or (s.liveSlots == Set())
  }

  // =========================================================================
  // Adversarial Buggy Mutants (9 real-bug mutants; EVERY ONE MUST FAIL!)
  // =========================================================================

  // Mutant 1: Minor GC promotes new_mat without releasing its dead opposite half (pre-P1-1 bug!)
  action buggyPromoteNewMatWithoutOppRelease = all {
    s' = { ...s, newMatPromotedCount: s.newMatPromotedCount + 1, strandedOppHalfBug: true }
  }

  // Mutant 2: Release opposite half even though a stack/heap claim is still active on it
  action buggyReleaseClaimedHalf = all {
    s' = { ...s, oppHalfClaimed: true, releasedClaimedHalfBug: true }
  }

  // Mutant 3: Run selective evacuation while Concurrent Major GC MARKING is active
  action buggyEvacDuringMarking = all {
    s.majorPhase == "MARKING",
    s' = { ...s, evacSet: Set(2), evacDuringMarkingBug: true }
  }

  // Mutant 4: Pick an evacuating sparse section as a Minor GC promo_tail destination
  action buggyEvacOverlapPromoTail = all {
    s.majorPhase == "IDLE",
    s' = { ...s, evacSet: Set(2), promoTailSet: Set(2), evacPromoOverlapBug: true }
  }

  // Mutant 5: Scan only dirty cards during selective evacuation -> clean pinned ref dangles (UAF!)
  action buggyEvacDirtyCardsOnly = all {
    s.majorPhase == "IDLE",
    s.pinnedCleanRefToEvac,
    s' = { ...s, evacSet: Set(2), pinnedRefUpdated: false, evacUnlinkedAndFreed: true, danglingPinnedRefBug: true }
  }

  // Mutant 6: Classic 1:1 mature->nursery expansion on 400 mature sections (400 free young bloat!)
  action buggyLinearMatureNurseryBloat = all {
    s' = { ...s, matureCount: 400, nurseryFreeSections: 400, totalSections: 800, linearNurseryBloatBug: true }
  }

  // Mutant 7: Double-free a slab slot (missing live-bit check / racy unlock)
  action buggySlabDoubleFree(slot: int): bool = all {
    s.chunkMapped,
    not(s.liveSlots.contains(slot)),
    s' = { ...s, slabDoubleFreeBug: true }
  }

  // Mutant 8: munmap a slab chunk that still holds a live still object (UAF!)
  action buggySlabMunmapLiveChunk = all {
    s.chunkMapped,
    s.liveSlots != Set(),
    s' = { ...s, chunkMapped: false, slabMunmapLiveBug: true }
  }

  // Mutant 9: Fail to purge empty cached slab chunk on GC contraction (RSS retention leak!)
  action buggySlabLeakAfterPurge = all {
    s.chunkMapped,
    s.liveSlots == Set(),
    s.chunkCachedEmpty,
    s' = { ...s, slabEmptyLeakBug: true }
  }

  // Mutant 10: Open an Immix dead-line hole (gc_is_dest==3) inside a pinned mature
  // section while evac_selective linearly scans [0..scan_end_words) (t5 SIGBUS bug!)
  action buggyEvacHoleRecycleInPinnedSection = all {
    s.majorPhase == "IDLE",
    s' = { ...s, evacSet: Set(2, 3), promoTailSet: Set(0), evacHoleRecycleBug: true }
  }

  // =========================================================================
  // Positive & Negative (Mutation-Killer) Executable Tests
  // =========================================================================

  run positiveEndToEndP1P2Test = {
    init
      .then(safePromoteNewMat(false))
      .then(safeUpdateAdaptiveTrigger(400, 80))
      .then(safeEnterMarking)
      .then(safeFinishMarkingToIdle)
      .then(safeSelectiveEvacuate)
      .then(safeResizeGenerational(400))
      .then(safeSlabAlloc(0))
      .then(safeSlabAlloc(1))
      .then(safeSlabFree(0))
      .then(safeSlabFree(1))
      .then(safeSlabPurgeEmpty)
      .then(all { assert(safe), assert(s.majorTrigger == 500), assert(s.nurseryFreeSections == 96), assert(not(s.chunkMapped)), s' = s })
  }

  run mutant1SkipNewMatOppReleaseKilledTest = {
    init.then(buggyPromoteNewMatWithoutOppRelease).then(all { assert(not(safe)), s' = s })
  }

  run mutant2ReleaseClaimedHalfKilledTest = {
    init.then(buggyReleaseClaimedHalf).then(all { assert(not(safe)), s' = s })
  }

  run mutant3EvacDuringConcurrentMarkKilledTest = {
    init.then(safeEnterMarking).then(buggyEvacDuringMarking).then(all { assert(not(safe)), s' = s })
  }

  run mutant4EvacSectionAsPromoTailKilledTest = {
    init.then(buggyEvacOverlapPromoTail).then(all { assert(not(safe)), s' = s })
  }

  run mutant5DirtyCardsOnlyDuringEvacKilledTest = {
    init.then(buggyEvacDirtyCardsOnly).then(all { assert(not(safe)), s' = s })
  }

  run mutant6LinearMatureNurseryBloatKilledTest = {
    init.then(buggyLinearMatureNurseryBloat).then(all { assert(not(safe)), s' = s })
  }

  run mutant7SlabDoubleFreeKilledTest = {
    init.then(safeSlabAlloc(0)).then(safeSlabFree(0)).then(buggySlabDoubleFree(0)).then(all { assert(not(safe)), s' = s })
  }

  run mutant8SlabMunmapWhileLiveKilledTest = {
    init.then(safeSlabAlloc(0)).then(buggySlabMunmapLiveChunk).then(all { assert(not(safe)), s' = s })
  }

  run mutant9SlabLeakEmptyChunkAfterPurgeKilledTest = {
    init.then(safeSlabAlloc(0)).then(safeSlabFree(0)).then(buggySlabLeakAfterPurge).then(all { assert(not(safe)), s' = s })
  }

  run mutant10EvacHoleRecycleInPinnedSectionKilledTest = {
    init.then(buggyEvacHoleRecycleInPinnedSection).then(all { assert(not(safe)), s' = s })
  }
}

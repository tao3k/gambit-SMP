// Axis 1 (DEV Refactory) formal convergence contracts for Family 6 Checklist 10-12
// and outer SMP Families 6-12:
//   1. D-MEM-1: Worker-owned GC section lookup caches vs file-static race and
//      same-thread multi-section adjust_msections shift / cross-VM epoch collision.
//   2. C2: Single-acquire copy_gate fast-path lease equivalence (4x -> 1x gate).
//   3. C1: WriteGroupPlan monotonic pre-commit expansion and emitSpec coverage gate.
module axis1_convergence_contracts {
  // 1. D-MEM-1: Collector scan-state cache ownership and multi-section shift safety
  type SectionId = int
  type ScanCache = { valid: bool, vm: int, epoch: int, section: SectionId, base: int }

  // Separating mutant 1: file-static scan_state_section overwritten between hit-check
  // and read by a second collector worker in the same GC round (causes
  // "GC scan owner lost before completion" in rest-9-ordinary-race).
  pure def fileStaticRaceInterleaving(secA: SectionId, secB: SectionId): bool = {
    val checkedOnA = true
    val overwrittenSection = secB
    val claimedBitmapSection = if (checkedOnA) overwrittenSection else secA
    val retiredBitmapSection = secA
    claimedBitmapSection == retiredBitmapSection
  }

  // Production target: worker-owned cache inside ___collector_worker_struct.
  pure def workerOwnedInterleaving(secA: SectionId, secB: SectionId): bool = {
    val w0Cache: ScanCache = { valid: true, vm: 1, epoch: 7, section: secA, base: 1000 }
    val w1Cache: ScanCache = { valid: true, vm: 1, epoch: 7, section: secB, base: 2000 }
    val w0Claimed = w0Cache.section
    val w1Claimed = w1Cache.section
    w0Claimed == secA and w1Claimed == secB
  }

  // Separating mutant 2: _Thread_local msection_find_cache bumped only once before
  // adjust_msections's while(ns < n) loop; adding 2 sections shifts pos without
  // invalidating the cached pos from iteration 1 on the same thread.
  pure def threadLocalMultiSectionShiftPos(bumpPerInsert: bool): (int, int) = {
    // Initial descending array: [sec100 (pos 0)].
    // Insert 1: sec300 inserted at index 0 -> array becomes [sec300 (0), sec100 (1)].
    // Before shift, lookup(sec100) cached pos = 0 under gen = 2.
    val genAtEntry = 2
    val cachedSec100Gen = genAtEntry
    val cachedSec100Pos = 0
    val actualSec100PosAfterInsert1 = 1
    val genAfterInsert1 = if (bumpPerInsert) genAtEntry + 1 else genAtEntry
    val observedPos =
      if (cachedSec100Gen == genAfterInsert1) cachedSec100Pos else actualSec100PosAfterInsert1
    (observedPos, actualSec100PosAfterInsert1)
  }

  // Separating mutant 3: _Thread_local census_section without VM identity collides
  // when two VMs share epoch == 1 on a carrier/host thread.
  pure def censusLookupMatchesVm(checkVmIdentity: bool): bool = {
    val cachedVm = 1
    val cachedEpoch = 1
    val cachedSection = 10
    val activeVm = 2
    val activeEpoch = 1
    val hit = cachedEpoch == activeEpoch and (not(checkVmIdentity) or cachedVm == activeVm)
    val resolvedSection = if (hit) cachedSection else 20
    resolvedSection == 20
  }

  // 2. Decision C2: Single-acquire copy_gate fast-path lease equivalence
  type FastAdmissionView = {
    phase: int,
    ctxHp: int,
    ctxFp: int,
    liveHp: int,
    liveFp: int,
    softHeapLimit: int,
    hardHeapLimit: int,
    stackLo: int,
    stackHi: int,
    fudgeWords: int,
    heapOwned: bool,
    stackOwned: bool,
    stackWords: int,
    heapWords: int
  }

  pure def stackSpanAdjustFits(lo: int, hi: int, fp: int, fudge: int, delta: int): bool =
    if (delta <= 0) true
    else
      lo <= fp and fp <= hi and (hi - lo) > fudge and
      fp >= lo + fudge and (fp - (lo + fudge)) >= delta and (fp - delta) <= hi

  pure def legacyFastPathAdmit(v: FastAdmissionView): (bool, int) = {
    val firstTryCalls =
      if (v.phase == 0 and v.ctxHp == v.liveHp and v.ctxFp == v.liveFp) {
        if (not(v.stackOwned) or v.liveFp < v.stackLo or v.liveFp > v.stackHi) 1
        else if (v.heapWords > 0 and (v.liveHp >= v.softHeapLimit or
                 (v.softHeapLimit - v.liveHp) < v.heapWords or
                 not(v.heapOwned) or (v.hardHeapLimit - v.liveHp) < v.heapWords)) 1
        else if (v.stackWords > 0) 2
        else 1
      } else 0
    val firstOk =
      v.phase == 0 and v.ctxHp == v.liveHp and v.ctxFp == v.liveFp and
      v.stackOwned and v.stackLo <= v.liveFp and v.liveFp <= v.stackHi and
      (v.heapWords <= 0 or (v.heapOwned and v.liveHp < v.softHeapLimit and
        (v.softHeapLimit - v.liveHp) >= v.heapWords and
        (v.hardHeapLimit - v.liveHp) >= v.heapWords)) and
      stackSpanAdjustFits(v.stackLo, v.stackHi, v.liveFp, v.fudgeWords, v.stackWords)
    if (firstOk) (true, firstTryCalls)
    else if (v.phase != 2) {
      val secondCalls =
        if (not(v.stackOwned) or v.liveFp < v.stackLo or v.liveFp > v.stackHi) 1
        else if (v.heapWords > 0 and (v.liveHp >= v.softHeapLimit or
                 (v.softHeapLimit - v.liveHp) < v.heapWords or
                 not(v.heapOwned) or (v.hardHeapLimit - v.liveHp) < v.heapWords)) 1
        else if (v.stackWords > 0) 2
        else 1
      val secondOk =
        v.stackOwned and v.stackLo <= v.liveFp and v.liveFp <= v.stackHi and
        (v.heapWords <= 0 or (v.heapOwned and v.liveHp < v.softHeapLimit and
          (v.softHeapLimit - v.liveHp) >= v.heapWords and
          (v.hardHeapLimit - v.liveHp) >= v.heapWords)) and
        stackSpanAdjustFits(v.stackLo, v.stackHi, v.liveFp, v.fudgeWords, v.stackWords)
      (secondOk, firstTryCalls + secondCalls)
    } else (false, firstTryCalls)
  }

  pure def singleGateFastPathAdmit(v: FastAdmissionView): (bool, int) = {
    if (v.phase == 2) (false, 0)
    else {
      val heapOk =
        v.heapWords <= 0 or
        (v.heapOwned and v.liveHp < v.softHeapLimit and
         (v.softHeapLimit - v.liveHp) >= v.heapWords and
         (v.hardHeapLimit - v.liveHp) >= v.heapWords)
      if (not(heapOk)) (false, 0)
      else if (not(v.stackOwned) or v.liveFp < v.stackLo or v.liveFp > v.stackHi) (false, 1)
      else (stackSpanAdjustFits(v.stackLo, v.stackHi, v.liveFp, v.fudgeWords, v.stackWords), 1)
    }
  }

  // 3. Decision C1: WriteGroupPlan & emitSpec coverage state machine
  type PlanState = {
    phase: str,
    entryFp: int,
    stackWords: int,
    heapWords: int,
    obsStack: int,
    obsHeap: int,
    specEmitted: bool
  }

  var p: PlanState

  action initPlan = p' = {
    phase: "open", entryFp: 4, stackWords: 2, heapWords: 6,
    obsStack: 0, obsHeap: 0, specEmitted: false
  }

  action expandGroup(fp: int, ns: int, nh: int): bool = all {
    p.phase == "open" and fp == p.entryFp,
    p' = {
      ...p,
      stackWords: if (ns > p.stackWords) ns else p.stackWords,
      heapWords: if (nh > p.heapWords) nh else p.heapWords
    }
  }

  action recordGroupEffect(sd: int, hd: int): bool = all {
    p.phase == "open" and sd <= p.stackWords and p.obsHeap + hd <= p.heapWords,
    p' = {
      ...p,
      obsStack: if (sd > p.obsStack) sd else p.obsStack,
      obsHeap: p.obsHeap + hd
    }
  }

  action commitAndEmitSpec = all {
    p.phase == "open" and p.obsStack <= p.stackWords and p.obsHeap <= p.heapWords,
    p' = { ...p, phase: "committed", specEmitted: true }
  }

  val planSafe =
    p.obsStack <= p.stackWords and
    p.obsHeap <= p.heapWords and
    (not(p.specEmitted) or p.phase == "committed")

  pure def groupHeapDemand(reserved: int, committed: int, dirtyFlonums: int, flonumSpace: int): int = {
    val delta = if (reserved > committed) (reserved - committed) else 0
    delta + dirtyFlonums * flonumSpace
  }

  // Tests
  run workerOwnedScanCacheSafeTest =
    assert(workerOwnedInterleaving(1, 2) and not(fileStaticRaceInterleaving(1, 2)))

  run statelessOrPerInsertShiftSafeTest = {
    val buggy = threadLocalMultiSectionShiftPos(false)
    val sound = threadLocalMultiSectionShiftPos(true)
    assert(buggy._1 != buggy._2 and sound._1 == sound._2)
  }

  run workerScopedCensusCrossVmSafeTest =
    assert(censusLookupMatchesVm(true) and not(censusLookupMatchesVm(false)))

  run singleAcquireCopyGateEquivalenceTest = {
    val advancedCursorFitting: FastAdmissionView = {
      phase: 0, ctxHp: 100, ctxFp: 500, liveHp: 108, liveFp: 500,
      softHeapLimit: 140, hardHeapLimit: 160,
      stackLo: 300, stackHi: 520, fudgeWords: 32,
      heapOwned: true, stackOwned: true, stackWords: 8, heapWords: 12
    }
    val heapShortage: FastAdmissionView = { ...advancedCursorFitting, softHeapLimit: 112 }
    val stackFudgeShortage: FastAdmissionView = { ...advancedCursorFitting, liveFp: 336 }
    val oldFit = legacyFastPathAdmit(advancedCursorFitting)
    val newFit = singleGateFastPathAdmit(advancedCursorFitting)
    val oldHeapShort = legacyFastPathAdmit(heapShortage)
    val newHeapShort = singleGateFastPathAdmit(heapShortage)
    val oldStackShort = legacyFastPathAdmit(stackFudgeShortage)
    val newStackShort = singleGateFastPathAdmit(stackFudgeShortage)
    assert(
      oldFit._1 == newFit._1 and oldFit._1 == true and oldFit._2 == 2 and newFit._2 == 1 and
      oldHeapShort._1 == newHeapShort._1 and oldHeapShort._1 == false and newHeapShort._2 == 0 and
      oldStackShort._1 == newStackShort._1 and oldStackShort._1 == false and newStackShort._2 == 1
    )
  }

  run writeGroupPlanCoverageGateTest =
    initPlan
      .then(expandGroup(4, 6, 12))
      .then(recordGroupEffect(6, 12))
      .then(commitAndEmitSpec)
      .expect(planSafe and p.specEmitted and p.stackWords == 6 and p.heapWords == 12)

  run postCommitExpansionRejectedControlTest =
    initPlan
      .then(commitAndEmitSpec)
      .then(all { p' = { ...p, obsHeap: p.heapWords + 1 } })
      .expect(not(planSafe))

  run incrementalGroupHeapWatermarkSafeTest = {
    val g1 = groupHeapDemand(8, 0, 0, 3)
    val postCommitIdle = groupHeapDemand(8, 8, 0, 3)
    val g2 = groupHeapDemand(16, 8, 0, 3)
    val beforeFlush = groupHeapDemand(8, 8, 2, 3)
    val afterFlush = groupHeapDemand(11, 8, 1, 3)
    assert(
      g1 == 8 and
      postCommitIdle == 0 and
      g1 + g2 == 16 and
      beforeFlush == 6 and
      afterFlush == beforeFlush
    )
  }
}

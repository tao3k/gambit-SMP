// Adversarial challenge model for Gambit-SMP rest-parameter nursery TLAB refill
// vs. whole-heap garbage collection (vendor/gambit/lib/_kernel.scm,
// vendor/gambit/lib/_mem/heap-sections.inc:___rest_take_free_section).
//
// Models the architectural separation between:
//   (1) In-section soft-edge publication (zero lock, zero GC),
//   (2) Zero-growth budgeted free-nursery TLAB refill (___rest_take_free_section:
//       consumes an already-budgeted free msection when freeSections >= 1,
//       NEVER grows the_msections, respects max_heap, stack_slots, and
//       planted-short cut-9 dominance), and
//   (3) Genuine heap-exhaustion collection (root-window -> caller-chain ->
//       ___garbage_collect -> post-GC ___rest_extend_interval).
module smp_rest_nursery_refill {
  type State = {
    initialSections: int,
    totalSections: int,
    assignedSections: int,
    overflowReserve: int,
    maxHeapSections: int,       // 0 = unbounded
    lifecycleGcAdmitted: bool,
    gcCount: int,
    refillCount: int,
    cut9Refusals: int,
    stackRefusals: int,
    oversizedRefusals: int,
    violatedPreGcGrowth: bool,
    violatedPlantedShort: bool,
    violatedStackIsolation: bool,
    violatedMaxHeap: bool,
    violatedMissedGc: bool
  }

  var s: State

  pure def freeNursery(st: State): int =
    st.totalSections - st.assignedSections - st.overflowReserve

  pure def maxHeapAdmits(st: State): bool =
    st.maxHeapSections == 0 or (st.assignedSections + 1 <= st.maxHeapSections)

  action initWith(total: int, assigned: int, reserve: int, maxHeap: int, admitted: bool): bool =
    s' = {
      initialSections: total,
      totalSections: total,
      assignedSections: assigned,
      overflowReserve: reserve,
      maxHeapSections: maxHeap,
      lifecycleGcAdmitted: admitted,
      gcCount: 0,
      refillCount: 0,
      cut9Refusals: 0,
      stackRefusals: 0,
      oversizedRefusals: 0,
      violatedPreGcGrowth: false,
      violatedPlantedShort: false,
      violatedStackIsolation: false,
      violatedMaxHeap: false,
      violatedMissedGc: false
    }

  action init = initWith(16, 4, 2, 0, true)

  // Honest architectural transition: ___rest_take_free_section + handler_get_rest.
  // Models a rest-parameter call whose current 512 KiB TLAB is physically short.
  action restPhysicalShortage(
      plantedShort: bool,
      oneWordShort: bool,
      stackFits: bool,
      freshOwned: bool,
      demandWords: int,
      freshRoom: int): bool =
    if (plantedShort and oneWordShort) {
      // Tier 1: Cut 9 refusal dominates refill and GC; zero state mutation.
      s' = { ...s, cut9Refusals: s.cut9Refusals + 1 }
    } else if (not(stackFits)) {
      // Stack shortage is never a heap-section refill trigger.
      s' = { ...s, stackRefusals: s.stackRefusals + 1 }
    } else if (not(plantedShort) and freeNursery(s) >= 1 and maxHeapAdmits(s)
               and not(freshOwned) and demandWords > 0 and demandWords <= freshRoom) {
      // Tier 3: Zero-growth TLAB refill from already-budgeted free nursery.
      s' = {
        ...s,
        assignedSections: s.assignedSections + 1,
        refillCount: s.refillCount + 1
      }
    } else if (not(plantedShort) and freeNursery(s) >= 1 and demandWords > freshRoom) {
      // Oversized demand refuses BEFORE committing a fresh section.
      s' = { ...s, oversizedRefusals: s.oversizedRefusals + 1 }
    } else if (not(s.lifecycleGcAdmitted) and not(plantedShort) and maxHeapAdmits(s)
               and demandWords > 0 and demandWords <= freshRoom) {
      // Pre-GC bootstrap only: direct growth before GC admission opens.
      s' = {
        ...s,
        totalSections: if (freeNursery(s) < 1) s.totalSections + 8 else s.totalSections,
        assignedSections: s.assignedSections + 1,
        refillCount: s.refillCount + 1
      }
    } else {
      // Tier 4: Free nursery truly exhausted (or max_heap hit) -> genuine GC,
      // resetting assigned sections to live set (4) with fresh nursery headroom.
      s' = {
        ...s,
        assignedSections: 4,
        gcCount: s.gcCount + 1
      }
    }

  // Adversarial Mutant 1 (exact v15 defect): skips free-nursery refill whenever
  // lifecycleGcAdmitted == true, forcing a full-heap GC on every 512 KiB TLAB!
  action mutantLegacyGcPerSection(demandWords: int, freshRoom: int): bool = all {
    s.lifecycleGcAdmitted and demandWords > 0 and demandWords <= freshRoom,
    s' = { ...s, gcCount: s.gcCount + 1 }
  }

  // Adversarial Mutant 2 (pre-Family-6 defect): grows totalSections before GC
  // even when lifecycleGcAdmitted == true and freeNursery == 0.
  action mutantUnboundedPreGcGrowth(demandWords: int, freshRoom: int): bool = all {
    s.lifecycleGcAdmitted and freeNursery(s) <= 0 and demandWords <= freshRoom,
    s' = {
      ...s,
      totalSections: s.totalSections + 8,
      assignedSections: s.assignedSections + 1,
      refillCount: s.refillCount + 1,
      violatedPreGcGrowth: true
    }
  }

  // Adversarial Mutant 3: omits !___rest_planted_short() before refill,
  // allowing Checklist 6 one-word-short probes to refill instead of cut-9.
  action mutantPlantedShortBypass: bool = all {
    freeNursery(s) >= 1,
    s' = {
      ...s,
      assignedSections: s.assignedSections + 1,
      refillCount: s.refillCount + 1,
      violatedPlantedShort: true
    }
  }

  // Honest architectural transition for handler_stack_limit heap exhaustion:
  //   vendor/gambit/lib/_kernel.scm:347-379
  //   vendor/gambit/lib/_mem/allocation-limits.inc:___heap_continue_on_free_section & ___stack_limit
  // Once lifecycleGcAdmitted == true (and primlockDepth == 0), NEVER grows the_msections
  // before GC; consumes an already-budgeted free nursery section only, and when free
  // nursery is exhausted (or cursor is past hard edge), ___stack_limit returns 2 -> GC!
  action handlerStackLimitHeapShortage(primlockDepth: int, pastHardEdge: bool): bool =
    if (not(pastHardEdge) and freeNursery(s) >= 1 and maxHeapAdmits(s)) {
      // Zero-growth continuation on already-budgeted free nursery section
      s' = {
        ...s,
        assignedSections: s.assignedSections + 1,
        refillCount: s.refillCount + 1
      }
    } else if (not(s.lifecycleGcAdmitted) and s.maxHeapSections == 0 and not(pastHardEdge)) {
      // Pre-GC bootstrap only (before VM lifecycle opens GC admission)
      s' = {
        ...s,
        totalSections: s.totalSections + 8,
        assignedSections: s.assignedSections + 1,
        refillCount: s.refillCount + 1
      }
    } else if (primlockDepth > 0 and not(pastHardEdge) and maxHeapAdmits(s)) {
      // Raw spinlock held: cannot enter STW GC barrier; grow +1 section respecting max_heap
      s' = {
        ...s,
        totalSections: s.totalSections + 1,
        assignedSections: s.assignedSections + 1,
        refillCount: s.refillCount + 1
      }
    } else {
      // Free nursery exhausted (or past hard edge) -> ___stack_limit returns 2 -> genuine GC!
      s' = {
        ...s,
        assignedSections: 4,
        gcCount: s.gcCount + 1
      }
    }

  // Adversarial Mutant 4 (exact v23 allocation-limits.inc:1066-1077 defect):
  // ___heap_continue_on_free_section grows the_msections by 1.5x when max_heap == 0
  // even while lifecycleGcAdmitted == true -> 0 GCs and unbounded +37..200 MiB/s RSS leak!
  action mutantHeapContinueUnboundedGrowth: bool = all {
    s.lifecycleGcAdmitted and s.maxHeapSections == 0 and freeNursery(s) <= 0,
    s' = {
      ...s,
      totalSections: s.totalSections + (if (s.totalSections / 2 < 8) 8 else s.totalSections / 2),
      assignedSections: s.assignedSections + 1,
      refillCount: s.refillCount + 1,
      violatedPreGcGrowth: true
    }
  }

  // Adversarial Mutant 5 (missed GC when ___stack_limit returns 0 on heap-only shortage):
  action mutantStackLimitReturnsZeroOnHeapShortage: bool = all {
    s.lifecycleGcAdmitted and freeNursery(s) <= 0,
    s' = {
      ...s,
      violatedMissedGc: true
    }
  }

  val safety =
    not(s.violatedPreGcGrowth) and
    not(s.violatedPlantedShort) and
    not(s.violatedStackIsolation) and
    not(s.violatedMaxHeap) and
    not(s.violatedMissedGc) and
    (s.gcCount > 0 or not(s.lifecycleGcAdmitted) or s.totalSections == s.initialSections) and
    (s.maxHeapSections == 0 or s.assignedSections <= s.maxHeapSections) and
    s.assignedSections <= s.totalSections

  // Nondeterministic step for simulator invariant fuzzing.
  action step = any {
    restPhysicalShortage(false, false, true, false, 100, 56316),
    restPhysicalShortage(true, true, true, false, 100, 56316),
    restPhysicalShortage(false, false, false, false, 100, 56316),
    restPhysicalShortage(false, false, true, false, 70000, 56316),
    restPhysicalShortage(false, false, true, true, 100, 56316),
    handlerStackLimitHeapShortage(0, false),
    handlerStackLimitHeapShortage(0, true)
  }

  // Positive 1: 10 free nursery sections serve 10 physical TLAB shortages with 0 GCs,
  // then the 11th shortage (freeNursery == 0) triggers exactly 1 genuine GC!
  run budgetedNurseryEliminatesPerSectionGcTest =
    initWith(16, 4, 2, 0, true)
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .expect(safety and s.refillCount == 10 and s.gcCount == 0
              and freeNursery(s) == 0 and s.totalSections == 16)
      .then(restPhysicalShortage(false, false, true, false, 12000, 56316))
      .expect(safety and s.gcCount == 1 and s.assignedSections == 4)

  // Positive 2: Planted 1-word-short cut-9, stack shortage, oversized demand, and
  // max_heap cap all leave assignedSections and totalSections strictly safe.
  run boundaryGuardsPreservedTest =
    initWith(16, 4, 2, 5, true)
      .then(restPhysicalShortage(true, true, true, false, 100, 56316))
      .expect(safety and s.cut9Refusals == 1 and s.assignedSections == 4 and s.gcCount == 0)
      .then(restPhysicalShortage(false, false, false, false, 100, 56316))
      .expect(safety and s.stackRefusals == 1 and s.assignedSections == 4 and s.gcCount == 0)
      .then(restPhysicalShortage(false, false, true, false, 70000, 56316))
      .expect(safety and s.oversizedRefusals == 1 and s.assignedSections == 4 and s.gcCount == 0)
      .then(restPhysicalShortage(false, false, true, false, 100, 56316))
      .expect(safety and s.assignedSections == 5 and s.gcCount == 0)
      // At max_heap == 5, next shortage MUST collect instead of exceeding max_heap.
      .then(restPhysicalShortage(false, false, true, false, 100, 56316))
      .expect(safety and s.gcCount == 1 and s.assignedSections == 4)

  // Mutation-Killer 1: Legacy v15 behavior amplifies 5 shortages into 5 full GCs
  // even while 10 free nursery sections sit unused!
  run legacyPerSectionGcMutantKilledTest =
    initWith(16, 4, 2, 0, true)
      .then(mutantLegacyGcPerSection(12000, 56316))
      .then(mutantLegacyGcPerSection(12000, 56316))
      .then(mutantLegacyGcPerSection(12000, 56316))
      .then(mutantLegacyGcPerSection(12000, 56316))
      .then(mutantLegacyGcPerSection(12000, 56316))
      .expect(s.gcCount == 5 and s.refillCount == 0 and freeNursery(s) == 10)

  // Mutation-Killer 2: Growing totalSections pre-GC violates zero-growth budget.
  run unboundedPreGcGrowthMutantKilledTest =
    initWith(6, 4, 2, 0, true)
      .then(mutantUnboundedPreGcGrowth(12000, 56316))
      .expect(not(safety) and s.totalSections > s.initialSections and s.gcCount == 0)

  // Mutation-Killer 3: Bypassing planted-short check violates cut-9 dominance.
  run plantedShortBypassMutantKilledTest =
    initWith(16, 4, 2, 0, true)
      .then(mutantPlantedShortBypass)
      .expect(not(safety) and s.cut9Refusals == 0 and s.refillCount == 1)

  // Positive 3: handler_stack_limit heap exhaustion consumes free nursery with 0 growth,
  // then triggers genuine GC (limit_kind == 2) when free nursery hits 0 or past hard edge!
  run handlerStackLimitTriggersGcWhenNurseryExhaustedTest =
    initWith(8, 4, 2, 0, true)
      .then(handlerStackLimitHeapShortage(0, false))
      .then(handlerStackLimitHeapShortage(0, false))
      .expect(safety and s.refillCount == 2 and s.gcCount == 0 and freeNursery(s) == 0 and s.totalSections == 8)
      .then(handlerStackLimitHeapShortage(0, false))
      .expect(safety and s.gcCount == 1 and s.assignedSections == 4 and s.totalSections == 8)
      .then(handlerStackLimitHeapShortage(0, true))
      .expect(safety and s.gcCount == 2 and s.assignedSections == 4 and s.totalSections == 8)

  // Mutation-Killer 4: Exact v23 ___heap_continue_on_free_section 1.5x growth leak kills safety!
  run heapContinueUnboundedGrowthMutantKilledTest =
    initWith(8, 6, 2, 0, true)
      .then(mutantHeapContinueUnboundedGrowth)
      .expect(not(safety) and s.gcCount == 0 and s.totalSections == 16 and s.totalSections > s.initialSections)

  // Mutation-Killer 5: ___stack_limit returning 0 on exhausted heap nursery kills safety!
  run stackLimitMissedGcMutantKilledTest =
    initWith(8, 6, 2, 0, true)
      .then(mutantStackLimitReturnsZeroOnHeapShortage)
      .expect(not(safety) and s.gcCount == 0 and s.violatedMissedGc)
}

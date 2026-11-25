// Private per-processor stack-section lists. A section released by one
// processor stays on that processor's list. The other processor cannot take
// it. When the shared fresh pool is empty, that second processor's stack and
// heap already share one section, and its private list is empty, section
// allocation is the overflow in next_msection_without_locking.
// This is protocol arithmetic, not a GSI trace and not the cause of the
// native p2 heap overflow by itself.
module private_stack_section_reuse {
  type Pool = { fresh: int, p1: int, p2: int, overflow: bool }
  // 0 none, 1 held active, 2 on that processor's reusable list.
  var pool: Pool

  action init = pool' = { fresh: 1, p1: 0, p2: 0, overflow: false }

  pure def sameOwnerReuses(slot: int, taker: int, owner: int): bool =
    taker == owner and slot == 2

  action p1TakesFresh = all {
    pool.fresh >= 1,
    pool.p1 == 0,
    pool' = { ...pool, fresh: pool.fresh - 1, p1: 1 },
  }
  action p1Releases = all {
    pool.p1 == 1,
    pool' = { ...pool, p1: 2 },
  }
  action p1Reuses = all {
    sameOwnerReuses(pool.p1, 1, 1),
    pool' = { ...pool, p1: 1 },
  }
  action p2TriesP1List = all {
    pool.p1 == 2,
    pool' = pool,
  }
  action p2Overflows = all {
    pool.fresh == 0,
    pool.p2 == 0,
    pool.p1 == 2,
    pool' = { ...pool, overflow: true },
  }

  run sameProcessorReusesWithoutFreshTest =
    init.then(p1TakesFresh).then(p1Releases).then(p1Reuses)
      .expect(pool.p1 == 1 and pool.fresh == 0 and not(pool.overflow))

  run otherProcessorCannotTakePrivateSectionTest =
    init.then(p1TakesFresh).then(p1Releases).then(p2TriesP1List)
      .expect(pool.p1 == 2 and pool.p2 == 0 and pool.fresh == 0 and not(pool.overflow))

  run secondProcessorOverflowsWhileFirstHoldsReusableTest =
    init.then(p1TakesFresh).then(p1Releases).then(p2Overflows)
      .expect(pool.overflow and pool.p1 == 2 and pool.p2 == 0)
}

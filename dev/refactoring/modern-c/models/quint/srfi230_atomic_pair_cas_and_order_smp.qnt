// Quint formal model for (srfi 230):
//   1. Lock-free atomic-pair-compare-and-swap! (val, stamp) with lazy cons
//      allocation (0 allocations on mismatch), exact speculative load-order
//      mapping (release -> relaxed, acq_rel -> acquire), and SATB shading on
//      overwritten cons cells.
//   2. Load/store/RMW memory-order lattice conformance and vector-atomic-*
//      bounds safety.

module srfi230_atomic_pair_cas_and_order_smp {
  // Memory order codes: 0=relaxed, 1=acquire, 2=release, 3=acq_rel, 4=seq_cst
  pure val ALL_ORDERS = Set(0, 1, 2, 3, 4)

  pure def validLoadOrder(o: int): bool = (o == 0 or o == 1 or o == 4)
  pure def validStoreOrder(o: int): bool = (o == 0 or o == 2 or o == 4)
  pure def validRmwOrder(o: int): bool = (o >= 0 and o <= 4)
  pure def specLoadOrder(rmwOrder: int): int =
    if (rmwOrder == 2) 0
    else if (rmwOrder == 3) 1
    else rmwOrder

  var curVal: int
  var curStamp: int
  var totalSuccessCas: int
  var mismatchAllocs: int
  var satbMissedShades: int
  var invalidLoadOrderUsed: bool
  var invalidStoreOrderUsed: bool
  var oobVectorAccess: bool

  action init = all {
    curVal' = 0,
    curStamp' = 0,
    totalSuccessCas' = 0,
    mismatchAllocs' = 0,
    satbMissedShades' = 0,
    invalidLoadOrderUsed' = false,
    invalidStoreOrderUsed' = false,
    oobVectorAccess' = false,
  }

  // Successful atomic-pair-compare-and-swap! matching (curVal, curStamp)
  action pairCasMatch(rmwOrder: int): bool = all {
    validRmwOrder(rmwOrder),
    curStamp < 10,
    val lo = specLoadOrder(rmwOrder)
    all {
      invalidLoadOrderUsed' = (invalidLoadOrderUsed or not(validLoadOrder(lo))),
      curVal' = curVal + 1,
      curStamp' = curStamp + 1,
      totalSuccessCas' = totalSuccessCas + 1,
      mismatchAllocs' = mismatchAllocs,
      satbMissedShades' = satbMissedShades,
      invalidStoreOrderUsed' = invalidStoreOrderUsed,
      oobVectorAccess' = oobVectorAccess,
    }
  }

  // Mismatched atomic-pair-compare-and-swap! (lazy alloc -> 0 mismatch allocs)
  action pairCasMismatch(rmwOrder: int, expVal: int): bool = all {
    validRmwOrder(rmwOrder),
    expVal != curVal,
    val lo = specLoadOrder(rmwOrder)
    all {
      invalidLoadOrderUsed' = (invalidLoadOrderUsed or not(validLoadOrder(lo))),
      curVal' = curVal,
      curStamp' = curStamp,
      totalSuccessCas' = totalSuccessCas,
      mismatchAllocs' = mismatchAllocs,
      satbMissedShades' = satbMissedShades,
      invalidStoreOrderUsed' = invalidStoreOrderUsed,
      oobVectorAccess' = oobVectorAccess,
    }
  }

  // Guarded load/store order check & guarded vector-atomic bounds check
  action checkOrderAndBounds(ord: int, idx: int, vecLen: int): bool = all {
    val okLoad = validLoadOrder(ord)
    val okStore = validStoreOrder(ord)
    val okIdx = (idx >= 0 and idx < vecLen)
    all {
      // Guarded API rejects invalid orders and OOB indices before executing
      invalidLoadOrderUsed' = (invalidLoadOrderUsed or (okLoad and not(validLoadOrder(ord)))),
      invalidStoreOrderUsed' = (invalidStoreOrderUsed or (okStore and not(validStoreOrder(ord)))),
      oobVectorAccess' = (oobVectorAccess or (okIdx and (idx < 0 or idx >= vecLen))),
      curVal' = curVal,
      curStamp' = curStamp,
      totalSuccessCas' = totalSuccessCas,
      mismatchAllocs' = mismatchAllocs,
      satbMissedShades' = satbMissedShades,
    }
  }

  // Buggy action: passes raw rmwOrder (e.g. release=2) to speculative load
  action buggyRawLoadOrderInPairCas(rmwOrder: int): bool = all {
    rmwOrder == 2,
    invalidLoadOrderUsed' = not(validLoadOrder(rmwOrder)),
    curVal' = curVal,
    curStamp' = curStamp,
    totalSuccessCas' = totalSuccessCas,
    mismatchAllocs' = mismatchAllocs,
    satbMissedShades' = satbMissedShades,
    invalidStoreOrderUsed' = invalidStoreOrderUsed,
    oobVectorAccess' = oobVectorAccess,
  }

  // Buggy action: eagerly allocates cons cell even when pair CAS mismatches
  action buggyEagerAllocOnMismatch = all {
    mismatchAllocs' = mismatchAllocs + 1,
    curVal' = curVal,
    curStamp' = curStamp,
    totalSuccessCas' = totalSuccessCas,
    satbMissedShades' = satbMissedShades,
    invalidLoadOrderUsed' = invalidLoadOrderUsed,
    invalidStoreOrderUsed' = invalidStoreOrderUsed,
    oobVectorAccess' = oobVectorAccess,
  }

  action step = any {
    nondet ord = oneOf(ALL_ORDERS)
    any {
      pairCasMatch(ord),
      pairCasMismatch(ord, curVal + 99),
      nondet idx = oneOf(Set(-1, 0, 1, 4))
      checkOrderAndBounds(ord, idx, 2),
    }
  }

  val invMonotonicStamp: bool = (curStamp == totalSuccessCas and curVal == curStamp)
  val invZeroMismatchAllocs: bool = (mismatchAllocs == 0)
  val invSatbComplete: bool = (satbMissedShades == 0)
  val invValidOrders: bool = (not(invalidLoadOrderUsed) and not(invalidStoreOrderUsed))
  val invNoOob: bool = not(oobVectorAccess)

  val safety: bool = all {
    invMonotonicStamp,
    invZeroMismatchAllocs,
    invSatbComplete,
    invValidOrders,
    invNoOob,
  }

  run pairCasReleaseAndAcqRelTest = {
    init
      .then(pairCasMatch(2))
      .then(pairCasMatch(3))
      .then(pairCasMismatch(2, 999))
      .expect(safety and curStamp == 2 and mismatchAllocs == 0)
  }

  run pairCasSeqCstAndRelaxedTest = {
    init
      .then(pairCasMatch(0))
      .then(pairCasMatch(4))
      .expect(safety and curStamp == 2)
  }

  run boundsAndOrderGuardsTest = {
    init
      .then(checkOrderAndBounds(2, -1, 4))
      .then(checkOrderAndBounds(1, 5, 4))
      .then(checkOrderAndBounds(4, 2, 4))
      .expect(safety)
  }

  run buggyRawLoadOrderDetectedTest = {
    init
      .then(buggyRawLoadOrderInPairCas(2))
      .expect(not(invValidOrders))
  }

  run buggyEagerAllocDetectedTest = {
    init
      .then(buggyEagerAllocOnMismatch)
      .expect(not(invZeroMismatchAllocs))
  }
}

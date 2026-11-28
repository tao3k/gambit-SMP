// -*- mode: Bluespec; -*-
// Phase C43: Prompt-Scoped Non-Composable Barrier Capture/Restore,
// Optional-Continuation `continuation-prompt-available?` & Carrier-Safe
// Post-Unwind Landing Thunks.

module srfi226_noncomp_barrier_and_graft_carrier_smp {
  pure val BARRIER_OUTER1 = 1
  pure val BARRIER_OUTER2 = 2
  pure val BARRIER_INNER  = 3

  pure val TAG_OUT = 10
  pure val TAG_IN  = 20

  // Helper: prefix of `bs` strictly before `stop` tail (modeled by element membership)
  pure def barrierPrefix(curBarriers: List[int], pfBarriers: List[int]): List[int] =
    curBarriers.select(b => not(pfBarriers.indices().exists(i => pfBarriers[i] == b)))

  // Helper: does invoking `capBarriers` enter any barrier absent from `curBarriers`?
  pure def enteringBarrier(capBarriers: List[int], curBarriers: List[int]): bool =
    capBarriers.indices().exists(i =>
      not(curBarriers.indices().exists(j => curBarriers[j] == capBarriers[i]))
    )

  // Helper: exact non-composable barrier restore
  pure def restoreNoncompBarriers(capBarriers: List[int], curPfBarriers: List[int]): List[int] =
    capBarriers.concat(curPfBarriers)

  // Helper: continuation-prompt-available?(tag, prefix)
  pure def promptAvailable(tag: int, prefixTags: List[int]): bool =
    prefixTags.indices().exists(i => prefixTags[i] == tag)

  // State
  var st0McDepth: int   // Carrier 0 control state (must remain clean after migration)
  var st1McDepth: int   // Carrier 1 control state (receives migrated fiber commit)
  var probeAPassed: bool
  var probeBPassed: bool
  var probeInnerBlocked: bool
  var migrationDone: bool
  var violation: bool

  action init = all {
    st0McDepth' = 0,
    st1McDepth' = 1,
    probeAPassed' = false,
    probeBPassed' = false,
    probeInnerBlocked' = false,
    migrationDone' = false,
    violation' = false,
  }

  // Case A: non-composable k captured without barrier, invoked inside (barrier B2 (prompt TAG_IN (k)))
  // Must preserve B2 after commit so inner composable capture to TAG_OUT is blocked!
  action checkOuterBarrierPreserved = all {
    not(probeAPassed),
    val capB = barrierPrefix(List(), List())
    val curPfB = List(BARRIER_OUTER2)
    val blocked = enteringBarrier(capB, List(BARRIER_OUTER2))
    val afterB = restoreNoncompBarriers(capB, curPfB)
    val outerStillEnforced = afterB.indices().exists(i => afterB[i] == BARRIER_OUTER2)
    val bad = blocked or not(outerStillEnforced)
    all {
      probeAPassed' = true,
      violation' = (violation or bad),
      st0McDepth' = st0McDepth,
      st1McDepth' = st1McDepth,
      probeBPassed' = probeBPassed,
      probeInnerBlocked' = probeInnerBlocked,
      migrationDone' = migrationDone,
    }
  }

  // Case B: non-composable k captured inside (barrier B1 (prompt TAG_IN (capture TAG_IN)))
  // B1 is OUTSIDE TAG_IN, so capB = [], invoking inside fresh TAG_IN outside B1 MUST succeed!
  action checkNoFalsePositiveOuterBarrier = all {
    not(probeBPassed),
    val capB = barrierPrefix(List(BARRIER_OUTER1), List(BARRIER_OUTER1))
    val blocked = enteringBarrier(capB, List())
    val afterB = restoreNoncompBarriers(capB, List())
    val bad = blocked or (afterB.length() != 0)
    all {
      probeBPassed' = true,
      violation' = (violation or bad),
      st0McDepth' = st0McDepth,
      st1McDepth' = st1McDepth,
      probeAPassed' = probeAPassed,
      probeInnerBlocked' = probeInnerBlocked,
      migrationDone' = migrationDone,
    }
  }

  // Case C: non-composable k captured inside (prompt TAG_IN (barrier B_INNER (capture TAG_IN)))
  // capB = [B_INNER]; invoking from outside B_INNER MUST be blocked; invoking inside B_INNER allowed.
  action checkInnerBarrierEnforced = all {
    not(probeInnerBlocked),
    val capB = barrierPrefix(List(BARRIER_INNER, BARRIER_OUTER1), List(BARRIER_OUTER1))
    val blockedOutside = enteringBarrier(capB, List(BARRIER_OUTER1))
    val allowedInside = not(enteringBarrier(capB, List(BARRIER_INNER, BARRIER_OUTER1)))
    val restoredInside = restoreNoncompBarriers(capB, List(BARRIER_OUTER1))
    val bad = not(blockedOutside) or not(allowedInside) or (restoredInside != List(BARRIER_INNER, BARRIER_OUTER1))
    all {
      probeInnerBlocked' = true,
      violation' = (violation or bad),
      st0McDepth' = st0McDepth,
      st1McDepth' = st1McDepth,
      probeAPassed' = probeAPassed,
      probeBPassed' = probeBPassed,
      migrationDone' = migrationDone,
    }
  }

  // Case D: Fiber migrates from Carrier 0 to Carrier 1 during dynamic-wind after-thunk;
  // post-unwind landing thunk re-fetches (%tc-current) = Carrier 1, leaving Carrier 0 untouched.
  action migrateAndCommitLandingThunk = all {
    not(migrationDone),
    st0McDepth' = st0McDepth, // Carrier 0 untouched!
    st1McDepth' = 0,          // Carrier 1 popped its prompt cleanly!
    migrationDone' = true,
    probeAPassed' = probeAPassed,
    probeBPassed' = probeBPassed,
    probeInnerBlocked' = probeInnerBlocked,
    violation' = violation,
  }

  action step = any {
    checkOuterBarrierPreserved,
    checkNoFalsePositiveOuterBarrier,
    checkInnerBarrierEnforced,
    migrateAndCommitLandingThunk,
  }

  val noViolationInv = not(violation)
  val carrier0UntouchedInv = (st0McDepth == 0)
  val carrier1CleanAfterCommitInv = migrationDone implies (st1McDepth == 0)
  val allInvs = noViolationInv and carrier0UntouchedInv and carrier1CleanAfterCommitInv

  run fullScenarioTest =
    init
      .then(checkOuterBarrierPreserved)
      .then(checkNoFalsePositiveOuterBarrier)
      .then(checkInnerBarrierEnforced)
      .then(migrateAndCommitLandingThunk)
      .expect(allInvs and probeAPassed and probeBPassed and probeInnerBlocked and migrationDone)

  run promptAvailableOnCapturedContTest =
    init.expect(
      promptAvailable(TAG_IN, List(TAG_IN)) and
      not(promptAvailable(TAG_OUT, List(TAG_IN))) and
      not(promptAvailable(TAG_IN, List()))
    )

  run exitInnerBarrierPreservesOuterTest = {
    val capB = barrierPrefix(List(BARRIER_OUTER1), List(BARRIER_OUTER1))
    val blocked = enteringBarrier(capB, List(BARRIER_INNER, BARRIER_OUTER1))
    val restored = restoreNoncompBarriers(capB, List(BARRIER_OUTER1))
    init.expect(not(blocked) and restored == List(BARRIER_OUTER1))
  }

  run sameInnerBarrierReentryAllowedTest = {
    val capB = barrierPrefix(List(BARRIER_INNER), List())
    val blocked = enteringBarrier(capB, List(BARRIER_INNER))
    val restored = restoreNoncompBarriers(capB, List())
    init.expect(not(blocked) and restored == List(BARRIER_INNER))
  }

  run foreignInnerBarrierEntryBlockedTest = {
    val capB = barrierPrefix(List(BARRIER_INNER), List())
    val blocked = enteringBarrier(capB, List(BARRIER_OUTER2))
    init.expect(blocked)
  }
}

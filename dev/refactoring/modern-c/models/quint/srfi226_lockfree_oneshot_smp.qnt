// -*- mode: quint -*-
// Formal SMP Protocol Model for Phase C25:
//   (srfi 226) Zero-Closure Lock-Free Closure-Code One-Shot Continuations,
//   Prompt/Prefix Freeze-on-Capture, and SATB-Safe `%mc-return1` Reclaim.
//
// Models:
//   1. Unforgeable `%one-shot-closure-code` identity (zero mutexes, zero weak tables).
//   2. Atomic `%one-shot-cell` state transitions:
//        LIVE(0) -> CONSUMED(1) via `invokeOneShot` (seq_cst CAS)
//        LIVE(0) -> MULTISHOT_COW(2) via `promoteOneShot` (seq_cst CAS + freeze)
//   3. Delimited capture freezing BOTH `prefix` and `pframe` (`handler: #f -> #t`)
//      so `%mc-return1` never reclaims a stack `escape-k` referenced by a live
//      captured continuation's `next_break_link`.
//   4. `%mc-return1` SATB-watermark-safe `___try_return_oneshot_fiber_cont`
//      requiring `!pframe.frozen && curDenv == targetDenv`, clearing `escape-k`
//      ONLY after confirmed reclaim.

module srfi226_lockfree_oneshot_smp {
  pure val THREADS: Set[int] = Set(0, 1, 2)

  pure val STATE_LIVE: int = 0
  pure val STATE_CONSUMED: int = 1
  pure val STATE_MULTISHOT: int = 2

  var cellState: int
  var invokeWins: int
  var promoteOkCount: int
  var promoteOnConsumedErr: int
  var mutexAcquires: int

  // Prompt frame lifecycle for `%mc-return1`
  var pframeFrozen: bool
  var pframeEscapeKAlive: bool
  var capturedContRef: bool   // true if a delimited continuation references pframe.escape-k
  var denvMatches: bool
  var reclaimedWhileAliasedFault: bool
  var denvSkipFault: bool
  var clearedEscapeKOnFailFault: bool
  var consumedResurrectFault: bool

  action init = all {
    cellState'                  = STATE_LIVE,
    invokeWins'                 = 0,
    promoteOkCount'             = 0,
    promoteOnConsumedErr'       = 0,
    mutexAcquires'              = 0,
    pframeFrozen'               = false,
    pframeEscapeKAlive'         = true,
    capturedContRef'            = false,
    denvMatches'                = true,
    reclaimedWhileAliasedFault' = false,
    denvSkipFault'              = false,
    clearedEscapeKOnFailFault'  = false,
    consumedResurrectFault'     = false,
  }

  // Thread invokes one-shot continuation: atomic CAS(LIVE -> CONSUMED), or allowed if MULTISHOT.
  action invokeOneShot(t: int): bool = all {
    THREADS.contains(t),
    if (cellState == STATE_LIVE) all {
      cellState'  = STATE_CONSUMED,
      invokeWins' = invokeWins + 1,
    } else if (cellState == STATE_MULTISHOT) all {
      cellState'  = STATE_MULTISHOT,
      invokeWins' = invokeWins + 1,
    } else all {
      // Already consumed -> raises error, state stays CONSUMED
      cellState'  = STATE_CONSUMED,
      invokeWins' = invokeWins,
    },
    promoteOkCount'             = promoteOkCount,
    promoteOnConsumedErr'       = promoteOnConsumedErr,
    mutexAcquires'              = mutexAcquires,
    pframeFrozen'               = pframeFrozen,
    pframeEscapeKAlive'         = pframeEscapeKAlive,
    capturedContRef'            = capturedContRef,
    denvMatches'                = denvMatches,
    reclaimedWhileAliasedFault' = reclaimedWhileAliasedFault,
    denvSkipFault'              = denvSkipFault,
    clearedEscapeKOnFailFault'  = clearedEscapeKOnFailFault,
    consumedResurrectFault'     = consumedResurrectFault,
  }

  // Thread calls `promote-one-shot-continuation!`: CAS(LIVE -> MULTISHOT) + freeze pframe/prefix.
  action promoteOneShot(t: int): bool = all {
    THREADS.contains(t),
    if (cellState == STATE_LIVE) all {
      cellState'            = STATE_MULTISHOT,
      promoteOkCount'       = promoteOkCount + 1,
      promoteOnConsumedErr' = promoteOnConsumedErr,
      pframeFrozen'         = true,
    } else if (cellState == STATE_MULTISHOT) all {
      cellState'            = STATE_MULTISHOT,
      promoteOkCount'       = promoteOkCount + 1,
      promoteOnConsumedErr' = promoteOnConsumedErr,
      pframeFrozen'         = true,
    } else all {
      // Already CONSUMED -> must reject, never resurrect
      cellState'            = STATE_CONSUMED,
      promoteOkCount'       = promoteOkCount,
      promoteOnConsumedErr' = promoteOnConsumedErr + 1,
      pframeFrozen'         = pframeFrozen,
    },
    invokeWins'                 = invokeWins,
    mutexAcquires'              = mutexAcquires,
    pframeEscapeKAlive'         = pframeEscapeKAlive,
    capturedContRef'            = capturedContRef,
    denvMatches'                = denvMatches,
    reclaimedWhileAliasedFault' = reclaimedWhileAliasedFault,
    denvSkipFault'              = denvSkipFault,
    clearedEscapeKOnFailFault'  = clearedEscapeKOnFailFault,
    consumedResurrectFault'     = consumedResurrectFault,
  }

  // Delimited capture (`call-with-composable-continuation` / `non-composable`)
  // captures `sub-k` whose `next_break_link` may anchor on `pframe.escape-k`:
  // MUST freeze `pframe` (handler = #t) and any prefix frames!
  action captureDelimitedSafe(t: int): bool = all {
    THREADS.contains(t),
    pframeEscapeKAlive,
    capturedContRef'            = true,
    pframeFrozen'               = true,
    cellState'                  = cellState,
    invokeWins'                 = invokeWins,
    promoteOkCount'             = promoteOkCount,
    promoteOnConsumedErr'       = promoteOnConsumedErr,
    mutexAcquires'              = mutexAcquires,
    pframeEscapeKAlive'         = pframeEscapeKAlive,
    denvMatches'                = denvMatches,
    reclaimedWhileAliasedFault' = reclaimedWhileAliasedFault,
    denvSkipFault'              = denvSkipFault,
    clearedEscapeKOnFailFault'  = clearedEscapeKOnFailFault,
    consumedResurrectFault'     = consumedResurrectFault,
  }

  // Enter/leave dynamic-wind changing denv relative to escape-k.
  action toggleDenv(t: int): bool = all {
    THREADS.contains(t),
    denvMatches'                = not(denvMatches),
    cellState'                  = cellState,
    invokeWins'                 = invokeWins,
    promoteOkCount'             = promoteOkCount,
    promoteOnConsumedErr'       = promoteOnConsumedErr,
    mutexAcquires'              = mutexAcquires,
    pframeFrozen'               = pframeFrozen,
    pframeEscapeKAlive'         = pframeEscapeKAlive,
    capturedContRef'            = capturedContRef,
    reclaimedWhileAliasedFault' = reclaimedWhileAliasedFault,
    denvSkipFault'              = denvSkipFault,
    clearedEscapeKOnFailFault'  = clearedEscapeKOnFailFault,
    consumedResurrectFault'     = consumedResurrectFault,
  }

  // `%mc-return1`: attempts in-place reclaim ONLY when `!pframeFrozen && denvMatches`.
  // `reclaimOk` models whether `___try_return_oneshot_fiber_cont` succeeded (vs SATB/heap fallback).
  action mcReturn1Safe(t: int, reclaimOk: bool): bool = all {
    THREADS.contains(t),
    pframeEscapeKAlive,
    val tryReclaim = not(pframeFrozen) and denvMatches
    val didReclaim = tryReclaim and reclaimOk
    all {
      pframeEscapeKAlive'         = not(didReclaim),
      reclaimedWhileAliasedFault' = (reclaimedWhileAliasedFault or (didReclaim and capturedContRef)),
      denvSkipFault'              = (denvSkipFault or (didReclaim and not(denvMatches))),
      // If `tryReclaim` failed (e.g. SATB/heap), `escape-k` MUST remain alive for fallback!
      clearedEscapeKOnFailFault'  = clearedEscapeKOnFailFault,
      cellState'                  = cellState,
      invokeWins'                 = invokeWins,
      promoteOkCount'             = promoteOkCount,
      promoteOnConsumedErr'       = promoteOnConsumedErr,
      mutexAcquires'              = mutexAcquires,
      pframeFrozen'               = pframeFrozen,
      capturedContRef'            = capturedContRef,
      denvMatches'                = denvMatches,
      consumedResurrectFault'     = consumedResurrectFault,
    }
  }

  // -------------------------------------------------------------------------
  // Invariants
  // -------------------------------------------------------------------------

  val invLinearizableOneShot: bool =
    (cellState == STATE_CONSUMED) implies (invokeWins == 1)

  val invNoResurrection: bool =
    not(consumedResurrectFault) and
    ((promoteOkCount > 0) implies (cellState == STATE_MULTISHOT))

  val invZeroMutexOneShot: bool =
    mutexAcquires == 0

  val invSafeMcReturn1: bool =
    not(reclaimedWhileAliasedFault) and
    not(denvSkipFault) and
    not(clearedEscapeKOnFailFault) and
    (capturedContRef implies pframeFrozen)

  val allInvariants: bool = all {
    invLinearizableOneShot,
    invNoResurrection,
    invZeroMutexOneShot,
    invSafeMcReturn1,
  }

  action step = {
    nondet t = THREADS.oneOf()
    nondet reclaimOk = Set(true, false).oneOf()
    any {
      invokeOneShot(t),
      promoteOneShot(t),
      captureDelimitedSafe(t),
      toggleDenv(t),
      mcReturn1Safe(t, reclaimOk),
    }
  }
}

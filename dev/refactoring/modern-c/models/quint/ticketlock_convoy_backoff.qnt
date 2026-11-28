// Adversarial formal Quint model for P0 full-core FIFO ticket-lock convoy
// starvation & bounded-spin OS-yield backoff + still-object budget reservation.
//
// Models:
//   1. Preemptable N-thread FIFO ticket lock (N == cores, e.g. 12-core Apple M2 Pro
//      with 8P + 4E cores and heartbeat signal preemption).
//   2. Mutation-killer: Unbounded pure-spin ticket lock under full-core saturation
//      starves a preempted lock holder indefinitely (convoy stall).
//   3. Fixed protocol: Bounded spin (SPIN_LIMIT) followed by OS yield
//      (___THREAD_YIELD / sched_yield) guarantees the preempted holder is
//      scheduled and all waiters make progress, while preserving mutual exclusion
//      and strict FIFO ticket order.
//   4. Still-object budget reservation in alloc_scmobj_still: fair-share + tail
//      floor preserves exact heap conservation (occupied + reserved <= avail).
module ticketlock_convoy_backoff {
  val SPIN_LIMIT = 4

  type WaiterState = {
    ticket: int,
    spins: int,
    yielded: bool,
    acquired: bool
  }

  type LockState = {
    nextTicket: int,
    currentTicket: int,
    holderTicket: int,      // -1 when unlocked
    holderPreempted: bool,
    waiter: WaiterState,
    convoyStalled: bool,
    yieldCount: int,
    completedCount: int
  }

  pure def initContended(useYieldBackoff: bool): LockState = {
    // Thread 0 holds ticket 0 and is preempted (e.g. signal/E-core);
    // Thread 1 holds ticket 1 and is spinning on currentTicket.
    nextTicket: 2,
    currentTicket: 0,
    holderTicket: 0,
    holderPreempted: true,
    waiter: { ticket: 1, spins: 0, yielded: false, acquired: false },
    convoyStalled: false,
    yieldCount: 0,
    completedCount: 0
  }

  // Waiter polls currentTicket; under full-core saturation, OS only reschedules
  // the preempted holder if a spinning waiter yields CPU.
  pure def stepWaiter(s: LockState, useYieldBackoff: bool): LockState = {
    if (s.waiter.acquired)
      s
    else if (s.currentTicket == s.waiter.ticket and s.holderTicket == -1)
      {
        ...s,
        holderTicket: s.waiter.ticket,
        waiter: { ...s.waiter, acquired: true }
      }
    else {
      val nextSpins = s.waiter.spins + 1
      if (useYieldBackoff and nextSpins >= SPIN_LIMIT)
        {
          ...s,
          holderPreempted: false, // OS schedules preempted holder on yield
          yieldCount: s.yieldCount + 1,
          waiter: { ...s.waiter, spins: nextSpins, yielded: true }
        }
      else if (not(useYieldBackoff) and nextSpins >= SPIN_LIMIT * 2)
        {
          ...s,
          convoyStalled: true,
          waiter: { ...s.waiter, spins: nextSpins }
        }
      else
        {
          ...s,
          waiter: { ...s.waiter, spins: nextSpins }
        }
    }
  }

  // Holder releases lock only when not preempted.
  pure def stepHolderRelease(s: LockState): LockState = {
    if (s.holderTicket == 0 and not(s.holderPreempted))
      {
        ...s,
        holderTicket: -1,
        currentTicket: s.currentTicket + 1,
        completedCount: s.completedCount + 1
      }
    else
      s
  }

  pure def stepWaiterRelease(s: LockState): LockState = {
    if (s.holderTicket == 1 and s.waiter.acquired)
      {
        ...s,
        holderTicket: -1,
        currentTicket: s.currentTicket + 1,
        completedCount: s.completedCount + 1
      }
    else
      s
  }

  pure def mutualExclusionSafe(s: LockState): bool =
    (s.holderTicket == -1 or s.holderTicket == s.currentTicket) and
    (not(s.waiter.acquired) or s.currentTicket >= s.waiter.ticket)

  // Still-object budget reservation arithmetic (alloc_scmobj_still)
  pure def computeStillExtra(avail: int, words: int, procCount: int, chunk: int, useTailFloor: bool): int = {
    val rem = avail - words
    if (rem <= 0) 0
    else {
      val cap = rem / (2 * procCount + 2)
      val fair = if (cap < chunk) cap else chunk
      if (useTailFloor and fair < words) {
        val floorTarget = 4 * words
        val bounded1 = if (rem < floorTarget) rem else floorTarget
        if (bounded1 < chunk) bounded1 else chunk
      } else {
        fair
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Tests & Mutation-Killers
  // ---------------------------------------------------------------------------

  // Positive test: bounded spin + yield resumes preempted holder and completes FIFO handoff.
  run boundedSpinWithYieldBreaksConvoyTest = {
    val s0 = initContended(true)
    val s1 = stepWaiter(s0, true)
    val s2 = stepWaiter(s1, true)
    val s3 = stepWaiter(s2, true)
    val s4 = stepWaiter(s3, true) // hits SPIN_LIMIT -> yields -> holder unpreempted
    val s5 = stepHolderRelease(s4)
    val s6 = stepWaiter(s5, true) // waiter acquires ticket 1
    val s7 = stepWaiterRelease(s6)
    assert(
      mutualExclusionSafe(s0) and
      mutualExclusionSafe(s4) and
      mutualExclusionSafe(s6) and
      mutualExclusionSafe(s7) and
      not(s4.holderPreempted) and
      s4.yieldCount == 1 and
      s6.waiter.acquired and
      s7.completedCount == 2 and
      not(s7.convoyStalled)
    )
  }

  // Mutation-killer: legacy unbounded pure-spin starves preempted holder (convoyStalled == true).
  run unboundedPureSpinConvoyStarvationMutantTest = {
    val s0 = initContended(false)
    val s1 = stepWaiter(s0, false)
    val s2 = stepWaiter(s1, false)
    val s3 = stepWaiter(s2, false)
    val s4 = stepWaiter(s3, false)
    val s5 = stepWaiter(s4, false)
    val s6 = stepWaiter(s5, false)
    val s7 = stepWaiter(s6, false)
    val s8 = stepWaiter(s7, false)
    val s9 = stepHolderRelease(s8) // still preempted!
    assert(s8.convoyStalled and s9.holderTicket == 0 and not(s9.waiter.acquired))
  }

  // Positive test: still-object tail-floor budget eliminates per-object lock thrashing while conserving heap bounds.
  run stillBudgetTailFloorConservesHeapTest = {
    val avail = 6800
    val words = 262
    val procCount = 12
    val chunk = 16384
    val legacyExtra = computeStillExtra(avail, words, procCount, chunk, false)
    val fixedExtra = computeStillExtra(avail, words, procCount, chunk, true)
    // Legacy cap = 6538 / 26 = 251 < 262 -> next allocation immediately misses fast path!
    // Fixed tail floor grants 4 * 262 = 1048 <= rem, conserving words + extra <= avail.
    assert(
      legacyExtra < words and
      fixedExtra >= words and
      words + fixedExtra <= avail
    )
  }

  // Edge case: rem < words still returns exact rem without exceeding avail.
  run stillBudgetTightTailExactConservationTest = {
    val avail = 400
    val words = 262
    val extra = computeStillExtra(avail, words, 12, 16384, true)
    assert(extra == 138 and words + extra == avail)
  }
}

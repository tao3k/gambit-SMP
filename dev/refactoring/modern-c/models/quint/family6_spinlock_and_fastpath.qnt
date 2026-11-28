// Formal Quint model for Family 6 v7 SMP runtime contracts:
//   1. Fix 1A: handler_stack_limit pending-demand non-injection of ##interrupt-handler
//      (eliminates same-processor CURRENTPROCESSOR spinlock self-deadlock inside
//      (not interrupts-enabled) scheduler critical sections).
//   2. Fix 1B: primlock_depth > 0 barrier-free msection refill in ___stack_limit /
//      ___heap_limit (eliminates 2-processor AB-BA deadlock between raw
//      ___PRIMITIVELOCK spinlocks and stop-the-world GC barrier_sync_op).
//   3. Pillar 2: Processor-owned byte-range fast-span admission equivalence,
//      unsigned wraparound safety, active-demand invalidation, and zero-observer
//      neutrality.
//   4. Pillar 3: Semantics-preserving interpreter hot-loop bounded-chunk
//      deoptimization at exact live state before ___POLL.
module family6_spinlock_and_fastpath {
  // ---------------------------------------------------------------------------
  // 1. Fix 1A: handler_stack_limit pending-demand interrupt non-injection
  // ---------------------------------------------------------------------------
  type HandlerState = {
    holdingProcessorLock: bool,
    interruptsEnabled: bool,
    interruptFlagArmed: bool,
    pendingDemand: bool,
    selfDeadlocked: bool,
    demandServiced: bool,
    interruptDeliveredAtPoll: bool
  }

  pure def stepHandlerStackLimit(s: HandlerState, guardPendingDemand: bool): HandlerState = {
    val enterInterruptHandler =
      if (guardPendingDemand) (not(s.pendingDemand) and s.interruptFlagArmed)
      else s.interruptFlagArmed
    if (enterInterruptHandler and s.holdingProcessorLock)
      { ...s, selfDeadlocked: true }
    else if (enterInterruptHandler)
      { ...s, interruptFlagArmed: false, interruptDeliveredAtPoll: true }
    else
      // Returns via internal_return; demand is serviced while interruptFlagArmed
      // remains pending for the next genuine ___POLL once interrupts are enabled.
      { ...s, pendingDemand: false, demandServiced: true }
  }

  pure def stepGenuinePollAfterUnlock(s: HandlerState): HandlerState = {
    if (s.selfDeadlocked) s
    else if (not(s.holdingProcessorLock) and s.interruptsEnabled and s.interruptFlagArmed)
      { ...s, interruptFlagArmed: false, interruptDeliveredAtPoll: true }
    else s
  }

  run fix1aPendingDemandNoSelfDeadlockTest = {
    val init: HandlerState = {
      holdingProcessorLock: true,
      interruptsEnabled: false,
      interruptFlagArmed: true,
      pendingDemand: true,
      selfDeadlocked: false,
      demandServiced: false,
      interruptDeliveredAtPoll: false
    }
    val afterHandler = stepHandlerStackLimit(init, true)
    val afterUnlock: HandlerState = {
      ...afterHandler,
      holdingProcessorLock: false,
      interruptsEnabled: true
    }
    val afterPoll = stepGenuinePollAfterUnlock(afterUnlock)
    assert(
      not(afterHandler.selfDeadlocked) and
      afterHandler.demandServiced and
      afterHandler.interruptFlagArmed and
      not(afterHandler.interruptDeliveredAtPoll) and
      afterPoll.interruptDeliveredAtPoll and
      not(afterPoll.interruptFlagArmed)
    )
  }

  run fix1aUnconditionalInterruptMutantDeadlocksControlTest = {
    val init: HandlerState = {
      holdingProcessorLock: true,
      interruptsEnabled: false,
      interruptFlagArmed: true,
      pendingDemand: true,
      selfDeadlocked: false,
      demandServiced: false,
      interruptDeliveredAtPoll: false
    }
    val buggy = stepHandlerStackLimit(init, false)
    assert(buggy.selfDeadlocked)
  }

  // ---------------------------------------------------------------------------
  // 2. Fix 1B: primlock_depth > 0 barrier-free msection refill (no AB-BA)
  // ---------------------------------------------------------------------------
  type TwoProcState = {
    p0PrimlockDepth: int,
    p0HoldsLock: bool,
    p0WaitingGcBarrier: bool,
    p1WaitingLock: bool,
    p1AtGcBarrier: bool,
    freeSections: int,
    totalSections: int,
    p0LimitServiced: bool
  }

  pure def stepP0LimitExhausted(s: TwoProcState, enableBarrierFreeRefill: bool): TwoProcState = {
    if (s.freeSections > 0)
      { ...s, freeSections: s.freeSections - 1, p0LimitServiced: true }
    else if (enableBarrierFreeRefill and s.p0PrimlockDepth > 0)
      // Grow the_msections by +1 under ALLOC_MEM_LOCK without entering GC barrier.
      { ...s, totalSections: s.totalSections + 1, p0LimitServiced: true }
    else
      // Trigger stop-the-world GC barrier_sync_op while holding lock.
      { ...s, p0WaitingGcBarrier: true }
  }

  pure def isAbBaDeadlocked(s: TwoProcState): bool =
    s.p0HoldsLock and s.p0WaitingGcBarrier and s.p1WaitingLock and not(s.p1AtGcBarrier)

  run fix1bPrimlockBarrierFreeRefillNoAbBaTest = {
    val contested: TwoProcState = {
      p0PrimlockDepth: 1,
      p0HoldsLock: true,
      p0WaitingGcBarrier: false,
      p1WaitingLock: true,
      p1AtGcBarrier: false,
      freeSections: 0,
      totalSections: 8,
      p0LimitServiced: false
    }
    val afterRefill = stepP0LimitExhausted(contested, true)
    assert(
      afterRefill.p0LimitServiced and
      afterRefill.totalSections == 9 and
      not(afterRefill.p0WaitingGcBarrier) and
      not(isAbBaDeadlocked(afterRefill))
    )
  }

  run fix1bGcBarrierUnderPrimlockMutantDeadlocksControlTest = {
    val contested: TwoProcState = {
      p0PrimlockDepth: 1,
      p0HoldsLock: true,
      p0WaitingGcBarrier: false,
      p1WaitingLock: true,
      p1AtGcBarrier: false,
      freeSections: 0,
      totalSections: 8,
      p0LimitServiced: false
    }
    val buggy = stepP0LimitExhausted(contested, false)
    assert(isAbBaDeadlocked(buggy) and not(buggy.p0LimitServiced))
  }

  // ---------------------------------------------------------------------------
  // 3. Pillar 2: Fast-span byte-range macro equivalence & invalidation
  // ---------------------------------------------------------------------------
  val WORD_BYTES = 8

  type FastSpan = {
    groupDemandActive: bool,
    stackFloorB: int,
    stackLimitB: int,
    heapLoB: int,
    heapBytes: int
  }

  type MemView = {
    stackOwned: bool,
    stackLo: int,
    stackHi: int,
    fudgeWords: int,
    heapOwned: bool,
    heapStart: int,
    heapLimit: int,
    heapHardEnd: int,
    groupDemandActive: bool
  }

  pure def publishFastSpan(m: MemView): FastSpan = {
    if (m.groupDemandActive)
      { groupDemandActive: true, stackFloorB: 0, stackLimitB: 0, heapLoB: 0, heapBytes: 0 }
    else {
      val sFloor =
        if (m.stackOwned and m.stackLo > 0 and (m.stackHi - m.stackLo) > m.fudgeWords)
          (m.stackLo + m.fudgeWords) * WORD_BYTES
        else 0
      val sLimit =
        if (m.stackOwned and m.stackLo > 0 and (m.stackHi - m.stackLo) > m.fudgeWords)
          (m.stackHi * WORD_BYTES) - sFloor + 1
        else 0
      val hValid =
        m.heapOwned and m.heapStart > 0 and
        m.heapLimit > m.heapStart and m.heapLimit <= m.heapHardEnd
      {
        groupDemandActive: false,
        stackFloorB: sFloor,
        stackLimitB: sLimit,
        heapLoB: if (hValid) m.heapStart * WORD_BYTES else 0,
        heapBytes: if (hValid) (m.heapLimit - m.heapStart) * WORD_BYTES else 0
      }
    }
  }

  // Unsigned-subtraction model over non-negative addresses with wrap sentinel.
  pure def uSub(a: int, b: int): int =
    if (a >= b) (a - b) else (1000000000 + a - b)

  pure def fastSpanAdmits(fs: FastSpan, fpW: int, hpW: int, sw: int, hw: int): bool = {
    val fpB = fpW * WORD_BYTES
    val hpB = hpW * WORD_BYTES
    val sDist = uSub(fpB, fs.stackFloorB)
    val hDist = uSub(hpB, fs.heapLoB)
    fpW > 0 and hpW > 0 and sw >= 0 and hw >= 0 and
    sDist < fs.stackLimitB and
    (sDist / WORD_BYTES) >= sw and
    (hw == 0 or (hDist < fs.heapBytes and ((fs.heapBytes - hDist) / WORD_BYTES) >= hw))
  }

  pure def slowLocalRoom(m: MemView, fpW: int, hpW: int, sw: int, hw: int): bool = {
    not(m.groupDemandActive) and
    fpW > 0 and hpW > 0 and sw >= 0 and hw >= 0 and
    m.stackOwned and m.stackLo <= fpW and fpW <= m.stackHi and
    (sw == 0 or ((m.stackHi - m.stackLo) > m.fudgeWords and fpW >= m.stackLo + m.fudgeWords and (fpW - (m.stackLo + m.fudgeWords)) >= sw)) and
    (hw == 0 or (m.heapOwned and m.heapStart <= hpW and hpW < m.heapLimit and
                 (m.heapLimit - hpW) >= hw and m.heapHardEnd >= hpW and (m.heapHardEnd - hpW) >= hw))
  }

  run pillar2FastSpanSoundnessAndBoundaryTest = {
    val m: MemView = {
      stackOwned: true, stackLo: 100, stackHi: 200, fudgeWords: 16,
      heapOwned: true, heapStart: 500, heapLimit: 540, heapHardEnd: 560,
      groupDemandActive: false
    }
    val fs = publishFastSpan(m)
    val activeFs = publishFastSpan({ ...m, groupDemandActive: true })
    assert(
      // Fitting exact boundary
      fastSpanAdmits(fs, 118, 535, 2, 5) == true and
      slowLocalRoom(m, 118, 535, 2, 5) == true and
      // 1 word short on stack fudge reserve
      fastSpanAdmits(fs, 117, 535, 2, 5) == false and
      slowLocalRoom(m, 117, 535, 2, 5) == false and
      // 1 word short on soft heap limit
      fastSpanAdmits(fs, 118, 536, 2, 5) == false and
      slowLocalRoom(m, 118, 536, 2, 5) == false and
      // Below stackFloor (unsigned wrap) rejected
      fastSpanAdmits(fs, 110, 520, 2, 0) == false and
      // Below heapStart (unsigned wrap) rejected
      fastSpanAdmits(fs, 150, 499, 2, 1) == false and
      // Active demand invalidates fast span completely
      fastSpanAdmits(activeFs, 150, 520, 2, 5) == false and
      // Unobserved fast-span never admits when slowLocalRoom rejects
      (not(fastSpanAdmits(fs, 201, 520, 2, 0)) and not(slowLocalRoom(m, 201, 520, 2, 0)))
    )
  }

  // ---------------------------------------------------------------------------
  // 4. Pillar 3: Interpreter hot-loop bounded-chunk deoptimization
  // ---------------------------------------------------------------------------
  type InterpGuards = {
    entryHookPresent: bool,
    dynamicStepperActive: bool,
    primitiveRebound: bool,
    selfRebound: bool,
    argIsFixnum: bool
  }

  pure def fastPlanEligible(g: InterpGuards): bool =
    not(g.entryHookPresent) and
    not(g.dynamicStepperActive) and
    not(g.primitiveRebound) and
    not(g.selfRebound) and
    g.argIsFixnum

  pure def referenceCountdown(n: int, lo: int, step: int, interruptAtStep: int, mutateTo: int): (int, int) = {
    // Returns (finalN, totalStepsBeforeInterruptOrEnd)
    val totalNatural = if (n > lo) ((n - lo + step - 1) / step) else 0
    if (interruptAtStep >= 0 and interruptAtStep < totalNatural) {
      val liveN = n - interruptAtStep * step
      // Interrupt mutates live RTE slot to mutateTo and resumes from mutateTo
      val afterMutate = if (mutateTo > lo) ((mutateTo - lo + step - 1) / step) else 0
      (mutateTo - afterMutate * step, interruptAtStep + afterMutate)
    } else
      (n - totalNatural * step, totalNatural)
  }

  pure def chunkedDeoptCountdown(
    n: int, lo: int, step: int, chunkLimit: int, tripAfterChunk: int, mutateTo: int
  ): (int, int, bool) = {
    // Runs bounded chunks of chunkLimit steps; when stack_trip triggers after
    // tripAfterChunk chunks, deopts at exact live n2 by allocating a fresh RTE
    // and jumping to normal interpreted body so ___POLL delivers interrupt.
    val totalNatural = if (n > lo) ((n - lo + step - 1) / step) else 0
    val stepsBeforeTrip = tripAfterChunk * chunkLimit
    if (tripAfterChunk >= 0 and stepsBeforeTrip < totalNatural) {
      val n2 = n - stepsBeforeTrip * step
      val freshRteAllocated = true
      val afterMutate = if (mutateTo > lo) ((mutateTo - lo + step - 1) / step) else 0
      (mutateTo - afterMutate * step, stepsBeforeTrip + afterMutate, freshRteAllocated and n2 > lo)
    } else
      (n - totalNatural * step, totalNatural, false)
  }

  run pillar3CountdownDeoptAndGuardsTest = {
    val cleanGuards: InterpGuards = {
      entryHookPresent: false, dynamicStepperActive: false,
      primitiveRebound: false, selfRebound: false, argIsFixnum: true
    }
    val refNoTrip = referenceCountdown(2000, 0, 1, -1, 0)
    val optNoTrip = chunkedDeoptCountdown(2000, 0, 1, 512, -1, 0)
    // Trip after 2 chunks (1024 steps, live n2 = 976); interrupt mutates rte slot to 1.
    val refTrip = referenceCountdown(2000, 0, 1, 1024, 1)
    val optTrip = chunkedDeoptCountdown(2000, 0, 1, 512, 2, 1)
    assert(
      fastPlanEligible(cleanGuards) and
      not(fastPlanEligible({ ...cleanGuards, entryHookPresent: true })) and
      not(fastPlanEligible({ ...cleanGuards, dynamicStepperActive: true })) and
      not(fastPlanEligible({ ...cleanGuards, primitiveRebound: true })) and
      not(fastPlanEligible({ ...cleanGuards, selfRebound: true })) and
      not(fastPlanEligible({ ...cleanGuards, argIsFixnum: false })) and
      optNoTrip._1 == refNoTrip._1 and optNoTrip._2 == refNoTrip._2 and
      optTrip._1 == refTrip._1 and optTrip._2 == refTrip._2 and optTrip._3 == true
    )
  }
}

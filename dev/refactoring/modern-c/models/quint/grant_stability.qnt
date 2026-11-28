// Design cut for one write-group grant. Finite obligations only.
// A qualified image grants one straight-line group once, and the same
// input does not both succeed and refuse. Phase 3 and phase 4 are
// refusals, not repaired returns. This module does not read generated
// C, does not execute a GSI, and does not admit the 295/300 campaign.
module grant_stability {
  pure def wholeGroup(enters: int, commits: int, stores: int): bool =
    enters == 1 and commits == 1 and stores > 0

  pure def stable(grantedRuns: int, refusedRuns: int): bool =
    (grantedRuns == 0 or refusedRuns == 0) and grantedRuns >= 0 and refusedRuns >= 0

  pure def refusal(phase: int): bool =
    phase == 3 or phase == 4

  // A repaired return is phase 2. Phase 3 and 4 do not return to the old label.
  pure def repairedReturn(phase: int): bool =
    phase == 2

  // One section is 131072 words. A positive remainder below that cannot fund it.
  pure def sectionFunded(freeWords: int, sectionWords: int): bool =
    sectionWords > 0 and freeWords >= sectionWords

  pure def sliceShorterThanGroup(remain: int, groupWords: int): bool =
    remain >= 0 and groupWords > remain

  // The next list node is the live stack. Assigning it removes handler backing.
  pure def handlerBackingKept(nextNodeIsLiveStack: bool): bool =
    not(nextNodeIsLiveStack)

  // Absent processor or thread float vector: return. Do not yield.
  pure def heartbeatReturns(isFloatVector: bool, yields: bool): bool =
    isFloatVector or not(yields)

  run leafWholeGroupTest =
    assert(wholeGroup(1, 1, 3))

  run splitStoresAreNotOneGroupTest =
    assert(not(wholeGroup(6, 6, 6)) and not(wholeGroup(0, 0, 3)))

  run qualifiedImageIsStableTest =
    assert(stable(1, 0) and stable(0, 1))

  // self-host, eight compiles of the same leaf: three identical C files
  // and five "group demand was not granted" refusals. That pair is not
  // a stable grant.
  run observedLeafIsUnstableTest =
    assert(not(stable(3, 5)))

  run phaseThreeAndFourAreRefusalsTest =
    assert(refusal(3) and refusal(4) and not(refusal(2)) and not(refusal(0)))

  run modelCheckDoesNotAdmitRuntimeTest =
    assert(wholeGroup(1, 1, 3) and not(stable(3, 5)) and not(sectionFunded(57336, 131072)))

  // Measured tail: 1 word left, group asks for 12, free budget 57336, section 131072.
  run observedBudgetCannotFundSectionTest =
    assert(sliceShorterThanGroup(1, 12) and not(sectionFunded(57336, 131072)))

  run liveStackCannotBackTheHandlerTest =
    assert(handlerBackingKept(false) and not(handlerBackingKept(true)))

  run absentFloatVectorReturnsWithoutYieldTest =
    assert(heartbeatReturns(false, false) and not(heartbeatReturns(false, true)) and heartbeatReturns(true, true))

  run phaseTwoIsTheRepairedReturnTest =
    assert(repairedReturn(2) and not(repairedReturn(3)) and not(repairedReturn(4)))

  // A child counted in processor_count answers the barrier only when its
  // native thread is live. Waiting on a dead child does not return.
  pure def barrierWaits(childCounted: bool, nativeLive: bool): bool =
    childCounted and nativeLive

  run countedChildWithoutAThreadDoesNotWaitTest =
    assert(not(barrierWaits(true, false)) and barrierWaits(true, true) and not(barrierWaits(false, true)))
}

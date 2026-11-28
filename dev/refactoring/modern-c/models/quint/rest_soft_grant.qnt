// Admission versus the 84138e91 fast-pair counterexample.
// Two emitted pairs are 6 words. The ordinary complete demand is 10:
// those 6, plus np 3, plus one vector word. Room 9 passes the fast
// predicate and has not passed the 10-word admission. That rejects the
// image as a complete-demand witness. It does not say the fast path
// wrote 10 words, overflowed, or that every Scheme program is unable
// to reach a later refusal. This is not a GSI trace and not 295/300.
module rest_soft_grant {
  pure def pairWords: int = 3
  pure def pending: int = 2
  pure def np: int = 3
  pure def vectorBody: int = 1
  pure def fastWords: int = pending * pairWords
  pure def completeDemand: int = fastWords + np + vectorBody
  pure def fits(room: int): bool = room >= fastWords
  // Successor: one complete-demand check before any protected effect.
  // A fast execution still consumes only the six pair words. The
  // envelope is ten; the debit is six, once.
  pure def admits(room: int): bool = room >= completeDemand
  pure def debit(granted: bool): int = if (granted) fastWords else 0

  run exactSoftFitTest =
    assert(fastWords == 6 and fits(6))
  run oneWordShortIsNotFastTest =
    assert(not(fits(5)) and not(fits(4)))
  run slackStillFitsTest =
    assert(fits(8))
  run imageRoomNinePassesFastPairOnlyTest =
    assert(completeDemand == 10 and fits(9) and not(admits(9)))
  run successorChecksTenBeforeEffectTest =
    assert(not(admits(9)) and debit(false) == 0)
  run successorTenGrantsSixOnceTest =
    assert(admits(10) and debit(true) == 6 and debit(true) != fastWords + completeDemand)

  // Abstract publication contract, not a collector/resize implementation.
  // The image separately supplies the two caps and the physical reserve.
  pure def publishedRoom(quota: int, hardTail: int, fudge: int): int = {
    val physical = if (hardTail > fudge) hardTail - fudge else 0
    if (quota < physical) quota else physical
  }
  run nineWordTailIsNotExcludedByFudgeTest =
    assert(publishedRoom(1000, 9220 + 9, 9220) == 9)
  run freshSectionIsADifferentPremiseTest =
    assert(publishedRoom(100000, 65536, 9220) == 56316)
  run completeShortCanStillBeFastTest =
    assert(fits(9) and not(admits(9)))
  run recoveryAndTerminalRefusalAreDistinctTest =
    assert(publishedRoom(100000, 9220 + 4968, 9220) >= completeDemand and
      not(publishedRoom(1000, 9220 + 9, 9220) >= completeDemand))

  // Absence of a later grant can also mean a pending or dead attempt. A
  // refusal needs an explicit terminal outcome and no construction effects.
  pure def terminalRefusal(room: int, outcome: str, effects: int): bool =
    room + 1 == completeDemand and outcome == "refused" and effects == 0
  pure def recoveredDelivery(initialRoom: int, laterRoom: int): bool =
    not(admits(initialRoom)) and admits(laterRoom)
  run nineThenGrantIsRecoveryTest =
    assert(recoveredDelivery(9, 5199) and not(terminalRefusal(9, "delivered", 6)))
  run nineNeedsTerminalZeroEffectRefusalTest =
    assert(terminalRefusal(9, "refused", 0) and not(terminalRefusal(9, "pending", 0)) and
      not(terminalRefusal(9, "refused", 6)))

  // A heap grant says nothing about pin, root writer or delivery ownership.
  type Delivery = { pin: bool, view: bool, writer: bool, current: bool,
                    installed: bool, ready: bool, delivered: bool }
  pure def canFinish(d: Delivery): bool =
    d.pin and d.view and d.writer and d.current and (d.installed or d.ready)
      and not(d.delivered)
  pure def mayStartEffects(room: int, before: Delivery, protectedThroughFinish: bool): bool =
    admits(room) and canFinish(before) and protectedThroughFinish
  pure val installedView: Delivery = { pin: true, view: true, writer: true,
    current: true, installed: true, ready: false, delivered: false }
  run grantAloneCannotExcludeFinishFailureTest =
    assert(admits(10) and not(canFinish({...installedView, writer: false})))
  run readinessMustSurviveConstructionTest =
    assert(canFinish(installedView) and not(mayStartEffects(10, installedView, false)) and
      mayStartEffects(10, installedView, true) and
      not(canFinish({...installedView, installed: false, ready: true, delivered: true})))

  // Source invalidity, logical completion, and destination shortage
  // are different results. Only the shortage enters extension.
  pure def mayExtend(sourceValid: bool, room: int): bool = sourceValid and not(admits(room))
  run chainResultsStayDistinctTest =
    assert(not(mayExtend(false, 9)) and not(mayExtend(true, 10)) and mayExtend(true, 9))
}

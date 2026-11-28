module stack_call_boundary_reserve {
  // Finite envelope for the unqualified call-boundary candidate.
  // Parent compiled stress, lock 3e046e5c…, recorded SET_STK(9) at an fp 32
  // bytes above the floor: 9*8-32 = 40 bytes below that floor. That record is
  // not a measurement of this candidate image.
  // Default frame arithmetic in include/gambit.h.in: FRAME_RESERVE 3,
  // FRAME_ALIGN 4, NB_GVM_REGS 5, so FRAME_SPACE(NB_GVM_REGS+1) = 12 words.
  // The parent owner limit sat 8194 words above the floor, which is
  // MAX_NB_FRAME_SLOTS+1+SUBTYPED_BODY when SUBTYPED_BODY is 1. A maximum
  // frame from that soft limit leaves 2 words, short of the 12-word handler
  // prologue. The candidate fudge adds those 12 words. A passing run is not
  // bootstrap, stress, source refinement, or runtime admission.
  pure val maxFrame = 8192
  pure val subtypedBody = 1
  pure val handlerWords = 12
  pure val originalFudge = maxFrame + 1 + subtypedBody
  pure val candidateFudge = originalFudge + handlerWords
  pure val recordedSlots = 9
  pure val recordedWordBytes = 8
  pure val recordedFpAboveFloor = 32
  pure val recordedStore =
    (recordedSlots * recordedWordBytes) - recordedFpAboveFloor == 40
  pure val recordedFpWords = recordedFpAboveFloor / recordedWordBytes
  pure val recordedCheckWouldBeLate = recordedFpWords < handlerWords
  pure val reserveHoldsHandler = candidateFudge - maxFrame >= handlerWords
  pure val originalReserveTooSmall = originalFudge - maxFrame < handlerWords

  pure val floor = 0
  pure val callFrame = 9
  pure val entryFp = 24

  type State = {
    phase: str,
    fp: int,
    enabled: bool,
    serviceInterrupts: bool,
    reserved: bool,
    damaged: bool,
    interrupts: bool
  }
  var s: State

  pure def opened(reserved: bool, service: bool): State = {
    phase: "above", fp: entryFp, enabled: true, serviceInterrupts: service,
    reserved: reserved, damaged: false, interrupts: false
  }

  action initOmitted = s' = {
    phase: "above", fp: entryFp, enabled: false, serviceInterrupts: false,
    reserved: false, damaged: false, interrupts: false
  }
  action initServicesInterrupts = s' = opened(true, true)
  action initFixed = s' = opened(true, false)

  action buildCall = all {
    s.phase == "above",
    s.fp >= 16,
    s' = { ...s, phase: "boundary", fp: s.fp - callFrame }
  }
  action boundaryCheck = all {
    s.phase == "boundary",
    s.enabled,
    s.reserved,
    s.fp >= handlerWords,
    s' = { ...s, phase: "check", interrupts: s.serviceInterrupts }
  }
  action resume = all {
    s.phase == "check",
    not(s.interrupts),
    s' = { ...s, phase: "done", fp: 40 }
  }
  action service = all {
    s.phase == "check",
    s.interrupts,
    s' = { ...s, phase: "done" }
  }
  action unchecked = all {
    s.phase == "boundary",
    not(s.enabled),
    s.fp - callFrame >= floor,
    s' = { ...s, fp: s.fp - callFrame }
  }
  action smash = all {
    s.phase == "boundary",
    not(s.enabled),
    s.fp - callFrame < floor,
    s' = { ...s, phase: "done", fp: s.fp - callFrame, damaged: true }
  }
  val terminal = s.phase == "done"
  action stutter = all { terminal, s' = s }
  action step = any { buildCall, unchecked, boundaryCheck, resume, service, smash, stutter }

  val safe = not(s.damaged) and not(s.interrupts) and recordedStore and
    recordedCheckWouldBeLate and reserveHoldsHandler and originalReserveTooSmall
  val interruptsOff = not(s.interrupts) and recordedStore and recordedCheckWouldBeLate
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}

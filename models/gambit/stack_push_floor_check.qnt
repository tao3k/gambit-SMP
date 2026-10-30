module stack_push_floor_check {
  // Finite envelope for stores that bypass ___SET_STK.
  // Words are abstract. Both recorded byte relations are checked here:
  // SET_STK(9) at fp 32 bytes above the floor is 9*8-32 = 40 bytes below it.
  // A 4-word ___PUSH from fp 24 bytes above the floor starts 4*8-24 = 8
  // bytes inside the 24-byte msection header.
  // The guarded outcome is the noreturn diagnostic: no store, no interrupt
  // service, and no fresh-stack resume. A passing run is not native
  // bootstrap, stress, or runtime admission.

  pure val floor = 0
  pure val pollLimit = 8
  pure val frame = 3
  pure val freshTop = 40
  pure val recordedSlots = 9
  pure val recordedWordBytes = 8
  pure val recordedFpAboveFloor = 32
  pure val recordedStore =
    (recordedSlots * recordedWordBytes) - recordedFpAboveFloor == 40
  pure val pushWords = 4
  pure val headerBytes = 24
  pure val recordedPush =
    (pushWords * recordedWordBytes) - headerBytes == 8
  pure val frameRaSlot = 0

  type State = {
    phase: str,
    fp: int,
    enabled: bool,
    serviceInterrupts: bool,
    damaged: bool,
    interrupts: bool
  }
  var s: State

  action init = s' = {
    phase: "alloc", fp: 20, enabled: true, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initOmitted = s' = {
    phase: "alloc", fp: 20, enabled: false, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initServicesInterrupts = s' = {
    phase: "alloc", fp: 20, enabled: true, serviceInterrupts: true,
    damaged: false, interrupts: false
  }
  action initPush = s' = {
    phase: "push", fp: 3, enabled: true, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initPushOmitted = s' = {
    phase: "push", fp: 3, enabled: false, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initFrameRa = s' = {
    phase: "frame", fp: -1, enabled: true, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initFrameRaOmitted = s' = {
    phase: "frame", fp: -1, enabled: false, serviceInterrupts: false,
    damaged: false, interrupts: false
  }

  action allocate = all {
    s.phase == "alloc",
    s.fp - frame >= pollLimit,
    s' = { ...s, fp: s.fp - frame }
  }
  action fallThrough = all {
    s.phase == "alloc",
    not(s.enabled),
    s.fp - frame < pollLimit,
    s.fp - frame >= floor,
    s' = { ...s, fp: s.fp - frame }
  }
  action stackCheck = all {
    s.phase == "alloc",
    s.enabled,
    s.fp - frame < pollLimit,
    s.fp - frame >= floor,
    s' = { ...s, phase: "check", interrupts: s.serviceInterrupts }
  }
  action resume = all {
    s.phase == "check",
    not(s.interrupts),
    s' = { ...s, phase: "done", fp: freshTop }
  }
  action smash = all {
    s.phase == "alloc",
    not(s.enabled),
    s.fp - frame < floor,
    s' = { ...s, phase: "done", fp: s.fp - frame, damaged: true }
  }
  action refusePush = all {
    s.phase == "push",
    s.enabled,
    s.fp - pushWords < floor,
    s' = { ...s, phase: "refused", damaged: false, interrupts: false }
  }
  action smashPush = all {
    s.phase == "push",
    not(s.enabled),
    s.fp - pushWords < floor,
    s' = { ...s, phase: "done", fp: s.fp - pushWords, damaged: true }
  }
  action refuseFrame = all {
    s.phase == "frame",
    s.enabled,
    s.fp - frameRaSlot < floor,
    s' = { ...s, phase: "refused", damaged: false, interrupts: false }
  }
  action smashFrame = all {
    s.phase == "frame",
    not(s.enabled),
    s.fp - frameRaSlot < floor,
    s' = { ...s, phase: "done", fp: s.fp - frameRaSlot, damaged: true }
  }
  action stutter = all {
    s.phase == "done",
    s' = s
  }
  action hold = all {
    s.phase == "refused",
    s' = s
  }
  action step = any {
    allocate, fallThrough, stackCheck, resume, smash,
    refusePush, smashPush, refuseFrame, smashFrame, stutter, hold
  }

  val Safe = not(s.damaged) and not(s.interrupts) and recordedStore and recordedPush
  val InterruptsOff = not(s.interrupts) and recordedStore and recordedPush
}

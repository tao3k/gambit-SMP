module stack_disabled_region_check {
  // Finite envelope for interrupt-disabled stack checks. Words are abstract.
  // The recorded native byte relation is checked here, not by a Python assert:
  // SET_STK(9) at fp 32 bytes above the floor is 9*8-32 = 40 bytes below it.
  // A passing run is not native bootstrap, stress, or runtime admission.
  pure val floor = 0
  pure val pollLimit = 8
  pure val frame = 3
  pure val freshTop = 40
  pure val recordedSlots = 9
  pure val recordedWordBytes = 8
  pure val recordedFpAboveFloor = 32
  pure val recordedStore =
    (recordedSlots * recordedWordBytes) - recordedFpAboveFloor == 40

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
  action stutter = all {
    s.phase == "done",
    s' = s
  }
  action step = any { allocate, fallThrough, stackCheck, resume, smash, stutter }

  val Safe = not(s.damaged) and not(s.interrupts) and recordedStore
  val InterruptsOff = not(s.interrupts) and recordedStore
}

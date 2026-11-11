module stack_member_header_check {
  // Finite envelope for the membership header gate.
  // SET_STK(9) at fp 32 bytes above the allocation floor is 9*8-32 = 40
  // bytes below that floor. A 4-word ___PUSH from fp 24 bytes above the
  // floor starts 4*8-24 = 8 bytes inside the 24-byte header.
  // The section-base bootstrap aborted a mark whose slot was 220729408
  // bytes below the current stack section base. That gap is greater than
  // 24, so the slot is not that section's header. The membership check
  // allows it. The same check refuses a gap of 8 bytes, which is inside
  // the header. A passing run is not native bootstrap, stress, or admission.

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
  pure val observedBelowLimitBytes = 416
  pure val observedBreakBelowLimitBytes = 32
  pure val recordedFromspace =
    observedBelowLimitBytes > headerBytes and
    observedBreakBelowLimitBytes > headerBytes
  pure val observedGapBytes = 220729408
  pure val recordedDistant = observedGapBytes > headerBytes
  pure val headerGapBytes = 8
  pure val recordedHeaderGap =
    headerGapBytes > 0 and headerGapBytes <= headerBytes
  pure val distantMark = -3
  pure val headerMark = -1

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
  action initDistant = s' = {
    phase: "mark", fp: distantMark, enabled: true, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initHeader = s' = {
    phase: "mark", fp: headerMark, enabled: true, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initHeaderOmitted = s' = {
    phase: "mark", fp: headerMark, enabled: false, serviceInterrupts: false,
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
  action allowDistant = all {
    s.phase == "mark",
    s.enabled,
    s.fp == distantMark,
    recordedDistant,
    s' = { ...s, phase: "kept", damaged: false, interrupts: false }
  }
  action refuseHeader = all {
    s.phase == "mark",
    s.enabled,
    s.fp == headerMark,
    recordedHeaderGap,
    s' = { ...s, phase: "refused", damaged: false, interrupts: false }
  }
  action smashHeader = all {
    s.phase == "mark",
    not(s.enabled),
    s.fp == headerMark,
    s' = { ...s, phase: "done", fp: s.fp, damaged: true }
  }
  action stutter = all {
    s.phase == "done",
    s' = s
  }
  action hold = all {
    s.phase == "refused",
    s' = s
  }
  action keep = all {
    s.phase == "kept",
    s' = s
  }
  action step = any {
    allocate, fallThrough, stackCheck, resume, smash,
    refusePush, smashPush, allowDistant, refuseHeader, smashHeader,
    stutter, hold, keep
  }

  val Safe =
    not(s.damaged) and not(s.interrupts) and
    recordedStore and recordedPush and recordedFromspace and
    recordedDistant and recordedHeaderGap
  val InterruptsOff =
    not(s.interrupts) and recordedStore and recordedPush and recordedFromspace and
    recordedDistant and recordedHeaderGap
}

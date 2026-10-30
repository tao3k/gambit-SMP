module stack_section_base_check {
  // Finite envelope for the section-base frame-RA guard.
  // SET_STK(9) at fp 32 bytes above the allocation floor is 9*8-32 = 40
  // bytes below that floor. A 4-word ___PUSH from fp 24 bytes above the
  // floor starts 4*8-24 = 8 bytes inside the 24-byte header.
  // After setup_stack_heap_vmstate, alloc_stack_limit is the new tospace.
  // The statement-lock abort wrote a frame RA 416 bytes below that limit,
  // with the break 32 bytes below it. Both distances are greater than the
  // 24-byte header, and the slot stays at or above stack_msection->base.
  // The guard refuses only a slot below the section base. A passing run is
  // not native bootstrap, stress, or runtime admission.

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
  pure val sectionBase = -65536
  pure val fromspaceFp = -52

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
  action initFromspace = s' = {
    phase: "mark", fp: fromspaceFp, enabled: true, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initHeader = s' = {
    phase: "mark", fp: sectionBase - 1, enabled: true, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initHeaderOmitted = s' = {
    phase: "mark", fp: sectionBase - 1, enabled: false, serviceInterrupts: false,
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
  action allowFromspace = all {
    s.phase == "mark",
    s.enabled,
    s.fp < floor,
    s.fp >= sectionBase,
    s' = { ...s, phase: "kept", damaged: false, interrupts: false }
  }
  action refuseHeader = all {
    s.phase == "mark",
    s.enabled,
    s.fp < sectionBase,
    s' = { ...s, phase: "refused", damaged: false, interrupts: false }
  }
  action smashHeader = all {
    s.phase == "mark",
    not(s.enabled),
    s.fp < sectionBase,
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
    refusePush, smashPush, allowFromspace, refuseHeader, smashHeader,
    stutter, hold, keep
  }

  val Safe =
    not(s.damaged) and not(s.interrupts) and
    recordedStore and recordedPush and recordedFromspace
  val InterruptsOff =
    not(s.interrupts) and recordedStore and recordedPush and recordedFromspace
}

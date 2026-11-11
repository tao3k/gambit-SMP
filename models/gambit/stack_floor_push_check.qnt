module stack_floor_push_check {
  // The p1 wrong-nargs handler reaches ___PUSH(___FIX(0)) with fp equal
  // to the tospace floor. That floor is section->base. The pushed word
  // is base[-1], at byte offset 24-8 = 16, inside the 24-byte header.
  // The refuted 4-word reservation is 4*8 = 32 bytes below stack_break.
  // 32 is greater than 24, so that reservation is not this header.
  // Decoding it as an 8-word return steps 64 bytes and passes the break.
  // A passing run is not native bootstrap, stress, or admission.

  pure val floor = 0
  pure val wordBytes = 8
  pure val headerBytes = 24
  pure val headerOffset = headerBytes - wordBytes
  pure val recordedHeaderWord =
    headerOffset == 16 and headerOffset > 0 and headerOffset <= headerBytes
  pure val frameWords = 4
  pure val frameBytes = frameWords * wordBytes
  pure val recordedFrame = frameBytes == 32 and frameBytes > headerBytes
  pure val substitutedWords = 8
  pure val substitutedBytes = substitutedWords * wordBytes
  pure val recordedOvershoot =
    substitutedBytes == 64 and substitutedBytes > frameBytes

  type State = {
    phase: str,
    fp: int,
    enabled: bool,
    serviceInterrupts: bool,
    damaged: bool,
    interrupts: bool
  }
  var s: State

  action initFloor = s' = {
    phase: "floor", fp: floor, enabled: true, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initFloorOmitted = s' = {
    phase: "floor", fp: floor, enabled: false, serviceInterrupts: false,
    damaged: false, interrupts: false
  }
  action initServicesInterrupts = s' = {
    phase: "floor", fp: floor, enabled: true, serviceInterrupts: true,
    damaged: false, interrupts: false
  }
  action initFrame = s' = {
    phase: "frame", fp: frameBytes, enabled: true, serviceInterrupts: false,
    damaged: false, interrupts: false
  }

  action refuseFloor = all {
    s.phase == "floor",
    s.enabled,
    s.fp - 1 < floor,
    recordedHeaderWord,
    s' = { ...s, phase: "refused", damaged: false, interrupts: s.serviceInterrupts }
  }
  action smashFloor = all {
    s.phase == "floor",
    not(s.enabled),
    s.fp - 1 < floor,
    s' = { ...s, phase: "done", fp: s.fp - 1, damaged: true }
  }
  action keepFrame = all {
    s.phase == "frame",
    s.enabled,
    recordedFrame,
    recordedOvershoot,
    s' = { ...s, phase: "kept", damaged: false, interrupts: false }
  }
  action hold = all {
    s.phase == "refused",
    s' = s
  }
  action keep = all {
    s.phase == "kept",
    s' = s
  }
  action stutter = all {
    s.phase == "done",
    s' = s
  }
  action step = any {
    refuseFloor, smashFloor, keepFrame, hold, keep, stutter
  }

  val Safe =
    not(s.damaged) and not(s.interrupts) and
    recordedHeaderWord and recordedFrame and recordedOvershoot
  val InterruptsOff =
    not(s.interrupts) and
    recordedHeaderWord and recordedFrame and recordedOvershoot
}

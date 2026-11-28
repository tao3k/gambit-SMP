module stack_frame_ra_padding_check {
  // FRAME-RA-BOUNDARY at mem.c:4362 reads fp[0] of the oldest frame.
  // That slot is tag 0. ___tRETURN is tag 1. The frame is 4 words, 32 bytes,
  // below stack_break. 32 is greater than the 24-byte header, so this slot
  // is not a header store. An 8-word descriptor at the high end of the same
  // reservation steps 64 bytes and passes stack_break. Decoding tag 0 is the
  // omitted check. A passing run is not native bootstrap, stress, or admission.

  pure val headerBytes = 24
  pure val wordBytes = 8
  pure val frameWords = 4
  pure val frameBytes = frameWords * wordBytes
  pure val recordedGap =
    frameBytes == 32 and frameBytes > headerBytes
  pure val tagZero = 0
  pure val returnTag = 1
  pure val recordedTag = tagZero != returnTag
  pure val substitutedWords = 8
  pure val substitutedBytes = substitutedWords * wordBytes
  pure val recordedOvershoot =
    substitutedBytes == 64 and substitutedBytes > frameBytes

  type State = {
    phase: str,
    enabled: bool,
    serviceInterrupts: bool,
    decodedZero: bool,
    crossed: bool,
    damaged: bool,
    interrupts: bool
  }
  var s: State

  action initKeep = s' = {
    phase: "mark", enabled: true, serviceInterrupts: false, decodedZero: false,
    crossed: false, damaged: false, interrupts: false
  }
  action initDecodeZero = s' = {
    phase: "mark", enabled: false, serviceInterrupts: false, decodedZero: false,
    crossed: false, damaged: false, interrupts: false
  }
  action initSubstitute = s' = {
    phase: "substitute", enabled: false, serviceInterrupts: false,
    decodedZero: false, crossed: false, damaged: false, interrupts: false
  }
  action initServicesInterrupts = s' = {
    phase: "mark", enabled: true, serviceInterrupts: true, decodedZero: false,
    crossed: false, damaged: false, interrupts: false
  }

  action keepPadding = all {
    s.phase == "mark",
    s.enabled,
    not(s.serviceInterrupts),
    recordedGap,
    recordedTag,
    recordedOvershoot,
    s' = { ...s, phase: "kept", decodedZero: false, crossed: false,
           damaged: false, interrupts: false }
  }
  action decodeZero = all {
    s.phase == "mark",
    not(s.enabled),
    s' = { ...s, phase: "done", decodedZero: true, damaged: true }
  }
  action crossBreak = all {
    s.phase == "substitute",
    not(s.enabled),
    recordedOvershoot,
    s' = { ...s, phase: "done", crossed: true, damaged: true }
  }
  action serviceInterrupts = all {
    s.phase == "mark",
    s.enabled,
    s.serviceInterrupts,
    s' = { ...s, phase: "done", interrupts: true }
  }
  action hold = all { s.phase == "kept", s' = s }
  action stutter = all { s.phase == "done", s' = s }
  action step = any {
    keepPadding, decodeZero, crossBreak, serviceInterrupts, hold, stutter
  }

  val Safe =
    not(s.damaged) and not(s.decodedZero) and not(s.crossed) and not(s.interrupts) and
    recordedGap and recordedTag and recordedOvershoot
  val InterruptsOff =
    not(s.interrupts) and recordedGap and recordedTag and recordedOvershoot
}

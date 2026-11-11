module stack_padding_step_check {
  // The padding-mark probe died with SIGSEGV, exit -11, empty stderr, and
  // no processor topology. That path marked a non-return word in the oldest
  // 4-word frame and jumped fp to stack_break. Tag 0 is not a return.
  // The reservation is 4*8 = 32 bytes, greater than the 24-byte header.
  // An 8-word descriptor steps 64 bytes and passes the break.
  // The kept path steps exactly one 4-word frame and marks nothing there.
  // A passing run is not native bootstrap, stress, or admission.

  pure val headerBytes = 24
  pure val wordBytes = 8
  pure val frameWords = 4
  pure val frameBytes = frameWords * wordBytes
  pure val recordedGap = frameBytes == 32 and frameBytes > headerBytes
  pure val tagZero = 0
  pure val returnTag = 1
  pure val recordedTag = tagZero != returnTag
  pure val substitutedWords = 8
  pure val substitutedBytes = substitutedWords * wordBytes
  pure val recordedOvershoot = substitutedBytes == 64 and substitutedBytes > frameBytes
  pure val probeExit = -11
  pure val recordedSignal = probeExit == -11

  type State = {
    phase: str,
    enabled: bool,
    serviceInterrupts: bool,
    markedPadding: bool,
    decodedZero: bool,
    stepped: bool,
    damaged: bool,
    interrupts: bool
  }
  var s: State

  action initStep = s' = {
    phase: "mark", enabled: true, serviceInterrupts: false, markedPadding: false,
    decodedZero: false, stepped: false, damaged: false, interrupts: false
  }
  action initMarkJump = s' = {
    phase: "mark", enabled: false, serviceInterrupts: false, markedPadding: false,
    decodedZero: false, stepped: false, damaged: false, interrupts: false
  }
  action initDecodeZero = s' = {
    phase: "decode", enabled: false, serviceInterrupts: false, markedPadding: false,
    decodedZero: false, stepped: false, damaged: false, interrupts: false
  }
  action initServicesInterrupts = s' = {
    phase: "mark", enabled: true, serviceInterrupts: true, markedPadding: false,
    decodedZero: false, stepped: false, damaged: false, interrupts: false
  }

  action stepFour = all {
    s.phase == "mark",
    s.enabled,
    not(s.serviceInterrupts),
    recordedGap,
    recordedTag,
    recordedOvershoot,
    recordedSignal,
    s' = { ...s, phase: "kept", stepped: true, markedPadding: false,
           decodedZero: false, damaged: false, interrupts: false }
  }
  action markAndJump = all {
    s.phase == "mark",
    not(s.enabled),
    s' = { ...s, phase: "done", markedPadding: true, damaged: true }
  }
  action decodeZero = all {
    s.phase == "decode",
    not(s.enabled),
    s' = { ...s, phase: "done", decodedZero: true, damaged: true }
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
    stepFour, markAndJump, decodeZero, serviceInterrupts, hold, stutter
  }

  val Safe =
    not(s.damaged) and not(s.markedPadding) and not(s.decodedZero) and
    not(s.interrupts) and
    recordedGap and recordedTag and recordedOvershoot and recordedSignal
  val InterruptsOff =
    not(s.interrupts) and
    recordedGap and recordedTag and recordedOvershoot and recordedSignal
}

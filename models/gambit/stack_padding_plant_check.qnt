module stack_padding_plant_check {
  // The padding-step probe died SIGSEGV, exit -11, empty stderr, with no
  // processor topology. That path left tag 0 at fp[0] and fell through with
  // fs=1. Tag 0 is not a return. The reservation is 4*8=32 bytes, greater
  // than the 24-byte header. An 8-word descriptor steps 64 bytes past the
  // break. The kept path plants the check continuation, a real return,
  // before the 4-word step and does not mark the padding.
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
    planted: bool,
    decodedZero: bool,
    damaged: bool,
    interrupts: bool
  }
  var s: State

  action initPlant = s' = {
    phase: "mark", enabled: true, serviceInterrupts: false, planted: false,
    decodedZero: false, damaged: false, interrupts: false
  }
  action initSigsegv = s' = {
    phase: "sigsegv", enabled: false, serviceInterrupts: false, planted: false,
    decodedZero: false, damaged: false, interrupts: false
  }
  action initDecodeZero = s' = {
    phase: "decode", enabled: false, serviceInterrupts: false, planted: false,
    decodedZero: false, damaged: false, interrupts: false
  }
  action initServicesInterrupts = s' = {
    phase: "mark", enabled: true, serviceInterrupts: true, planted: false,
    decodedZero: false, damaged: false, interrupts: false
  }

  action plantAndStep = all {
    s.phase == "mark",
    s.enabled,
    not(s.serviceInterrupts),
    recordedGap,
    recordedTag,
    recordedOvershoot,
    recordedSignal,
    s' = { ...s, phase: "kept", planted: true, decodedZero: false,
           damaged: false, interrupts: false }
  }
  action oldFallthrough = all {
    s.phase == "sigsegv",
    not(s.enabled),
    s' = { ...s, phase: "done", planted: false, damaged: true }
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
    plantAndStep, oldFallthrough, decodeZero, serviceInterrupts, hold, stutter
  }

  val Safe =
    not(s.damaged) and not(s.decodedZero) and not(s.interrupts) and
    recordedGap and recordedTag and recordedOvershoot and recordedSignal
  val InterruptsOff =
    not(s.interrupts) and
    recordedGap and recordedTag and recordedOvershoot and recordedSignal
}

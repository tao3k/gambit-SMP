module stack_padding_saved_return_check {
  // The padding-plant probe aborted FRAME-RA-BOUNDARY, exit -6, ra=0 tag=0,
  // at the non-return ___RETN_GET. The heap-limit plant had not stored a
  // return at fp[0]. Kernel init leaves that slot 0 and the real return at
  // fp[3], one word below stack_break. The reservation is 4*8=32 bytes,
  // greater than the 24-byte header. Decoding the slot as an 8-word frame
  // steps 64 bytes past the break. The kept path steps four words with an
  // empty map when the saved word is a return, and does not service
  // interrupts. A passing run is not native bootstrap, stress, or admission.

  pure val headerBytes = 24
  pure val wordBytes = 8
  pure val frameWords = 4
  pure val frameBytes = frameWords * wordBytes
  pure val savedIndex = frameWords - 1
  pure val recordedGap = frameBytes == 32 and frameBytes > headerBytes and savedIndex == 3
  pure val tagZero = 0
  pure val returnTag = 1
  pure val recordedTag = tagZero != returnTag
  pure val substitutedWords = 8
  pure val substitutedBytes = substitutedWords * wordBytes
  pure val recordedOvershoot = substitutedBytes == 64 and substitutedBytes > frameBytes
  pure val probeExit = -6
  pure val recordedAbort = probeExit == -6

  type State = {
    phase: str,
    enabled: bool,
    serviceInterrupts: bool,
    savedReturn: bool,
    decodedZero: bool,
    damaged: bool,
    interrupts: bool
  }
  var s: State

  action initSaved = s' = {
    phase: "mark", enabled: true, serviceInterrupts: false, savedReturn: true,
    decodedZero: false, damaged: false, interrupts: false
  }
  action initAbort = s' = {
    phase: "abort", enabled: false, serviceInterrupts: false, savedReturn: true,
    decodedZero: false, damaged: false, interrupts: false
  }
  action initOvershoot = s' = {
    phase: "overshoot", enabled: false, serviceInterrupts: false, savedReturn: true,
    decodedZero: false, damaged: false, interrupts: false
  }
  action initServicesInterrupts = s' = {
    phase: "mark", enabled: true, serviceInterrupts: true, savedReturn: true,
    decodedZero: false, damaged: false, interrupts: false
  }

  action stepSaved = all {
    s.phase == "mark",
    s.enabled,
    s.savedReturn,
    not(s.serviceInterrupts),
    recordedGap,
    recordedTag,
    recordedOvershoot,
    recordedAbort,
    s' = { ...s, phase: "kept", decodedZero: false, damaged: false, interrupts: false }
  }
  action omittedSavedCheck = all {
    s.phase == "abort",
    not(s.enabled),
    s.savedReturn,
    s' = { ...s, phase: "done", decodedZero: true, damaged: true }
  }
  action overshoot = all {
    s.phase == "overshoot",
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
    stepSaved, omittedSavedCheck, overshoot, serviceInterrupts, hold, stutter
  }

  val Safe =
    not(s.damaged) and not(s.decodedZero) and not(s.interrupts) and
    recordedGap and recordedTag and recordedOvershoot and recordedAbort
  val InterruptsOff =
    not(s.interrupts) and
    recordedGap and recordedTag and recordedOvershoot and recordedAbort
}

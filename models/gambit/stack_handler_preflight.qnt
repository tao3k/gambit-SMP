module stack_handler_preflight {
  // Word coordinates relative to the active allocation floor. The captured
  // BTQ store uses fp=4 and writes slot 9, reaching word -5. A stack-limit
  // check cannot be considered harmless: its handler pushes all GVM registers
  // and RA before testing stack_limit. The complete RETI frame is 12 words
  // with NB_GVM_REGS=5 and FRAME_ALIGN=4; the exact generated handler and
  // compiler frame-bound premise remain source obligations.
  pure val floor = 0
  pure val recordedFp = 4
  pure val entryWriteWords = 9
  pure val handlerFrameWords = 12
  pure val sourceFudgeWords = 8194
  pure val proposedFudgeWords = sourceFudgeWords + handlerFrameWords

  type State = {
    phase: str,
    fp: int,
    nextWrite: int,
    preflight: bool,
    checked: bool,
    frameValid: bool,
    damaged: bool
  }
  var s: State

  action initLate = s' = {
    phase: "enter", fp: recordedFp, nextWrite: entryWriteWords,
    preflight: false, checked: false, frameValid: true, damaged: false
  }
  action initReserved = s' = {
    phase: "enter", fp: proposedFudgeWords, nextWrite: entryWriteWords,
    preflight: true, checked: false, frameValid: true, damaged: false
  }
  action initUnboundedBurst = s' = {
    phase: "enter", fp: proposedFudgeWords, nextWrite: proposedFudgeWords + 1,
    preflight: true, checked: false, frameValid: true, damaged: false
  }
  action initMidFrame = s' = {
    phase: "enter", fp: proposedFudgeWords, nextWrite: entryWriteWords,
    preflight: true, checked: false, frameValid: false, damaged: false
  }

  // A preflight is legal only if its own frame fits before the comparison.
  action check = all {
    s.phase == "enter",
    s' = { ...s, phase: "write", checked: true,
      damaged: s.damaged or s.fp - handlerFrameWords < floor or
        not(s.frameValid) }
  }
  action write = all {
    s.phase == "write",
    s' = { ...s, phase: "done", fp: s.fp - s.nextWrite,
      damaged: s.damaged or s.fp - s.nextWrite < floor }
  }
  action hold = all { s.phase == "done", s' = s }
  action step = any { check, write, hold }
  val safe = not(s.damaged)
  val admission = s.preflight and s.checked and
    s.fp >= floor and s.nextWrite <= sourceFudgeWords and
    s.frameValid and s.fp >= handlerFrameWords and s.fp >= s.nextWrite

  run lateCheckCounterexampleTest = initLate.then(check)
    .then(all { assert(not(safe)), s' = s })
  run recordedStoreCounterexampleTest = initLate.then(s' = { ...s, phase: "write" })
    .then(write).then(all { assert(not(safe)), s' = s })
  run boundedPreflightTest = initReserved.then(check).then(write)
    .then(all { assert(safe), assert(admission), s' = s })
  run unboundedBurstCounterexampleTest = initUnboundedBurst.then(check).then(write)
    .then(all { assert(not(safe)), assert(not(admission)), s' = s })
  run midFrameCounterexampleTest = initMidFrame.then(check)
    .then(all { assert(not(safe)), assert(not(admission)), s' = s })
}

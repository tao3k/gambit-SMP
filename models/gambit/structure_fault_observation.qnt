module structure_fault_observation {
  // The TYPEID fault at ##wr-structure stays unknown until a pre-load record
  // of the header word is taken without sending the object back through the
  // printer. That record selects exactly one cause. Only the matching repair
  // is enabled: delay publication, remove the later write, refresh that one
  // root, or fix the earlier error. A printer guard and a diagnostic root
  // do not repair any cause.
  type State = {
    control: int, fault: bool, headerRecorded: bool, reprinted: bool,
    laterWrite: bool, relocated: bool, firstError: bool,
    cause: int, repair: int, solved: bool
  }
  var s: State
  pure def initial(control: int): State = {
    control: control, fault: false, headerRecorded: false, reprinted: false,
    laterWrite: false, relocated: false, firstError: false,
    cause: 0, repair: 0, solved: false
  }
  action initUnknown = s' = initial(0)
  action initRecorded = s' = initial(1)
  action initBlame = s' = initial(2)
  action initPrinter = s' = initial(3)
  action initMask = s' = initial(4)
  action initNoRecord = s' = initial(5)
  action initReprint = s' = initial(6)
  action noteFault = all {
    or { s.control == 0, s.control == 1 }, not(s.fault),
    s' = { ...s, fault: true }
  }
  action recordEarly = all {
    s.control == 1, s.fault, not(s.headerRecorded), not(s.reprinted), s.cause == 0,
    s' = { ...s, headerRecorded: true, cause: 1 }
  }
  action recordLaterWrite = all {
    s.control == 1, s.fault, not(s.headerRecorded), not(s.reprinted), s.cause == 0,
    s' = { ...s, headerRecorded: true, laterWrite: true, cause: 2 }
  }
  action recordStale = all {
    s.control == 1, s.fault, not(s.headerRecorded), not(s.reprinted), s.cause == 0,
    s' = { ...s, headerRecorded: true, relocated: true, cause: 3 }
  }
  action recordEarlier = all {
    s.control == 1, s.fault, not(s.headerRecorded), not(s.reprinted), s.cause == 0,
    s' = { ...s, headerRecorded: true, firstError: true, cause: 4 }
  }
  action repairSelected = all {
    s.control == 1, s.headerRecorded, not(s.reprinted), s.cause >= 1, s.cause <= 4,
    s.repair == 0,
    s' = { ...s, repair: s.cause, solved: true }
  }
  action blameFromFault = all {
    s.control == 2, not(s.headerRecorded), s.cause == 0,
    s' = { ...s, fault: true, cause: 1 }
  }
  action guardPrinter = all {
    s.control == 3, not(s.headerRecorded), s.repair == 0,
    s' = { ...s, fault: true, repair: 8, solved: true }
  }
  action addDiagnosticRoot = all {
    s.control == 4, not(s.headerRecorded),
    s' = { ...s, relocated: true, repair: 9, solved: true }
  }
  action solveWithoutRecord = all {
    s.control == 5, s.fault or true, not(s.headerRecorded), not(s.solved),
    s' = { ...s, fault: true, cause: 1, repair: 1, solved: true }
  }
  action reprintRecord = all {
    s.control == 6, not(s.reprinted),
    s' = { ...s, fault: true, reprinted: true, headerRecorded: true, cause: 1,
           repair: 1, solved: true }
  }
  val terminal =
    (s.control == 0 and s.fault and s.cause == 0 and not(s.headerRecorded) and not(s.solved)) or
    (s.control == 1 and s.solved and s.headerRecorded and not(s.reprinted) and
     s.cause >= 1 and s.cause <= 4 and s.repair == s.cause)
  action done = all { terminal, s' = s }
  action step = any {
    noteFault, recordEarly, recordLaterWrite, recordStale, recordEarlier,
    repairSelected, blameFromFault, guardPrinter, addDiagnosticRoot,
    solveWithoutRecord, reprintRecord, done
  }
  val safe =
    (s.cause == 0 or s.headerRecorded) and
    (not(s.solved) or
      (s.headerRecorded and not(s.reprinted) and s.repair == s.cause and
       s.cause >= 1 and s.cause <= 4)) and
    (s.control != 0 or (s.cause == 0 and not(s.solved) and not(s.headerRecorded)))
  val recordedSafe = safe
  val witnessed = s.cause == 0 or s.headerRecorded
  val noPrinter = s.repair != 8
  val noMask = s.repair != 9
  val recordFirst = not(s.solved) or s.headerRecorded
  val noReprint = not(s.reprinted) or not(s.solved)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
  // Observation refinement: a valid capture can witness a bad runtime value.
  // Image, ownership and epochs are observations/premises, not native proofs.
  type Capture = { expectedImage: int, loadedImage: int, recordOwner: int,
    copyOwner: int, copyEpoch: int, stopEpoch: int, api: str,
    stage: str, readResult: str, rawWord: int, mapped: bool }
  pure val captureGood: Capture = { expectedImage: 1, loadedImage: 1,
    recordOwner: 1, copyOwner: 1, copyEpoch: 1, stopEpoch: 1,
    api: "qualified", stage: "read", readResult: "ok", rawWord: 0, mapped: true }
  pure def captureAccepted(c: Capture): bool =
    c.expectedImage == c.loadedImage and c.recordOwner == c.copyOwner and
    c.copyEpoch == c.stopEpoch and c.api == "qualified" and c.stage == "read" and
    c.readResult == "ok"
  pure def badDescriptorWitness(c: Capture): bool = captureAccepted(c) and
    Set(0, 8262).contains(c.rawWord)
  pure def tagCompatible(c: Capture): bool = c.rawWord % 4 == 1
  // Actual causes remain a compatibility set; one header never chooses one.
  pure def headerCompatibleCauses(c: Capture): Set[int] = Set(1, 2, 3, 4)
  pure def captureAdvance(c: Capture, event: str): Capture =
    if (event == "claim" and c.stage == "empty") { ...c, stage: "claimed" }
    else if (event == "copy" and c.stage == "claimed") { ...c, stage: "copied" }
    else if (event == "publish" and c.stage == "copied") { ...c, stage: "published" }
    else if (event == "gc-gap" and c.stage == "published") { ...c, stopEpoch: 2 }
    else if (event == "stop" and c.stage == "published") { ...c, stage: "stopped" }
    else if (event == "read" and c.stage == "stopped") { ...c, stage: "read" }
    else c
  run mechanismBadValueCaptureTest = initUnknown.then(all {
    assert(captureAccepted(captureGood)), assert(badDescriptorWitness(captureGood)),
    assert(headerCompatibleCauses(captureGood).size() == 4), s' = s })
  run mechanismReadFailureUnknownTest = initUnknown.then(all {
    assert(not(captureAccepted({ ...captureGood, readResult: "unreadable" }))),
    assert(not(badDescriptorWitness({ ...captureGood, readResult: "unreadable" }))), s' = s })
  run mechanismTagNotMappedTest = initUnknown.then(all {
    assert(tagCompatible({ ...captureGood, rawWord: 4097, mapped: false })),
    assert(not(badDescriptorWitness({ ...captureGood, rawWord: 4097, mapped: false }))), s' = s })
  run mechanismFreezeGapTest = initUnknown.then(all {
    assert(not(captureAccepted({ ...captureGood, stopEpoch: 2 }))),
    assert(not(captureAccepted({ ...captureGood, loadedImage: 2 }))),
    assert(not(captureAccepted({ ...captureGood, copyOwner: 2 }))),
    assert(not(captureAccepted({ ...captureGood, api: "failed" }))),
    assert(not(captureAccepted({ ...captureGood, stage: "published" }))), s' = s })
  run mechanismPublicationSequenceTest = initUnknown.then(all {
    assert(List("claim", "copy", "publish", "stop", "read").foldl(
      { ...captureGood, stage: "empty" }, (c, event) => captureAdvance(c, event)) == captureGood),
    assert(not(captureAccepted(List("claim", "copy", "publish", "gc-gap", "stop", "read").foldl(
      { ...captureGood, stage: "empty" }, (c, event) => captureAdvance(c, event))))), s' = s })

}

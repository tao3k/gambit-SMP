module gsi_child_progress {
  // Bounded witness for one hash-bound runner copy and one original file.
  // A completed GC report is VM-total last-gc-alloc plus one finished collection.
  // Observer bytes sit inside that total. No action establishes a mutator share.
  // Recording a presented witness is not a theorem that another GC, a TFIB root,
  // or process exit occurs. Integers are envelope tags, not host resource limits.
  type State = {
    mode: str,
    reportedPid: int, childPid: int, nonceFresh: bool,
    runnerHashOk: bool, sourceHashOk: bool, reporterHashOk: bool,
    fileOriginal: bool, epochMatch: bool, kind: str,
    sample: int, cursor: int,
    collectionComplete: bool, reportForwarded: bool, reportFramed: bool,
    gcReportEnabled: bool, attested: bool, completedFlag: bool,
    interferenceDisclosed: bool, claimsMutator: bool, mutatorKnown: bool,
    vmAlloc: int, observerAlloc: int, stockReadUntilEof: bool,
    childExit: int, stdoutOriginal: bool,
    proposal: bool, proposalSuite: bool,
    renewed: bool, suiteAdmitted: bool, forcedNext: bool, terminal: bool,
    hostCpuAdvanced: bool,
    // sleepReturned is the primordial leaving thread-sleep!.
    // sleepFlushed is the later force-output. An unflushed write can
    // leave inbandObservation unchanged. That abstraction is not the
    // io-settings=lu merge: tags below are 0 unset, 1 no buffering,
    // 2 full buffering. portObjectObserved stays false.
    sleepReturned: bool, sleepFlushed: bool,
    generalBuffering: int, fileSlotBuffering: int, filePortBuffering: int,
    portObjectObserved: bool
  }
  var s: State

  // childExit -1 means the inner process has not been reaped.
  // vmAlloc 2 with observerAlloc 1 is an explicit mixed VM total.
  pure def accepted(sample: int, cursor: int): State = {
    mode: "admit",
    reportedPid: 1, childPid: 1, nonceFresh: true,
    runnerHashOk: true, sourceHashOk: true, reporterHashOk: true,
    fileOriginal: true, epochMatch: true, kind: "gc-collection",
    sample: sample, cursor: cursor,
    collectionComplete: true, reportForwarded: true, reportFramed: true,
    gcReportEnabled: true, attested: true, completedFlag: true,
    interferenceDisclosed: true, claimsMutator: false, mutatorKnown: false,
    vmAlloc: 2, observerAlloc: 1, stockReadUntilEof: false,
    childExit: -1, stdoutOriginal: true,
    proposal: true, proposalSuite: false,
    renewed: false, suiteAdmitted: false, forcedNext: false, terminal: false,
    hostCpuAdvanced: false, sleepReturned: false, sleepFlushed: false,
    generalBuffering: 0, fileSlotBuffering: 0, filePortBuffering: 0,
    portObjectObserved: false
  }

  action initAcceptedWitness = s' = accepted(1, 0)
  action initWrongChild = s' = { ...accepted(1, 0), reportedPid: 2 }
  action initWrongSource = s' = { ...accepted(1, 0), sourceHashOk: false, fileOriginal: false }
  action initWrongEpoch = s' = { ...accepted(1, 0), epochMatch: false }
  action initReplay = {
    nondet sample = Set(1, 2).oneOf()
    s' = accepted(sample, 2)
  }
  action initBegin = s' = {
    ...accepted(1, 0), kind: "begin",
    collectionComplete: false, reportForwarded: false
  }
  action initIncompleteGc = s' = { ...accepted(1, 0), collectionComplete: false }
  action initHostValidationAsChildGc = s' = {
    ...accepted(1, 0), kind: "host-input-validation", collectionComplete: false
  }
  // Native reports may interleave even though collections really completed.
  // Completion does not authenticate the transport record carrying it.
  action initInterleavedGc = s' = { ...accepted(1, 0), reportFramed: false }
  action initHiddenInterference = s' = {
    ...accepted(1, 0), mode: "hidden", gcReportEnabled: false,
    interferenceDisclosed: false
  }
  // The whole reported allocation is the observer. The mutator premise is absent.
  action initObserverOnly = s' = {
    ...accepted(1, 0), mode: "claim-mutator",
    vmAlloc: 1, observerAlloc: 1
  }
  action initFailureExit = s' = {
    ...accepted(1, 0), kind: "file-exit",
    childExit: 1, proposalSuite: true, proposal: false
  }
  action initNoForcedNext = s' = {
    ...accepted(0, 0), mode: "force",
    collectionComplete: false, reportForwarded: false,
    proposal: false
  }
  action initHeldUntilEof = s' = {
    ...accepted(1, 0), stockReadUntilEof: true, reportForwarded: false
  }

  // The population observer published "started", but not its next sample.
  // Its unpublished VM totals are not part of the observer's visible cursor.
  // Work and no work in this finite interval must remain distinguishable
  // hypotheses; silence alone does not establish global mutator stoppage.
  pure val quietInitial: State = {
    ...accepted(0, 0), mode: "quiet", kind: "observer-sample",
    collectionComplete: false, reportForwarded: false, reportFramed: false,
    gcReportEnabled: false, attested: false, completedFlag: false,
    vmAlloc: 1, observerAlloc: 1, proposal: false
  }
  pure def inbandObservation(x: State): (int, int, int, int, bool, bool, bool, bool, int) = (
    x.reportedPid, x.childPid, x.sample, x.cursor, x.reportForwarded,
    x.reportFramed, x.collectionComplete, x.completedFlag, x.childExit
  )
  action initQuiet = s' = quietInitial
  action unpublishedMutatorWork = all {
    s.mode == "quiet", not(s.terminal), s.vmAlloc == s.observerAlloc,
    s' = { ...s, vmAlloc: s.vmAlloc + 1 }
  }
  // Host process time is a different cursor from the in-band sample row.
  // Advancing it does not publish a Scheme row, a completion, or a mutator share.
  action recordHostCpuAdvanced = all {
    s.mode == "quiet", not(s.terminal), not(s.hostCpuAdvanced),
    s' = { ...s, hostCpuAdvanced: true },
  }
  // Leaving thread-sleep! is not the force-output that follows it.
  // The retained after-start file writes that marker and flushes only
  // after a later join, so a missing line does not select this action.
  action returnSleepUnflushed = all {
    s.mode == "quiet", not(s.terminal), not(s.sleepReturned),
    s' = { ...s, sleepReturned: true }
  }
  action flushSleepMarker = all {
    s.mode == "quiet", not(s.terminal), s.sleepReturned, not(s.sleepFlushed),
    s' = { ...s, sleepFlushed: true, cursor: s.cursor + 1 }
  }
  // In (write (count-done) port), returning the argument precedes entering
  // the writer; neither boundary publishes a digit. kind is hidden here
  // because reportForwarded is false. This does not assume full buffering.
  action returnCountArgumentUnpublished = all {
    s.mode == "quiet", not(s.terminal), s.kind == "observer-sample",
    s' = { ...s, kind: "count-return-unpublished" }
  }
  action enterCountWriterUnpublished = all {
    s.mode == "quiet", not(s.terminal), s.kind == "count-return-unpublished",
    s' = { ...s, kind: "count-write-entry-unpublished" }
  }
  // ___io_settings_finalize merges GENERAL into unset fields, then the
  // device default. io-settings=lu sets general EOL LF and NO_BUFFERING.
  // An unset file slot therefore keeps no-buffering; a file slot that
  // already selected full buffering does not take the general tag.
  // Neither action reads a live port object.
  action noteGeneralNoBuffering = all {
    s.mode == "quiet", not(s.terminal), s.generalBuffering == 0,
    s' = { ...s, generalBuffering: 1 }
  }
  action finalizeUnsetFileSlot = all {
    s.mode == "quiet", not(s.terminal), not(s.portObjectObserved),
    s.fileSlotBuffering == 0, s.generalBuffering != 0, s.filePortBuffering == 0,
    s' = { ...s, filePortBuffering: s.generalBuffering }
  }
  action noteFileSlotFullBuffering = all {
    s.mode == "quiet", not(s.terminal), s.fileSlotBuffering == 0,
    s' = { ...s, fileSlotBuffering: 2 }
  }
  action finalizeSetFileSlot = all {
    s.mode == "quiet", not(s.terminal), not(s.portObjectObserved),
    s.fileSlotBuffering != 0, s.filePortBuffering == 0,
    s' = { ...s, filePortBuffering: s.fileSlotBuffering }
  }

  action admit = all {
    not(s.terminal), s.mode != "idle",
    s' = { ...s, renewed: s.proposal,
      gcReportEnabled: s.gcReportEnabled or s.mode == "hidden",
      claimsMutator: s.mode == "claim-mutator",
      forcedNext: s.mode == "force",
      suiteAdmitted: s.suiteAdmitted or s.proposalSuite, terminal: true },
  }
  action idle = all { s.mode == "idle", not(s.terminal), s' = s }
  action finished = all { s.terminal, s' = s }
  action protocol = any { admit, idle }
  action step = any { protocol, finished }

  val identityHeld =
    s.reportedPid == s.childPid and s.nonceFresh and
    s.runnerHashOk and s.reporterHashOk
  val sourceHeld = s.sourceHashOk and s.fileOriginal
  val strictAdvance = s.sample > s.cursor
  val collectionHeld =
    s.kind == "gc-collection" and s.collectionComplete and
    s.reportForwarded and s.gcReportEnabled and s.attested and s.completedFlag
  val streamHeld = s.reportForwarded and s.reportFramed and not(s.stockReadUntilEof)

  val identitySafe = not(s.renewed) or identityHeld
  val sourceSafe = not(s.renewed) or sourceHeld
  val epochSafe = not(s.renewed) or s.epochMatch
  val replaySafe = not(s.renewed) or strictAdvance
  val beginSafe = not(s.renewed) or not(s.kind == "begin")
  val collectionSafe = not(s.renewed) or collectionHeld
  val interferenceSafe = not(s.gcReportEnabled) or s.interferenceDisclosed
  val attributionSafe = not(s.claimsMutator) or s.mutatorKnown
  val exitSafe =
    not(s.suiteAdmitted) or
    (s.childExit == 0 and s.stdoutOriginal and s.kind == "file-exit" and
     s.sample <= 1 and strictAdvance)
  val livenessSafe = not(s.forcedNext)
  val streamSafe = not(s.renewed) or streamHeld
  val framingSafe = not(s.renewed) or s.reportFramed

  val safe =
    (not(s.renewed) or (
      identityHeld and sourceHeld and s.epochMatch and strictAdvance and
      collectionHeld and streamHeld and s.interferenceDisclosed and
      not(s.claimsMutator) and not(s.mutatorKnown) and
      s.observerAlloc <= s.vmAlloc and s.observerAlloc >= 1 and
      not(s.kind == "begin"))) and
    exitSafe and interferenceSafe and attributionSafe and livenessSafe and
    (not(s.kind == "file-exit") or s.sample <= 1)
  val done = s.terminal
  temporal completion = weakFair(protocol, Set(s)).implies(eventually(done))

  run quietCanHideWorkTest = initQuiet.then(unpublishedMutatorWork).then(admit)
    .then(all {
      assert(inbandObservation(s) == inbandObservation(quietInitial)),
      assert(s.vmAlloc > s.observerAlloc), assert(not(s.mutatorKnown)),
      assert(not(s.renewed)), assert(not(s.suiteAdmitted)),
      assert(not(s.forcedNext)), assert(safe), s' = s
    })
  run quietHostCpuAdvancesWithoutInbandRowTest = initQuiet.then(recordHostCpuAdvanced).then(admit)
    .then(all {
      assert(inbandObservation(s) == inbandObservation(quietInitial)),
      assert(s.hostCpuAdvanced), assert(s.vmAlloc == s.observerAlloc),
      assert(not(s.sleepReturned)), assert(not(s.sleepFlushed)),
      assert(not(s.mutatorKnown)), assert(not(s.renewed)),
      assert(not(s.suiteAdmitted)), assert(not(s.forcedNext)),
      assert(safe), s' = s
    })
  // The retained file can show host CPU and no sleep line while the
  // sleep has already returned into the buffer. This is not a native
  // measurement and does not choose which history happened.
  run hostCpuAndUnflushedSleepShareOneCursorTest =
    initQuiet.then(recordHostCpuAdvanced).then(returnSleepUnflushed).then(admit)
    .then(all {
      assert(inbandObservation(s) == inbandObservation(quietInitial)),
      assert(s.hostCpuAdvanced), assert(s.sleepReturned),
      assert(not(s.sleepFlushed)), assert(s.vmAlloc == s.observerAlloc),
      assert(not(s.mutatorKnown)), assert(not(s.renewed)),
      assert(not(s.suiteAdmitted)), assert(not(s.forcedNext)),
      assert(safe), s' = s
    })
  run bufferedSleepReturnStaysUnpublishedTest = initQuiet.then(returnSleepUnflushed).then(admit)
    .then(all {
      assert(inbandObservation(s) == inbandObservation(quietInitial)),
      assert(s.sleepReturned), assert(not(s.sleepFlushed)),
      assert(not(s.hostCpuAdvanced)), assert(s.vmAlloc == s.observerAlloc),
      assert(not(s.mutatorKnown)), assert(not(s.renewed)),
      assert(not(s.suiteAdmitted)), assert(not(s.forcedNext)),
      assert(safe), s' = s
    })
  run flushedSleepMarkerAdvancesCursorTest =
    initQuiet.then(returnSleepUnflushed).then(flushSleepMarker).then(admit)
    .then(all {
      assert(s.sleepReturned), assert(s.sleepFlushed),
      assert(s.cursor == quietInitial.cursor + 1),
      assert(inbandObservation(s) != inbandObservation(quietInitial)),
      assert(not(s.mutatorKnown)), assert(not(s.renewed)),
      assert(not(s.suiteAdmitted)), assert(not(s.forcedNext)),
      assert(safe), s' = s
    })
  run quietCanHideNoWorkTest = initQuiet.then(admit)
    .then(all {
      assert(inbandObservation(s) == inbandObservation(quietInitial)),
      assert(s.vmAlloc == s.observerAlloc), assert(not(s.mutatorKnown)),
      assert(not(s.renewed)), assert(not(s.suiteAdmitted)),
      assert(not(s.forcedNext)), assert(safe), s' = s
    })
  // Host validation may advance the outer supervisor, never this child's GC.
  run hostValidationCannotBeChildGcTest = initHostValidationAsChildGc.then(admit)
    .then(all {
      assert(s.renewed), assert(not(collectionSafe)), assert(not(safe)),
      assert(not(s.suiteAdmitted)), s' = s
    })
  run generalNoBufferingFillsUnsetFileSlotTest =
    initQuiet.then(noteGeneralNoBuffering).then(finalizeUnsetFileSlot).then(admit)
    .then(all {
      assert(inbandObservation(s) == inbandObservation(quietInitial)),
      assert(s.generalBuffering == 1), assert(s.fileSlotBuffering == 0),
      assert(s.filePortBuffering == 1), assert(not(s.portObjectObserved)),
      assert(not(s.mutatorKnown)), assert(not(s.renewed)),
      assert(not(s.suiteAdmitted)), assert(not(s.forcedNext)),
      assert(safe), s' = s
    })
  run fileSlotFullKeepsFilePortTest =
    initQuiet.then(noteGeneralNoBuffering).then(noteFileSlotFullBuffering)
    .then(finalizeSetFileSlot).then(admit)
    .then(all {
      assert(inbandObservation(s) == inbandObservation(quietInitial)),
      assert(s.generalBuffering == 1), assert(s.fileSlotBuffering == 2),
      assert(s.filePortBuffering == 2), assert(not(s.portObjectObserved)),
      assert(not(s.mutatorKnown)), assert(not(s.renewed)),
      assert(not(s.suiteAdmitted)), assert(not(s.forcedNext)),
      assert(safe), s' = s
    })
  run countReturnCanShareTheAbsentDigitObservationTest = initQuiet
    .then(returnCountArgumentUnpublished).then(admit)
    .then(all {
      assert(s.kind == "count-return-unpublished"),
      assert(inbandObservation(s) == inbandObservation(quietInitial)),
      assert(not(s.portObjectObserved)), assert(not(s.renewed)),
      assert(not(s.suiteAdmitted)), assert(safe), s' = s
    })
  run writerEntryCanShareTheAbsentDigitObservationTest = initQuiet
    .then(returnCountArgumentUnpublished).then(enterCountWriterUnpublished).then(admit)
    .then(all {
      assert(s.kind == "count-write-entry-unpublished"),
      assert(inbandObservation(s) == inbandObservation(quietInitial)),
      assert(not(s.portObjectObserved)), assert(not(s.renewed)),
      assert(not(s.suiteAdmitted)), assert(safe), s' = s
    })
}

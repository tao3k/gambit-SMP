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
    collectionComplete: bool, reportForwarded: bool,
    gcReportEnabled: bool, attested: bool, completedFlag: bool,
    interferenceDisclosed: bool, claimsMutator: bool, mutatorKnown: bool,
    vmAlloc: int, observerAlloc: int, stockReadUntilEof: bool,
    childExit: int, stdoutOriginal: bool,
    proposal: bool, proposalSuite: bool,
    renewed: bool, suiteAdmitted: bool, forcedNext: bool, terminal: bool
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
    collectionComplete: true, reportForwarded: true,
    gcReportEnabled: true, attested: true, completedFlag: true,
    interferenceDisclosed: true, claimsMutator: false, mutatorKnown: false,
    vmAlloc: 2, observerAlloc: 1, stockReadUntilEof: false,
    childExit: -1, stdoutOriginal: true,
    proposal: true, proposalSuite: false,
    renewed: false, suiteAdmitted: false, forcedNext: false, terminal: false
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
  val streamHeld = s.reportForwarded and not(s.stockReadUntilEof)

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
}

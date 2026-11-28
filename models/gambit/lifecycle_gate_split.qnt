module lifecycle_gate_split {
  // One campaign state for the four open gates. solved is their conjunction.
  // Quiet is recorded by the exiting processor before thread exit and observed
  // by the owner after join returns, before transfer and before pending is
  // cleared. It is not initially true and seal does not write it. A normal
  // shrink never had a still-joinable error and cannot witness the other gates.
  // The 90-second cap stays 90. No native admission.
  type State = {
    control: int, rootHeld: bool, rootClaimed: bool, pending: bool,
    hadJoinError: bool, quietRecorded: bool, recordedByExit: bool,
    joined: bool, quietObserved: bool, transferred: bool, resized: bool,
    crossed: bool, cap: int, grouping: int, phiSmaller: bool,
    numericDone: bool, inventory: bool, gcClosed: bool,
    fault: bool, headerRecorded: bool, reprinted: bool, cause: int, repair: int,
    structureSolved: bool, rounds: int, failed: bool, stable: bool,
    published: bool, solved: bool
  }
  var s: State
  pure def initial(control: int): State = {
    control: control, rootHeld: false, rootClaimed: false, pending: true,
    hadJoinError: false, quietRecorded: false, recordedByExit: false,
    joined: false, quietObserved: false, transferred: false, resized: false,
    crossed: false, cap: 0, grouping: 0, phiSmaller: false,
    numericDone: false, inventory: false, gcClosed: false,
    fault: false, headerRecorded: false, reprinted: false, cause: 0, repair: 0,
    structureSolved: false, rounds: 0, failed: false, stable: true,
    published: false, solved: false
  }
  action initSplit = s' = initial(0)
  action initRootOnly = s' = initial(1)
  action initUnquiet = s' = initial(2)
  action initRootClaim = s' = initial(3)
  action initNormalShrink = s' = initial(4)
  action initSeal = s' = initial(5)
  action initAssumeQuiet = s' = initial(6)
  action rootRetain = all {
    s.control == 0, not(s.rootHeld),
    s' = { ...s, rootHeld: true }
  }
  action markJoinError = all {
    s.control == 0, s.rootHeld, s.pending, not(s.hadJoinError),
    s' = { ...s, hadJoinError: true }
  }
  action recordQuietBeforeExit = all {
    s.control == 0, s.hadJoinError, s.pending, not(s.joined), not(s.quietRecorded),
    s' = { ...s, quietRecorded: true, recordedByExit: true }
  }
  action joinAfterRecord = all {
    s.control == 0, s.quietRecorded, s.recordedByExit, s.pending, not(s.joined),
    s' = { ...s, joined: true }
  }
  action observeAfterJoin = all {
    s.control == 0, s.joined, s.quietRecorded, s.pending, not(s.quietObserved),
    s' = { ...s, quietObserved: true }
  }
  action transferAfterObserve = all {
    s.control == 0, s.quietObserved, s.joined, s.pending, not(s.transferred),
    s' = { ...s, transferred: true, pending: false }
  }
  action resizeAfterTransfer = all {
    s.control == 0, s.transferred, s.quietObserved, not(s.resized),
    s' = { ...s, resized: true }
  }
  action selectNewGrouping = all {
    s.control == 0, s.resized, s.cap == 0, s.grouping == 0, not(s.phiSmaller),
    s' = { ...s, cap: 90, grouping: 1 }
  }
  action finishNumeric = all {
    s.control == 0, s.cap == 90, s.grouping == 1, not(s.phiSmaller),
    not(s.numericDone),
    s' = { ...s, numericDone: true }
  }
  action recordInventory = all {
    s.control == 0, s.numericDone, s.cap == 90, not(s.inventory),
    s' = { ...s, inventory: true }
  }
  action closeGc = all {
    s.control == 0, s.inventory, s.cap == 90, s.grouping == 1, not(s.phiSmaller),
    not(s.gcClosed),
    s' = { ...s, gcClosed: true }
  }
  action noteFault = all {
    s.control == 0, s.gcClosed, not(s.fault),
    s' = { ...s, fault: true }
  }
  action recordEarly = all {
    s.control == 0, s.fault, not(s.headerRecorded), not(s.reprinted), s.cause == 0,
    s' = { ...s, headerRecorded: true, cause: 1 }
  }
  action recordLaterWrite = all {
    s.control == 0, s.fault, not(s.headerRecorded), not(s.reprinted), s.cause == 0,
    s' = { ...s, headerRecorded: true, cause: 2 }
  }
  action recordStale = all {
    s.control == 0, s.fault, not(s.headerRecorded), not(s.reprinted), s.cause == 0,
    s' = { ...s, headerRecorded: true, cause: 3 }
  }
  action recordEarlier = all {
    s.control == 0, s.fault, not(s.headerRecorded), not(s.reprinted), s.cause == 0,
    s' = { ...s, headerRecorded: true, cause: 4 }
  }
  action delayPublication = all {
    s.control == 0, s.headerRecorded, not(s.reprinted), s.cause == 1, s.repair == 0,
    s' = { ...s, repair: 1, structureSolved: true }
  }
  action removeLaterWrite = all {
    s.control == 0, s.headerRecorded, not(s.reprinted), s.cause == 2, s.repair == 0,
    s' = { ...s, repair: 2, structureSolved: true }
  }
  action refreshRoot = all {
    s.control == 0, s.headerRecorded, not(s.reprinted), s.cause == 3, s.repair == 0,
    s' = { ...s, repair: 3, structureSolved: true }
  }
  action fixFirstError = all {
    s.control == 0, s.headerRecorded, not(s.reprinted), s.cause == 4, s.repair == 0,
    s' = { ...s, repair: 4, structureSolved: true }
  }
  action sampleRound = all {
    s.control == 0, s.structureSolved, s.rounds < 2, not(s.failed), s.stable,
    s' = { ...s, rounds: s.rounds + 1 }
  }
  action publishMatched = all {
    s.control == 0, s.rounds == 2, not(s.failed), s.stable, not(s.published),
    s' = { ...s, published: true }
  }
  action closeCampaign = all {
    s.control == 0, s.rootHeld, s.hadJoinError, s.quietRecorded, s.recordedByExit,
    s.joined, s.quietObserved, s.transferred, s.resized, not(s.crossed),
    not(s.rootClaimed), s.cap == 90, s.grouping == 1, not(s.phiSmaller),
    s.numericDone, s.inventory, s.gcClosed, s.headerRecorded, not(s.reprinted),
    s.cause >= 1, s.cause <= 4, s.repair == s.cause, s.structureSolved,
    s.rounds == 2, s.published, not(s.failed), s.stable, not(s.solved),
    s' = { ...s, solved: true }
  }
  action closeRootOnly = all {
    s.control == 1, s.rootHeld or true, not(s.rootHeld),
    s' = { ...s, rootHeld: true }
  }
  action finishRootOnly = all {
    s.control == 1, s.rootHeld, not(s.resized), not(s.solved),
    s' = { ...s, solved: true }
  }
  action joinUnquiet = all {
    s.control == 2, s.pending, not(s.joined),
    s' = { ...s, joined: true }
  }
  action resizeUnquiet = all {
    s.control == 2, s.joined, not(s.quietRecorded), not(s.crossed),
    s' = { ...s, crossed: true, resized: true, pending: false }
  }
  action rootClaimsChild = all {
    s.control == 3, not(s.rootClaimed),
    s' = { ...s, rootHeld: true, rootClaimed: true, solved: true }
  }
  action normalShrink = all {
    s.control == 4, not(s.hadJoinError), not(s.resized),
    s' = { ...s, resized: true, joined: true, transferred: true, pending: false }
  }
  action shrinkStealsOthers = all {
    s.control == 4, s.resized, not(s.hadJoinError), not(s.gcClosed),
    s' = { ...s, gcClosed: true, structureSolved: true, published: true }
  }
  action sealWritesQuiet = all {
    s.control == 5, not(s.quietRecorded),
    s' = { ...s, quietRecorded: true, recordedByExit: false }
  }
  action assumeQuiet = all {
    s.control == 6, not(s.quietRecorded),
    s' = { ...s, quietRecorded: true, recordedByExit: false }
  }
  val campaign =
    s.solved and s.rootHeld and s.hadJoinError and s.quietRecorded and
    s.recordedByExit and s.joined and s.quietObserved and s.transferred and
    s.resized and not(s.crossed) and not(s.rootClaimed) and s.cap == 90 and
    s.grouping == 1 and not(s.phiSmaller) and s.numericDone and s.inventory and
    s.gcClosed and s.headerRecorded and not(s.reprinted) and s.cause >= 1 and
    s.cause <= 4 and s.repair == s.cause and s.structureSolved and
    s.rounds == 2 and s.published and not(s.failed) and s.stable
  val terminal = s.control == 0 and campaign
  action done = all { terminal, s' = s }
  action step = any {
    rootRetain, markJoinError, recordQuietBeforeExit, joinAfterRecord,
    observeAfterJoin, transferAfterObserve, resizeAfterTransfer, selectNewGrouping,
    finishNumeric, recordInventory, closeGc, noteFault, recordEarly,
    recordLaterWrite, recordStale, recordEarlier, delayPublication,
    removeLaterWrite, refreshRoot, fixFirstError, sampleRound, publishMatched,
    closeCampaign, closeRootOnly, finishRootOnly,
    joinUnquiet, resizeUnquiet, rootClaimsChild, normalShrink, shrinkStealsOthers,
    sealWritesQuiet, assumeQuiet, done
  }
  val safe =
    (not(s.quietRecorded) or s.recordedByExit or s.control == 5 or s.control == 6) and
    (not(s.quietObserved) or (s.joined and s.quietRecorded)) and
    (not(s.transferred) or s.quietObserved or s.control == 4) and
    (not(s.solved) or campaign)
  val bothEntries = not(s.solved) or (s.rootHeld and s.resized and s.hadJoinError)
  val noCross = not(s.crossed)
  val noRootClaim = not(s.rootClaimed)
  val noShrinkCarry =
    not(s.resized) or s.hadJoinError or
    (not(s.gcClosed) and not(s.structureSolved) and not(s.published))
  val quietFromExit = not(s.quietRecorded) or s.recordedByExit or s.control != 5
  val notAssumed = not(s.quietRecorded) or s.recordedByExit or s.control != 6
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}

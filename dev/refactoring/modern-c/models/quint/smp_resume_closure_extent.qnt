module smp_resume_closure_extent {
  // Conditional arithmetic for the selected profile only. The physical limit
  // is exclusive; an allocation of `words` writes through cursor + words - 1.
  // No live pointer, section ownership, or C ordering is modeled here.
  // A pre-check does not itself prove the next group fits.
  pure def fits(hp: int, words: int, end: int): bool =
    hp >= 0 and words > 0 and hp <= end and words <= end - hp
  pure def triggers(hp: int, poll: int): bool = hp > poll
  // Native rest fallback finishes pending pairs, then packs the parameters
  // in a vector before reaching a complete frame at which GC can run.
  pure def restFallbackWords(pending: int, params: int, pairWords: int, vectorHeader: int): int =
    pending * pairWords + params + vectorHeader
  val runtimeFudge = 8194
  val compilerBudget = 4096
  val largestObservedSingleClosure = 15
  // A static run of adjacent closure allocations, not a complete batch.
  val largestObservedContiguousRun = 22
  run witnessedExtentTest = assert(fits(100, 6, 100 + runtimeFudge))
  run selectedLargestTest = assert(fits(100, largestObservedSingleClosure, 100 + runtimeFudge))
  run observedClosureRunTest = assert(fits(100, largestObservedContiguousRun, 100 + runtimeFudge))
  run equalLimitNoPollTest = assert(not(triggers(100, 100)) and fits(100, runtimeFudge, 100 + runtimeFudge))
  run oversizedGroupNegativeTest = assert(not(triggers(100, 100)) and not(fits(100, runtimeFudge + 1, 100 + runtimeFudge)))
  run compilerMarginTest = assert(compilerBudget < runtimeFudge and largestObservedSingleClosure < compilerBudget)
  run nativeRestFallbackExactFitTest =
    assert(restFallbackWords(3000, 1, 3, 1) == 9002 and fits(100, 9002, 9102))
  run nativeRestFirstPairFitsButBatchRefusedTest =
    assert(fits(100, 3, 100 + runtimeFudge) and
      not(fits(100, restFallbackWords(3000, 1, 3, 1), 100 + runtimeFudge)))
  run nativeRestFinalVectorWordRefusedTest =
    assert(fits(100, 9000, 9101) and not(fits(100, 9002, 9101)))
}

// Temporal ownership only. The sibling module owns footprint arithmetic.
// A true root flag assumes the configured frame/RC projection was validated.
module smp_rest_reentry {
  type Wait = { key: int, epoch: int, grant: int, source: bool,
    installed: bool, ack: bool, repaired: bool, ready: bool,
    claimed: bool, entries: int }
  var w: Wait

  action init = w' = { key: 1, epoch: 0, grant: -1, source: true,
    installed: false, ack: false, repaired: false, ready: false,
    claimed: false, entries: 0 }
  action install = all {
    w.source and not(w.installed),
    w' = {...w, installed: true}
  }
  pure def query(s: Wait, key: int): bool = s.key == key and s.installed
  action acknowledge(key: int): bool = all {
    query(w, key) and not(w.ack),
    w' = {...w, source: false, ack: true}
  }
  action repair = all {
    w.ack and not(w.ready) and not(w.claimed),
    w' = {...w, epoch: w.epoch + 1, grant: -1, repaired: true}
  }
  pure def writable(s: Wait, epoch: int): bool =
    s.ack and s.repaired and not(s.ready) and not(s.claimed) and
    s.epoch == epoch and s.grant == epoch
  action reserve = all {
    w.repaired and not(w.ready) and not(w.claimed),
    w' = {...w, grant: w.epoch}
  }
  action finish = all {
    writable(w, w.epoch),
    w' = {...w, ready: true, grant: -1}
  }
  pure def claimable(s: Wait, key: int): bool =
    s.key == key and s.ready and not(s.claimed)
  action claim(key: int): bool = all {
    claimable(w, key),
    w' = {...w, claimed: true, entries: w.entries + 1}
  }
  val safe = (w.source or w.installed) and
    (not(w.ack) or w.installed) and
    (not(w.ready) or w.ack and w.repaired) and
    w.entries <= 1

  action missingAck = init.then(install).expect(safe and w.source and not(w.ack))
  action afterGC = missingAck.then(acknowledge(1)).then(repair)
  action packed = afterGC.then(reserve).then(finish)
  run restLostInstallReplyTest = missingAck
    .expect(query(w, 1) and not(query(w, 2)) and not(writable(w, 0)))
    .then(acknowledge(1)).expect(safe and not(w.source))
  run restRetryNeedsRepairedEpochTest = afterGC
    .expect(not(writable(w, 0)) and not(writable(w, 1)))
    .then(reserve).then(repair).expect(safe and not(writable(w, 1)))
    .then(reserve).expect(writable(w, 2))
  run restResumeOnceTest = packed.then(claim(1))
    .expect(safe and w.entries == 1 and not(claimable(w, 1)) and not(claimable(w, 2)))
  run restEarlyReleaseControlTest = init
    .then(all { w' = {...w, source: false} }).expect(not(safe))
  run restReplayControlTest = packed.then(claim(1))
    .then(all { w' = {...w, entries: w.entries + 1} }).expect(not(safe))
}

// Abstract directory slot only. The active record's GC roots and the
// wait's result are modeled by smp_rest_reentry, not by this module.
module smp_rest_record_lifetime {
  type Slot = { generation: int, phase: str, pinned: bool, invalidRead: bool }
  var slot: Slot

  action init = slot' = { generation: 1, phase: "open", pinned: false, invalidRead: false }
  pure def mayPin(s: Slot, generation: int): bool =
    s.phase == "open" and s.generation == generation and not(s.pinned)
  action pin(generation: int): bool = all {
    mayPin(slot, generation),
    slot' = {...slot, pinned: true}
  }
  action close = all {
    slot.phase == "open",
    slot' = {...slot, phase: "closed"}
  }
  pure def mayRead(s: Slot, generation: int): bool =
    s.phase != "free" and s.generation == generation and s.pinned
  action release = all {
    slot.pinned,
    slot' = {...slot, pinned: false}
  }
  pure def mayRetire(s: Slot): bool = s.phase == "closed" and not(s.pinned)
  action retire = all {
    mayRetire(slot),
    slot' = {...slot, phase: "free"}
  }
  action reuse = all {
    slot.phase == "free" and not(slot.pinned),
    slot' = {...slot, phase: "open", generation: slot.generation + 1}
  }
  val safe = not(slot.invalidRead) and (not(slot.pinned) or slot.phase != "free")

  run restPinWinsBeforeCloseTest = init.then(pin(1)).then(close)
    .expect(safe and mayRead(slot, 1) and not(mayRetire(slot)) and not(mayPin(slot, 1)))
    .then(release).then(retire).expect(safe and not(mayRead(slot, 1)))
  run restCloseWinsBeforePinTest = init.then(close).then(retire)
    .expect(safe and not(mayPin(slot, 1)) and not(mayRead(slot, 1)))
    .then(reuse).expect(safe and not(mayPin(slot, 1)) and mayPin(slot, 2))
  run restRawPointerFirstReadControlTest = init.then(close).then(retire)
    .then(all { slot' = {...slot, invalidRead: true} }).expect(not(safe))
}

// Caller-frame grant for one rest attempt. Arithmetic matches the selected
// no-handle layout: three words per pair, one vector header. Collection is
// admitted only after the caller frame and the root span are published.
// A one-word-short retry refuses the whole group. This is not a native trace.
module rest_caller_frame_grant {
  val pairWords = 3
  val vectorHeader = 1
  pure def fastWords(pending: int): int = pending * pairWords
  pure def retryWords(pending: int, params: int): int =
    fastWords(pending) + params + vectorHeader
  pure def fits(hp: int, words: int, end: int): bool =
    hp >= 0 and words > 0 and hp <= end and words <= end - hp
  pure def collectAdmitted(callerFrame: bool, roots: bool): bool =
    callerFrame and roots
  type Cut = { callerFrame: bool, roots: bool, collected: bool,
    stagedView: int, publishedView: int, consumedView: int,
    reloaded: bool, granted: bool, writes: int, pops: int, entries: int }
  var c: Cut
  action init = c' = { callerFrame: false, roots: false, collected: false,
    stagedView: 0, publishedView: 0, consumedView: 0,
    reloaded: false, granted: false, writes: 0, pops: 0, entries: 0 }
  action stageFrame = all {
    c.stagedView == 0,
    c' = {...c, stagedView: 1}
  }
  action publish = all {
    c.stagedView != 0 and c.publishedView == 0 and not(c.collected),
    c' = {...c, callerFrame: true, roots: true, publishedView: c.stagedView}
  }
  action collect = all {
    collectAdmitted(c.callerFrame, c.roots) and c.publishedView != 0 and not(c.collected),
    c' = {...c, collected: true, consumedView: c.publishedView}
  }
  action reload = all {
    c.collected and not(c.reloaded),
    c' = {...c, reloaded: true}
  }
  action grantExact = all {
    c.reloaded and not(c.granted) and fits(0, retryWords(4000, 1), 12002),
    c' = {...c, granted: true}
  }
  action writeGroup = all {
    c.granted and c.writes == 0 and c.pops == 0,
    c' = {...c, writes: fastWords(4000), pops: 4000, entries: 1}
  }
  action refuseShort = all {
    c.reloaded and not(c.granted) and not(fits(0, retryWords(4000, 1), 12001)),
    c' = c
  }
  val safe = c.entries <= 1 and
    (c.writes == 0 or c.granted) and
    (c.pops == 0 or c.granted) and
    (not(c.collected) or (collectAdmitted(c.callerFrame, c.roots) and
      c.publishedView != 0 and c.consumedView == c.publishedView))

  run exactRetryAdmittedTest = init.then(stageFrame).then(publish).then(collect).then(reload)
    .then(grantExact).then(writeGroup)
    .expect(safe and c.entries == 1 and c.writes == fastWords(4000) and c.pops == 4000)
  run oneShortRetryRefusedTest = init.then(stageFrame).then(publish).then(collect).then(reload)
    .then(refuseShort)
    .expect(safe and c.writes == 0 and c.pops == 0 and c.entries == 0 and not(c.granted))
  run windowCollectControlTest = init
    .then(all { c' = {...c, collected: true} }).expect(not(safe))
  run stagedViewCollectControlTest = init.then(stageFrame)
    .then(all { c' = {...c, callerFrame: true, roots: true,
      collected: true, consumedView: c.stagedView} }).expect(not(safe))
  run splitCursorViewControlTest = init.then(stageFrame).then(publish)
    .then(all { c' = {...c, collected: true, consumedView: c.publishedView + 1} })
    .expect(not(safe))
  run secondEntryControlTest = init.then(stageFrame).then(publish).then(collect).then(reload)
    .then(grantExact).then(writeGroup)
    .then(all { c' = {...c, entries: c.entries + 1} }).expect(not(safe))
  run fastOneShortBoundaryTest =
    assert(fits(0, pairWords, 100) and
      not(fits(0, fastWords(4000), 11999)) and
      fits(0, fastWords(4000), 12000) and
      not(fits(0, retryWords(4000, 1), 12001)) and
      fits(0, retryWords(4000, 1), 12002) and
      retryWords(4000, 1) == 12002)
}

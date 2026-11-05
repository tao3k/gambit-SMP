module generational_barrier {
  // TARGET only. Three old source slots/two cards, one young object/two words,
  // one explicit native root, one outstanding writer and one evacuation owner.
  type State = { phase: int, slots: int -> int, root: int, dirty: Set[int],
    hints: Set[int], overflow: bool, pending: int, selected: Set[int],
    scannedCards: Set[int], registered: bool, known: bool, epoch: int,
    cutEpoch: int, reserved: int, used: int, forward: bool, everForward: bool,
    remaining: int, copyOwner: bool, ready: bool, copyScanned: bool,
    rootRewritten: bool, sourceAlive: bool, payloadRead: bool, gcCalls: int }
  var s: State
  val allSlots = Set(0, 1, 2)
  pure def card(i: int): int = if (i < 2) 0 else 1
  action init = s' = { phase: 0, slots: Map(0 -> -1, 1 -> -1, 2 -> -1), root: -1,
    dirty: Set(), hints: Set(), overflow: false, pending: -1, selected: Set(),
    scannedCards: Set(), registered: true, known: true, epoch: 1, cutEpoch: 0,
    reserved: 0, used: 0, forward: false, everForward: false, remaining: 0,
    copyOwner: false, ready: false, copyScanned: false, rootRewritten: false,
    sourceAlive: true, payloadRead: false, gcCalls: 0 }
  val youngEdges = allSlots.filter(i => s.slots.get(i) == 0)
  val allRewritten = youngEdges.size() == 0 and s.root != 0
  val cut = s.phase >= 2 and s.phase <= 5
  val safe = youngEdges.forall(i => s.dirty.contains(card(i))) and
    (not(cut) or (s.pending == -1 and s.known and s.registered and s.cutEpoch == s.epoch)) and
    (not(cut) or youngEdges.forall(i => s.selected.contains(card(i)))) and
    (not(s.forward) or (s.used == 2 and (s.ready or s.copyOwner))) and
    (not(s.everForward) or s.phase != 0) and
    (not(s.payloadRead) or s.ready) and
    (s.sourceAlive or s.phase == 5) and
    (s.phase != 5 or (s.ready and s.copyScanned and s.rootRewritten and allRewritten and not(s.copyOwner))) and
    s.gcCalls == 0
  // Card coverage is authoritative; the capacity-one hint set is only an accelerator.
  action reserveStore = all { s.phase == 0, s.pending == -1,
    nondet i = allSlots.oneOf()
    val c = card(i)
    val room = s.hints.contains(c) or s.hints.size() < 1
    s' = { ...s, pending: i, dirty: s.dirty.union(Set(c)),
      hints: if (room) s.hints.union(Set(c)) else s.hints,
      overflow: s.overflow or not(room) } }
  action commitStore = all { s.pending >= 0, s.phase <= 1,
    s' = { ...s, slots: s.slots.set(s.pending, 0), pending: -1 } }
  action abortBeforeStore = all { s.pending >= 0, s.phase <= 1,
    s' = { ...s, pending: -1 } }
  action rootStore = all { s.phase == 0, s.pending == -1, s.registered,
    s' = { ...s, root: 0 } }
  action closeIngress = all { s.phase == 0, s' = { ...s, phase: 1 } }
  action seal = all { s.phase == 1, s.pending == -1, s.known, s.registered,
    s' = { ...s, phase: 2, cutEpoch: s.epoch,
      selected: if (s.overflow) s.dirty else s.hints } }
  // Physical destination + copy-work custody acquired before destructive forwarding.
  action acceptReserve = all { s.phase == 2,
    s' = { ...s, phase: 3, reserved: 2, copyOwner: true } }
  action rejectReserve = all { s.phase == 2, not(s.everForward),
    s' = { ...s, phase: 6 } }
  action retryOrDeliverFailure = all { s.phase == 6, not(s.everForward), s.sourceAlive,
    s' = { ...s, phase: 0 } }
  action releaseUnpublishedReserve = all { s.phase == 3, not(s.everForward),
    s' = { ...s, phase: 6, reserved: 0, copyOwner: false } }
  action publishForward = all { s.phase == 3, s.reserved == 2, s.copyOwner,
    s' = { ...s, phase: 4, reserved: 0, used: 2, forward: true,
      everForward: true, remaining: 2 } }
  action initializeWord = all { s.phase == 4, s.copyOwner, s.remaining > 0,
    s' = { ...s, remaining: s.remaining - 1 } }
  action makeReady = all { s.phase == 4, s.remaining == 0, s.copyOwner,
    s' = { ...s, ready: true } }
  // Redirecting a root to a pending copy is allowed; dereferencing its body is not.
  action rewriteRoot = all { s.phase == 4, s.forward, not(s.rootRewritten),
    s' = { ...s, root: if (s.root == 0) 10 else s.root, rootRewritten: true } }
  action scanCard = all { s.phase == 4, s.forward,
    s.selected.exclude(s.scannedCards).size() > 0,
    nondet c = s.selected.exclude(s.scannedCards).oneOf()
    s' = { ...s, scannedCards: s.scannedCards.union(Set(c)),
      slots: s.slots.mapBy((i, v) => if (card(i) == c and v == 0) 10 else v) } }
  action scanCopy = all { s.phase == 4, s.ready, s.copyOwner,
    s' = { ...s, copyScanned: true, copyOwner: false, payloadRead: true } }
  action finish = all { s.phase == 4, s.ready, s.copyScanned, not(s.copyOwner),
    s.rootRewritten, s.selected.subseteq(s.scannedCards), allRewritten,
    s' = { ...s, phase: 5, sourceAlive: false, dirty: Set(), hints: Set(), overflow: false } }
  action resumeNextEpoch = all { s.phase == 5,
    s' = { ...s, phase: 0, epoch: s.epoch + 1, selected: Set(), scannedCards: Set(),
      forward: false, everForward: false, used: 0, ready: false, copyScanned: false,
      rootRewritten: false, sourceAlive: true, payloadRead: false } }
  action quarantineUnexpectedFailure = all { s.phase == 4,
    s' = { ...s, phase: 7 } }
  action step = any { reserveStore, commitStore, abortBeforeStore, rootStore,
    closeIngress, seal, acceptReserve, rejectReserve, retryOrDeliverFailure,
    releaseUnpublishedReserve, publishForward, initializeWord, makeReady,
    rewriteRoot, scanCard, scanCopy, finish, resumeNextEpoch, quarantineUnexpectedFailure }
  action badDirectStore = s' = { ...s, slots: s.slots.set(0, 0) }
  action badClearDirty = s' = { ...s, dirty: Set() }
  action badSuppressOverflow = s' = { ...s, overflow: false }
  action badSealPending = s' = { ...s, phase: 2, selected: s.dirty, cutEpoch: s.epoch }
  action badConsumePending = s' = { ...s, payloadRead: true }
  action badRollbackPublished = s' = { ...s, phase: 0, forward: false, remaining: 0 }
  action badReturnUsedCredit = s' = { ...s, used: 0 }
  action badLoseCopyOwner = s' = { ...s, copyOwner: false }
  action badFreeSource = s' = { ...s, sourceAlive: false }
  action badHiddenGC = s' = { ...s, gcCalls: 1 }
  action badReuseEpoch = s' = { ...s, epoch: s.epoch + 1 }
  action badFinish = s' = { ...s, phase: 5 }
  // Deterministic adapters select actual source-slot scenarios within this finite kernel.
  action writeFrame = reserveStore.expect(s.pending == 0).then(commitStore)
  action writeDenv = reserveStore.expect(s.pending == 2).then(commitStore)
  action reserveFrame = reserveStore.expect(s.pending == 0)
  action reserveDenv = reserveStore.expect(s.pending == 2)
  action copyComplete = initializeWord.then(initializeWord).then(makeReady).then(scanCopy)
  run matureFrameTest = init.then(writeFrame).then(closeIngress).then(seal).then(acceptReserve)
    .then(publishForward).then(rewriteRoot).then(scanCard).then(copyComplete).then(finish).expect(safe)
  run denvOverflowTest = init.then(writeFrame).then(writeDenv).then(closeIngress).then(seal)
    .then(acceptReserve).then(publishForward).then(scanCard).then(scanCard).then(rewriteRoot)
    .then(copyComplete).then(finish).expect(safe)
  run nativeRootTest = init.then(rootStore).then(closeIngress).then(seal).then(acceptReserve)
    .then(publishForward).then(rewriteRoot).then(copyComplete).then(finish).expect(safe)
  run closeWaitsWriterTest = init.then(reserveFrame).then(closeIngress).then(commitStore).then(seal).expect(safe)
  run abortLeavesDirtyTest = init.then(reserveFrame).then(closeIngress).then(abortBeforeStore).then(seal).expect(safe and s.dirty == Set(0))
  run preflightFailureTest = init.then(writeFrame).then(closeIngress).then(seal).then(rejectReserve)
    .then(retryOrDeliverFailure).expect(safe and s.slots.get(0) == 0 and s.dirty == Set(0))
  run unpublishedReserveRefundTest = init.then(closeIngress).then(seal).then(acceptReserve)
    .then(releaseUnpublishedReserve).then(retryOrDeliverFailure).expect(safe and s.reserved == 0)
  run pendingForwardRootTest = init.then(rootStore).then(closeIngress).then(seal).then(acceptReserve)
    .then(publishForward).then(rewriteRoot).expect(safe and not(s.ready) and s.remaining == 2 and s.root == 10)
  run partialFailureCustodyTest = init.then(closeIngress).then(seal).then(acceptReserve).then(publishForward)
    .then(initializeWord).then(quarantineUnexpectedFailure).expect(safe and s.copyOwner and s.sourceAlive)
  run nextEpochResetTest = init.then(writeFrame).then(closeIngress).then(seal).then(acceptReserve)
    .then(publishForward).then(scanCard).then(rewriteRoot).then(copyComplete).then(finish)
    .then(resumeNextEpoch).then(writeDenv).expect(safe and s.epoch == 2 and s.dirty == Set(1))
  run uncheckedFrameControlTest = init.then(badDirectStore).expect(not(safe))
  run earlyCardClearControlTest = init.then(writeFrame).then(badClearDirty).expect(not(safe))
  run lostOverflowControlTest = init.then(writeFrame).then(writeDenv).then(badSuppressOverflow)
    .then(closeIngress).then(seal).expect(not(safe))
  run pendingWriterCutControlTest = init.then(reserveFrame).then(closeIngress).then(badSealPending).expect(not(safe))
  run partialPayloadReadControlTest = init.then(closeIngress).then(seal).then(acceptReserve).then(publishForward)
    .then(badConsumePending).expect(not(safe))
  run publishedRollbackControlTest = init.then(closeIngress).then(seal).then(acceptReserve).then(publishForward)
    .then(badRollbackPublished).expect(not(safe))
  run prematureRefundControlTest = init.then(closeIngress).then(seal).then(acceptReserve).then(publishForward)
    .then(badReturnUsedCredit).expect(not(safe))
  run lostCopyOwnerControlTest = init.then(closeIngress).then(seal).then(acceptReserve).then(publishForward)
    .then(badLoseCopyOwner).expect(not(safe))
  run prematureSourceFreeControlTest = init.then(closeIngress).then(seal).then(acceptReserve).then(publishForward)
    .then(badFreeSource).expect(not(safe))
  run implicitGCControlTest = init.then(reserveFrame).then(badHiddenGC).expect(not(safe))
  run staleCutControlTest = init.then(closeIngress).then(seal).then(badReuseEpoch).expect(not(safe))
  run incompleteFinishControlTest = init.then(closeIngress).then(seal).then(acceptReserve).then(publishForward)
    .then(badFinish).expect(not(safe))
}

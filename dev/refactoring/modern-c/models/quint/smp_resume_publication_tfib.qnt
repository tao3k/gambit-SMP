module smp_resume_publication_tfib {
  // Two-participant ordering abstracted from barrier_sync_op's child-before
  // parent release, plus the publication reserve. This is not the C memory
  // model, a scheduler bound, or a native barrier witness.
  // TFIB figures are conditional arithmetic. The reduced 1,000-delay counter
  // is not a measurement of go 15 5000.
  pure def release(childArrived: bool, readerHeld: bool): bool =
    childArrived and not(readerHeld)
  pure def allocate(released: bool, published: bool, reserve: bool): bool =
    released and published and reserve
  pure def positiveWitness(waitingLoad: int, readerReleased: int,
                           readerFinished: int, parentReturned: int): bool =
    0 < waitingLoad and waitingLoad < readerReleased and
      readerReleased < readerFinished and readerFinished < parentReturned
  pure def bypassWitness(parentCrossed: int, readerReleased: int,
                         readerFinished: int, cleanupReached: bool): bool =
    0 < parentCrossed and parentCrossed < readerReleased and
      readerReleased < readerFinished and not(cleanupReached)
  pure def reloadWitness(firstMatches: bool, noGap: bool): bool =
    firstMatches and noGap
  // C refinement supplies the identity comparisons and the complete write
  // extent. Range alone cannot establish a current allocation authority.
  pure def firstWriteAdmitted(released: bool, published: bool, reserve: bool,
                              sameOwner: bool, sameEpoch: bool,
                              sameSection: bool, sameHalf: bool,
                              sameInterval: bool, reloaded: bool,
                              completeWriteFits: bool): bool =
    allocate(released, published, reserve) and sameOwner and sameEpoch and
      sameSection and sameHalf and sameInterval and reloaded and completeWriteFits

  run currentReloadAdmitsWriteTest = assert(
    firstWriteAdmitted(true, true, true, true, true, true, true, true, true, true))
  run foreignInRangeControlTest = assert(not(
    firstWriteAdmitted(true, true, true, false, true, true, true, true, true, true)))
  run staleEpochInRangeControlTest = assert(not(
    firstWriteAdmitted(true, true, true, true, false, true, true, true, true, true)))
  run wrongSectionWithSameBoundsRefusedTest = assert(not(
    firstWriteAdmitted(true, true, true, true, true, false, true, true, true, true)))
  run wrongHalfWithSameBoundsRefusedTest = assert(not(
    firstWriteAdmitted(true, true, true, true, true, true, false, true, true, true)))
  run wrongIntervalControlTest = assert(not(
    firstWriteAdmitted(true, true, true, true, true, true, true, false, true, true)))
  run missingReloadControlTest = assert(not(
    firstWriteAdmitted(true, true, true, true, true, true, true, true, false, true)))
  run lastFieldOutsideGrantControlTest = assert(not(
    firstWriteAdmitted(true, true, true, true, true, true, true, true, true, false)))
  pure def sharedHeapPublicationFits(base: int, cursor: int, heapPast: int,
                                     stackFloor: int, halfPast: int,
                                     sameCarrier: bool): bool =
    sameCarrier and base <= cursor and cursor <= heapPast and
      heapPast <= stackFloor and stackFloor <= halfPast
  run sharedHeapExactStackFloorTest = assert(
    sharedHeapPublicationFits(0, 2, 8, 8, 16, true))
  run sharedHeapOneWordStackOverlapTest = assert(not(
    sharedHeapPublicationFits(0, 2, 9, 8, 16, true)))
  run sharedHeapForeignStackClaimTest = assert(not(
    sharedHeapPublicationFits(0, 2, 8, 8, 16, false)))

  pure def coveredWriteFits(cursor: int, words: int, physicalPast: int): bool =
    cursor <= physicalPast and words <= physicalPast - cursor
  run firstPairWithExactRoomTest = assert(
    firstWriteAdmitted(true, true, true, true, true, true, true, true, true,
      coveredWriteFits(4, 3, 7)))
  run firstPairWithShortRoomRefusedTest = assert(not(
    firstWriteAdmitted(true, true, true, true, true, true, true, true, true,
      coveredWriteFits(4, 3, 6))))
  pure def unaryRteWitness(selectedHost: bool, cursor: int, physicalPast: int,
                           header: bool, writtenFields: Set[int], advanced: int): bool =
    selectedHost and coveredWriteFits(cursor, 4, physicalPast)
      and header and writtenFields == Set(0, 1, 2) and advanced == cursor + 4
  run unaryRteCompleteWriteTest = assert(unaryRteWitness(true, 4, 8, true, Set(0, 1, 2), 8))
  run unaryRteThreeWordRoomRefusedTest = assert(not(unaryRteWitness(true, 4, 7, true, Set(0, 1, 2), 8)))
  run unaryRteMissingPayloadRefusedTest = assert(not(unaryRteWitness(true, 4, 8, true, Set(0, 1), 8)))

  pure def linkedJoinWitness(requestedAtJoin: bool, firstKind: str,
                             returnedToJoin: bool, complete: bool): bool =
    requestedAtJoin and firstKind == "closure" and returnedToJoin and complete
  run linkedJoinFirstCompleteClosureTest = assert(linkedJoinWitness(true, "closure", true, true))
  run interveningPairCannotCertifyJoinFirstTest = assert(not(
    linkedJoinWitness(true, "pair", true, true)))
  pure def perDelayCalls(delay: int): int = delay + 2
  pure def conditionalRte(nodes: int, roots: int, delay: int): int =
    nodes * roots * perDelayCalls(delay)

  run heldReaderBlocksReleaseTest = assert(not(release(true, true)))
  run childArrivalReleasesTest = assert(release(true, false))
  run missingChildControlTest = assert(not(release(false, false)))
  run reserveAllowsFirstClosureTest = assert(allocate(true, true, true))
  run shortReserveControlTest = assert(not(allocate(true, true, false)))
  run barrierBypassControlTest = assert(not(allocate(false, true, true)))
  run observedWaitingLoadTest = assert(positiveWitness(1, 2, 3, 4))
  run preLoadEntryMarkerRefusedTest = assert(not(positiveWitness(0, 2, 3, 4)))
  run earlyParentReturnRefusedTest = assert(not(positiveWitness(1, 2, 4, 3)))
  run heldReaderBypassDetectedTest = assert(bypassWitness(1, 2, 3, false))
  run bypassCleanupRefusedTest = assert(not(bypassWitness(1, 2, 3, true)))
  run laterCorrectReloadCannotRepairFirstTest = assert(not(reloadWitness(false, true)))
  run cursorGapAfterFirstReloadRefusedTest = assert(not(reloadWitness(true, false)))
  run reducedDelayRatioTest = assert(1000 * perDelayCalls(6000) == 6002000)
  run fullConditionalRteTest = assert(
    conditionalRte(1973, 5000, 6000) == 59209730000)
  run reducedIsNotFullControlTest = assert(
    not(1000 * perDelayCalls(6000) == conditionalRte(1973, 5000, 6000)))
  run erasedDelayControlTest = assert(
    not(conditionalRte(1973, 5000, 0) == conditionalRte(1973, 5000, 6000)))
  run app2DoubleControlTest = assert(not(12003 == perDelayCalls(6000) * 2))
}

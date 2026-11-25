module smp_interpreter_source_order {
  // Source-order obligations taken from the current interpreter and the
  // generated thread-join shape. This is not an implementation, a census,
  // a measured TFIB profile, or a native barrier witness.
  // ##cprc-prc-req1 consults the entry hook before execute. execute is the
  // path that builds one macro-make-rte vector. A hook that never calls
  // exec builds none; each exec call builds one. ##cprc-app1-red and
  // ##cprc-app2-sub remain separate dispatches if that vector is removed.
  // collection-round sets restored and then calls BARRIER(), which reaches
  // barrier_sync_op. The generated thread-join site writes ALLOC_CLO(4)
  // before CHECK_HEAP, and that macro does not evaluate its reservation.
  pure def rteVectors(hookPresent: bool, execCalls: int): int =
    if (hookPresent) execCalls else 1
  pure def dispatchesRemain(removeVector: bool): bool = true
  pure def vectorRemovalIsNotEquivalent(removeVector: bool): bool =
    removeVector and dispatchesRemain(removeVector)
  pure def parentPasses(childArrived: bool, readerHeld: bool, syncCalled: bool): bool =
    childArrived and not(readerHeld) and syncCalled
  pure def writePrecedesCheck(allocIndex: int, checkIndex: int): bool =
    allocIndex < checkIndex
  pure def reservationEvaluated(macroIgnoresSecondArg: bool): bool =
    not(macroIgnoresSecondArg)
  pure def perDelayCalls(delay: int): int = delay + 2
  pure def conditionalRte(nodes: int, roots: int, delay: int): int =
    nodes * roots * perDelayCalls(delay)
  pure def numericCalls(nodes: int, roots: int, delay: int): int =
    nodes * roots * (2 * delay + 1)
  pure def binaryFast(builtinEntered: bool, arity: int, exactOperands: bool,
                      resultFits: bool): bool =
    builtinEntered and arity == 2 and exactOperands and resultFits

  pure def binaryResultRoute(fastProof: bool, polled: bool, checkedFallback: bool): bool =
    if (fastProof) polled else checkedFallback
  run provedResultRetainsPollTest = assert(binaryResultRoute(true, true, false))
  run provedResultWithoutPollRefusedTest = assert(not(binaryResultRoute(true, false, false)))
  run overflowWithoutResultChecksRefusedTest = assert(not(binaryResultRoute(false, true, false)))

  run noHookBuildsOneVectorTest = assert(rteVectors(false, 0) == 1)
  run hookCanSkipVectorTest = assert(rteVectors(true, 0) == 0)
  run hookReentryBuildsTwoTest = assert(rteVectors(true, 2) == 2)
  run negativeExecCountStaysNegativeTest = assert(rteVectors(true, -1) < 0)
  run vectorRemovalLeavesDispatchesTest = assert(dispatchesRemain(true))
  run removalIsNotEquivalenceTest = assert(vectorRemovalIsNotEquivalent(true))
  run keptVectorIsNotRemovalTest = assert(not(vectorRemovalIsNotEquivalent(false)))
  run heldReaderBlocksParentTest = assert(not(parentPasses(true, true, true)))
  run skippedSyncBlocksParentTest = assert(not(parentPasses(true, false, false)))
  run arrivedFreeSyncPassesTest = assert(parentPasses(true, false, true))
  run missingChildBlocksParentTest = assert(not(parentPasses(false, false, true)))
  run writeBeforeCheckTest = assert(writePrecedesCheck(1, 2))
  run reversedWriteOrderRejectedTest = assert(not(writePrecedesCheck(2, 1)))
  run ignoredReservationTest = assert(not(reservationEvaluated(true)))
  run evaluatedReservationDiffersTest = assert(reservationEvaluated(false))
  run fullCountRetainsDelaysTest = assert(
    conditionalRte(1973, 5000, 6000) == 59209730000)
  run reducedIsNotFullSourceOrderTest = assert(
    not(1000 * perDelayCalls(6000) == conditionalRte(1973, 5000, 6000)))
  run fullNumericCallsTest = assert(numericCalls(1973, 5000, 6000) == 118389865000)
  run exactBinaryCallsFastTest = assert(binaryFast(true, 2, true, true))
  run replacementOperatorKeepsDispatchTest = assert(not(binaryFast(false, 2, true, true)))
  run subtractionOverflowKeepsFallbackTest = assert(not(binaryFast(true, 2, true, false)))
  run nonFixnumKeepsFallbackTest = assert(not(binaryFast(true, 2, false, true)))
  run variadicCallKeepsFoldTest = assert(not(binaryFast(true, 3, true, true)))
}

module continuation_contract {
  // Existing save/restore/current-root/saved-origin behavior; arbitrary distinct IDs.
  import continuation_saved_stack_origin.* from "./continuation_saved_stack_origin"
  action injectedOriginLoss = all { s.phase >= 2,
    s' = { ...s, raw: s.raw.exclude(Set(s.savedPrevious)) } }
  run currentAndSavedDistinctTest = init.then(saveCurrent).then(restoreNext).then(scanCurrentRoots)
    .expect(guardSound and s.rootCopied == Set(s.next) and s.raw.contains(s.previous))
  run savedTraversalTest = init.then(saveCurrent).then(restoreNext).then(scanCurrentRoots)
    .then(queueSavedContinuation).then(rootBarrier).then(scanSavedContinuation)
    .expect(guardSound and terminal and s.scanInput == "stack")
  run currentRootsAloneControlTest = init.then(saveCurrent).then(restoreNext).then(scanCurrentRoots)
    .then(injectedOriginLoss).expect(not(savedFrameRetained))
}

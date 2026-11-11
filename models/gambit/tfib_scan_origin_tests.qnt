module tfib_scan_origin_tests {
  import tfib_scan_origin.* from "./tfib_scan_origin"
  action normalFirst = selectEntry.then(commitCell).then(readCell)
    .then(commitHeader).then(readHeader).then(postmortem).then(nextEpoch)
  action secondHeader = selectEntry.then(commitCell).then(readCell)
    .then(commitHeader).then(readHeader).then(postmortem)
  action initF64 = all { s' = initial(0,1) }
  action initFrame = all { s' = initial(0,2) }
  action initWriter = all { s' = initial(0,4) }
  action initUnknownWriter = all { s' = initial(0,8) }
  action initTail = all { s' = initial(0,5) }
  action initCellFault = all { s' = initial(0,10) }
  action initReusedObject = all { s' = initial(0,11) }
  run sameAddressOldWriterIsNotCause = initReusedObject.then(normalFirst).then(secondHeader)
    .expect(done and s.diagnosis == 6 and s.record.writerObject == s.record.object
      and s.record.writerGeneration != s.record.objectGeneration and safe)
  run sameWordF64Route = initF64.then(normalFirst).then(secondHeader)
    .expect(done and s.fault and s.diagnosis == 1 and not(nativeSuccess) and safe)
  run sameWordFrameRoute = initFrame.then(normalFirst).then(secondHeader)
    .expect(done and s.fault and s.diagnosis == 2 and safe)
  run actualWriterWitness = initWriter.then(normalFirst).then(secondHeader)
    .expect(done and s.diagnosis == 5 and safe)
  run heapCorruptionDoesNotInventWriter = initUnknownWriter.then(normalFirst).then(secondHeader)
    .expect(done and s.diagnosis == 6 and s.record.writerObject == 0 and safe)
  run tailRetainsEntryAndCursor = initTail.then(normalFirst).then(secondHeader)
    .expect(done and s.record.entry == 3 and s.record.cursor == 1 and s.diagnosis == 6 and safe)
  run badCellNeedsPreCellRecord = initCellFault.then(normalFirst)
    .then(selectEntry).then(commitCell).then(readCell).then(postmortem)
    .expect(done and s.faultOp == 1 and not(s.rawKnown) and s.diagnosis == 4 and safe)
}

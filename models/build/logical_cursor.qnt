module logical_cursor {
  import logical_cursor_parameters.* from "./logical_cursor_parameters"
  // Five decoded characters: ignored prefix [0,1), lexeme [1,4), lookahead [4,5).
  // This is interval accounting, not a Scheme/regexp interpreter.
  type State = { committed: int, fetched: int, logical: int, tokenId: int,
    peekId: int, pins: int, errors: int, borrows: int, unknown: bool,
    result: int, reads: int, delivered: bool, retired: bool,
    generation: int, captureGeneration: int, saved: int, observed: int,
    accepted: Set[int], trivia: Set[int], unread: Set[int], repeated: bool }
  var s: State
  action init = s' = { committed: 0, fetched: 0, logical: 0, tokenId: -1,
    peekId: -1, pins: 0, errors: 0, borrows: 0, unknown: false,
    result: 0, reads: 0, delivered: false, retired: false,
    generation: 1, captureGeneration: 0, saved: 0, observed: -1,
    accepted: Set(), trivia: Set(), unread: Set(), repeated: false }
  action scan = all { s.committed == 0, not(s.retired),
    s' = { ...s, committed: 4, fetched: FixtureChars, logical: 4, tokenId: 7,
      accepted: Set(1, 2, 3), trivia: Set(0), unread: Set(4) } }
  action peek = all { s.tokenId == 7, s' = { ...s, peekId: s.tokenId } }
  action capture = all { s.pins == 0, not(s.retired),
    s' = { ...s, pins: 1, saved: s.logical, captureGeneration: s.generation } }
  action readUnknown = all { s.logical == 4, s.reads == 0, not(s.retired),
    s' = { ...s, logical: 5, committed: 5, reads: 1, result: 1, unknown: true,
      accepted: s.accepted.union(s.unread), unread: Set() } }
  action errorUnknown = all { s.logical == 4, s.reads == 0, not(s.retired),
    s' = { ...s, logical: 5, committed: 5, reads: 1, result: 2, errors: 1, unknown: true,
      accepted: s.accepted.union(s.unread), unread: Set() } }
  action settle = all { s.unknown, not(s.delivered),
    s' = { ...s, unknown: false, delivered: true } }
  action resume = all { s.pins == 1, s.captureGeneration == s.generation,
    s' = { ...s, observed: s.logical } }
  action releaseCapture = all { s.pins == 1, s' = { ...s, pins: 0 } }
  action releaseError = all { s.errors == 1, s.delivered, s' = { ...s, errors: 0 } }
  action borrow = all { s.borrows == 0, not(s.retired), s' = { ...s, borrows: 1 } }
  action releaseBorrow = all { s.borrows == 1, s' = { ...s, borrows: 0 } }
  def drained = s.pins == 0 and s.errors == 0 and s.borrows == 0 and not(s.unknown)
  action retire = all { drained, s' = { ...s, retired: true } }
  def fetchedSet = if (s.fetched == 0) Set() else 0.to(s.fetched - 1)
  def partitioned = s.accepted.union(s.trivia).union(s.unread) == fetchedSet and
    s.accepted.intersect(s.trivia) == Set() and s.accepted.intersect(s.unread) == Set() and
    s.trivia.intersect(s.unread) == Set()
  def safe = partitioned and not(s.repeated) and s.committed == s.logical and
    s.logical <= s.fetched and s.committed <= s.fetched and s.reads <= 1 and
    (s.peekId != -1 implies s.peekId == s.tokenId) and
    (s.retired implies drained) and
    (s.pins > 0 implies s.captureGeneration == s.generation)
  action step = any { scan, peek, capture, readUnknown, errorUnknown, settle,
    resume, releaseCapture, releaseError, borrow, releaseBorrow, retire, s' = s }
  action loseTrivia = s' = { ...s, trivia: Set() }
  action overlapLookahead = s' = { ...s, accepted: s.accepted.union(s.unread) }
  action cloneToken = s' = { ...s, peekId: 8 }
  action rewindCapture = s' = { ...s, logical: s.saved, observed: s.saved }
  action retireEarly = s' = { ...s, retired: true }
  action retry = s' = { ...s, reads: s.reads + 1, repeated: true }
  action replaceGeneration = s' = { ...s, generation: s.generation + 1 }
  run intervalPartitionTest = init.then(scan).expect(safe and s.committed == 4 and s.fetched == 5 and s.logical == 4)
  run identityPeekTest = init.then(scan).then(peek).then(peek).expect(safe and s.peekId == 7)
  run resumeCurrentTest = init.then(scan).then(capture).then(readUnknown).then(resume).expect(safe and s.observed == 5 and s.saved == 4)
  run valueSettleTest = init.then(scan).then(readUnknown).then(settle).expect(safe and s.delivered and s.reads == 1)
  run errorSettleTest = init.then(scan).then(errorUnknown).then(settle).expect(safe and s.result == 2 and s.errors == 1)
  run drainTest = init.then(scan).then(capture).then(errorUnknown).then(settle).then(releaseCapture).then(releaseError).then(retire).expect(safe and s.retired)
  run borrowDrainTest = init.then(borrow).then(releaseBorrow).then(retire).expect(safe and s.retired)
  run pendingBlocksRetireTest = init.then(scan).then(readUnknown).expect(safe and not(drained))
  run lostTriviaControlTest = init.then(scan).then(loseTrivia).expect(not(safe))
  run overlappingSpanControlTest = init.then(scan).then(overlapLookahead).expect(not(safe))
  run tokenCloneControlTest = init.then(scan).then(cloneToken).expect(not(safe))
  run captureRollbackControlTest = init.then(scan).then(capture).then(readUnknown).then(rewindCapture).expect(not(safe) and s.observed != 5)
  run earlyRetireControlTest = init.then(capture).then(retireEarly).expect(not(safe))
  run unknownRetryControlTest = init.then(scan).then(readUnknown).then(retry).expect(not(safe))
  run generationReplaceControlTest = init.then(capture).then(replaceGeneration).expect(not(safe))
  run errorRootDropControlTest = init.then(scan).then(errorUnknown).then(settle).then(retireEarly).expect(not(safe))
}

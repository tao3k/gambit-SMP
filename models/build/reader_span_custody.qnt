module reader_span_custody {
  import reader_span_parameters.* from "./reader_span_parameters"
  // Occurrence identities, not character values: equal characters at different
  // source offsets must never collapse in the conservation check.
  type State = { entry: int, pc: int, fetched: int,
    pending: Set[int], accepted: Set[int], trivia: Set[int], unread: Set[int], failed: Set[int],
    source: List[int], exposed: List[int], logical: int, saved: int, observed: int,
    captures: int, errorRoot: bool, wrapping: bool, wrappedRoot: bool,
    result: int, parseError: bool, translated: bool,
    unknown: bool, delivered: bool, aliases: int, retired: bool, reads: int, replayed: bool }
  var s: State
  pure def initial(entry: int): State = { entry: entry, pc: 0, fetched: 0,
    pending: Set(), accepted: Set(), trivia: Set(), unread: Set(), failed: Set(),
    source: List(32, 97, 98, 99, 39), exposed: List(97, 98, 99), logical: 0,
    saved: 0, observed: -1, captures: 0, errorRoot: false, wrapping: false, wrappedRoot: false,
    result: 0, parseError: true, translated: false,
    unknown: false, delivered: false, aliases: 1, retired: false, reads: 0, replayed: false }
  action init = s' = initial(3)
  action initHeader = s' = initial(1)
  action fetch = all { s.pc == 0, s' = { ...s, pc: 1, fetched: FixtureCharacters, pending: 0.to(FixtureCharacters - 1) } }
  action accept = all { s.pc == 1, s' = { ...s, pc: 2, pending: Set(), trivia: Set(0), accepted: Set(1,2,3), unread: Set(4), logical: 4 } }
  action capture = all { s.captures == 0, not(s.retired), s' = { ...s, captures: 1, saved: s.logical } }
  action mutateExposed = all { s.pc == 2, s' = { ...s, exposed: List(0) } }
  action reductionReturn = all { s.pc == 2, s' = { ...s, pc: 3 } }
  action reductionThrow = all { s.pc == 2, s' = { ...s, pc: 4,
    failed: s.accepted, accepted: Set(), result: 2, errorRoot: true, unknown: true } }
  action readerReturn = all { s.pc == 3, s.reads == 0,
    s' = { ...s, pc: 5, accepted: s.accepted.union(s.unread), unread: Set(), logical: 5,
      reads: 1, result: 1, unknown: true } }
  action readerThrow = all { s.pc == 3, s.reads == 0,
    s' = { ...s, pc: 4, failed: s.unread, unread: Set(), logical: 5,
      reads: 1, result: 2, errorRoot: true, unknown: true } }
  action nonParseError = all { s.pc == 4, not(s.wrapping), s' = { ...s, parseError: false } }
  action beginWrap = all { s.pc == 4, BodyCatch.nth(s.entry), s.parseError,
    s' = { ...s, wrapping: true } }
  action finishWrap = all { s.pc == 4, s.wrapping, s.errorRoot,
    s' = { ...s, pc: 5, wrapping: false, wrappedRoot: true, errorRoot: false, translated: true } }
  action routeOriginal = all { s.pc == 4, not(BodyCatch.nth(s.entry) and s.parseError), s' = { ...s, pc: 5 } }
  action settle = all { s.pc == 5, s.unknown, s' = { ...s, unknown: false, delivered: true } }
  action resume = all { s.captures == 1, s' = { ...s, observed: s.logical } }
  action releaseCapture = all { s.captures == 1, s' = { ...s, captures: 0 } }
  action releaseError = all { s.delivered, s' = { ...s, errorRoot: false, wrappedRoot: false } }
  action releaseAliases = all { s.delivered, s.captures == 0, s' = { ...s, aliases: 0 } }
  def drained = s.captures == 0 and not(s.errorRoot) and not(s.wrappedRoot) and not(s.unknown) and s.aliases == 0
  action retire = all { drained, s' = { ...s, retired: true } }
  def pieces = List(s.pending, s.accepted, s.trivia, s.unread, s.failed)
  def covered = s.pending.union(s.accepted).union(s.trivia).union(s.unread).union(s.failed)
  def disjoint = 0.to(4).forall(i => 0.to(4).forall(j => i == j or pieces.nth(i).intersect(pieces.nth(j)) == Set()))
  def errorOwned = s.result != 2 or s.delivered or s.errorRoot or s.wrappedRoot
  def safe = covered == (if (s.fetched == 0) Set() else 0.to(s.fetched - 1)) and disjoint and
    s.source == List(32,97,98,99,39) and errorOwned and
    (s.wrapping implies s.errorRoot) and
    (s.translated implies BodyCatch.nth(s.entry) and s.parseError) and
    (s.retired implies drained) and s.reads <= 1 and not(s.replayed)
  action step = any { fetch, accept, capture, mutateExposed, reductionReturn, reductionThrow,
    readerReturn, readerThrow, nonParseError, beginWrap, finishWrap, routeOriginal,
    settle, resume, releaseCapture, releaseError, releaseAliases, retire, s' = s }
  action losePending = s' = { ...s, pending: Set() }
  action loseFailure = s' = { ...s, failed: Set() }
  action duplicateLookahead = s' = { ...s, accepted: s.accepted.union(s.unread) }
  action aliasRawToExposed = s' = { ...s, source: s.exposed }
  action forceHeaderTranslation = s' = { ...s, translated: true }
  action dropDuringWrap = s' = { ...s, errorRoot: false }
  action retireEarly = s' = { ...s, retired: true }
  action retryUnknown = s' = { ...s, reads: s.reads + 1, replayed: true }
  action rewindCaptured = s' = { ...s, logical: s.saved, observed: s.saved }
  run nativeEntryRoutesTest = init.expect(BodyCatch == List(false,false,false,true,true))
  run inflightConservedTest = init.then(fetch).expect(safe and s.pending.size() == 5)
  run acceptedPartitionTest = init.then(fetch).then(accept).expect(safe and s.unread == Set(4))
  run mutableReductionIsolationTest = init.then(fetch).then(accept).then(mutateExposed).expect(safe and s.exposed == List(0))
  run failedLexemeCustodyTest = init.then(fetch).then(accept).then(reductionThrow).expect(safe and s.failed == Set(1,2,3))
  run bodyWrapCustodyTest = init.then(fetch).then(accept).then(reductionThrow).then(beginWrap).then(capture).then(finishWrap).then(settle).expect(safe and s.translated and s.wrappedRoot)
  run headerOriginalExceptionTest = initHeader.then(fetch).then(accept).then(reductionThrow).then(routeOriginal).then(settle).expect(safe and not(s.translated))
  run nonParseRethrowTest = init.then(fetch).then(accept).then(reductionThrow).then(nonParseError).then(routeOriginal).then(settle).expect(safe and not(s.translated))
  run readerFailureHorizonTest = init.then(fetch).then(accept).then(reductionReturn).then(readerThrow).expect(safe and s.failed == Set(4) and s.accepted == Set(1,2,3))
  run captureSeesCurrentTest = init.then(fetch).then(accept).then(capture).then(reductionReturn).then(readerReturn).then(resume).expect(safe and s.observed == 5 and s.saved == 4)
  run settledDrainTest = init.then(fetch).then(accept).then(reductionReturn).then(readerReturn).then(settle).then(releaseAliases).then(retire).expect(safe and s.retired)
  run lostInflightControlTest = init.then(fetch).then(losePending).expect(not(safe))
  run lostFailureControlTest = init.then(fetch).then(accept).then(reductionThrow).then(loseFailure).expect(not(safe))
  run overlappingLookaheadControlTest = init.then(fetch).then(accept).then(duplicateLookahead).expect(not(safe))
  run mutableAliasControlTest = init.then(fetch).then(accept).then(mutateExposed).then(aliasRawToExposed).expect(not(safe))
  run wrongHeaderCatchControlTest = initHeader.then(fetch).then(accept).then(reductionThrow).then(forceHeaderTranslation).expect(not(safe))
  run dropErrorBeforeWrapControlTest = init.then(fetch).then(accept).then(reductionThrow).then(beginWrap).then(dropDuringWrap).expect(not(safe))
  run capturedRetireControlTest = init.then(capture).then(retireEarly).expect(not(safe))
  run pendingRetryControlTest = init.then(fetch).then(accept).then(reductionReturn).then(readerReturn).then(retryUnknown).expect(not(safe))
  run reductionRetryControlTest = init.then(fetch).then(accept).then(reductionThrow).then(retryUnknown).expect(not(safe))
  run capturedRollbackControlTest = init.then(fetch).then(accept).then(capture).then(reductionReturn).then(readerReturn).then(rewindCaptured).expect(s.observed != 5)
}

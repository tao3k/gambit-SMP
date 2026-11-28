module ebnf_cursor_handoff {
  import ebnf_cursor_parameters.* from "./ebnf_cursor_parameters"
  val Cases = 0.to(CaseCount - 1)
  pure def actionBoundary(c: int): bool =
    if (lexerKind.get(c) == 0) prefix.get(c) == List(32, 45, 62)
    else prefix.get(c) == List(61, 62) and
      (suffix.get(c).length() == 0 or suffix.get(c).head() == 39)
  // Exact finite fixture reader relation, not a general Scheme reader or regexp compiler.
  pure def datum(xs: List[int]): int = {
    val ys = if (xs.length() > 0 and (xs.head() == 32 or xs.head() == 10)) xs.tail() else xs
    if (ys == List()) 0
    else if (ys == List(40, 84, 32, 52, 50, 41, 10)) 1
    else if (ys == List(39, 40, 84, 32, 52, 50, 41, 10)) 2
    else if (ys == List(84, 32, 52, 50, 41, 10)) 3
    else if (ys == List(118, 97, 108, 117, 101, 10)) 4
    else if (ys == List(39, 118, 97, 108, 117, 101, 10)) 5 else -2
  }
  pure def afterLookahead(c: int): List[int] = if (suffix.get(c).length() == 0) List() else suffix.get(c).tail()
  pure def residue(c: int): List[int] = if (suffix.get(c).length() == 0) List() else List(suffix.get(c).head())
  type State = { c: int, mode: int, admitted: bool, pc: int, physical: int,
    chars: List[int], tokens: int, owner: int, root: bool, aliases: bool,
    epoch: int, receiptEpoch: int, observed: int, unknown: bool, replayed: bool,
    wrongLocation: bool, lostResidue: bool, reads: int }
  var s: State
  pure def initial(c: int, mode: int, admitted: bool): State = {
    c: c, mode: mode, admitted: admitted, pc: 0, physical: 0, chars: List(), tokens: 0,
    owner: 0, root: true, aliases: true, epoch: 0, receiptEpoch: -1, observed: -1,
    unknown: false, replayed: false, wrongLocation: false, lostResidue: false, reads: 0 }
  action init = s' = initial(0, 0, true)
  action initActual = s' = initial(0, 0, ActualAdapterAdmitted)
  action initCoherent = s' = initial(0, 1, true)
  action initParen = s' = initial(1, 0, true)
  action initSpace = s' = initial(2, 0, true)
  action initNewline = s' = initial(3, 0, true)
  action initParserQuote = s' = initial(4, 0, true)
  action initMergedIdent = s' = initial(5, 0, true)
  action initEOF = s' = initial(6, 0, true)
  action initPendingToken = s' = { ...initial(0, 0, true), tokens: 1 }
  action scanDelimiter = all { s.pc == 0, actionBoundary(s.c),
    s' = { ...s, pc: 1, physical: prefix.get(s.c).length() } }
  action rejectMergedIdent = all { s.pc == 0, not(actionBoundary(s.c)), s' = { ...s, pc: 7 } }
  action readPastDelimiter = all { s.pc == 1,
    s' = { ...s, pc: 2, chars: residue(s.c),
      physical: s.physical + (if (suffix.get(s.c).length() == 0) 0 else 1) } }
  def canReserve = s.admitted and s.tokens == 0 and s.aliases and s.root
  action reserve = all { s.pc == 2, canReserve,
    s' = { ...s, pc: 3, receiptEpoch: s.epoch } }
  action rejectTarget = all { s.pc == 3, s' = { ...s, pc: 2 } }
  action commit = all { s.pc == 3, s.receiptEpoch == s.epoch,
    s' = { ...s, pc: 4, owner: 1 } }
  // Authoritative ownership committed; response delivery is unknown to the caller.
  action commitUnknown = all { s.pc == 3, s.receiptEpoch == s.epoch,
    s' = { ...s, pc: 5, owner: 1, unknown: true } }
  action settle = all { s.pc == 5, s.owner == 1,
    s' = { ...s, pc: if (s.reads == 1) 6 else 4, unknown: false } }
  action readSelectedMode = all { s.pc == 4, s.reads == 0,
    s' = { ...s, pc: 6, reads: 1, observed: if (s.mode == 0) datum(afterLookahead(s.c))
      else datum(s.chars.concat(afterLookahead(s.c))) } }
  action targetReadsBeforeSettlement = all { s.pc == 5, s.reads == 0,
    s' = { ...s, reads: 1, observed: if (s.mode == 0) datum(afterLookahead(s.c))
      else datum(s.chars.concat(afterLookahead(s.c))) } }
  action changeEpoch = s' = { ...s, epoch: s.epoch + 1 }
  def observationOK = (s.pc != 6 and s.reads == 0) or s.observed ==
    (if (s.mode == 0) legacyDatum.get(s.c) else coherentDatum.get(s.c))
  def safe = observationOK and s.root and s.aliases and s.reads <= 1 and
    not(s.replayed) and not(s.wrongLocation) and not(s.lostResidue) and
    ((s.pc < 4 or s.pc == 7) implies s.owner == 0) and
    (Set(4, 5, 6).contains(s.pc) implies s.owner == 1)
  action step = any { scanDelimiter, rejectMergedIdent, readPastDelimiter, reserve,
    rejectTarget, commit, commitUnknown, settle, readSelectedMode, targetReadsBeforeSettlement, changeEpoch, s' = s }
  action loseChars = s' = { ...s, chars: List(), lostResidue: true }
  action dropRoot = s' = { ...s, root: false }
  action copyTokens = s' = { ...s, aliases: false }
  action prematureTransfer = s' = { ...s, owner: 1 }
  action retryUnknown = s' = { ...s, replayed: true }
  action substitutePhysicalLocation = s' = { ...s, wrongLocation: true }
  action readWrongMode = all { s.pc == 4,
    s' = { ...s, pc: 6, observed: if (s.mode == 0) datum(s.chars.concat(afterLookahead(s.c))) else datum(afterLookahead(s.c)) } }
  run nativeCasesConsistentTest = init.expect(Cases.forall(c => not(actionBoundary(c)) or
    (datum(afterLookahead(c)) == legacyDatum.get(c) and datum(residue(c).concat(afterLookahead(c))) == coherentDatum.get(c))))
  run quoteLegacyWitnessTest = init.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commit).then(readSelectedMode).expect(safe and s.observed == 1 and s.chars == List(39))
  run coherentQuoteDiffersTest = initCoherent.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commit).then(readSelectedMode).expect(safe and s.observed == 2)
  run parenLossEntryTest = initParen.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commit).then(readSelectedMode).expect(safe and s.observed == 3)
  run standardSpaceDatumTest = initSpace.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commit).then(readSelectedMode).expect(safe and s.observed == 1)
  run standardNewlineDatumTest = initNewline.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commit).then(readSelectedMode).expect(safe and s.observed == 1)
  run selectedParserQuoteTest = initParserQuote.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commit).then(readSelectedMode).expect(safe and s.observed == 4)
  run maximalMunchIdentDeniesActionTest = initMergedIdent.then(rejectMergedIdent).expect(safe and s.pc == 7)
  run eofExplicitErrorBoundaryTest = initEOF.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commit).then(readSelectedMode).expect(safe and s.observed == 0 and s.chars == List())
  run actualAdapterDeniedTest = initActual.then(scanDelimiter).then(readPastDelimiter).expect(safe and not(s.admitted))
  run pendingTokenDeniesRawReadTest = initPendingToken.then(scanDelimiter).then(readPastDelimiter).expect(safe and not(canReserve))
  run targetRejectRetainsSourceTest = init.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(rejectTarget).expect(safe and s.owner == 0 and s.chars == List(39))
  run changedEpochBlocksCommitTest = init.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(changeEpoch).expect(safe and s.receiptEpoch != s.epoch)
  run unknownCommitSettlesWithoutReplayTest = init.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commitUnknown).then(settle).then(readSelectedMode).expect(safe and s.owner == 1 and not(s.replayed))
  run completedReadSettlesWithoutReplayTest = init.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commitUnknown).then(targetReadsBeforeSettlement).then(settle).expect(safe and s.pc == 6 and s.reads == 1 and s.observed == 1)
  run coherentClaimWithLegacyReadControlTest = initCoherent.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commit).then(readWrongMode).expect(not(safe))
  run legacyClaimWithCorrectedReadControlTest = init.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commit).then(readWrongMode).expect(not(safe))
  run lostCharsControlTest = init.then(scanDelimiter).then(readPastDelimiter).then(loseChars).expect(not(safe))
  run rootDropControlTest = init.then(dropRoot).expect(not(safe))
  run tokenAliasCopyControlTest = init.then(copyTokens).expect(not(safe))
  run earlyOwnerTransferControlTest = init.then(prematureTransfer).expect(not(safe))
  run unknownReplayControlTest = init.then(scanDelimiter).then(readPastDelimiter).then(reserve).then(commitUnknown).then(retryUnknown).expect(not(safe))
  run physicalForLogicalLocationControlTest = initCoherent.then(substitutePhysicalLocation).expect(not(safe))
}

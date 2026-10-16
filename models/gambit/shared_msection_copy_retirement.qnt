module shared_msection_copy_retirement {
  // Abstract word coordinates, not a machine processor count or ABI size.
  pure val halfWords = 8
  pure val firstBreakWords = 4
  pure val processors = Set(0, 1)
  type State = { phase: str, pending: Set[int], borrowed: Set[int],
    live: bool, copied: Set[int], words: int, offset: int,
    headerIntact: bool, unsafeRange: bool, unsafeRetirement: bool }
  var s: State
  pure def initial(words: int, offset: int, badRange: bool, badRetirement: bool): State = {
    phase: "copy", pending: processors, borrowed: processors,
    live: true, copied: Set(), words: words, offset: offset,
    headerIntact: true, unsafeRange: badRange, unsafeRetirement: badRetirement }
  action init = {
    nondet words = 0.to(halfWords - firstBreakWords).oneOf()
    nondet offset = Set(0, halfWords).oneOf()
    s' = initial(words, offset, false, false)
  }
  action initEscapedFrameRange = {
    nondet words = (halfWords - firstBreakWords + 1).to(halfWords + 1).oneOf()
    s' = initial(words, 0, true, false)
  }
  action initPrematureRetirement = s' = initial(1, 0, false, true)
  pure def destinationLow(state: State): int =
    state.offset + halfWords - firstBreakWords - state.words
  pure def rangeValid(state: State): bool =
    state.words >= 0 and destinationLow(state) >= state.offset
  action copy = {
    nondet owner = s.pending.oneOf()
    all {
      s.phase == "copy", s.live,
      rangeValid(s) or s.unsafeRange,
      s' = { ...s, pending: s.pending.exclude(Set(owner)),
        copied: s.copied.union(Set(owner)),
        headerIntact: s.headerIntact and destinationLow(s) >= 0 }
    }
  }
  action finishCopyPhase = all {
    s.phase == "copy", s.pending == Set(),
    s' = { ...s, phase: "resize", borrowed: Set() }
  }
  action retire = all {
    s.live, (s.phase == "resize" and s.borrowed == Set()) or s.unsafeRetirement,
    s' = { ...s, live: false, phase: "done" }
  }
  action step = any { copy, finishCopyPhase, retire,
    all { s.phase == "done", s' = s } }
  val safe = s.headerIntact and (s.borrowed != Set()).implies(s.live)
  // Safety is conditional on valid descriptors/ranges and borrower retirement.
  // Neither premise is inferred from the native catalog-member observation.
}

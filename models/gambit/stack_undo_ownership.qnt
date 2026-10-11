module stack_undo_ownership {
  // Five ownership transitions plus an ordinary private-overflow control.
  // First/nested active breaks and present/absent overflow eligibility.
  // Undo is considered only after unwinding to the first break; stack/heap
  // sections are distinct. One saved frame and boundary abstracted, no full GC.
  type State = { mode: int, phase: int, operation: int, nested: bool,
    metadata: bool, eligible: bool, activeFirst: bool, shared: bool,
    boundary: int, previous: int, reused: bool }
  var s: State
  pure def initialState(mode: int): State = {
    mode: mode, phase: 0, operation: -1, nested: false, metadata: false,
    eligible: false, activeFirst: true, shared: false,
    boundary: 72, previous: 91, reused: false,
  }
  action initOld = s' = initialState(0)
  action initWrongTarget = s' = initialState(2)
  action initWipedMetadata = s' = initialState(3)
  action initFixed = s' = initialState(1)
  action choose(op: int, nested: bool, metadata: bool): bool = all {
    s.phase == 0,
    s' = { ...s, phase: 1, operation: op, nested: nested, metadata: metadata,
           eligible: metadata, activeFirst: not(nested) },
  }
  action ownershipTransition = all {
    s.phase == 1,
    val changing = s.operation != 5
    val invalidateFirst = s.mode == 1 or s.mode == 3 or (s.mode == 2 and not(s.nested))
    s' = { ...s, phase: 2, shared: changing,
           eligible: s.eligible and not(changing and invalidateFirst),
           boundary: if (changing and s.mode == 3) 0 else s.boundary,
           previous: if (changing and s.mode == 3) 0 else s.previous },
  }
  action unwindToFirst = all {
    s.phase == 2, not(s.activeFirst), s' = { ...s, activeFirst: true },
  }
  action undo = all {
    s.phase == 2, s.activeFirst,
    s' = { ...s, phase: 3, reused: s.eligible },
  }
  action finished = all { s.phase == 3, s' = s }
  action step = any {
    choose(0, false, false), choose(0, false, true), choose(0, true, false), choose(0, true, true),
    choose(1, false, false), choose(1, false, true), choose(1, true, false), choose(1, true, true),
    choose(2, false, false), choose(2, false, true), choose(2, true, false), choose(2, true, true),
    choose(3, false, false), choose(3, false, true), choose(3, true, false), choose(3, true, true),
    choose(4, false, false), choose(4, false, true), choose(4, true, false), choose(4, true, true),
    choose(5, false, false), choose(5, false, true), choose(5, true, false), choose(5, true, true),
    ownershipTransition, unwindToFirst, undo, finished,
  }
  val ownershipSafe = not(s.shared and s.reused)
  val nestedSafe = not(s.nested) or ownershipSafe
  val metadataSafe = s.boundary == 72 and s.previous == 91
  val privateSafe = s.phase != 3 or s.operation != 5 or s.reused == s.metadata
  val safe = ownershipSafe and metadataSafe and privateSafe
}

module c_continuation_label_partition {
  // Characterization of patches/fixtures/c-continuation-label-partition.patch.
  // Value-label cells are assigned after emission. The patch numbers every
  // non-internal value label, in definition order, before any return whose
  // info tag is internal, then numbers goto-only labels from the original
  // definition order. Stack checks stay in the emitted code.
  // Kinds: 0 procedure, 1 ordinary/task return, 2 internal return, 3 goto.
  // This is not a fault PC, source refinement, or runtime admission.
  // Debug-info control-point ids stay in emission order and are not reordered.

  pure val P = 0
  pure val RET = 1
  pure val INT = 2
  pure val GOTO = 3
  pure val W = 4
  pure val N = 256

  pure val kernelVisible = 14
  pure val kernelInternal = 13
  pure val kernelEntries = 27
  pure val stackPos = 4
  pure val manualStack = 2
  pure val denvPos = 2
  pure val denvVisible = 2
  pure val manualDenv = 1

  pure def one(cond: bool): int = if (cond) 1 else 0
  pure def isVis(k: int): bool = k == P or k == RET
  pure def isInt(k: int): bool = k == INT
  pure def isVal(k: int): bool = k != GOTO
  pure def isGoto(k: int): bool = k == GOTO

  pure def pow4(pos: int): int =
    if (pos == 0) 1
    else if (pos == 1) 4
    else if (pos == 2) 16
    else 64

  pure def kind(id: int, pos: int): int = (id / pow4(pos)) % 4

  pure def countVisBefore(id: int, pos: int): int =
    one(pos > 0 and isVis(kind(id, 0))) +
    one(pos > 1 and isVis(kind(id, 1))) +
    one(pos > 2 and isVis(kind(id, 2)))

  pure def visibleCount(id: int): int =
    one(isVis(kind(id, 0))) + one(isVis(kind(id, 1))) +
    one(isVis(kind(id, 2))) + one(isVis(kind(id, 3)))

  pure def countIntBefore(id: int, pos: int): int =
    one(pos > 0 and isInt(kind(id, 0))) +
    one(pos > 1 and isInt(kind(id, 1))) +
    one(pos > 2 and isInt(kind(id, 2)))

  pure def internalCount(id: int): int =
    one(isInt(kind(id, 0))) + one(isInt(kind(id, 1))) +
    one(isInt(kind(id, 2))) + one(isInt(kind(id, 3)))

  pure def countValBefore(id: int, pos: int): int =
    one(pos > 0 and isVal(kind(id, 0))) +
    one(pos > 1 and isVal(kind(id, 1))) +
    one(pos > 2 and isVal(kind(id, 2)))

  pure def valueCount(id: int): int =
    one(isVal(kind(id, 0))) + one(isVal(kind(id, 1))) +
    one(isVal(kind(id, 2))) + one(isVal(kind(id, 3)))

  pure def countGotoBefore(id: int, pos: int): int =
    one(pos > 0 and isGoto(kind(id, 0))) +
    one(pos > 1 and isGoto(kind(id, 1))) +
    one(pos > 2 and isGoto(kind(id, 2)))

  // Partition allocator: visible prefix, internal suffix, then definition-order gotos.
  pure def allocated(id: int, pos: int): int =
    if (isVis(kind(id, pos))) countVisBefore(id, pos)
    else if (isInt(kind(id, pos))) visibleCount(id) + countIntBefore(id, pos)
    else valueCount(id) + countGotoBefore(id, pos)

  // Old rule: value labels in definition order, then goto-only labels.
  pure def oldDef(id: int, pos: int): int =
    if (isGoto(kind(id, pos))) valueCount(id) + countGotoBefore(id, pos)
    else countValBefore(id, pos)

  // Independent specification: order value labels by rank
  // (visible, then internal), and by definition index inside a rank.
  // Goto labels are not value labels.
  pure def classRank(k: int): int =
    if (isVis(k)) 0 else if (isInt(k)) 1 else 2

  pure def precedes(id: int, earlier: int, pos: int): bool =
    isVal(kind(id, earlier)) and isVal(kind(id, pos)) and
    (classRank(kind(id, earlier)) < classRank(kind(id, pos)) or
     (classRank(kind(id, earlier)) == classRank(kind(id, pos)) and earlier < pos))

  pure def specOrdinal(id: int, pos: int): int =
    one(precedes(id, 0, pos)) + one(precedes(id, 1, pos)) +
    one(precedes(id, 2, pos)) + one(precedes(id, 3, pos))

  pure def posOk(id: int, pos: int): bool =
    if (isVal(kind(id, pos)))
      allocated(id, pos) == specOrdinal(id, pos) and
      0 <= allocated(id, pos) and allocated(id, pos) < valueCount(id) and
      0 <= oldDef(id, pos) and oldDef(id, pos) < valueCount(id)
    else
      allocated(id, pos) == oldDef(id, pos) and
      allocated(id, pos) == valueCount(id) + countGotoBefore(id, pos) and
      valueCount(id) <= allocated(id, pos) and allocated(id, pos) < W

  pure def distinct(id: int, a: int, b: int): bool =
    not(isVal(kind(id, a))) or not(isVal(kind(id, b))) or
    allocated(id, a) != allocated(id, b)

  pure def visibleOrder(id: int, a: int, b: int): bool =
    a >= b or not(isVis(kind(id, a))) or not(isVis(kind(id, b))) or
    specOrdinal(id, a) < specOrdinal(id, b)

  pure def internalOrder(id: int, a: int, b: int): bool =
    a >= b or not(isInt(kind(id, a))) or not(isInt(kind(id, b))) or
    specOrdinal(id, a) < specOrdinal(id, b)

  pure def unchangedWithoutInternal(id: int): bool =
    internalCount(id) != 0 or
    (oldDef(id, 0) == allocated(id, 0) and
     oldDef(id, 1) == allocated(id, 1) and
     oldDef(id, 2) == allocated(id, 2) and
     oldDef(id, 3) == allocated(id, 3))

  pure def sequenceOk(id: int): bool =
    posOk(id, 0) and posOk(id, 1) and posOk(id, 2) and posOk(id, 3) and
    distinct(id, 0, 1) and distinct(id, 0, 2) and distinct(id, 0, 3) and
    distinct(id, 1, 2) and distinct(id, 1, 3) and distinct(id, 2, 3) and
    visibleOrder(id, 0, 1) and visibleOrder(id, 0, 2) and visibleOrder(id, 0, 3) and
    visibleOrder(id, 1, 2) and visibleOrder(id, 1, 3) and visibleOrder(id, 2, 3) and
    internalOrder(id, 0, 1) and internalOrder(id, 0, 2) and internalOrder(id, 0, 3) and
    internalOrder(id, 1, 2) and internalOrder(id, 1, 3) and internalOrder(id, 2, 3) and
    unchangedWithoutInternal(id) and
    valueCount(id) == visibleCount(id) + internalCount(id)

  // ##kernel-handlers: proc, then (internal, ordinary return) thirteen times.
  // The stack handler is the ordinary return at definition index 4.
  pure def kAllocated(i: int): int =
    if (i % 2 == 0) i / 2 else kernelVisible + (i / 2)

  // ##dynamic-env-bind: proc, internal resume, ordinary return.
  // The return's visible ordinal is the one procedure label before it.
  pure def dAllocated(i: int): int =
    if (i == 0) 0
    else if (i == denvPos) one(i > 0)
    else denvVisible

  pure val entryRelation = kernelEntries == kernelVisible + kernelInternal
  pure val measuredKernel =
    kAllocated(0) == 0 and kAllocated(2) == 1 and
    kAllocated(stackPos) == manualStack and kAllocated(1) == kernelVisible and
    kAllocated(26) == kernelVisible - 1 and stackPos == manualStack + 2
  pure val measuredDenv =
    dAllocated(0) == 0 and dAllocated(denvPos) == manualDenv and
    dAllocated(1) == 2 and denvPos == manualDenv + 1

  type State = {
    phase: str,
    mode: str,
    index: int,
    handlerOrdinal: int,
    handlerSpec: int,
    denvOrdinal: int,
    denvSpec: int
  }
  var s: State

  action initScan = s' = {
    phase: "scan", mode: "scan", index: 0,
    handlerOrdinal: 0, handlerSpec: 0, denvOrdinal: 0, denvSpec: 0
  }
  action initMeasured = s' = {
    phase: "open", mode: "measured", index: 0,
    handlerOrdinal: 0, handlerSpec: 0, denvOrdinal: 0, denvSpec: 0
  }

  action advance = all {
    s.mode == "scan",
    s.phase == "scan",
    s.index < N,
    s' = {
      phase: if (s.index + 1 == N) "done" else "scan",
      mode: s.mode,
      index: s.index + 1,
      handlerOrdinal: s.handlerOrdinal,
      handlerSpec: s.handlerSpec,
      denvOrdinal: s.denvOrdinal,
      denvSpec: s.denvSpec
    }
  }
  action placeMeasured = all {
    s.mode == "measured",
    s.phase == "open",
    s' = {
      phase: "done",
      mode: s.mode,
      index: stackPos,
      handlerOrdinal: stackPos,
      handlerSpec: kAllocated(stackPos),
      denvOrdinal: denvPos,
      denvSpec: dAllocated(denvPos)
    }
  }
  action hold = all { s.phase == "done", s' = s }
  action step = any { advance, placeMeasured, hold }

  val partitionOk =
    entryRelation and measuredKernel and measuredDenv and
    (s.phase == "scan" implies sequenceOk(s.index)) and
    (s.mode == "scan" and s.phase == "done" implies s.index == N)
  val oldMatchesSpec =
    s.phase == "done" and s.mode == "measured" implies
    s.handlerOrdinal == s.handlerSpec and s.denvOrdinal == s.denvSpec
  temporal progress = weakFair(step, Set(s)).implies(eventually(s.phase == "done"))
}

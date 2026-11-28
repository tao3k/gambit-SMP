module c_continuation_debug_projection {
  // Characterization of patches/fixtures/c-continuation-debug-projection.patch.
  // Value labels keep definition order in the debug queue. Stable partition
  // stores a different cell number when an internal return precedes a later
  // visible value label. Projected metadata publishes that cell. Identity
  // metadata publishes the queue index. Lookup is last-match on the stored
  // id, as ##subprocedure-info scans the descriptor vector from the end.
  // Canonical labels 0 and 2 are visible; 1 and 3 are internal. All 24
  // definition orders are checked. This is not crash causality, source
  // refinement, bootstrap, stress, or runtime admission.

  pure val VIS = 0
  pure val INT = 1
  pure val MISSING = 4
  pure val PERMS = 24

  pure def one(cond: bool): int = if (cond) 1 else 0

  pure def d0(id: int): int = id / 6
  pure def d1(id: int): int = (id % 6) / 2
  pure def d2(id: int): int = id % 2

  pure def a0(id: int): int = d0(id)
  pure def a1(id: int): int = if (d1(id) < a0(id)) d1(id) else d1(id) + 1
  pure def skip2(id: int, x: int): bool = x == a0(id) or x == a1(id)
  pure def rem0(id: int): int =
    if (not(skip2(id, 0))) 0
    else if (not(skip2(id, 1))) 1
    else if (not(skip2(id, 2))) 2
    else 3
  pure def rem1(id: int): int =
    if (not(skip2(id, 0)) and rem0(id) != 0) 0
    else if (not(skip2(id, 1)) and rem0(id) != 1) 1
    else if (not(skip2(id, 2)) and rem0(id) != 2) 2
    else 3
  pure def a2(id: int): int = if (d2(id) == 0) rem0(id) else rem1(id)
  pure def a3(id: int): int =
    if (a0(id) != 0 and a1(id) != 0 and a2(id) != 0) 0
    else if (a0(id) != 1 and a1(id) != 1 and a2(id) != 1) 1
    else if (a0(id) != 2 and a1(id) != 2 and a2(id) != 2) 2
    else 3
  pure def at(id: int, pos: int): int =
    if (pos == 0) a0(id)
    else if (pos == 1) a1(id)
    else if (pos == 2) a2(id)
    else a3(id)

  pure def canonKind(label: int): int = if (label == 0 or label == 2) VIS else INT
  pure def kindAt(id: int, pos: int): int = canonKind(at(id, pos))
  pure def isVis(k: int): bool = k == VIS
  pure def isInt(k: int): bool = k == INT

  pure def countVisBefore(id: int, pos: int): int =
    one(pos > 0 and isVis(kindAt(id, 0))) +
    one(pos > 1 and isVis(kindAt(id, 1))) +
    one(pos > 2 and isVis(kindAt(id, 2)))
  pure def visibleCount(id: int): int =
    one(isVis(kindAt(id, 0))) + one(isVis(kindAt(id, 1))) +
    one(isVis(kindAt(id, 2))) + one(isVis(kindAt(id, 3)))
  pure def countIntBefore(id: int, pos: int): int =
    one(pos > 0 and isInt(kindAt(id, 0))) +
    one(pos > 1 and isInt(kindAt(id, 1))) +
    one(pos > 2 and isInt(kindAt(id, 2)))
  pure def allocated(id: int, pos: int): int =
    if (isVis(kindAt(id, pos))) countVisBefore(id, pos)
    else visibleCount(id) + countIntBefore(id, pos)

  pure def precedes(id: int, earlier: int, pos: int): bool =
    (isVis(kindAt(id, earlier)) and isInt(kindAt(id, pos))) or
    (isVis(kindAt(id, earlier)) and isVis(kindAt(id, pos)) and earlier < pos) or
    (isInt(kindAt(id, earlier)) and isInt(kindAt(id, pos)) and earlier < pos)
  pure def specOrdinal(id: int, pos: int): int =
    one(precedes(id, 0, pos)) + one(precedes(id, 1, pos)) +
    one(precedes(id, 2, pos)) + one(precedes(id, 3, pos))

  // Last matching stored id. Projected slots store allocated cells.
  pure def ownerProjected(id: int, actual: int): int =
    if (allocated(id, 3) == actual) 3
    else if (allocated(id, 2) == actual) 2
    else if (allocated(id, 1) == actual) 1
    else if (allocated(id, 0) == actual) 0
    else MISSING
  // Identity slots store the definition index itself.
  pure def ownerIdentity(actual: int): int =
    if (actual == 3) 3
    else if (actual == 2) 2
    else if (actual == 1) 1
    else if (actual == 0) 0
    else MISSING

  pure def projectedAssociated(id: int, pos: int): bool =
    ownerProjected(id, allocated(id, pos)) == pos
  pure def identityAssociated(id: int, pos: int): bool =
    ownerIdentity(allocated(id, pos)) == pos
  pure def allProjected(id: int): bool =
    projectedAssociated(id, 0) and projectedAssociated(id, 1) and
    projectedAssociated(id, 2) and projectedAssociated(id, 3)
  pure def allIdentity(id: int): bool =
    identityAssociated(id, 0) and identityAssociated(id, 1) and
    identityAssociated(id, 2) and identityAssociated(id, 3)
  pure def badOrder(id: int): bool =
    (isInt(kindAt(id, 0)) and (isVis(kindAt(id, 1)) or isVis(kindAt(id, 2)) or isVis(kindAt(id, 3)))) or
    (isInt(kindAt(id, 1)) and (isVis(kindAt(id, 2)) or isVis(kindAt(id, 3)))) or
    (isInt(kindAt(id, 2)) and isVis(kindAt(id, 3)))
  pure def distinctLabels(id: int): bool =
    at(id, 0) != at(id, 1) and at(id, 0) != at(id, 2) and at(id, 0) != at(id, 3) and
    at(id, 1) != at(id, 2) and at(id, 1) != at(id, 3) and at(id, 2) != at(id, 3)
  pure def distinctCells(id: int): bool =
    allocated(id, 0) != allocated(id, 1) and allocated(id, 0) != allocated(id, 2) and
    allocated(id, 0) != allocated(id, 3) and allocated(id, 1) != allocated(id, 2) and
    allocated(id, 1) != allocated(id, 3) and allocated(id, 2) != allocated(id, 3)
  pure def ranked(id: int): bool =
    allocated(id, 0) == specOrdinal(id, 0) and allocated(id, 1) == specOrdinal(id, 1) and
    allocated(id, 2) == specOrdinal(id, 2) and allocated(id, 3) == specOrdinal(id, 3)
  pure def permOk(id: int): bool =
    distinctLabels(id) and distinctCells(id) and ranked(id) and allProjected(id) and
    (allIdentity(id) == not(badOrder(id)))

  pure val anchors =
    at(0, 0) == 0 and at(0, 1) == 1 and at(0, 2) == 2 and at(0, 3) == 3 and
    at(2, 0) == 0 and at(2, 1) == 2 and at(2, 2) == 1 and at(2, 3) == 3 and
    not(allIdentity(0)) and allProjected(0)

  // Procedure, internal resume, ordinary return: cells 0, 2, 1.
  // Identity lookup of cell 2 hits the return slot, not the internal slot.
  pure def denvKind(pos: int): int = if (pos == 1) INT else VIS
  pure def denvVisBefore(pos: int): int =
    one(pos > 0 and denvKind(0) == VIS) + one(pos > 1 and denvKind(1) == VIS)
  pure def denvVisCount: int =
    one(denvKind(0) == VIS) + one(denvKind(1) == VIS) + one(denvKind(2) == VIS)
  pure def denvIntBefore(pos: int): int =
    one(pos > 0 and denvKind(0) == INT) + one(pos > 1 and denvKind(1) == INT)
  pure def denvAllocated(pos: int): int =
    if (denvKind(pos) == VIS) denvVisBefore(pos) else denvVisCount + denvIntBefore(pos)
  pure def denvOwnerProjected(actual: int): int =
    if (denvAllocated(2) == actual) 2
    else if (denvAllocated(1) == actual) 1
    else if (denvAllocated(0) == actual) 0
    else MISSING
  pure val denvOk =
    denvAllocated(0) == 0 and denvAllocated(1) == 2 and denvAllocated(2) == 1 and
    denvOwnerProjected(denvAllocated(0)) == 0 and
    denvOwnerProjected(denvAllocated(1)) == 1 and
    denvOwnerProjected(denvAllocated(2)) == 2 and
    ownerIdentity(denvAllocated(1)) == 2 and
    ownerIdentity(denvAllocated(1)) != 1

  pure val exhaustive = 0.to(PERMS - 1).forall(i => permOk(i))

  type State = { phase: str, mode: str, index: int }
  var s: State

  action initScan = s' = { phase: "scan", mode: "projected", index: 0 }
  action initOld = s' = { phase: "start", mode: "identity", index: 0 }
  action enter = all {
    s.phase == "start",
    s.mode == "identity",
    s' = { phase: "scan", mode: "identity", index: 0 }
  }
  action advance = all {
    s.phase == "scan",
    s.mode == "projected",
    s.index >= 0,
    s.index < PERMS,
    s' = {
      phase: if (s.index + 1 == PERMS) "done" else "scan",
      mode: "projected",
      index: s.index + 1
    }
  }
  action hold = all { s.phase == "done", s.mode == "projected", s' = s }
  action step = any { enter, advance, hold }

  val associationOk = exhaustive and anchors and denvOk and
    (s.phase == "scan" implies
      s.mode == "projected" and s.index >= 0 and s.index < PERMS and permOk(s.index)) and
    (s.phase == "done" implies s.index == PERMS and s.mode == "projected")
  val oldAgrees = s.phase != "scan" or allIdentity(s.index)
  temporal progress = weakFair(step, Set(s)).implies(eventually(s.phase == "done"))
}

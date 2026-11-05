module gc_table_iteration {
  // Three rooted keys with stable logical identities and arbitrary GC rehashes.
  // Snapshot capture is atomic and non-allocating after buffer allocation.
  // This is an obligation for source audit, not a proof of that C/SCM boundary.
  type State = { snapshot: bool, phase: int, layout: int, index: int,
    seen0: int, seen1: int, seen2: int, typedCopy: bool, invalidCopy: bool }
  var s: State
  pure def initial(snapshot: bool): State = {
    snapshot: snapshot, phase: 0, layout: 0, index: 0,
    seen0: 0, seen1: 0, seen2: 0, typedCopy: true, invalidCopy: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  // Rejected native prototype: WEAK/SUBTYPED storage is not VECTOR-tagged.
  action initWrongTagCopy = s' = { ...initial(true), typedCopy: false }
  pure def keyAt(layout: int, index: int): int =
    if (layout == 0) (if (index == 0) 0 else if (index == 1) 1 else 2)
    else if (layout == 1) (if (index == 0) 1 else if (index == 1) 0 else 2)
    else if (layout == 2) (if (index == 0) 2 else if (index == 1) 1 else 0)
    else if (layout == 3) (if (index == 0) 0 else if (index == 1) 2 else 1)
    else if (layout == 4) (if (index == 0) 1 else if (index == 1) 2 else 0)
    else (if (index == 0) 2 else if (index == 1) 0 else 1)
  action visit = all {
    s.phase == 0,
    val key = keyAt(if (s.snapshot) 0 else s.layout, s.index)
    s' = { ...s, phase: 1,
      seen0: s.seen0 + (if (key == 0) 1 else 0),
      seen1: s.seen1 + (if (key == 1) 1 else 0),
      seen2: s.seen2 + (if (key == 2) 1 else 0),
      invalidCopy: s.invalidCopy or (s.snapshot and not(s.typedCopy)) },
  }
  action callbackGc(layout: int): bool = all {
    s.phase == 1, s' = { ...s, layout: layout },
  }
  action advance = all {
    s.phase == 1,
    s' = { ...s, phase: if (s.index == 2) 2 else 0, index: s.index + 1 },
  }
  action finished = all { s.phase == 2, s' = s }
  action step = any { visit, callbackGc(0), callbackGc(1), callbackGc(2),
    callbackGc(3), callbackGc(4), callbackGc(5), advance, finished }
  val encodingSafe = not(s.invalidCopy)
  val safe = encodingSafe and (s.phase != 2 or (s.seen0 == 1 and s.seen1 == 1 and s.seen2 == 1))
}

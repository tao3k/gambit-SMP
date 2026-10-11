module gc_table_serialization {
  // Strongly rooted logical keys. Cons allocation may collect and rehash
  // between slot visits. Snapshot capture is a source-audit assumption.
  type State = { fixed: bool, phase: int, index: int, layout: int,
                 seen0: int, seen1: int, seen2: int }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, phase: 0, index: 0, layout: 0,
    seen0: 0, seen1: 0, seen2: 0,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  pure def keyAt(layout: int, index: int): int =
    if (layout == 0) (if (index == 0) 0 else if (index == 1) 1 else 2)
    else if (layout == 1) (if (index == 0) 1 else if (index == 1) 0 else 2)
    else if (layout == 2) (if (index == 0) 2 else if (index == 1) 1 else 0)
    else if (layout == 3) (if (index == 0) 0 else if (index == 1) 2 else 1)
    else if (layout == 4) (if (index == 0) 1 else if (index == 1) 2 else 0)
    else (if (index == 0) 2 else if (index == 1) 0 else 1)
  action readPair = all {
    s.phase == 0,
    val key = keyAt(if (s.fixed) 0 else s.layout, s.index)
    s' = { ...s, phase: 1,
      seen0: s.seen0 + (if (key == 0) 1 else 0),
      seen1: s.seen1 + (if (key == 1) 1 else 0),
      seen2: s.seen2 + (if (key == 2) 1 else 0) },
  }
  action allocationGC(layout: int): bool = all {
    s.phase == 1, s' = { ...s, layout: layout },
  }
  action appendAndAdvance = all {
    s.phase == 1,
    s' = { ...s, index: s.index + 1, phase: if (s.index == 2) 2 else 0 },
  }
  action finished = all { s.phase == 2, s' = s }
  action step = any { readPair, allocationGC(0), allocationGC(1), allocationGC(2),
    allocationGC(3), allocationGC(4), allocationGC(5), appendAndAdvance, finished }
  val safe = s.phase != 2 or (s.seen0 == 1 and s.seen1 == 1 and s.seen2 == 1)
}

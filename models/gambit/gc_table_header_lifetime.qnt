module gc_table_header_lifetime {
  // A special-reader/worklist obligation omitted from generic key rehash.
  // Forwarded headers and early retirement are injected controls, not the
  // established cause of either native fault. A normal-looking header also
  // needs correspondence to the allocated extent and scanned payload layout.
  type State = { fault: int, phase: int, canonical: int, queued: int,
    header: int -> int, extent: int -> int, layout: int -> int,
    retired: int -> bool, reader: int, reading: bool,
    badHeader: bool, useAfterRetire: bool, badExtent: bool, badLayout: bool }
  var s: State
  pure def initial(fault: int): State = {
    fault: fault, phase: 0, canonical: 1, queued: 1,
    header: Map(1 -> 4, 2 -> 4), retired: Map(1 -> false, 2 -> false),
    extent: Map(1 -> 4, 2 -> 4), layout: Map(1 -> 1, 2 -> 1),
    reader: -1, reading: false, badHeader: false, useAfterRetire: false,
    badExtent: false, badLayout: false,
  }
  action initOld = s' = initial(1)
  action initEarlyRetirement = s' = initial(2)
  action initWrongExtent = s' = initial(3)
  action initWrongLayout = s' = initial(4)
  action initFixed = s' = initial(0)
  // Collector moves the table: the old header is now forwarding metadata,
  // not an allocation-size header. The published worklist must track the
  // canonical body before cleanup readers interpret its representation.
  action relocate = all {
    s.phase == 0,
    s' = { ...s, phase: 1, canonical: 2,
      header: s.header.set(1, 99).set(2, if (s.fault == 3) 6 else 4),
      layout: s.layout.set(2, if (s.fault == 4) 2 else 1) },
  }
  action publishWorklist = all {
    s.phase == 1,
    s' = { ...s, phase: 2, queued: if (s.fault == 1) 1 else s.canonical },
  }
  action beginRead(worker: int): bool = all {
    s.phase == 2,
    s' = { ...s, phase: 3, reader: worker, reading: true },
  }
  action retire = all {
    (s.phase == 4 or (s.fault == 2 and s.phase == 3)),
    not(s.retired.get(s.canonical)),
    s' = { ...s, retired: s.retired.set(s.canonical, true) },
  }
  action readHeader = all {
    s.phase == 3,
    s' = { ...s, phase: 4, reading: false,
      badHeader: s.header.get(s.queued) == 99,
      useAfterRetire: s.retired.get(s.queued),
      badExtent: s.header.get(s.queued) != 99 and
        s.header.get(s.queued) != s.extent.get(s.queued),
      badLayout: s.layout.get(s.queued) != 1 },
  }
  action finished = all { s.phase == 4, s' = s }
  action step = any { relocate, publishWorklist, beginRead(1), beginRead(2),
    retire, readHeader, finished }
  val headerSafe = not(s.badHeader)
  val lifetimeSafe = not(s.useAfterRetire)
  val extentSafe = not(s.badExtent)
  val layoutSafe = not(s.badLayout)
  val safe = headerSafe and lifetimeSafe and extentSafe and layoutSafe
}

module stress_gsi_resume_cut {
  // One source parity, one destination grant, one independently delayed reader.
  // The addresses intentionally overlap in the abstraction to expose ABA.
  type Cut = { reader: bool, closed: bool, restored: bool, retired: bool, published: bool,
    grant: int, loaded: int, written: bool, bad: bool }
  var s: Cut
  pure val initial: Cut = { reader: false, closed: false, restored: false,
    retired: false, published: false, grant: 0, loaded: 0, written: false, bad: false }
  action init = s' = initial
  action enterOld = all { not(s.closed), not(s.reader), s' = {...s, reader: true} }
  action closeOld = all { not(s.closed), s' = {...s, closed: true} }
  action leaveOld = all { s.reader, s' = {...s, reader: false} }
  action restore = all { s.closed, not(s.reader), not(s.restored),
    s' = {...s, restored: true, grant: 1} }
  action reload = all { s.published, s.loaded != s.grant,
    s' = {...s, loaded: s.grant} }
  action retire = all { s.restored, not(s.reader), not(s.retired),
    s' = {...s, retired: true} }
  action publish = all { s.retired, not(s.published), s' = {...s, published: true} }
  pure def writeAllowed(base: int, words: int, end: int, loaded: int, grant: int): bool =
    base >= 0 and words > 0 and base + words <= end and loaded == grant
  action allocate = all { s.restored, s.retired, not(s.written),
    writeAllowed(2, 6, 8, s.loaded, s.grant), s' = {...s, written: true} }
  action step = any { enterOld, closeOld, leaveOld, restore, reload, retire, publish, allocate, s' = s }
  val safe = not(s.bad) and (not(s.retired) or not(s.reader))
    and (not(s.written) or (s.restored and s.published and s.retired and s.loaded == s.grant))

  // Negative controls weaken one guard at a time.
  action earlyRetire = all { s.closed, s.reader, s' = {...s, retired: true} }
  action staleWrite = all { s.published, s.loaded != s.grant,
    s' = {...s, written: true, bad: true} }

  run delayedReaderDrainsTest = init.then(enterOld).then(closeOld)
    .expect(s.reader and not(s.retired) and not(s.written) and safe)
    .then(leaveOld).then(restore).then(retire).then(publish).then(reload).then(allocate).expect(s.written and safe)
  run earlyRetireRejectedTest = init.then(enterOld).then(closeOld)
    .then(earlyRetire).expect(not(safe))
  run staleCursorRejectedTest = init.then(closeOld).then(restore).then(retire).then(publish)
    .then(staleWrite).expect(not(safe))
  run intervalBoundaryTest = init.expect(writeAllowed(2, 6, 8, 1, 1)
    and not(writeAllowed(2, 6, 7, 1, 1))
    and not(writeAllowed(2, 6, 8, 0, 1)))
}

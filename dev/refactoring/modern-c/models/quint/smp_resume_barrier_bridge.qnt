module smp_resume_barrier_bridge {
  // Two physical participants, one restore phase and one generated region.
  // Atomic actions abstract the tree's release/acquire protocol; its actual C
  // memory-order refinement, all readers and production scheduling are external.
  type State = { reader: bool, arrived0: bool, arrived1: bool, released: bool,
    drained0: bool, drained1: bool,
    retired: bool, generation: int, published: bool, loaded: int,
    cursor: int, end: int, written: bool, bad: bool }
  var s: State
  action init = s' = { reader: true, arrived0: false, arrived1: false,
    drained0: false, drained1: false,
    released: false, retired: false, generation: 1, published: false,
    loaded: 0, cursor: 2, end: 8, written: false, bad: false }
  action readerExit = all { s.reader, s' = {...s, reader: false} }
  action arrive0 = all { not(s.arrived0), s' = {...s, arrived0: true} }
  action arrive1 = all { not(s.reader), not(s.arrived1), s' = {...s, arrived1: true} }
  action barrierRelease = all { s.arrived0, s.arrived1, not(s.released), s' = {...s, released: true} }
  action cleanup0 = all { s.released, not(s.drained0), s' = {...s, drained0: true} }
  action cleanup1 = all { s.released, not(s.drained1), s' = {...s, drained1: true} }
  action retire = all { s.drained0, s.drained1, not(s.retired), s' = {...s, retired: true} }
  action publish = all { s.retired, not(s.published), s' = {...s, published: true} }
  action reload = all { s.published, s.loaded != s.generation, s' = {...s, loaded: s.generation} }
  pure def fits(cursor: int, words: int, end: int): bool =
    cursor >= 0 and words > 0 and cursor <= end and words <= end - cursor
  action allocate = all { s.published, not(s.written), s.loaded == s.generation,
    fits(s.cursor, 6, s.end), s' = {...s, cursor: s.cursor + 6, written: true} }
  action step = any { readerExit, arrive0, arrive1, barrierRelease, cleanup0, cleanup1, retire,
    publish, reload, allocate, s' = s }
  val safe = all { s.released implies (s.arrived0 and s.arrived1 and not(s.reader)),
    (s.drained0 or s.drained1) implies s.released,
    s.retired implies (s.drained0 and s.drained1),
    s.written implies (s.published and s.loaded == s.generation and s.cursor <= s.end),
    not(s.bad) }
  run delayedParticipantTest = init.then(arrive0).expect(s.reader and not(s.released))
    .then(readerExit).then(arrive1).then(barrierRelease).then(cleanup0).then(cleanup1).then(retire)
    .then(publish).then(reload).then(allocate).expect(s.written and safe)
  run earlyBarrierControlTest = init.then(arrive0)
    .then(all { s' = {...s, released: true} }).expect(not(safe))
  run staleReloadControlTest = init.then(arrive0).then(readerExit).then(arrive1)
    .then(barrierRelease).then(cleanup0).then(cleanup1).then(retire).then(publish)
    .then(all { s' = {...s, written: true, cursor: 8} }).expect(not(safe))
  run shortIntervalControlTest = init.expect(fits(2, 6, 8) and not(fits(2, 6, 7)))
  run wrongEpochControlTest = init.then(arrive0).then(readerExit).then(arrive1)
    .then(barrierRelease).then(cleanup0).then(cleanup1).then(retire).then(publish).then(reload)
    .then(all { s' = {...s, generation: 2, written: true, cursor: 8} }).expect(not(safe))
  run incompleteCleanupControlTest = init.then(arrive0).then(readerExit).then(arrive1)
    .then(barrierRelease).then(cleanup0)
    .then(all { s' = {...s, retired: true} }).expect(not(safe))
}

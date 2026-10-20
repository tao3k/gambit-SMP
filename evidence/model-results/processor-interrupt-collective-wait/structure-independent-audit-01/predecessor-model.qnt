module structure_type_lifetime {
  /// Toy finite product only. No GC theorem and no native causality proof.
  /// life: 0 uninitialized, 1 initialized, 2 retired.
  /// path: 0 unknown, 1 ordinary, 2 exception. Marker absence stays unknown.
  type State = {
    life: int, published: bool, typeValid: bool, typeIdValid: bool,
    objectFresh: bool, typeFresh: bool, storageEpoch: int, currentRef: int,
    path: int, errorMarker: bool, readDone: bool, readValid: bool, control: int
  }
  var s: State
  pure def initial(c: int): State = {
    life: 0,
    published: false,
    typeValid: false,
    typeIdValid: false,
    objectFresh: true,
    typeFresh: true,
    storageEpoch: 1,
    currentRef: 1,
    path: 0,
    errorMarker: false,
    readDone: false,
    readValid: true,
    control: c
  }
  action initSafe = s' = initial(0)
  action initPremature = s' = initial(1)
  action initMissRefresh = s' = initial(2)
  action initOverwrite = s' = initial(3)
  action initReuse = s' = initial(4)
  action initRooted = s' = initial(5)
  action initUnknown = s' = initial(6)
  action initRetire = s' = initial(7)

  action initialize = all {
    or { s.control == 0, s.control == 2, s.control == 3, s.control == 4, s.control == 5, s.control == 7 },
    s.life == 0, not(s.published), not(s.readDone),
    s' = { ...s, life: 1, typeValid: true, typeIdValid: true, objectFresh: true, typeFresh: true }
  }
  action publish = all {
    or { s.control == 0, s.control == 2, s.control == 3, s.control == 4, s.control == 5 },
    s.life == 1, s.typeValid, s.typeIdValid, not(s.published),
    s' = { ...s, published: true }
  }
  action readOk = all {
    or { s.control == 0, s.control == 5 },
    s.published, s.life == 1, s.typeValid, s.typeIdValid,
    s.objectFresh, s.typeFresh, s.currentRef == s.storageEpoch,
    s' = { ...s, readDone: true, readValid: true, path: 1 }
  }
  /// Candidate move of the object and its type. Refresh is a separate premise.
  action relocateBoth = all {
    or { s.control == 2, s.control == 5 },
    s.published, s.life == 1, s.storageEpoch == 1, s.objectFresh, s.typeFresh,
    s' = { ...s, storageEpoch: 2, objectFresh: false, typeFresh: false }
  }
  action refreshBoth = all {
    s.control == 5, s.storageEpoch == 2, not(s.objectFresh), not(s.typeFresh), s.currentRef == 1,
    s' = { ...s, currentRef: 2, objectFresh: true, typeFresh: true }
  }
  action retireUnread = all {
    s.control == 7, s.life == 1, not(s.published), not(s.readDone),
    s' = { ...s, life: 2 }
  }
  /// Absent hook marker is unknown. It does not select the ordinary path.
  action absentMarker = all {
    s.control == 6, s.path == 0, not(s.errorMarker),
    s' = { ...s, path: 0, errorMarker: false }
  }

  /// Unsafe controls stay out of safeStep so the union does not break the invariant.
  action publishPremature = all {
    s.control == 1, s.life == 0, not(s.typeValid), not(s.typeIdValid), not(s.published),
    s' = { ...s, published: true }
  }
  action readPremature = all {
    s.control == 1, s.published, s.life == 0, not(s.typeValid),
    s' = { ...s, readDone: true, readValid: false }
  }
  action readMissedRefresh = all {
    s.control == 2, s.published, s.life == 1, s.storageEpoch == 2,
    not(s.objectFresh), not(s.typeFresh), s.currentRef == 1,
    s' = { ...s, readDone: true, readValid: false }
  }
  action overwriteType = all {
    s.control == 3, s.published, s.life == 1, s.typeValid, s.typeIdValid,
    s' = { ...s, typeValid: false, typeIdValid: false }
  }
  action readOverwritten = all {
    s.control == 3, s.published, not(s.typeValid), not(s.typeIdValid),
    s' = { ...s, readDone: true, readValid: false }
  }
  action reuseStorage = all {
    s.control == 4, s.published, s.life == 1, s.currentRef == 1, s.storageEpoch == 1,
    s' = { ...s, life: 2, storageEpoch: 2, typeValid: false, typeIdValid: false, objectFresh: false, typeFresh: false }
  }
  action readReused = all {
    s.control == 4, s.life == 2, s.storageEpoch == 2, s.currentRef == 1, not(s.typeValid),
    s' = { ...s, readDone: true, readValid: false }
  }

  action safeStep = any {
    initialize, publish, readOk, relocateBoth, refreshBoth, retireUnread, absentMarker
  }

  val safe =
    (not(s.published) or ((s.life == 1) and s.typeValid and s.typeIdValid)) and
    // A read is an event: retain its validity at that event. Later relocation
    // must not retroactively invalidate a previously legal read. No native cause
    // follows from this abstract observation; type/root mapping remains open.
    (not(s.readDone) or s.readValid)

  run safeInitPublishReadTest =
    initSafe.then(initialize).then(publish).then(readOk)
      .expect(s.readDone and (s.life == 1) and s.published and (s.path == 1) and safe)
  run rootedRefreshReadTest =
    initRooted.then(initialize).then(publish).then(relocateBoth).then(refreshBoth).then(readOk)
      .expect(s.objectFresh and s.typeFresh and (s.currentRef == 2) and (s.storageEpoch == 2) and s.readDone and safe)
  run retireUnreadTest =
    initRetire.then(initialize).then(retireUnread)
      .expect((s.life == 2) and not(s.readDone) and not(s.published) and safe)
  run prematurePublishReadTest =
    initPremature.then(publishPremature).then(readPremature)
      .expect(s.published and (s.life == 0) and s.readDone and not(safe))
  run missedRefreshReadTest =
    initMissRefresh.then(initialize).then(publish).then(relocateBoth).then(readMissedRefresh)
      .expect(s.readDone and not(s.objectFresh) and not(s.typeFresh) and (s.currentRef == 1) and (s.storageEpoch == 2) and not(safe))
  run overwriteReadTest =
    initOverwrite.then(initialize).then(publish).then(overwriteType).then(readOverwritten)
      .expect(s.readDone and s.published and not(s.typeValid) and not(s.typeIdValid) and not(safe))
  run reuseReadTest =
    initReuse.then(initialize).then(publish).then(reuseStorage).then(readReused)
      .expect(s.readDone and (s.life == 2) and (s.currentRef == 1) and (s.storageEpoch == 2) and not(safe))
  run unknownPathTest =
    initUnknown.then(absentMarker)
      .expect(not(s.errorMarker) and (s.path == 0) and not(s.path == 1) and safe)
  // Auditor regression for the retained counterexample: reads are event-local.
  run legalReadThenRelocateTest =
    initRooted.then(initialize).then(publish).then(readOk).then(relocateBoth)
      .expect(s.readDone and s.readValid and not(s.objectFresh) and not(s.typeFresh) and safe)

}

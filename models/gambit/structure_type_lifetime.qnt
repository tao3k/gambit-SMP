module structure_type_lifetime {
  /// Toy finite product only. No GC theorem and no native causality proof.
  /// No source edits. life: 0 uninitialized, 1 initialized, 2 retired.
  /// path: 0 unknown, 1 ordinary, 2 exception. Marker absence stays unknown.
  /// Epochs move only from 1 to 2. Refs catch up only by a rooted refresh.
  /// Missing object or type roots are an abstract observation. This model does
  /// not assert that a native runtime must root the type separately. Object
  /// tracing may suffice for the native collector. No causal claim is made.
  ///
  /// Controls: 0 safe (both roots), 1 malformed publication, 2 object-only
  /// rooted move, 3 type-only rooted move, 4 both rooted moves, 5 missing
  /// object root, 6 missing type root, 7 overwrite, 8 reuse, 9 unknown path.
  type State = {
    life: int,
    published: bool,
    typeValid: bool,
    typeIdValid: bool,
    objectRooted: bool,
    typeRooted: bool,
    objectEpoch: int,
    typeEpoch: int,
    objectRefEpoch: int,
    typeRefEpoch: int,
    path: int,
    errorMarker: bool,
    readDone: bool,
    readValid: bool,
    control: int
  }

  var s: State

  pure def initial(c: int, objectRoot: bool, typeRoot: bool): State = {
    life: 0,
    published: false,
    typeValid: false,
    typeIdValid: false,
    objectRooted: objectRoot,
    typeRooted: typeRoot,
    objectEpoch: 1,
    typeEpoch: 1,
    objectRefEpoch: 1,
    typeRefEpoch: 1,
    path: 0,
    errorMarker: false,
    readDone: false,
    readValid: true,
    control: c
  }

  /// Validity is derived from the pre-state of the read. It is not an expected constant.
  pure def liveReadOk(st: State): bool =
    and {
      st.life == 1,
      st.published,
      st.typeValid,
      st.typeIdValid,
      st.objectRefEpoch == st.objectEpoch,
      st.typeRefEpoch == st.typeEpoch
    }

  pure def safeControl(c: int): bool =
    or { c == 0, c == 2, c == 3, c == 4, c == 9 }

  action initSafe = s' = initial(0, true, true)
  action initPremature = s' = initial(1, true, true)
  action initObjectRooted = s' = initial(2, true, true)
  action initTypeRooted = s' = initial(3, true, true)
  action initRooted = s' = initial(4, true, true)
  action initMissingObjectRoot = s' = initial(5, false, true)
  action initMissingTypeRoot = s' = initial(6, true, false)
  action initOverwrite = s' = initial(7, true, true)
  action initReuse = s' = initial(8, true, true)
  action initUnknown = s' = initial(9, true, true)

  action initialize = all {
    or {
      s.control == 0, s.control == 2, s.control == 3, s.control == 4,
      s.control == 5, s.control == 6, s.control == 7, s.control == 8
    },
    s.life == 0,
    not(s.published),
    not(s.readDone),
    s' = { ...s, life: 1, typeValid: true, typeIdValid: true }
  }

  action publish = all {
    or {
      s.control == 0, s.control == 2, s.control == 3, s.control == 4,
      s.control == 5, s.control == 6, s.control == 7, s.control == 8
    },
    s.life == 1,
    s.typeValid,
    s.typeIdValid,
    not(s.published),
    s.objectRefEpoch == s.objectEpoch,
    s.typeRefEpoch == s.typeEpoch,
    s' = { ...s, published: true }
  }

  /// One read for safe and negative controls. Invalid reads stay enabled.
  action read = all {
    or {
      s.control == 0, s.control == 1, s.control == 2, s.control == 3, s.control == 4,
      s.control == 5, s.control == 6, s.control == 7, s.control == 8
    },
    not(s.readDone),
    s' = {
      ...s,
      readDone: true,
      readValid: liveReadOk(s),
      path: if (liveReadOk(s)) 1 else s.path
    }
  }

  /// Safe schedules only take a read when the same live predicate holds.
  action safeRead = all { liveReadOk(s), read }

  action relocateObject = all {
    or { s.control == 2, s.control == 4, s.control == 5 },
    s.published,
    s.life == 1,
    s.objectEpoch == 1,
    s' = { ...s, objectEpoch: 2 }
  }

  action relocateType = all {
    or { s.control == 3, s.control == 4, s.control == 6 },
    s.published,
    s.life == 1,
    s.typeEpoch == 1,
    s' = { ...s, typeEpoch: 2 }
  }

  action refreshObject = all {
    or { s.control == 2, s.control == 4 },
    s.objectRooted,
    s.objectEpoch == 2,
    s.objectRefEpoch == 1,
    s' = { ...s, objectRefEpoch: 2 }
  }

  action refreshType = all {
    or { s.control == 3, s.control == 4 },
    s.typeRooted,
    s.typeEpoch == 2,
    s.typeRefEpoch == 1,
    s' = { ...s, typeRefEpoch: 2 }
  }

  /// Absent hook marker is unknown. It does not select the ordinary path.
  action absentMarker = all {
    s.control == 9,
    s.path == 0,
    not(s.errorMarker),
    s' = { ...s, path: 0, errorMarker: false }
  }

  action publishPremature = all {
    s.control == 1,
    s.life == 0,
    not(s.typeValid),
    not(s.typeIdValid),
    not(s.published),
    s' = { ...s, published: true }
  }

  action overwriteType = all {
    s.control == 7,
    s.published,
    s.life == 1,
    s.typeValid,
    s.typeIdValid,
    s' = { ...s, typeValid: false, typeIdValid: false }
  }

  action reuseStorage = all {
    s.control == 8,
    s.published,
    s.life == 1,
    s.objectEpoch == 1,
    s.typeEpoch == 1,
    s.objectRefEpoch == 1,
    s.typeRefEpoch == 1,
    s' = {
      ...s,
      life: 2,
      objectEpoch: 2,
      typeEpoch: 2,
      typeValid: false,
      typeIdValid: false
    }
  }

  /// Unsafe controls stay out of safeStep so the union does not break the invariant.
  action safeStep = any {
    all { safeControl(s.control), initialize },
    all { safeControl(s.control), publish },
    all { safeControl(s.control), safeRead },
    all { or { s.control == 2, s.control == 4 }, relocateObject },
    all { or { s.control == 3, s.control == 4 }, relocateType },
    all { or { s.control == 2, s.control == 4 }, refreshObject },
    all { or { s.control == 3, s.control == 4 }, refreshType },
    all { s.control == 9, absentMarker }
  }

  val safe =
    (not(s.published) or ((s.life == 1) and s.typeValid and s.typeIdValid)) and
    // A read is an event: retain its validity at that event. Later relocation
    // must not retroactively invalidate a previously legal read.
    (not(s.readDone) or s.readValid)

  run safeRootsInitialTest =
    initSafe.expect(s.objectRooted and s.typeRooted and (s.objectEpoch == 1) and (s.typeEpoch == 1) and safe)

  run safeInitPublishReadTest =
    initSafe.then(initialize).then(publish).then(read)
      .expect(s.readDone and s.readValid and (s.life == 1) and s.published and (s.path == 1) and safe)

  run objectOnlyRelocateRefreshReadTest =
    initObjectRooted.then(initialize).then(publish).then(relocateObject).then(refreshObject).then(read)
      .expect(
        s.objectRooted and s.typeRooted and s.readDone and s.readValid and (s.path == 1)
        and (s.objectEpoch == 2) and (s.objectRefEpoch == 2)
        and (s.typeEpoch == 1) and (s.typeRefEpoch == 1) and safe
      )

  run typeOnlyRelocateRefreshReadTest =
    initTypeRooted.then(initialize).then(publish).then(relocateType).then(refreshType).then(read)
      .expect(
        s.objectRooted and s.typeRooted and s.readDone and s.readValid and (s.path == 1)
        and (s.typeEpoch == 2) and (s.typeRefEpoch == 2)
        and (s.objectEpoch == 1) and (s.objectRefEpoch == 1) and safe
      )

  run bothRelocateRefreshReadTest =
    initRooted.then(initialize).then(publish)
      .then(relocateObject).then(relocateType)
      .then(refreshObject).then(refreshType).then(read)
      .expect(
        s.objectRooted and s.typeRooted and s.readDone and s.readValid
        and (s.objectEpoch == 2) and (s.objectRefEpoch == 2)
        and (s.typeEpoch == 2) and (s.typeRefEpoch == 2) and safe
      )

  // Auditor regression: a legal read stays valid after a later relocation.
  run legalReadThenRelocateTest =
    initRooted.then(initialize).then(publish).then(read).then(relocateObject).then(relocateType)
      .expect(
        s.readDone and s.readValid and (s.path == 1)
        and (s.objectEpoch == 2) and (s.objectRefEpoch == 1)
        and (s.typeEpoch == 2) and (s.typeRefEpoch == 1) and safe
      )

  run prematurePublishReadTest =
    initPremature.then(publishPremature).then(read)
      .expect(s.published and (s.life == 0) and s.readDone and not(s.readValid) and not(safe))

  run missingObjectRootReadTest =
    initMissingObjectRoot.then(initialize).then(publish).then(relocateObject).then(read)
      .expect(
        s.readDone and not(s.readValid) and not(s.objectRooted) and s.typeRooted
        and (s.objectEpoch == 2) and (s.objectRefEpoch == 1)
        and (s.typeEpoch == 1) and (s.typeRefEpoch == 1) and not(safe)
      )

  run missingTypeRootReadTest =
    initMissingTypeRoot.then(initialize).then(publish).then(relocateType).then(read)
      .expect(
        s.readDone and not(s.readValid) and s.objectRooted and not(s.typeRooted)
        and (s.typeEpoch == 2) and (s.typeRefEpoch == 1)
        and (s.objectEpoch == 1) and (s.objectRefEpoch == 1) and not(safe)
      )

  run overwriteReadTest =
    initOverwrite.then(initialize).then(publish).then(overwriteType).then(read)
      .expect(s.readDone and not(s.readValid) and s.published and not(s.typeValid) and not(s.typeIdValid) and not(safe))

  run reuseReadTest =
    initReuse.then(initialize).then(publish).then(reuseStorage).then(read)
      .expect(
        s.readDone and not(s.readValid) and (s.life == 2)
        and (s.objectRefEpoch == 1) and (s.objectEpoch == 2)
        and (s.typeRefEpoch == 1) and (s.typeEpoch == 2) and not(safe)
      )

  run unknownPathTest =
    initUnknown.then(absentMarker)
      .expect(not(s.errorMarker) and (s.path == 0) and not(s.path == 1) and safe)
}

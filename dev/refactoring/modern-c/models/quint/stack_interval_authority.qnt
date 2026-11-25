// Guard the existing publication protocol with a source-supplied interval
// identity check. Lean owns the arithmetic. This model does not validate C.
module stack_interval_authority {
  import rest_frame_publication.* from "./rest_frame_publication"

  var ownedInterval: bool

  action start = all { init, ownedInterval' = true }
  action preserveOwned = ownedInterval' = ownedInterval
  action validShortage = all { ownedInterval, requestSpace, preserveOwned }
  action validGrant = all { ownedInterval, grant, preserveOwned }
  action loseInterval = all {
    (a.phase == "entry" or a.phase == "retry") and not(a.serviceBusy),
    a' = {...a, room: false},
    ownedInterval' = false
  }
  action rejectInvalidInterval = all {
    not(ownedInterval) and (a.phase == "entry" or a.phase == "retry") and not(a.serviceBusy),
    a' = {...a, phase: "failed"},
    preserveOwned
  }
  val intervalSafe = safe and
    (ownedInterval or (not(a.room) and not(a.serviceBusy) and a.phase != "handler" and
      a.phase != "granted" and a.writes == 0 and a.pops == 0))

  run validShortageRetainsCustodyTest = start.then(validShortage)
    .expect(intervalSafe and a.serviceBusy and a.pending == a.request)
  run validIntervalCanGrantTest = start.then(all { alreadyFits, preserveOwned })
    .then(validGrant).expect(intervalSafe and a.phase == "granted")
  run invalidIntervalRefusesBeforeHandlerTest = start.then(loseInterval)
    .then(rejectInvalidInterval)
    .expect(intervalSafe and a.phase == "failed" and a.roots and not(a.spillWritten))
  run invalidIntervalAsShortageControlTest = start.then(loseInterval)
    .then(all { requestSpace, preserveOwned })
    .expect(not(intervalSafe))
  run invalidIntervalGrantControlTest = start.then(loseInterval)
    .then(all { alreadyFits, preserveOwned }).then(all { grant, preserveOwned })
    .expect(not(intervalSafe))
  run lostIntervalAfterRefillRefusesTest = start.then(validShortage)
    .then(all { enterRefill, preserveOwned }).then(all { restoreWithRoom, preserveOwned })
    .then(all { qualifyRefillOutcome, preserveOwned }).then(all { settleService, preserveOwned })
    .then(all { finishUnwind, preserveOwned }).then(loseInterval).then(rejectInvalidInterval)
    .expect(intervalSafe and a.roots and not(a.reloaded) and a.phase == "failed")
}

// A region can be retired/reused independently of moving GC. A callback can
// change the cursor view without changing either generation or GC epoch.
// Actual allocator provenance, root inventory and C stores remain premises.
module rest_authority_revision {
  type View = {
    owner: int, generation: int, rootRevision: int, cursorRevision: int,
    live: bool, loadedRevision: int, grantOwner: int, grantGeneration: int,
    grantRoots: int, grantCursor: int, writes: int, invalidWrite: bool
  }
  var view: View
  action init = view' = {
    owner: 1, generation: 1, rootRevision: 1, cursorRevision: 1,
    live: true, loadedRevision: 1, grantOwner: 0, grantGeneration: 0,
    grantRoots: 0, grantCursor: 0, writes: 0, invalidWrite: false
  }
  val currentGrant = view.live and view.loadedRevision == view.rootRevision and
    view.grantOwner == view.owner and view.grantGeneration == view.generation and
    view.grantRoots == view.rootRevision and view.grantCursor == view.cursorRevision
  action grant = all {
    view.live, view.loadedRevision == view.rootRevision,
    view' = {...view, grantOwner: view.owner, grantGeneration: view.generation,
      grantRoots: view.rootRevision, grantCursor: view.cursorRevision}
  }
  action moveRoots = all {
    view.live, view.rootRevision < 2,
    view' = {...view, rootRevision: view.rootRevision + 1,
      cursorRevision: view.cursorRevision + 1}
  }
  action reload = all {
    view.live, view.loadedRevision != view.rootRevision,
    view' = {...view, loadedRevision: view.rootRevision}
  }
  action callbackChangesCursor = all {
    view.live, view.cursorRevision < 3,
    view' = {...view, cursorRevision: view.cursorRevision + 1}
  }
  action retire = all { view.live, view' = {...view, live: false} }
  action reuseSameAddress = all {
    not(view.live), view.generation < 2,
    view' = {...view, live: true, owner: 2, generation: view.generation + 1}
  }
  action write = all {
    currentGrant, view.writes == 0,
    view' = {...view, writes: 1}
  }
  action uncheckedWrite = all {
    view.writes == 0,
    view' = {...view, writes: 1, invalidWrite: not(currentGrant)}
  }
  val safe = not(view.invalidWrite) and view.writes <= 1
  action step = any { grant, moveRoots, reload, callbackChangesCursor,
    retire, reuseSameAddress, write, view' = view }

  run currentAuthorityWritesTest = init.then(grant).then(write).expect(safe)
  run movingRootsRequireReloadAndNewGrantTest = init.then(grant).then(moveRoots)
    .expect(not(currentGrant)).then(reload).expect(not(currentGrant))
    .then(grant).then(write).expect(safe and view.writes == 1)
  run sameGcEpochChangedCursorRequiresNewGrantTest = init.then(grant)
    .then(callbackChangesCursor).expect(view.rootRevision == 1 and not(currentGrant))
    .then(grant).then(write).expect(safe)
  run sameAddressNewOwnerRejectsOldGrantTest = init.then(grant).then(retire)
    .then(reuseSameAddress)
    .expect(view.rootRevision == 1 and view.generation == 2 and not(currentGrant))
  run oldRegionGrantControlTest = init.then(grant).then(retire)
    .then(reuseSameAddress).then(uncheckedWrite).expect(not(safe))
  run missingRootReloadControlTest = init.then(grant).then(moveRoots)
    .then(uncheckedWrite).expect(not(safe))
  run sameEpochCursorReplayControlTest = init.then(grant).then(callbackChangesCursor)
    .then(uncheckedWrite).expect(not(safe))
  run retiredBackingControlTest = init.then(grant).then(retire)
    .then(uncheckedWrite).expect(not(safe))
}

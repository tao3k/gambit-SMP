// The movable bignum path. The separately allocated still-object branch
// has its own native refinement obligation. Words and real frame shape
// are premises here. This module owns only ordering and token custody.
module numeric_host_admission {
  type Attempt = {
    owner: int, point: int, attempt: int, epoch: int, rootEpoch: int,
    phase: int, grants: int, stores: int, deliveries: int
  }
  var s: Attempt

  action init = s' = {
    owner: 1, point: 2, attempt: 3, epoch: 0, rootEpoch: -1,
    phase: 0, grants: 0, stores: 0, deliveries: 0
  }

  action publishRoots = all {
    s.phase == 0,
    s' = { ...s, phase: 1, rootEpoch: s.epoch }
  }

  action collectOnShortage = all {
    s.phase == 1 and s.rootEpoch == s.epoch,
    s' = { ...s, phase: 2, epoch: s.epoch + 1 }
  }

  action reloadRepairedRoots = all {
    s.phase == 2,
    s' = { ...s, phase: 1, rootEpoch: s.epoch }
  }

  def canGrant(owner: int, point: int, attempt: int, epoch: int, fits: bool): bool =
    s.phase == 1 and s.rootEpoch == s.epoch and fits and
    s.owner == owner and s.point == point and s.attempt == attempt and s.epoch == epoch

  action grant = all {
    canGrant(1, 2, 3, s.epoch, true),
    s' = { ...s, phase: 3, grants: s.grants + 1 }
  }

  action refuse = all {
    s.phase == 1,
    s' = { ...s, phase: 6 }
  }

  action initialize = all {
    s.phase == 3 and s.rootEpoch == s.epoch,
    s' = { ...s, phase: 4, stores: s.stores + 1 }
  }

  action loseCommitReply = all {
    s.phase == 4,
    s' = { ...s, phase: 5 }
  }

  action queryOriginalCommit = all {
    s.phase == 5,
    s' = { ...s, phase: 4 }
  }

  action deliver = all {
    s.phase == 4,
    s' = { ...s, phase: 7, deliveries: s.deliveries + 1 }
  }

  val safe =
    s.deliveries <= s.stores and s.stores <= s.grants and s.grants <= 1 and
    (s.phase == 6 implies s.stores == 0) and
    (s.phase == 5 implies s.stores == 1 and s.deliveries == 0 and s.rootEpoch == s.epoch)

  action step = any {
    publishRoots, collectOnShortage, reloadRepairedRoots, grant, refuse,
    initialize, loseCommitReply, queryOriginalCommit, deliver, s' = s
  }

  action badProvisionalAdvance = all {
    s.phase == 1,
    s' = { ...s, stores: s.stores + 1 }
  }

  run exactGrantTest = init.then(publishRoots).then(grant).then(initialize).then(deliver)
    .expect(safe and s.stores == 1 and s.deliveries == 1)

  run shortRefusesWithNoStoreTest = init.then(publishRoots)
    .expect(not(canGrant(1, 2, 3, 0, false))).then(refuse)
    .expect(safe and s.stores == 0 and s.deliveries == 0)

  run collectionRequiresReloadAndNewGrantTest = init.then(publishRoots).then(collectOnShortage)
    .expect(not(canGrant(1, 2, 3, 1, true))).then(reloadRepairedRoots)
    .expect(not(canGrant(1, 2, 3, 0, true))).then(grant).then(initialize).then(deliver)
    .expect(safe and s.deliveries == 1)

  run foreignIdentityCannotConsumeTest = init.then(publishRoots)
    .expect(not(canGrant(4, 2, 3, 0, true)) and not(canGrant(1, 4, 3, 0, true)) and
            not(canGrant(1, 2, 4, 0, true)))

  run lostReplyQueriesWithoutRegrantTest = init.then(publishRoots).then(grant).then(initialize)
    .then(loseCommitReply).expect(safe and not(canGrant(1, 2, 3, 0, true)))
    .then(queryOriginalCommit).then(deliver).expect(safe and s.deliveries == 1)

  run provisionalCursorBeforeGrantCounterexampleTest = init.then(publishRoots)
    .then(badProvisionalAdvance).expect(not(safe))
}

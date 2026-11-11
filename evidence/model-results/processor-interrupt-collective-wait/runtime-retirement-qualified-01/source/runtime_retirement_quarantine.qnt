// Finite SC of source-ordered runtime retirement. Root cleanup seals and
// drains before it publishes the root shrink join. A local resize publication
// is not that root cleanup. Joinable exclusive ownership is only the premise
// of joinSuccess. Environmental join failure stays in the relation. Lease
// counts and flags are semantic roles, not CPU caps. The writer does not
// erase an admitted reader; an independent leave does.
module runtime_retirement_quarantine {
  type State = {
    policy: str,
    ownership: str,
    join: str,
    pendingCount: int,
    joinPending: bool,
    phase: str,
    setupState: int,
    sealed: bool,
    open: bool,
    admitted: bool,
    lease: int,
    sealOldLease: int,
    postCloseLease: int,
    qualified: bool,
    beforeAfterOnly: bool,
    destroyed: bool,
    resourcesLive: bool,
    selectAbortReady: bool,
    lastError: int,
    growRejected: bool,
    pointersSame: bool,
    seenBefore: bool,
    seenAfter: bool,
    rejectMarks: int,
    badForget: bool,
    badClear: bool,
    badSkip: bool,
    badWitness: bool
  }
  var s: State

  pure def initial(policy: str): State = {
    policy: policy,
    ownership: "joinable-exclusive",
    join: "idle",
    pendingCount: 0,
    joinPending: false,
    phase: "ready",
    setupState: 1,
    sealed: false,
    open: true,
    admitted: false,
    lease: 0,
    sealOldLease: 0,
    postCloseLease: -1,
    qualified: false,
    beforeAfterOnly: false,
    destroyed: false,
    resourcesLive: true,
    selectAbortReady: true,
    lastError: 0,
    growRejected: false,
    pointersSame: true,
    seenBefore: false,
    seenAfter: false,
    rejectMarks: 0,
    badForget: false,
    badClear: false,
    badSkip: false,
    badWitness: false
  }

  action init = s' = initial("actual")
  // Snapshots sit after the real event the negative control mishandles.
  action initForgetPending = s' = { ...initial("forget-pending"),
    phase: "resizing", join: "pending", pendingCount: 1, joinPending: true }
  action initClearSticky = s' = { ...initial("clear-sticky"),
    phase: "retained-root", setupState: 2, join: "fault", pendingCount: 1, joinPending: true,
    sealed: true, open: false, lastError: 22, postCloseLease: 0,
    resourcesLive: true, selectAbortReady: true, pointersSame: true }
  action initSkipDrain = s' = { ...initial("skip-drain"),
    phase: "cleaning", setupState: 2, admitted: true, lease: 1, sealOldLease: 1,
    sealed: true, open: false, postCloseLease: -1 }
  action initFalseWitness = s' = initial("false-before-after-witness")

  action beginResize = all {
    s.policy == "actual",
    s.phase == "ready",
    s.join == "idle",
    s.pendingCount == 0,
    s' = { ...s, phase: "resizing", join: "pending", pendingCount: 1, joinPending: true }
  }

  action beginCleanup = all {
    s.policy == "actual",
    s.phase == "ready",
    s.join == "idle",
    s.pendingCount == 0,
    s' = { ...s, phase: "cleaning", setupState: 2 }
  }

  action admitReader = all {
    s.policy == "actual",
    not(s.admitted),
    s.lease == 0,
    s.open,
    not(s.sealed),
    s.phase == "ready" or s.phase == "cleaning",
    s' = { ...s, admitted: true, lease: 1 }
  }

  action sealCapture = all {
    s.policy == "actual",
    s.phase == "cleaning",
    not(s.sealed),
    s' = { ...s, sealed: true, open: false, sealOldLease: s.lease }
  }

  action leaveReader = all {
    s.policy == "actual",
    s.lease > 0,
    s' = { ...s, lease: s.lease - 1 }
  }

  action observeDrain = all {
    s.policy == "actual",
    s.phase == "cleaning",
    s.sealed,
    s.lease == 0,
    s.postCloseLease == -1,
    s' = { ...s, postCloseLease: 0 }
  }

  action publishRootJoin = all {
    s.policy == "actual",
    s.phase == "cleaning",
    s.sealed,
    s.postCloseLease == 0,
    s.lease == 0,
    s.join == "idle",
    s.pendingCount == 0,
    s' = { ...s, join: "pending", pendingCount: 1, joinPending: true }
  }

  action joinSuccess = all {
    s.policy == "actual",
    s.ownership == "joinable-exclusive",
    s.join == "pending",
    s.pendingCount == 1,
    s.phase == "resizing" or s.phase == "cleaning",
    s' = if (s.phase == "resizing")
      { ...s, join: "joined", pendingCount: 0, joinPending: false,
        ownership: "cleared", phase: "local-complete" }
    else
      { ...s, join: "joined", pendingCount: 0, joinPending: false, ownership: "cleared" }
  }

  action environmentalJoinFault = all {
    s.policy == "actual",
    s.ownership == "joinable-exclusive",
    s.join == "pending",
    s.pendingCount == 1,
    s.phase == "resizing" or s.phase == "cleaning",
    s' = if (s.phase == "resizing")
      { ...s, join: "fault", lastError: 22, phase: "retained-local", setupState: 1,
        growRejected: true, resourcesLive: true, destroyed: false }
    else
      { ...s, join: "fault", lastError: 22, phase: "retained-root", setupState: 2,
        sealed: true, open: false, resourcesLive: true, selectAbortReady: true,
        pointersSame: true, destroyed: false }
  }

  action adversarialJoinFault = all {
    s.policy == "actual",
    s.join == "pending",
    s.pendingCount == 1,
    s.phase == "resizing" or s.phase == "cleaning",
    s' = if (s.phase == "resizing")
      { ...s, ownership: "adversarial-breach", join: "fault", lastError: 22,
        phase: "retained-local", setupState: 1, growRejected: true,
        resourcesLive: true, destroyed: false }
    else
      { ...s, ownership: "adversarial-breach", join: "fault", lastError: 22,
        phase: "retained-root", setupState: 2, sealed: true, open: false,
        resourcesLive: true, selectAbortReady: true, pointersSame: true, destroyed: false }
  }

  action rejectRetry = all {
    s.policy == "actual",
    s.phase == "retained-root",
    s.setupState == 2,
    s.rejectMarks == 0,
    s' = { ...s, rejectMarks: 1, lastError: 22, pendingCount: 1, joinPending: true,
      sealed: true, open: false, pointersSame: true, resourcesLive: true,
      selectAbortReady: true, destroyed: false }
  }

  action rejectSetup = all {
    s.policy == "actual",
    s.phase == "retained-root",
    s.setupState == 2,
    s.rejectMarks == 1,
    s' = { ...s, rejectMarks: 2, setupState: 2, lastError: 22, pendingCount: 1,
      sealed: true, open: false, pointersSame: true, resourcesLive: true,
      selectAbortReady: true, destroyed: false }
  }

  action rejectReopen = all {
    s.policy == "actual",
    s.phase == "retained-root",
    s.setupState == 2,
    s.rejectMarks == 2,
    s' = { ...s, rejectMarks: 3, sealed: true, open: false, lastError: 22,
      pointersSame: true, resourcesLive: true, selectAbortReady: true, destroyed: false }
  }

  action destroyClean = all {
    s.policy == "actual",
    s.phase == "cleaning",
    s.join == "joined",
    s.pendingCount == 0,
    not(s.joinPending),
    s.sealed,
    s.postCloseLease == 0,
    s.lease == 0,
    s' = { ...s, destroyed: true, resourcesLive: false, phase: "clean",
      qualified: s.sealOldLease > 0 and not(s.beforeAfterOnly) }
  }

  action noteBefore = all {
    s.policy == "false-before-after-witness",
    not(s.seenBefore),
    s' = { ...s, seenBefore: true }
  }
  action noteAfter = all {
    s.policy == "false-before-after-witness",
    s.seenBefore,
    not(s.seenAfter),
    s' = { ...s, seenAfter: true }
  }

  action forgetPending = all {
    s.policy == "forget-pending",
    s.pendingCount == 1,
    s.joinPending,
    not(s.badForget),
    s' = { ...s, pendingCount: 0, joinPending: false, destroyed: true,
      resourcesLive: false, badForget: true, phase: "clean" }
  }

  action clearSticky = all {
    s.policy == "clear-sticky",
    s.phase == "retained-root",
    s.setupState == 2,
    not(s.badClear),
    s' = { ...s, phase: "ready", setupState: 1, sealed: false, open: true,
      pendingCount: 0, joinPending: false, lastError: 0, pointersSame: false,
      badClear: true }
  }

  action skipDrain = all {
    s.policy == "skip-drain",
    s.lease > 0,
    s.sealed,
    not(s.badSkip),
    s' = { ...s, destroyed: true, resourcesLive: false, badSkip: true, phase: "clean" }
  }

  action falseBeforeAfterWitness = all {
    s.policy == "false-before-after-witness",
    s.seenBefore,
    s.seenAfter,
    s.sealOldLease == 0,
    not(s.badWitness),
    s' = { ...s, beforeAfterOnly: true, qualified: true, badWitness: true, phase: "clean" }
  }

  val actualTerminal =
    s.phase == "clean" or s.phase == "local-complete" or
    s.phase == "retained-local" or s.phase == "retained-root"
  val negativeTerminal = s.badForget or s.badClear or s.badSkip or s.badWitness
  val terminal = if (s.policy == "actual") actualTerminal else negativeTerminal
  action finished = all { terminal, s' = s }

  action step = any {
    beginResize, beginCleanup, admitReader, sealCapture, leaveReader, observeDrain,
    publishRootJoin, joinSuccess, environmentalJoinFault, adversarialJoinFault,
    rejectRetry, rejectSetup, rejectReopen, destroyClean, noteBefore, noteAfter,
    forgetPending, clearSticky, skipDrain, falseBeforeAfterWitness, finished
  }

  val nativeQualified =
    s.qualified and s.sealOldLease > 0 and s.postCloseLease == 0 and not(s.beforeAfterOnly)
  val stickyClosed = (s.phase == "retained-root" and s.setupState == 2) implies (
    s.sealed and not(s.open) and s.lastError == 22 and s.pointersSame and
    s.resourcesLive and s.selectAbortReady and not(s.destroyed) and
    s.pendingCount == 1 and s.joinPending)
  val safe = s.policy != "actual" or (
    not(s.badForget) and not(s.badClear) and not(s.badSkip) and not(s.badWitness) and
    stickyClosed and
    (s.destroyed implies (
      s.join == "joined" and s.pendingCount == 0 and not(s.joinPending) and
      s.sealed and s.postCloseLease == 0 and s.lease == 0)) and
    (s.qualified implies nativeQualified) and
    (s.sealed implies not(s.open)) and
    (s.phase == "retained-local" implies (
      s.setupState == 1 and s.growRejected and s.resourcesLive and not(s.destroyed) and
      s.pendingCount == 1 and s.joinPending and not(s.sealed)))
  )
  val forgetSafe = not(s.badForget)
  val clearSafe = not(s.badClear)
  val drainSafe = not(s.badSkip)
  val witnessSafe = not(s.badWitness)
  val noStall = terminal or enabled(step)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))

  run rootNormalCleanTest = init.then(beginCleanup).then(sealCapture).then(observeDrain)
    .then(publishRootJoin).then(joinSuccess).then(destroyClean)
    .then(all { assert(s.phase == "clean"), assert(s.pendingCount == 0),
      assert(s.sealOldLease == 0), assert(not(s.qualified)), assert(safe), s' = s })

  run localAdversarialPendingTest = init.then(beginResize).then(adversarialJoinFault)
    .then(all { assert(s.ownership == "adversarial-breach"), assert(s.phase == "retained-local"),
      assert(s.setupState == 1), assert(s.lastError == 22), assert(s.pendingCount == 1),
      assert(s.joinPending), assert(s.growRejected), assert(not(s.sealed)),
      assert(s.resourcesLive), assert(not(s.destroyed)), assert(safe), s' = s })

  run rootEnvironmentalStickyTest = init.then(beginCleanup).then(sealCapture).then(observeDrain)
    .then(publishRootJoin).then(environmentalJoinFault)
    .then(rejectRetry).then(rejectSetup).then(rejectReopen)
    .then(all { assert(s.ownership == "joinable-exclusive"), assert(s.phase == "retained-root"),
      assert(s.setupState == 2), assert(s.lastError == 22), assert(s.pendingCount == 1),
      assert(s.joinPending), assert(s.sealed), assert(not(s.open)),
      assert(s.selectAbortReady), assert(s.pointersSame), assert(s.resourcesLive),
      assert(not(s.destroyed)), assert(stickyClosed), assert(safe), s' = s })

  run rootWitnessedDrainTest = init.then(beginCleanup).then(admitReader).then(sealCapture)
    .then(leaveReader).then(observeDrain).then(publishRootJoin).then(joinSuccess)
    .then(destroyClean)
    .then(all { assert(s.sealOldLease > 0), assert(s.postCloseLease == 0),
      assert(s.lease == 0), assert(s.sealed), assert(nativeQualified),
      assert(s.phase == "clean"), assert(safe), s' = s })

  run forgetPendingTest = initForgetPending.then(forgetPending)
    .then(all { assert(s.badForget), assert(s.pendingCount == 0), assert(s.destroyed),
      assert(not(forgetSafe)), s' = s })

  run falseWitnessTest = initFalseWitness.then(noteBefore).then(noteAfter)
    .then(falseBeforeAfterWitness)
    .then(all { assert(s.seenBefore), assert(s.seenAfter), assert(s.sealOldLease == 0),
      assert(s.beforeAfterOnly), assert(s.badWitness), assert(not(witnessSafe)),
      assert(not(nativeQualified)), s' = s })
}

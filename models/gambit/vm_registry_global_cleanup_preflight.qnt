module vm_registry_global_cleanup_preflight {
  // Host lifecycle ownership is exclusive. One secondary VM stands for each
  // member checked under the list mutex; direct users have already joined.
  type State = { policy: str, childActive: bool, childPending: bool,
    childResource: bool, sealed: bool, setupReady: bool, phase: str }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, childActive: true, childPending: false,
    childResource: true, sealed: false, setupReady: true, phase: "request",
  }
  action init = all { s' = initial("preflight"), a' = admissionInitial(0, Set()) }
  action initRootOnly = all { s' = initial("root-only"), a' = admissionInitial(0, Set()) }
  action shrinkChild = all { s.childActive, s.childResource, not(s.sealed),
    s' = { ...s, childActive: false, childPending: true }, a' = a }
  action joinChild = all { s.childPending, not(s.sealed),
    s' = { ...s, childPending: false }, a' = a }
  val ready = not(s.childActive) and not(s.childPending)
  action reject = all { s.phase == "request", s.policy == "preflight", not(ready),
    s' = { ...s, phase: "rejected" }, a' = a }
  action retry = all { s.phase == "rejected", s.setupReady, not(s.sealed),
    s' = { ...s, phase: "request" }, a' = a }
  action seal = all { s.phase == "request", ready or s.policy == "root-only",
    s' = { ...s, sealed: true, setupReady: false, phase: "cleanup" }, a' = a }
  action free = all { s.phase == "cleanup",
    s' = { ...s, childResource: false, phase: "done" }, a' = a }
  action hold = all { s' = s, a' = a }
  action step = any { shrinkChild, joinChild, reject, retry, seal, free, hold }
  val safe = (s.childResource or ready) and
    (s.phase != "rejected" or (s.setupReady and not(s.sealed)))
  run activeChildControlTest = initRootOnly.then(seal).then(free)
    .then(all { assert(not(safe)), hold })
  run pendingChildControlTest = initRootOnly.then(shrinkChild).then(seal).then(free)
    .then(all { assert(not(safe)), hold })
  run rejectionPreservesRecoveryTest = init.then(reject).then(shrinkChild)
    .then(joinChild).then(retry).then(seal).then(free)
    .then(all { assert(safe), assert(s.phase == "done"), hold })
  run pendingJoinRejectTest = init.then(shrinkChild).then(reject)
    .then(all { assert(safe), assert(s.setupReady), assert(not(s.sealed)), hold })

  // Composition of close_cleanup_sfun_vms: list membership is stable under
  // exclusive host lifecycle ownership. Three abstract members expose a
  // nonempty closed prefix, a busy member, and a later untouched member.
  type Admission = { policy: int, busy: Set[int], closed: Set[int],
    cursor: int, undo: int, phase: str, rejected: bool,
    scans: int, reopens: int, gateWork: int,
    retries: int, totalScans: int, totalGateWork: int }
  var a: Admission
  pure def admissionInitial(policy: int, busy: Set[int]): Admission = {
    policy: policy, busy: busy, closed: Set(), cursor: 0, undo: 0,
    phase: "scan", rejected: false,
    scans: 0, reopens: 0, gateWork: 0,
    retries: 0, totalScans: 0, totalGateWork: 0,
  }
  action initAdmission = {
    nondet busy = Set(Set(), Set(0), Set(1), Set(2),
      Set(0, 1), Set(0, 2), Set(1, 2), Set(0, 1, 2)).oneOf()
    all { a' = admissionInitial(0, busy), s' = initial("preflight") }
  }
  action initMissingUndo = all {
    a' = admissionInitial(1, Set(2)), s' = initial("preflight"),
  }
  action initEarlyCommit = all {
    a' = admissionInitial(2, Set(2)), s' = initial("preflight"),
  }
  action initRedundantScan = all {
    a' = admissionInitial(3, Set(2)), s' = initial("preflight"),
  }
  action closeMember = all {
    s' = s,
    a.phase == "scan", a.cursor < 3,
    a' = if (a.busy.contains(a.cursor))
      { ...a, phase: if (a.policy == 1) "rejected" else "undo",
        rejected: true, scans: a.scans + 1,
        gateWork: a.gateWork + 2, totalScans: a.totalScans + 1,
        totalGateWork: a.totalGateWork + 2 }
    else { ...a, closed: a.closed.union(Set(a.cursor)), cursor: a.cursor + 1,
      scans: a.scans + (if (a.policy == 3) 2 else 1), gateWork: a.gateWork + 1,
      totalScans: a.totalScans + (if (a.policy == 3) 2 else 1),
      totalGateWork: a.totalGateWork + 1 },
  }
  action undoMember = all {
    s' = s,
    a.phase == "undo", a.undo < a.cursor,
    a' = { ...a, closed: a.closed.exclude(Set(a.undo)), undo: a.undo + 1,
      reopens: a.reopens + 1, gateWork: a.gateWork + 1,
      totalGateWork: a.totalGateWork + 1 },
  }
  action rejectAdmission = all {
    s' = s,
    a.phase == "undo", a.undo == a.cursor,
    a' = { ...a, phase: "rejected" },
  }
  action retryAdmission = all {
    s' = s,
    a.phase == "rejected", a.closed == Set(), a.retries == 0,
    // Callers have actually returned; retry is not permission to erase frames.
    a' = { ...a, busy: Set(), cursor: 0, undo: 0, phase: "scan",
      rejected: false, scans: 0, reopens: 0, gateWork: 0, retries: a.retries + 1 },
  }
  action commitAdmission = all {
    s' = s,
    a.phase == "scan", a.cursor == 3 or a.policy == 2,
    a' = { ...a, phase: "committed" },
  }
  action admissionIdle = all {
    Set("rejected", "committed").contains(a.phase), a' = a, s' = s,
  }
  action admissionStep = any { closeMember, undoMember, rejectAdmission,
    retryAdmission, commitAdmission, admissionIdle }
  val prefixRollbackSafe = a.phase != "rejected" or a.closed == Set()
  val admissionCommitSafe = a.phase != "committed" or
    (a.closed == Set(0, 1, 2) and a.busy == Set())
  val admissionSafe = prefixRollbackSafe and admissionCommitSafe and
    a.closed.intersect(a.busy) == Set()
  // Per attempt, each member is inspected once, and only a closed prefix is
  // reopened once. These are work units, not seconds or an OS scheduling bound.
  // A member inspection additionally scans up to that VM's processor population;
  // the unbounded arithmetic obligation is in CleanupAdmissionWork.lean.
  val admissionWorkBound = a.scans == a.cursor + (if (a.rejected) 1 else 0) and
    a.scans <= 3 and a.reopens <= a.cursor and a.gateWork <= 2 * a.scans and
    a.totalScans <= 3 * (a.retries + 1) and
    a.totalGateWork <= 2 * a.totalScans and a.totalScans >= a.scans
  val admissionContract = admissionSafe and admissionWorkBound
  temporal admissionProgress = weakFair(admissionStep, Set(a)).implies(
    eventually(Set("rejected", "committed").contains(a.phase)))
  run prefixRollbackRetryTest =
    (all { a' = admissionInitial(0, Set(2)), s' = initial("preflight") }).then(closeMember).then(closeMember)
      .then(closeMember).then(undoMember).then(undoMember).then(rejectAdmission)
      .then(all { assert(admissionSafe), assert(a.closed == Set()), hold })
      .then(retryAdmission).then(closeMember).then(closeMember).then(closeMember)
      .then(commitAdmission).then(all { assert(admissionContract),
        assert(a.totalScans == 6), assert(a.totalGateWork == 9), hold })
  run missingPrefixUndoControlTest = initMissingUndo.then(closeMember)
    .then(closeMember).then(closeMember)
    .then(all { assert(not(prefixRollbackSafe)), hold })
  run earlyAdmissionCommitControlTest = initEarlyCommit.then(commitAdmission)
    .then(all { assert(not(admissionCommitSafe)), hold })
  run redundantAdmissionScanControlTest = initRedundantScan.then(closeMember)
    .then(all { assert(admissionSafe), assert(not(admissionWorkBound)), hold })
}

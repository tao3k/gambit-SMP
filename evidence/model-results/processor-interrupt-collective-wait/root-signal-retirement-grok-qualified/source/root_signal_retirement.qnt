module root_signal_retirement {
  // Semantic roles, not host CPU limits. SC admission and successful retry
  // are explicit premises. Root-only routing must survive deferred delivery.
  type State = { policy: str, writer: str, installed: bool, open: bool,
    alive: bool, handler: str, lease: bool, pending: bool, sealed: bool, transient: str,
    ownerOpen: bool, producer: str, join: str, joinAttempts: int,
    rootDelivered: bool, childDelivered: bool, badRoot: bool,
    badDirect: bool, badJoin: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, writer: "preflight", installed: true, open: true,
    alive: true, handler: "new", lease: false, pending: false, sealed: false, transient: "new",
    ownerOpen: true, producer: "new", join: "pending", joinAttempts: 0,
    rootDelivered: false, childDelivered: false, badRoot: false,
    badDirect: false, badJoin: false,
  }
  action init = s' = initial("leased-owned-joined")
  action initRawRoot = s' = initial("raw-root")
  action initUnjoinedDirect = s' = initial("unjoined-direct")
  action initCountOnly = s' = initial("count-only")
  action initBroadcastRoot = s' = initial("broadcast-root")
  action startHandler = all { s.handler == "new", s.installed,
    s' = { ...s, handler: "started" } }
  action enterHandler = all { s.handler == "started",
    s' = if (s.open or s.policy == "raw-root")
      { ...s, handler: "access", lease: s.policy != "raw-root" }
    else { ...s, handler: "done", pending: true } }
  action rootAccess = all { s.handler == "access",
    s' = { ...s, handler: "leave", rootDelivered: true,
      childDelivered: s.policy == "broadcast-root",
      badRoot: s.badRoot or not(s.alive) or (not(s.open) and not(s.lease)) } }
  action leaveHandler = all { s.handler == "leave",
    s' = { ...s, handler: "done", lease: false } }
  action cancelHandler = all { s.handler == "new", not(s.installed),
    s' = { ...s, handler: "done" } }
  action enterDirect = all { s.producer == "new", s.ownerOpen,
    s' = { ...s, producer: "use" } }
  action closeOwner = all { s.ownerOpen,
    s' = { ...s, ownerOpen: false } }
  action leaveDirect = all { s.producer == "use",
    // Includes enqueue, unlocked wake and any detached consumer callback.
    s' = { ...s, producer: "done", badDirect: s.badDirect or not(s.alive) } }
  action rejectDirect = all { s.producer == "new", not(s.ownerOpen),
    s' = { ...s, producer: "done" } }
  action joinFailure = all { s.join == "pending",
    s' = { ...s, join: "failed", joinAttempts: 1 } }
  action retryJoin = all { s.join == "failed",
    s' = { ...s, join: "retry" } }
  action joinSuccess = all { s.join == "pending" or s.join == "retry",
    s' = { ...s, join: "joined", joinAttempts: s.joinAttempts + 1 } }
  // A bounded transient writer precedes terminal cleanup. Reopening waits for
  // admitted readers; replay itself owns admission (atomic in this SC model).
  action transientClose = all { s.writer == "preflight", s.transient == "new",
    s' = { ...s, open: false, transient: "closed" } }
  // Shared with run tests. enabled() is not used there.
  val guardTransientOpen = s.transient == "closed" and not(s.lease) and not(s.sealed)
  action transientOpen = all { guardTransientOpen,
    s' = { ...s, open: true, transient: "reopened" } }
  val guardReplay = s.pending and s.open and not(s.sealed) and s.alive
  action replay = all { guardReplay,
    s' = { ...s, pending: false, rootDelivered: true } }
  action preflight = all { s.writer == "preflight", s.transient != "closed",
    s' = { ...s, writer:
      if (s.join == "joined" or s.policy == "count-only") "uninstall" else "retained" } }
  action resumeCleanup = all { s.writer == "retained", s.join == "joined",
    s' = { ...s, writer: "preflight" } }
  action uninstall = all { s.writer == "uninstall",
    s' = { ...s, writer: "close", installed: false } }
  action close = all { s.writer == "close",
    s' = { ...s, writer: "drain", open: false, sealed: true } }
  action destroy = all { s.writer == "drain", not(s.lease),
    not(s.ownerOpen), s.producer != "use" or s.policy == "unjoined-direct",
    s' = { ...s, writer: "done", alive: false,
      badDirect: s.badDirect or s.producer == "use",
      badJoin: s.badJoin or s.join != "joined" } }
  val terminal = s.writer == "done" and s.handler == "done" and
    s.producer == "done" and s.join == "joined"
  action finished = all { terminal, s' = s }
  action step = any { startHandler, enterHandler, rootAccess, leaveHandler,
    cancelHandler, enterDirect, closeOwner, leaveDirect, rejectDirect,
    joinFailure, retryJoin, joinSuccess, preflight, resumeCleanup, uninstall,
    close, destroy, transientClose, transientOpen, replay, finished }
  val rootSafe = not(s.badRoot)
  val directSafe = not(s.badDirect)
  val joinSafe = not(s.badJoin)
  val routingSafe = not(s.childDelivered)
  val safe = rootSafe and directSafe and joinSafe and routingSafe and
    s.joinAttempts <= 2 and (s.sealed implies not(s.open))
  val noStall = terminal or enabled(step)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
  run closedSignalDefersTest = init.then(joinSuccess).then(preflight)
    .then(startHandler).then(uninstall).then(close).then(enterHandler)
    .then(all { assert(s.pending), assert(not(s.rootDelivered)), assert(safe), s' = s })
  run rawRootControlTest = initRawRoot.then(joinSuccess).then(preflight)
    .then(startHandler).then(uninstall).then(close).then(enterHandler).then(rootAccess)
    .then(all { assert(not(rootSafe)), s' = s })
  run transientReopenDeliversRootOnlyTest = init.then(transientClose)
    .then(startHandler).then(enterHandler)
    .then(all { assert(s.pending), assert(not(s.rootDelivered)), s' = s })
    .then(transientOpen).then(replay)
    .then(all { assert(s.rootDelivered), assert(not(s.pending)), assert(routingSafe), s' = s })
  run admittedReaderBlocksReopenTest = init.then(startHandler).then(enterHandler)
    .then(transientClose)
    .then(all { assert(not(guardTransientOpen)), s' = s })
    .then(rootAccess).then(leaveHandler).then(transientOpen)
    .then(all { assert(safe), s' = s })
  run terminalSealNeverReplaysTest = init.then(startHandler).then(joinSuccess)
    .then(preflight).then(uninstall).then(close).then(enterHandler)
    .then(all { assert(s.pending), assert(not(guardReplay)),
      assert(not(guardTransientOpen)), assert(safe), s' = s })
  run failedJoinRetainsThenRetryTest = init.then(joinFailure).then(preflight)
    .then(all { assert(s.alive), assert(s.installed), assert(s.open), s' = s })
    .then(retryJoin).then(joinSuccess).then(resumeCleanup).then(preflight)
    .then(uninstall).then(close).then(closeOwner).then(rejectDirect)
    .then(cancelHandler).then(destroy)
    .then(all { assert(terminal), assert(safe), s' = s })
}

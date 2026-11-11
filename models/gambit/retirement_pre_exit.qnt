module retirement_pre_exit {
  // One old-cohort donor and P0. Entry is BEFORE callback, withdrawal or exit.
  // A model error is a source-compatible failure return, not proof of a legal
  // Darwin errno scenario. No retry of a failed join is modeled here.
  // roots=0 donor-only; roots=1 actual scanner-visible recipient ownership.
  type State = { policy: int, outcome: int, needsGC: bool, phase: int,
    member: bool, roots: int, request: bool, served: bool,
    joinState: int, joining: bool, live: bool, gcRan: bool }
  var s: State
  pure def initial(policy: int, outcome: int, needsGC: bool): State = {
    policy: policy, outcome: outcome, needsGC: needsGC, phase: 0,
    member: true, roots: 0, request: false, served: false,
    joinState: 0, joining: false, live: true, gcRan: false }
  action initStagedSuccess = s' = initial(0,0,true)
  action initStagedErrorBeforeExit = s' = initial(0,1,true)
  action initCurrentCallbackGC = s' = initial(1,0,true)
  action initCurrentErrorRetained = s' = initial(1,1,false)
  action initQuietOnly = s' = initial(2,1,true)
  action initCurrentNormal = s' = initial(1,0,false)
  action startCallback = all { s.phase == 0, s.policy != 1 or not(s.member),
    s' = { ...s, phase: 1 } }
  action requestGC = all { s.phase == 1, s.needsGC, not(s.served), not(s.request),
    s' = { ...s, request: true } }
  action serviceGC = all { s.request, s.member, not(s.joining),
    s' = { ...s, request: false, served: true } }
  action callbackReturn = all { s.phase == 1, not(s.needsGC) or s.served,
    s' = { ...s, phase: 2 } }
  // Requires actual typed root/work handoff under a legal GC boundary in C.
  action handoff = all { s.phase == 2, s.member, s.roots == 0, s.policy != 1,
    s' = { ...s, roots: 1 } }
  action withdraw = all { s.member,
    s.policy == 1 or (s.phase == 2 and (s.roots == 1 or s.policy == 2)),
    s' = { ...s, member: false } }
  action joinAttempt = all { not(s.member), s.joinState == 0, not(s.joining),
    s' = if (s.outcome == 1) { ...s, joinState: 1 }
      else { ...s, joining: true } }
  action exitThread = all { not(s.member), s.phase == 2,
    s' = { ...s, phase: 4 } }
  action joinSuccess = all { s.joining, s.phase == 4,
    s' = { ...s, joining: false, joinState: 2 } }
  // Preserve the retained source's normal successful-join transfer suffix.
  action handoffAfterJoin = all { s.policy == 1, s.joinState == 2, s.roots == 0,
    s' = { ...s, roots: 1 } }
  // Survivor GC is possible after P0 returns from the result barrier.
  action survivorGC = all { not(s.member),
    s.joinState == 1 or (s.joinState == 2 and s.roots == 1 and not(s.live)), not(s.gcRan),
    s' = { ...s, gcRan: true } }
  action release = all { s.joinState == 2, s.phase == 4, s.roots == 1, s.live,
    s' = { ...s, live: false } }
  val terminal = s.phase == 4 and s.gcRan and
    ((s.joinState == 2 and not(s.live)) or (s.joinState == 1 and s.live))
  action done = all { terminal, s' = s }
  action step = any { startCallback, requestGC, serviceGC, callbackReturn,
    handoff, withdraw, joinAttempt, exitThread, joinSuccess, handoffAfterJoin, survivorGC, release, done }
  // P0 blocked in join cannot service the GC that the exit-side callback awaits.
  val noCallbackWaitCycle = not(s.request and (s.joining or not(s.member)))
  val rootsCovered = not(s.gcRan) or s.member or s.roots == 1
  val retainUntilJoined = s.live or (s.joinState == 2 and s.phase == 4)
  val safe = noCallbackWaitCycle and rootsCovered and retainUntilJoined
  temporal completion = weakFair(startCallback,Set(s)).and(weakFair(requestGC,Set(s)))
    .and(weakFair(serviceGC,Set(s))).and(weakFair(callbackReturn,Set(s)))
    .and(weakFair(handoff,Set(s))).and(weakFair(withdraw,Set(s)))
    .and(weakFair(joinAttempt,Set(s))).and(weakFair(exitThread,Set(s)))
    .and(weakFair(joinSuccess,Set(s))).and(weakFair(handoffAfterJoin,Set(s)))
    .and(weakFair(survivorGC,Set(s)))
    .and(weakFair(release,Set(s))).implies(eventually(terminal))
  run failedJoinDoesNotEstablishExit = initStagedErrorBeforeExit.then(startCallback)
    .then(requestGC).then(serviceGC).then(callbackReturn).then(handoff)
    .then(withdraw).then(joinAttempt).then(survivorGC)
    .expect(s.joinState == 1 and s.phase == 2 and s.live and s.roots == 1 and safe)
    .then(exitThread).expect(terminal and s.live and safe)
  run normalJoinConsumesAfterExit = initCurrentNormal.then(withdraw).then(joinAttempt)
    .then(startCallback).then(callbackReturn).then(exitThread).then(joinSuccess)
    .then(handoffAfterJoin)
    .then(release).then(survivorGC).expect(terminal and safe)
}

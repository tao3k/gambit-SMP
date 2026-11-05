module scheduler_wait_gc_contract {
  import scheduler_gc_root_cohort_composition as G from "./scheduler_gc_root_cohort_composition"

  // Compose the existing retry and root protocols at the SAME collective.
  // Roles and generations are finite abstractions, not CPU settings or clocks.
  // Atomic request publication, tracing and lock-metadata preservation are
  // assumptions to bind to C/SCM witnesses, not claims about the current TFIB.
  type Contract = { fault: str, phase: str, request: int, acknowledged: int,
    published: bool, version: int, checkedVersion: int, terminalPublished: bool,
    retained: bool, reclaimed: bool }
  var c: Contract
  // Controlled four-role cohort. kind "idle" leaves the existing machine unchanged.
  // Request and return flags here are protocol identities, not native GC epochs.
  // A raw condvar contender never enters. A participating contender enters while
  // the joiner's thread lock and end-condvar stay held. This is not original TFIB.
  // stressOpen stays true. A returned cohort does not admit the retained native
  // stress: signal 10, software exit 70 from thread-join!, or inactivity.
  // run-tests prints the bar before each file and stamps it after the previous
  // file. The retained 0.0s / 127.4s / 127.5s marks are cumulative boundaries:
  // tfib ran about 127.4s before signal 10, then interrupt2 failed about 0.1s
  // later. That is not a startup crash and not a state of this machine.
  // One (go 15 32) schedule died with printed heap overflow, exit 70.
  // A later schedule returned from (go 15 32). Neither is (go 15 5000).
  // Scheme thread-join! is not OS pthread join or processor retirement.
  type Join = { kind: str, threadHeld: bool, condvarHeld: bool,
    requesterIn: bool, joinerIn: bool, contenderIn: bool, gcDone: bool,
    published: bool, moved: bool, reloaded: bool, returned: bool, stressOpen: bool }
  var j: Join
  pure def initialContract(fault: str): Contract = {
      fault: fault, phase: "retry", request: 1, acknowledged: 0,
      published: false, version: 0, checkedVersion: 0, terminalPublished: false,
      retained: false, reclaimed: false
  }
  pure def joinIdle: Join = {
      kind: "idle", threadHeld: false, condvarHeld: false,
      requesterIn: false, joinerIn: false, contenderIn: false, gcDone: false,
      published: false, moved: false, reloaded: false, returned: false,
      stressOpen: true
  }
  pure def joinArmed(kind: str): Join = {
      kind: kind, threadHeld: true, condvarHeld: true,
      requesterIn: true, joinerIn: false, contenderIn: false, gcDone: false,
      published: false, moved: false, reloaded: false, returned: false,
      stressOpen: true
  }
  // Idle runs keep the old order. An active cohort may relocate only after
  // both the joiner and the condvar contender have entered, with both locks held.
  pure def cohortMayRelocate(state: Join): bool =
    state.kind == "idle" or
    (state.joinerIn and state.contenderIn and state.threadHeld and state.condvarHeld)
  action init = all {
    G::retry_s' = G::retry_initial(true), G::root_s' = G::root_initial(0),
    c' = initialContract("none"), j' = joinIdle,
  }
  action initMissingPublication = all {
    G::retry_s' = G::retry_initial(true), G::root_s' = G::root_initial(0),
    c' = initialContract("missing-publication"), j' = joinIdle,
  }
  action initStaleAcknowledgement = all {
    G::retry_s' = G::retry_initial(true), G::root_s' = G::root_initial(0),
    c' = initialContract("stale-acknowledgement"), j' = joinIdle,
  }
  action initStaleReload = all {
    G::retry_s' = G::retry_initial(true), G::root_s' = G::root_initial(2),
    c' = initialContract("stale-reload"), j' = joinIdle,
  }
  action initSkipRevalidation = all {
    G::retry_s' = G::retry_initial(true), G::root_s' = G::root_initial(0),
    c' = initialContract("skip-revalidation"), j' = joinIdle,
  }
  action initErrorRelease = all {
    G::retry_s' = G::retry_initial(true), G::root_s' = G::root_initial(0),
    c' = initialContract("error-release"), j' = joinIdle,
  }
  action initCondvarRaw = all {
    G::retry_s' = G::retry_initial(true), G::root_s' = G::root_initial(0),
    c' = initialContract("none"), j' = joinArmed("raw"),
  }
  action initCondvarParticipating = all {
    G::retry_s' = G::retry_initial(true), G::root_s' = G::root_initial(0),
    c' = initialContract("none"), j' = joinArmed("participating"),
  }

  action prepare = all {
    c.phase == "retry", G::retry_failedHeadTrylock, G::root_publish,
    c' = { ...c, phase: "published", published: c.fault != "missing-publication" },
    j' = { ...j, published: j.kind == "idle" or G::root_s.phase == 0 },
  }
  action participate = all {
    c.phase == "published", c.published or c.fault == "missing-publication",
    G::retry_joinAtUnlockedCheckpoint, G::root_join,
    c' = { ...c, phase: "collective",
      acknowledged: if (c.fault == "stale-acknowledgement") 0 else c.request },
    j' = j,
  }
  action joinJoiner = all {
    j.kind != "idle", not(j.joinerIn), j.threadHeld, j.condvarHeld, j.requesterIn,
    G::root_s.phase >= 1,
    G::retry_s' = G::retry_s, G::root_s' = G::root_s, c' = c,
    j' = { ...j, joinerIn: true },
  }
  action joinContender = all {
    j.kind == "participating", j.joinerIn, not(j.contenderIn), j.condvarHeld,
    G::retry_s' = G::retry_s, G::root_s' = G::root_s, c' = c,
    j' = { ...j, contenderIn: true },
  }
  // Root relocation is the collective's moving phase. An active cohort may
  // not move until the joiner and the condvar contender have both entered.
  // Idle runs keep the existing two-move order. Raw contenders never enter.
  action move = all {
    c.phase == "collective",
    cohortMayRelocate(j),
    G::root_move, G::retry_s' = G::retry_s, c' = c,
    j' = { ...j, moved: j.kind == "idle" or G::root_s.epoch == 1 },
  }
  action completeCollective = all {
    c.phase == "collective", G::root_s.epoch == 2,
    cohortMayRelocate(j),
    G::retry_finishGc, G::root_returnFromSync, c' = { ...c, phase: "reload" },
    j' = { ...j, gcDone: if (j.kind == "idle") j.gcDone else true },
  }
  action reload = all {
    c.phase == "reload", G::root_reload, G::retry_s' = G::retry_s,
    c' = { ...c, phase: "owner-publication" },
    j' = { ...j, reloaded: j.kind == "idle" or (j.gcDone and G::root_s.phase == 3) },
  }
  // Final state is published BEFORE the owner releases the low-level lock.
  // This does not collapse an end marker into the complete owned-deque drain.
  action publishTerminal = all {
    c.phase == "owner-publication", G::retry_s' = G::retry_s, G::root_s' = G::root_s,
    c' = { ...c, phase: "unlock", terminalPublished: true, version: 1 },
    j' = j,
  }
  action releaseOwner = all {
    c.phase == "unlock", c.terminalPublished,
    j.kind == "idle" or j.gcDone,
    G::retry_releaseQueued, G::root_ownerUnlock, c' = { ...c, phase: "acquire" },
    j' = { ...j, threadHeld: false },
  }
  action acquire = all {
    c.phase == "acquire", G::root_retry, G::retry_s' = G::retry_s,
    c' = { ...c, phase: "revalidate" },
    j' = j,
  }
  action revalidate = all {
    c.phase == "revalidate", G::retry_s' = G::retry_s, G::root_s' = G::root_s,
    c' = { ...c, phase: "return", checkedVersion:
      if (c.fault == "skip-revalidation") c.checkedVersion else c.version },
    j' = j,
  }
  action returnToCaller = all {
    c.phase == "return", j.kind == "idle" or j.gcDone,
    G::retry_resume, G::root_waiterUnlock,
    c' = { ...c, phase: "done" },
    j' = { ...j, returned: if (j.kind == "idle") j.returned else true },
  }
  // Error is an explicit non-returning disposition, not successful GC.
  // Native exception/continuation unwind and root-frame restoration remain
  // implementation obligations; this model only forbids premature reclaim.
  action failCollective = all {
    c.phase == "collective", G::retry_s' = G::retry_s, G::root_s' = G::root_s,
    c' = { ...c, phase: "error", retained: true,
      reclaimed: c.fault == "error-release" },
    j' = j,
  }
  val terminal = Set("done", "error").contains(c.phase)
  action finished = all { terminal, G::retry_s' = G::retry_s, G::root_s' = G::root_s, c' = c, j' = j }
  action step = any { prepare, participate, joinJoiner, joinContender, move, completeCollective, reload,
    publishTerminal, releaseOwner, acquire, revalidate, returnToCaller,
    failCollective, finished }
  val publicationSafe = G::retry_s.joined.implies(c.published and c.acknowledged == c.request)
  val revalidationSafe = G::retry_s.returned.implies(c.checkedVersion == c.version)
  val exitPublicationSafe = (not(G::root_s.ownerHeld)).implies(c.terminalPublished)
  val errorSafe = (c.phase == "error").implies(c.retained and not(c.reclaimed) and not(G::retry_s.returned))
  val joinReturned = (not(j.returned)) or j.gcDone or (j.kind == "idle")
  val joinLockRetained = (j.kind == "idle") or j.threadHeld or j.gcDone
  val joinWaiterExcluded = (not(j.contenderIn)) or j.condvarHeld
  val joinRawOpen = (j.kind != "raw") or ((not(j.contenderIn)) and (not(j.gcDone)) and (not(j.returned)))
  val joinPublished = (not(j.joinerIn)) or (G::root_s.phase >= 1)
  val joinNoEarlyRelocation = (j.kind == "idle") or (G::root_s.epoch == 0) or
    (j.joinerIn and j.contenderIn)
  // Same guards as move and completeCollective. The test interpreter rejects enabled().
  val relocationAuthorized =
    c.phase == "collective" and cohortMayRelocate(j) and
    G::root_s.phase == 2 and G::root_s.epoch < 2
  val collectiveReturnAuthorized =
    c.phase == "collective" and G::root_s.epoch == 2 and cohortMayRelocate(j) and
    G::retry_s.phase == "collective" and G::retry_s.joined and not(G::retry_s.gcDone) and
    G::root_s.phase == 2
  val joinRootClosed = (j.kind == "idle") or ((not(j.returned)) or (j.published and j.moved and j.reloaded))
  // No action clears this. Participation return is not the retained stress result.
  val stressRemainsOpen = j.stressOpen
  val safe = G::retry_safe and G::root_safe and publicationSafe and revalidationSafe and
    exitPublicationSafe and errorSafe and joinReturned and joinLockRetained and
    joinWaiterExcluded and joinRawOpen and joinPublished and joinNoEarlyRelocation and
    joinRootClosed and stressRemainsOpen
  // Progress assumes a scheduled returning collective OR an explicit error;
  // it does not prove OS fairness, bounded duration, or original TFIB progress.
  temporal completion = weakFair(step, Set((G::retry_s, G::root_s, c, j))).implies(eventually(terminal))
  action hold = all { G::retry_s' = G::retry_s, G::root_s' = G::root_s, c' = c, j' = j }
  run composedReturnTest = init.then(prepare).then(participate).then(move).then(move)
    .then(completeCollective).then(reload).then(publishTerminal)
    .then(releaseOwner).then(acquire).then(revalidate).then(returnToCaller)
    .then(all { assert(safe), assert(G::retry_s.returned), hold })
  run missingPublicationControlTest = initMissingPublication.then(prepare).then(participate)
    .then(all { assert(not(publicationSafe)), hold })
  run staleAcknowledgementControlTest = initStaleAcknowledgement.then(prepare).then(participate)
    .then(all { assert(not(publicationSafe)), hold })
  run staleReloadControlTest = initStaleReload.then(prepare).then(participate)
    .then(move).then(move).then(completeCollective).then(reload).then(publishTerminal)
    .then(releaseOwner).then(acquire).then(revalidate).then(returnToCaller)
    .then(all { assert(not(G::root_reloadSafe)), hold })
  run skippedRevalidationControlTest = initSkipRevalidation.then(prepare).then(participate)
    .then(move).then(move).then(completeCollective).then(reload).then(publishTerminal)
    .then(releaseOwner).then(acquire).then(revalidate).then(returnToCaller)
    .then(all { assert(not(revalidationSafe)), hold })
  run retainedErrorTest = init.then(prepare).then(participate).then(failCollective)
    .then(all { assert(safe), assert(not(G::retry_s.returned)), hold })
  run prematureErrorReleaseControlTest = initErrorRelease.then(prepare).then(participate)
    .then(failCollective).then(all { assert(not(errorSafe)), hold })
  run condvarParticipationReturnTest = initCondvarParticipating.then(prepare).then(joinJoiner)
    .then(participate).then(joinContender).then(move).then(move).then(completeCollective)
    .then(reload).then(publishTerminal).then(releaseOwner).then(acquire).then(revalidate)
    .then(returnToCaller).then(all {
      assert(safe), assert(j.gcDone), assert(not(j.threadHeld)), assert(j.condvarHeld),
      assert(j.published), assert(j.moved), assert(j.reloaded), assert(j.returned),
      assert(j.stressOpen),
      assert(G::root_reloadSafe), assert(G::retry_s.returned),
      assert(c.checkedVersion == c.version), hold })
  run rawCondvarDoesNotReturnTest = initCondvarRaw.then(prepare).then(joinJoiner)
    .then(participate).then(all {
      assert(not(j.contenderIn)), assert(not(j.gcDone)), assert(not(j.returned)),
      assert(not(j.moved)), assert(G::root_s.epoch == 0),
      assert(j.threadHeld), assert(j.condvarHeld), assert(j.stressOpen),
      assert(not(cohortMayRelocate(j))),
      assert(not(relocationAuthorized)), assert(not(collectiveReturnAuthorized)),
      hold })
}

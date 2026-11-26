// -*- mode: quint; -*-
// Adversarial protocol model challenging Gambit-SMP POSIX child-process reaping
// and device-group concurrency (lib/os_io.c + lib/os_io.h).
//
// Models the real SMP Gerbil stage1 deadlock discovered under P=6 concurrent
// open-process / process-status calls:
//   1. Cross-thread SIGCHLD premature reap: pthread_sigmask only blocks SIGCHLD
//      on the calling OS thread; waitpid(-1) in sigchld_signal_handler on a
//      sibling SMP thread steals & discards exit status before register().
//   2. Circular dgroup->list off-by-one head-skip: do { ... d = d->prev; }
//      while (d != head) skips `head` whenever |dgroup| >= 2.
//   3. Unlocked concurrent dgroup list mutation vs async signal traversal.
//   4. Release-before-exit orphan custody: avoids zombie leaks without waitpid(-1).
//
// Safe architecture:
//   - sigchld_signal_handler is 100% async-signal-safe (atomic pending flag only).
//   - All POSIX reaping uses PID-specific waitpid(dev->pid, &status, WNOHANG)
//     under process_mutex (never waitpid(-1)).
//   - Failed execvp reaps pid immediately via waitpid(pid, &status, 0).
//   - Early port release transfers unreaped pid to orphan queue under process_mutex.
//   - dgroup->list mutations hold dgroup->mutex.

module smp_process_reap_custody {

  type Pid = int
  type ThreadId = int
  // Lifecycle of a spawned child process across OS kernel + Gambit runtime
  // "FREE"          -> PID slot unused
  // "FORKED"        -> fork() succeeded; parent reading hdp_errno (NOT in dgroup yet)
  // "EXITED_UNREG"  -> child already exited while parent is still between fork() and register()
  // "REGISTERED"    -> ___device_process registered in dgroup, child still running
  // "EXITED_REG"    -> child exited while registered, zombie waiting for waitpid(pid)
  // "REAPED_DEV"    -> status captured cleanly in dev->got_status = 1
  // "ORPHAN_RUN"    -> Scheme port released while child still running; PID queued in orphan list
  // "ORPHAN_ZOMBIE" -> Orphaned child exited, waiting for orphan queue sweep
  // "REAPED_ORPHAN" -> Orphaned child reaped cleanly (no zombie)
  // "LOST_STATUS"   -> FATAL BUG: child was reaped by wildcard waitpid(-1) before dev saw it!
  type ProcState = str

  pure val PIDS: Set[Pid] = Set(1, 2, 3)

  var procState: Pid -> ProcState
  var exitCode: Pid -> int
  var capturedCode: Pid -> int
  var inDgroup: Set[Pid]
  var dgroupHead: Pid
  var orphanQueue: Set[Pid]
  var sigchldPending: bool
  var lostStatusViolation: bool
  var doubleReapViolation: bool
  var signalUnsafeViolation: bool
  var reapCount: Pid -> int

  action init = all {
    procState' = PIDS.mapBy(_ => "FREE"),
    exitCode' = PIDS.mapBy(_ => -1),
    capturedCode' = PIDS.mapBy(_ => -1),
    inDgroup' = Set(),
    dgroupHead' = 0,
    orphanQueue' = Set(),
    sigchldPending' = false,
    lostStatusViolation' = false,
    doubleReapViolation' = false,
    signalUnsafeViolation' = false,
    reapCount' = PIDS.mapBy(_ => 0),
  }

  // Step 1: Thread calls fork() -> enters FORKED window (not yet registered in dgroup)
  action forkChild(p: Pid): bool = all {
    p.in(PIDS),
    procState.get(p) == "FREE",
    procState' = procState.set(p, "FORKED"),
    exitCode' = exitCode,
    capturedCode' = capturedCode,
    inDgroup' = inDgroup,
    dgroupHead' = dgroupHead,
    orphanQueue' = orphanQueue,
    sigchldPending' = sigchldPending,
    lostStatusViolation' = lostStatusViolation,
    doubleReapViolation' = doubleReapViolation,
    signalUnsafeViolation' = signalUnsafeViolation,
    reapCount' = reapCount,
  }

  // Step 1b: Child fails execvp -> parent immediately calls waitpid(p, &st, 0)
  action execFailImmediateReap(p: Pid): bool = all {
    p.in(PIDS),
    procState.get(p) == "FORKED",
    procState' = procState.set(p, "REAPED_ORPHAN"),
    exitCode' = exitCode.set(p, 1),
    capturedCode' = capturedCode,
    inDgroup' = inDgroup,
    dgroupHead' = dgroupHead,
    orphanQueue' = orphanQueue,
    sigchldPending' = sigchldPending,
    lostStatusViolation' = lostStatusViolation,
    doubleReapViolation' = (doubleReapViolation or (reapCount.get(p) > 0)),
    signalUnsafeViolation' = signalUnsafeViolation,
    reapCount' = reapCount.set(p, reapCount.get(p) + 1),
  }

  // Step 2: Child exits while parent is STILL in fork()..register() window!
  // Kernel queues zombie + raises SIGCHLD (delivered to ANY SMP thread).
  action childExitsBeforeRegister(p: Pid, code: int): bool = all {
    p.in(PIDS),
    code >= 0,
    procState.get(p) == "FORKED",
    procState' = procState.set(p, "EXITED_UNREG"),
    exitCode' = exitCode.set(p, code),
    capturedCode' = capturedCode,
    inDgroup' = inDgroup,
    dgroupHead' = dgroupHead,
    orphanQueue' = orphanQueue,
    sigchldPending' = true,
    lostStatusViolation' = lostStatusViolation,
    doubleReapViolation' = doubleReapViolation,
    signalUnsafeViolation' = signalUnsafeViolation,
    reapCount' = reapCount,
  }

  // Step 3: Safe SIGCHLD handler on sibling SMP thread: ONLY sets atomic flag!
  // Never touches dgroup->list, never calls waitpid(-1).
  action safeSigchldHandler = all {
    sigchldPending,
    procState' = procState,
    exitCode' = exitCode,
    capturedCode' = capturedCode,
    inDgroup' = inDgroup,
    dgroupHead' = dgroupHead,
    orphanQueue' = orphanQueue,
    sigchldPending' = true,
    lostStatusViolation' = lostStatusViolation,
    doubleReapViolation' = doubleReapViolation,
    signalUnsafeViolation' = signalUnsafeViolation,
    reapCount' = reapCount,
  }

  // Step 4: Parent finishes reading hdp_errno and registers dev in dgroup (under dgroup->mutex)
  action registerDevice(p: Pid): bool = all {
    p.in(PIDS),
    procState.get(p) == "FORKED" or procState.get(p) == "EXITED_UNREG",
    procState' = procState.set(
      p,
      if (procState.get(p) == "FORKED") "REGISTERED" else "EXITED_REG"
    ),
    exitCode' = exitCode,
    capturedCode' = capturedCode,
    inDgroup' = inDgroup.union(Set(p)),
    dgroupHead' = if (dgroupHead == 0) p else dgroupHead,
    orphanQueue' = orphanQueue,
    sigchldPending' = sigchldPending,
    lostStatusViolation' = lostStatusViolation,
    doubleReapViolation' = doubleReapViolation,
    signalUnsafeViolation' = signalUnsafeViolation,
    reapCount' = reapCount,
  }

  // Step 5: Registered child exits normally -> kernel holds zombie until waitpid(p)
  action childExitsRegistered(p: Pid, code: int): bool = all {
    p.in(PIDS),
    code >= 0,
    procState.get(p) == "REGISTERED",
    procState' = procState.set(p, "EXITED_REG"),
    exitCode' = exitCode.set(p, code),
    capturedCode' = capturedCode,
    inDgroup' = inDgroup,
    dgroupHead' = dgroupHead,
    orphanQueue' = orphanQueue,
    sigchldPending' = true,
    lostStatusViolation' = lostStatusViolation,
    doubleReapViolation' = doubleReapViolation,
    signalUnsafeViolation' = signalUnsafeViolation,
    reapCount' = reapCount,
  }

  // Step 6: Safe PID-specific poll: ___device_process_status_poll(dev) under process_mutex
  // Calls waitpid(dev->pid, &status, WNOHANG) ONLY for dev->pid!
  action pollSpecificPid(p: Pid): bool = all {
    p.in(PIDS),
    p.in(inDgroup),
    procState.get(p) == "EXITED_REG",
    procState' = procState.set(p, "REAPED_DEV"),
    exitCode' = exitCode,
    capturedCode' = capturedCode.set(p, exitCode.get(p)),
    inDgroup' = inDgroup,
    dgroupHead' = dgroupHead,
    orphanQueue' = orphanQueue,
    sigchldPending' = sigchldPending,
    lostStatusViolation' = lostStatusViolation,
    doubleReapViolation' = (doubleReapViolation or (reapCount.get(p) > 0)),
    signalUnsafeViolation' = signalUnsafeViolation,
    reapCount' = reapCount.set(p, reapCount.get(p) + 1),
  }

  // Step 7: Early GC/close release before child exits -> transfers PID to orphanQueue
  action releaseDeviceEarly(p: Pid): bool = all {
    p.in(PIDS),
    p.in(inDgroup),
    procState.get(p) == "REGISTERED" or procState.get(p) == "EXITED_REG",
    procState' = procState.set(
      p,
      if (procState.get(p) == "REGISTERED") "ORPHAN_RUN" else "ORPHAN_ZOMBIE"
    ),
    exitCode' = exitCode,
    capturedCode' = capturedCode,
    inDgroup' = inDgroup.exclude(Set(p)),
    dgroupHead' = if (dgroupHead == p) 0 else dgroupHead,
    orphanQueue' = orphanQueue.union(Set(p)),
    sigchldPending' = sigchldPending,
    lostStatusViolation' = lostStatusViolation,
    doubleReapViolation' = doubleReapViolation,
    signalUnsafeViolation' = signalUnsafeViolation,
    reapCount' = reapCount,
  }

  action orphanChildExits(p: Pid, code: int): bool = all {
    p.in(PIDS),
    p.in(orphanQueue),
    code >= 0,
    procState.get(p) == "ORPHAN_RUN",
    procState' = procState.set(p, "ORPHAN_ZOMBIE"),
    exitCode' = exitCode.set(p, code),
    capturedCode' = capturedCode,
    inDgroup' = inDgroup,
    dgroupHead' = dgroupHead,
    orphanQueue' = orphanQueue,
    sigchldPending' = true,
    lostStatusViolation' = lostStatusViolation,
    doubleReapViolation' = doubleReapViolation,
    signalUnsafeViolation' = signalUnsafeViolation,
    reapCount' = reapCount,
  }

  // Step 8: Drain orphanQueue outside signal handler under process_mutex via waitpid(orphan, WNOHANG)
  action reapOrphanSpecific(p: Pid): bool = all {
    p.in(PIDS),
    p.in(orphanQueue),
    procState.get(p) == "ORPHAN_ZOMBIE",
    procState' = procState.set(p, "REAPED_ORPHAN"),
    exitCode' = exitCode,
    capturedCode' = capturedCode,
    inDgroup' = inDgroup,
    dgroupHead' = dgroupHead,
    orphanQueue' = orphanQueue.exclude(Set(p)),
    sigchldPending' = false,
    lostStatusViolation' = lostStatusViolation,
    doubleReapViolation' = (doubleReapViolation or (reapCount.get(p) > 0)),
    signalUnsafeViolation' = signalUnsafeViolation,
    reapCount' = reapCount.set(p, reapCount.get(p) + 1),
  }

  // =========================================================================
  // ADVERSARIAL MUTATION-KILLERS (modeling the exact legacy os_io.c bugs!)
  // =========================================================================

  // Mutant 1: Legacy sigchld_signal_handler calls waitpid(-1) on sibling SMP thread
  // while parent is in fork()..register(), stealing EXITED_UNREG status forever!
  action faultWildcardSigchldReap(p: Pid): bool = all {
    p.in(PIDS),
    procState.get(p) == "EXITED_UNREG",
    procState' = procState.set(p, "LOST_STATUS"),
    exitCode' = exitCode,
    capturedCode' = capturedCode,
    inDgroup' = inDgroup,
    dgroupHead' = dgroupHead,
    orphanQueue' = orphanQueue,
    sigchldPending' = false,
    lostStatusViolation' = true,
    doubleReapViolation' = doubleReapViolation,
    signalUnsafeViolation' = true,
    reapCount' = reapCount.set(p, reapCount.get(p) + 1),
  }

  // Mutant 2: Legacy os_io.c:8548-8563 `d = head->prev; do { ... d = d->prev; } while (d != head)`
  // skips `head` whenever |inDgroup| >= 2, losing status of dgroupHead!
  action faultHeadSkipTraversal(p: Pid): bool = all {
    p.in(PIDS),
    p == dgroupHead,
    inDgroup.size() >= 2,
    procState.get(p) == "EXITED_REG",
    procState' = procState.set(p, "LOST_STATUS"),
    exitCode' = exitCode,
    capturedCode' = capturedCode,
    inDgroup' = inDgroup,
    dgroupHead' = dgroupHead,
    orphanQueue' = orphanQueue,
    sigchldPending' = false,
    lostStatusViolation' = true,
    doubleReapViolation' = doubleReapViolation,
    signalUnsafeViolation' = true,
    reapCount' = reapCount.set(p, reapCount.get(p) + 1),
  }

  action step = any {
    nondet p = PIDS.oneOf()
    any {
      forkChild(p),
      execFailImmediateReap(p),
      childExitsBeforeRegister(p, 0),
      childExitsBeforeRegister(p, 70),
      safeSigchldHandler,
      registerDevice(p),
      childExitsRegistered(p, 0),
      childExitsRegistered(p, 1),
      pollSpecificPid(p),
      releaseDeviceEarly(p),
      orphanChildExits(p, 0),
      reapOrphanSpecific(p),
    }
  }

  // Safety invariants
  val noLostStatusInv: bool =
    not(lostStatusViolation) and PIDS.forall(p => procState.get(p) != "LOST_STATUS")

  val noDoubleReapInv: bool =
    not(doubleReapViolation) and PIDS.forall(p => reapCount.get(p) <= 1)

  val exactCapturedStatusInv: bool =
    PIDS.forall(p =>
      procState.get(p) == "REAPED_DEV" implies capturedCode.get(p) == exitCode.get(p)
    )

  val signalSafeInv: bool = not(signalUnsafeViolation)

  val safe: bool =
    noLostStatusInv and noDoubleReapInv and exactCapturedStatusInv and signalSafeInv

  // =========================================================================
  // Executable Verification Runs (Safe Protocol + Mutation Killers)
  // =========================================================================

  // Safe run 1: Fast child exits BEFORE registerDevice() while sibling handles SIGCHLD;
  // PID-specific poll recovers exact exit status with zero lost status!
  run fastExitBeforeRegisterSafeTest = {
    init
      .then(forkChild(1))
      .then(forkChild(2))
      .then(childExitsBeforeRegister(1, 0))
      .then(safeSigchldHandler)
      .then(registerDevice(1))
      .then(registerDevice(2))
      .then(pollSpecificPid(1))
      .then(childExitsRegistered(2, 42))
      .then(pollSpecificPid(2))
      .expect(safe and capturedCode.get(1) == 0 and capturedCode.get(2) == 42)
  }

  // Safe run 2: Early port GC release transfers active PID to orphanQueue and reaps cleanly
  run earlyReleaseOrphanReapSafeTest = {
    init
      .then(forkChild(1))
      .then(registerDevice(1))
      .then(releaseDeviceEarly(1))
      .then(orphanChildExits(1, 0))
      .then(reapOrphanSpecific(1))
      .expect(safe and orphanQueue == Set() and reapCount.get(1) == 1)
  }

  // Safe run 3: Failed execvp reaps immediately without zombie or double-reap
  run execFailImmediateReapSafeTest = {
    init
      .then(forkChild(3))
      .then(execFailImmediateReap(3))
      .expect(safe and reapCount.get(3) == 1)
  }

  // Mutation-killer 1: Legacy wildcard waitpid(-1) in SIGCHLD steals fast-exiting child
  // and violates noLostStatusInv + signalSafeInv!
  run wildcardSigchldMutantKilledTest = {
    init
      .then(forkChild(1))
      .then(childExitsBeforeRegister(1, 0))
      .then(faultWildcardSigchldReap(1))
      .expect(not(noLostStatusInv) and not(signalSafeInv))
  }

  // Mutation-killer 2: Legacy circular list off-by-one head-skip loses dgroupHead status
  // whenever |inDgroup| >= 2!
  run headSkipMutantKilledTest = {
    init
      .then(forkChild(1))
      .then(registerDevice(1))
      .then(forkChild(2))
      .then(registerDevice(2))
      .then(childExitsRegistered(1, 0))
      .then(faultHeadSkipTraversal(1))
      .expect(not(noLostStatusInv) and dgroupHead == 1)
  }
}

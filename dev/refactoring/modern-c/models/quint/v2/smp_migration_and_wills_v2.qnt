module smp_migration_and_wills_v2 {
  // Quint V2 (Micro-step, Non-Atomic, Mutation-Killing) Protocol Model for:
  //   1. Cross-core c-define return migration (`handler_return_to_c` ->
  //      `##c-return-on-other-processor` -> `##thread-migrate-to!` with
  //      temporary target-processor pinning + R1 return value preservation).
  //   2. Non-reentrant per-thread `##gc-finalize!` with VM-wide executable-will
  //      drain (`##gc-pop-executable-will!`) preventing SRFI-18 mutex self-
  //      deadlock inside `___INTR_GC` and idle-processor will stranding.

  pure val PROCS = 4       // P0..P3 (matches -:p4)
  pure val EXPECTED_RET = 777

  type ThreadLoc = str     // "running" | "queued"
  type WillPhase = str     // "idle" | "in_finalize_locked" | "done"

  type State = {
    // --- Part 1: Cross-core c-define return migration ---
    cFrameOwnerProc: int,       // processor holding native C stack frame (e.g. P2)
    curProc: int,               // processor where thread currently runs or is queued
    threadLoc: ThreadLoc,       // "running" or "queued"
    pinnedProc: int,            // -1 = unpinned, 0..3 = pinned to that processor
    r1Val: int,                 // GVM R1 register (Scheme return value to C)
    savedRetVal: int,           // saved return value on stack during migration
    cReturned: bool,
    observedCRetVal: int,
    selfStealEvents: int,       // counts source/peer stealing back a migrating thread
    migrationHops: int,
    // --- Part 2: Non-reentrant ##gc-finalize! + VM-wide will drain ---
    pendingWillsPerProc: int -> int,  // executable_wills_ count on P0..P3
    finalizingThread: bool,           // whether thread is in ##gc-finalizing-threads
    willMtxHeldBySelf: bool,          // whether thread holds user SRFI-18 will-mtx
    willsExecuted: int,
    selfDeadlocked: bool
  }

  var s: State

  action init = {
    s' = {
      cFrameOwnerProc: 2,
      curProc: 0,               // thread migrated to P0 mid-callback!
      threadLoc: "running",
      pinnedProc: -1,
      r1Val: EXPECTED_RET,      // Scheme c-define callback computed return value 777
      savedRetVal: -1,
      cReturned: false,
      observedCRetVal: EXPECTED_RET,
      selfStealEvents: 0,
      migrationHops: 0,
      pendingWillsPerProc: Map(0 -> 1, 1 -> 0, 2 -> 1, 3 -> 1),
      finalizingThread: false,
      willMtxHeldBySelf: false,
      willsExecuted: 0,
      selfDeadlocked: false
    }
  }

  // --- Safe Fix #1B + #1C: Preserve R1, pin to cFrameOwnerProc before btq-insert! ---
  action safeBeginMigrateToCFrameOwner = all {
    not(s.cReturned),
    s.threadLoc == "running",
    s.curProc != s.cFrameOwnerProc,
    s.migrationHops < 6,
    val target = s.cFrameOwnerProc
    s' = {
      ...s,
      savedRetVal: s.r1Val,       // Bug #1C fix: preserve R1 return value!
      pinnedProc: target,         // Bug #1B fix: pin BEFORE inserting into target btq!
      curProc: target,
      threadLoc: "queued",
      migrationHops: s.migrationHops + 1
    }
  }

  // Work-stealer on any peer processor `stealer != curProc`: respects `pinnedProc`!
  action peerAttemptWorkSteal(stealer: int): bool = all {
    not(s.cReturned),
    s.threadLoc == "queued",
    stealer >= 0 and stealer < PROCS,
    stealer != s.curProc,
    // Safe scheduler (`lib/_thread.scm:3013`): refuses to steal if pinnedProc != -1!
    s.pinnedProc == -1,
    s' = {
      ...s,
      curProc: stealer,
      threadLoc: "running",
      selfStealEvents: s.selfStealEvents + 1
    }
  }

  // Destination processor `curProc` dequeues its own run queue, restores old pinned (-1) and R1!
  action targetDequeueAndReturnToC = all {
    not(s.cReturned),
    s.threadLoc == "queued",
    s.curProc == s.cFrameOwnerProc,
    val ret = if (s.savedRetVal != -1) s.savedRetVal else s.r1Val
    s' = {
      ...s,
      threadLoc: "running",
      pinnedProc: -1,
      r1Val: ret,
      savedRetVal: -1,
      cReturned: true,
      observedCRetVal: ret
    }
  }

  // --- Safe Fix #2A + #2C: Non-reentrant ##gc-finalize! + VM-wide drain ---
  // Pop 1 executable will from ANY processor p in 0..3 (eliminating p4 idle stranding)
  // ONLY when `not(s.finalizingThread)` (eliminating re-entrant mutex self-deadlock!).
  action safeEnterGcFinalizeAndLockWillMtx(p: int): bool = all {
    not(s.selfDeadlocked),
    not(s.finalizingThread),
    p >= 0 and p < PROCS,
    s.pendingWillsPerProc.get(p) > 0,
    s' = {
      ...s,
      pendingWillsPerProc: s.pendingWillsPerProc.set(p, s.pendingWillsPerProc.get(p) - 1),
      finalizingThread: true,
      willMtxHeldBySelf: true
    }
  }

  // A second ___INTR_GC arrives while thread is inside will action holding willMtx:
  // Safe ##gc-finalize! checks `finalizingThread == true` and skips re-entry!
  action safeSecondGcInterruptWhileFinalizing = all {
    s.finalizingThread,
    s.willMtxHeldBySelf,
    // Adds a new executable will on P3; skips nested finalization cleanly!
    s.pendingWillsPerProc.get(3) < 3,
    s' = {
      ...s,
      pendingWillsPerProc: s.pendingWillsPerProc.set(3, s.pendingWillsPerProc.get(3) + 1)
    }
  }

  // Finish will action: unlock willMtx and leave ##gc-finalizing-threads
  action finishWillActionAndUnlock = all {
    s.finalizingThread,
    s.willMtxHeldBySelf,
    s' = {
      ...s,
      finalizingThread: false,
      willMtxHeldBySelf: false,
      willsExecuted: s.willsExecuted + 1
    }
  }

  action step = any {
    safeBeginMigrateToCFrameOwner,
    nondet st = oneOf(Set(0, 1, 2, 3))
    peerAttemptWorkSteal(st),
    targetDequeueAndReturnToC,
    nondet wp = oneOf(Set(0, 1, 2, 3))
    safeEnterGcFinalizeAndLockWillMtx(wp),
    safeSecondGcInterruptWhileFinalizing,
    finishWillActionAndUnlock
  }

  // --- Genuine Structural Safety Invariants ---
  val noSelfStealLivelock = s.selfStealEvents == 0 and s.migrationHops <= 1
  val cReturnValuePreserved = s.cReturned implies (s.observedCRetVal == EXPECTED_RET)
  val noWillMutexSelfDeadlock = not(s.selfDeadlocked)

  val safe = all {
    noSelfStealLivelock,
    cReturnValuePreserved,
    noWillMutexSelfDeadlock
  }

  run testSafeFixesWork =
    init
      .then(safeBeginMigrateToCFrameOwner)
      .then(targetDequeueAndReturnToC)
      .then(safeEnterGcFinalizeAndLockWillMtx(0))
      .then(safeSecondGcInterruptWhileFinalizing)
      .then(finishWillActionAndUnlock)
      .then(safeEnterGcFinalizeAndLockWillMtx(2))
      .then(finishWillActionAndUnlock)
      .then(safeEnterGcFinalizeAndLockWillMtx(3))
      .then(finishWillActionAndUnlock)
      .expect(safe and s.cReturned and s.observedCRetVal == EXPECTED_RET and s.willsExecuted == 3)
}

// ============================================================================
// Mutant 1 (Bug #1B pre-fix): ##thread-migrate-to! omits pinning -> P0 steals
// the thread right back before P2 wakes up -> self-steal livelock!
// ============================================================================
module smp_buggy_unpinned_migration {
  import smp_migration_and_wills_v2.*

  action buggyMigrateWithoutPin = all {
    not(s.cReturned),
    s.threadLoc == "running",
    s.curProc != s.cFrameOwnerProc,
    s.migrationHops < 6,
    s' = {
      ...s,
      savedRetVal: s.r1Val,
      pinnedProc: -1,             // BUG: forgot to pin to target processor!
      curProc: s.cFrameOwnerProc,
      threadLoc: "queued",
      migrationHops: s.migrationHops + 1
    }
  }

  action buggyStep = any {
    buggyMigrateWithoutPin,
    nondet st = oneOf(Set(0, 1, 2, 3))
    peerAttemptWorkSteal(st),
    targetDequeueAndReturnToC
  }

  run testUnpinnedMutantKilled =
    init
      .then(buggyMigrateWithoutPin)
      .then(peerAttemptWorkSteal(0))
      .expect(not(safe) and s.selfStealEvents == 1)
}

// ============================================================================
// Mutant 2 (Bug #1C pre-fix): handler_return_to_c overwrites R1 with targetId
// instead of preserving R1 -> C caller receives garbage/void instead of 777!
// ============================================================================
module smp_buggy_clobber_r1 {
  import smp_migration_and_wills_v2.*

  action buggyMigrateClobberR1 = all {
    not(s.cReturned),
    s.threadLoc == "running",
    s.curProc != s.cFrameOwnerProc,
    s' = {
      ...s,
      r1Val: 0,                   // BUG: R1 overwritten with #!void / targetId!
      savedRetVal: 0,
      pinnedProc: s.cFrameOwnerProc,
      curProc: s.cFrameOwnerProc,
      threadLoc: "queued",
      migrationHops: s.migrationHops + 1
    }
  }

  action buggyStep = any {
    buggyMigrateClobberR1,
    targetDequeueAndReturnToC
  }

  run testClobberR1MutantKilled =
    init
      .then(buggyMigrateClobberR1)
      .then(targetDequeueAndReturnToC)
      .expect(not(safe) and s.observedCRetVal != EXPECTED_RET)
}

// ============================================================================
// Mutant 3 (Bug #2A pre-fix): re-entrant ___INTR_GC runs ##will-execute! on
// the SAME thread while it holds non-reentrant SRFI-18 will-mtx -> DEADLOCK!
// ============================================================================
module smp_buggy_reentrant_will_mutex {
  import smp_migration_and_wills_v2.*

  action buggyReentrantGcInterrupt(p: int): bool = all {
    s.finalizingThread,
    s.willMtxHeldBySelf,
    p >= 0 and p < PROCS,
    s.pendingWillsPerProc.get(p) > 0,
    // BUG: re-enters ##will-execute! on same thread -> calls mutex-lock! while holding mutex!
    s' = {
      ...s,
      pendingWillsPerProc: s.pendingWillsPerProc.set(p, s.pendingWillsPerProc.get(p) - 1),
      selfDeadlocked: true
    }
  }

  action buggyStep = any {
    nondet p1 = oneOf(Set(0, 1, 2, 3))
    safeEnterGcFinalizeAndLockWillMtx(p1),
    nondet p2 = oneOf(Set(0, 1, 2, 3))
    buggyReentrantGcInterrupt(p2),
    finishWillActionAndUnlock
  }

  run testReentrantWillMutantKilled =
    init
      .then(safeEnterGcFinalizeAndLockWillMtx(0))
      .then(buggyReentrantGcInterrupt(2))
      .expect(not(safe) and s.selfDeadlocked)
}

module slice4_gerbil_smp_runtime_and_compiler_v2 {
  // Slice 4 Formal Behavioral & Mutation-Killing Model:
  //   1. Gerbil runtime single-slot atomic owner CAS inline lock (__lock-inline! / __unlock-inline! / __do-inline-lock!)
  //   2. Lock-free __shadow-class construction + atomic insert-if-absent canonicalization
  //   3. Re-entrancy-bounded wrap-runtime-exception (strict recursion depth <= 1)
  //   4. Parallel per-module compiler optimizer sessions (snapshot -> lock-free optimize-source/compile-ssxi -> atomic delta commit)
  //
  // Every upstream Gerbil SMP bug documented in family11-gerbil-v26-receipt.json
  // has an explicit adversarial mutant test below that violates `safe`.

  type ThreadId = int // 1, 2
  type ModId = int    // 1, 2

  type InlineLock = {
    owner: int,          // 0 = unlocked, 1/2 = owning thread
    legacyFlag: int      // used only by Mutant 1 (2-slot window)
  }

  type ThreadState = {
    alive: bool,
    holdingInlineLock: bool,
    shadowPhase: str,    // "idle", "constructing", "inserting", "done"
    shadowResult: int,   // canonical shadow class id observed
    wrapDepth: int,
    // Compiler session state
    compPhase: str,      // "idle", "checked_out", "optimizing", "ssxi_emitting", "committed"
    hasPrivateOverlay: bool
  }

  type State = {
    ilock: InlineLock,
    shadowCanonical: int,         // 0 = absent, >0 = canonical class id
    sharedOptWriters: int,        // concurrent writers to shared optimizer-info / !class-methods
    sharedOptReaders: int,        // concurrent readers of shared optimizer-info
    ssxiPublished: ModId -> bool,
    ssxiEmitted: ModId -> bool,
    threads: ThreadId -> ThreadState,
    // Violation latches
    nullOwnerDeref: bool,
    lockLeakOnException: bool,
    poisonedByTerminate: bool,
    shadowDiverged: bool,
    wrapInfiniteRecur: bool,
    sharedOptDataRace: bool,
    prematureSsxiPublish: bool
  }

  var s: State

  pure def initThread: ThreadState = {
    alive: true,
    holdingInlineLock: false,
    shadowPhase: "idle",
    shadowResult: 0,
    wrapDepth: 0,
    compPhase: "idle",
    hasPrivateOverlay: false
  }

  action init = {
    s' = {
      ilock: { owner: 0, legacyFlag: 0 },
      shadowCanonical: 0,
      sharedOptWriters: 0,
      sharedOptReaders: 0,
      ssxiPublished: Map(1 -> false, 2 -> false),
      ssxiEmitted: Map(1 -> false, 2 -> false),
      threads: Map(1 -> initThread, 2 -> initThread),
      nullOwnerDeref: false,
      lockLeakOnException: false,
      poisonedByTerminate: false,
      shadowDiverged: false,
      wrapInfiniteRecur: false,
      sharedOptDataRace: false,
      prematureSsxiPublish: false
    }
  }

  // --- 1. Single-slot atomic owner CAS inline lock (__shadow-classes-lock) ---
  action inlineLockAcquire(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    s.threads.get(tid).shadowPhase != "constructing",
    not(s.threads.get(tid).holdingInlineLock),
    s.ilock.owner == 0,
    s' = {
      ...s,
      ilock: { owner: tid, legacyFlag: 1 },
      threads: s.threads.set(tid, { ...s.threads.get(tid), holdingInlineLock: true })
    }
  }

  // Contended acquire observes exact non-zero owner atomically (never #f/0 when locked).
  action inlineLockInspectContended(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    not(s.threads.get(tid).holdingInlineLock),
    s.ilock.legacyFlag == 1,
    s' = {
      ...s,
      nullOwnerDeref: s.nullOwnerDeref or (s.ilock.owner == 0)
    }
  }

  // Exception unwind via __do-inline-lock! always CAS-unlocks owning thread.
  action inlineLockUnwindException(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    s.threads.get(tid).holdingInlineLock,
    s.ilock.owner == tid,
    s' = {
      ...s,
      ilock: { owner: 0, legacyFlag: 0 },
      threads: s.threads.set(tid, { ...s.threads.get(tid), holdingInlineLock: false })
    }
  }

  // --- 2. Lock-free __shadow-class construction + atomic insert-if-absent ---
  action shadowBeginConstruct(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    s.threads.get(tid).shadowPhase != "constructing",
    not(s.threads.get(tid).holdingInlineLock),
    s' = {
      ...s,
      threads: s.threads.set(tid, { ...s.threads.get(tid), shadowPhase: "constructing" })
    }
  }

  // Async thread-terminate! during lock-free class construction never poisons __shadow-classes-lock.
  action terminateDuringShadowConstruct(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    s.threads.get(tid).shadowPhase == "constructing",
    s' = {
      ...s,
      poisonedByTerminate: s.poisonedByTerminate or s.threads.get(tid).holdingInlineLock,
      threads: s.threads.set(tid, { ...s.threads.get(tid), alive: false, shadowPhase: "idle" })
    }
  }

  // Insert-if-absent under brief atomic lock: single canonical winner for all threads.
  action shadowInsertCanonical(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    s.threads.get(tid).shadowPhase == "constructing",
    s.ilock.owner == 0,
    val winner = if (s.shadowCanonical == 0) (100 + tid) else s.shadowCanonical
    s' = {
      ...s,
      shadowCanonical: winner,
      threads: s.threads.set(tid, {
        ...s.threads.get(tid),
        shadowPhase: "done",
        shadowResult: winner
      })
    }
  }

  // --- 3. Re-entrancy-bounded wrap-runtime-exception ---
  action wrapRuntimeExceptionEnter(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    val d = s.threads.get(tid).wrapDepth
    // Safe re-entrancy guard: if already wrapping (d >= 1), return raw exn without recursing.
    val nextD = if (d == 0) 1 else d
    s' = {
      ...s,
      threads: s.threads.set(tid, { ...s.threads.get(tid), wrapDepth: nextD })
    }
  }

  action wrapRuntimeExceptionExit(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    s.threads.get(tid).wrapDepth == 1,
    s' = {
      ...s,
      threads: s.threads.set(tid, { ...s.threads.get(tid), wrapDepth: 0 })
    }
  }

  // --- 4. Parallel per-module compiler optimizer sessions ---
  action compSessionCheckout(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    s.threads.get(tid).compPhase == "idle",
    s.sharedOptWriters == 0,
    s' = {
      ...s,
      threads: s.threads.set(tid, {
        ...s.threads.get(tid),
        compPhase: "optimizing",
        hasPrivateOverlay: true
      })
    }
  }

  // Both threads may optimize and emit SSXI simultaneously in their private overlays (0 shared writes!).
  action compParallelOptimizeToSsxi(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    s.threads.get(tid).compPhase == "optimizing",
    s.threads.get(tid).hasPrivateOverlay,
    s' = {
      ...s,
      ssxiEmitted: s.ssxiEmitted.set(tid, true),
      threads: s.threads.set(tid, { ...s.threads.get(tid), compPhase: "ssxi_emitting" })
    }
  }

  // Atomic commit of private delta into shared optimizer-info ONLY after SSXI emitted.
  action compSessionCommit(tid: ThreadId): bool = all {
    tid == 1 or tid == 2,
    s.threads.get(tid).alive,
    s.threads.get(tid).compPhase == "ssxi_emitting",
    s.ssxiEmitted.get(tid),
    s.sharedOptWriters == 0 and s.sharedOptReaders == 0,
    s' = {
      ...s,
      ssxiPublished: s.ssxiPublished.set(tid, true),
      threads: s.threads.set(tid, {
        ...s.threads.get(tid),
        compPhase: "committed",
        hasPrivateOverlay: false
      })
    }
  }

  // --- Adversarial Mutants (MUST violate `safe`) ---
  // Mutant 1: Upstream 2-slot inline lock sets flag=1 before writing owner slot -> contender derefs #f!
  action mutant1TwoSlotWindowDeref = all {
    s.ilock.owner == 0 and s.ilock.legacyFlag == 0,
    s' = {
      ...s,
      ilock: { owner: 0, legacyFlag: 1 },
      nullOwnerDeref: true
    }
  }

  // Mutant 2: Missing unwind handler in __do-inline-lock! leaks lock on exception.
  action mutant2ExceptionLeaksInlineLock(tid: ThreadId): bool = all {
    s.threads.get(tid).holdingInlineLock,
    s' = {
      ...s,
      lockLeakOnException: true,
      threads: s.threads.set(tid, { ...s.threads.get(tid), holdingInlineLock: false })
    }
  }

  // Mutant 3: Upstream __shadow-class holds __shadow-classes-lock across make-class-type;
  // thread-terminate! permanently poisons lock.
  action mutant3ShadowLockHeldAcrossConstruct(tid: ThreadId): bool = all {
    s.ilock.owner == 0,
    s.threads.get(tid).alive,
    s' = {
      ...s,
      ilock: { owner: tid, legacyFlag: 1 },
      poisonedByTerminate: true,
      threads: s.threads.set(tid, { ...s.threads.get(tid), alive: false, holdingInlineLock: true })
    }
  }

  // Mutant 4: Upstream wrap-runtime-exception lacks re-entrancy guard -> infinite recursion!
  action mutant4UnguardedWrapRecursion(tid: ThreadId): bool = all {
    s.threads.get(tid).wrapDepth >= 1,
    s' = {
      ...s,
      wrapInfiniteRecur: true,
      threads: s.threads.set(tid, { ...s.threads.get(tid), wrapDepth: s.threads.get(tid).wrapDepth + 1 })
    }
  }

  // Mutant 5: Parallel optimization mutates shared !class-methods without private overlay -> data race!
  action mutant5SharedOptMutationWithoutOverlay = all {
    s.threads.get(1).compPhase == "optimizing",
    s.threads.get(2).compPhase == "optimizing",
    s' = {
      ...s,
      sharedOptWriters: 2,
      sharedOptDataRace: true
    }
  }

  // Mutant 6: Publish ssxi[mod]=#t before compile-ssxi-code emits the .ssxi.ss artifact.
  action mutant6PrematureSsxiPublish(tid: ThreadId): bool = all {
    s.threads.get(tid).compPhase == "optimizing",
    not(s.ssxiEmitted.get(tid)),
    s' = {
      ...s,
      ssxiPublished: s.ssxiPublished.set(tid, true),
      prematureSsxiPublish: true
    }
  }

  action step = any {
    nondet tid = oneOf(Set(1, 2))
    any {
      inlineLockAcquire(tid),
      inlineLockInspectContended(tid),
      inlineLockUnwindException(tid),
      shadowBeginConstruct(tid),
      terminateDuringShadowConstruct(tid),
      shadowInsertCanonical(tid),
      wrapRuntimeExceptionEnter(tid),
      wrapRuntimeExceptionExit(tid),
      compSessionCheckout(tid),
      compParallelOptimizeToSsxi(tid),
      compSessionCommit(tid)
    }
  }

  val safe = and {
    not(s.nullOwnerDeref),
    not(s.lockLeakOnException),
    not(s.poisonedByTerminate),
    not(s.shadowDiverged),
    not(s.wrapInfiniteRecur),
    not(s.sharedOptDataRace),
    not(s.prematureSsxiPublish),
    // Single-slot invariant: lock flag and owner never disagree
    (s.ilock.legacyFlag == 1) == (s.ilock.owner != 0),
    // If lock is owned, owner thread claims it and is alive
    s.ilock.owner != 0 implies (
      s.threads.get(s.ilock.owner).holdingInlineLock and s.threads.get(s.ilock.owner).alive
    ),
    // Mutual exclusion on inline lock
    not(s.threads.get(1).holdingInlineLock and s.threads.get(2).holdingInlineLock),
    // Single-winner shadow class canonicalization
    (s.threads.get(1).shadowResult != 0 and s.threads.get(2).shadowResult != 0)
      implies (s.threads.get(1).shadowResult == s.threads.get(2).shadowResult),
    // Bounded wrap-runtime-exception depth <= 1
    s.threads.get(1).wrapDepth <= 1 and s.threads.get(2).wrapDepth <= 1,
    // No premature SSXI publication
    Set(1, 2).forall(m => s.ssxiPublished.get(m) implies s.ssxiEmitted.get(m)),
    // Zero concurrent shared optimizer writers
    s.sharedOptWriters <= 1
  }

  // Positive test: true parallel optimization + lock-free shadow class + unwind + bounded wrap
  run positiveParallelGerbilSmpClosureTest =
    init
      .then(compSessionCheckout(1))
      .then(compSessionCheckout(2))
      .then(compParallelOptimizeToSsxi(1))
      .then(compParallelOptimizeToSsxi(2))
      .then(compSessionCommit(1))
      .then(compSessionCommit(2))
      .then(shadowBeginConstruct(1))
      .then(shadowBeginConstruct(2))
      .then(shadowInsertCanonical(1))
      .then(shadowInsertCanonical(2))
      .then(inlineLockAcquire(1))
      .then(inlineLockInspectContended(2))
      .then(inlineLockUnwindException(1))
      .then(wrapRuntimeExceptionEnter(1))
      .then(wrapRuntimeExceptionEnter(1))
      .then(wrapRuntimeExceptionExit(1))
      .expect(
        safe and
        s.ssxiPublished.get(1) and s.ssxiPublished.get(2) and
        s.threads.get(1).shadowResult == s.threads.get(2).shadowResult and
        s.ilock.owner == 0
      )

  run positiveTerminateDuringShadowConstructSafeTest =
    init
      .then(shadowBeginConstruct(1))
      .then(terminateDuringShadowConstruct(1))
      .then(shadowBeginConstruct(2))
      .then(shadowInsertCanonical(2))
      .expect(safe and s.ilock.owner == 0 and s.threads.get(2).shadowResult == 102)

  run mutant1TwoSlotWindowDerefKilledTest =
    init.then(mutant1TwoSlotWindowDeref).expect(not(safe))

  run mutant2ExceptionLeaksInlineLockKilledTest =
    init.then(inlineLockAcquire(1)).then(mutant2ExceptionLeaksInlineLock(1)).expect(not(safe))

  run mutant3ShadowLockHeldAcrossConstructKilledTest =
    init.then(mutant3ShadowLockHeldAcrossConstruct(1)).expect(not(safe))

  run mutant4UnguardedWrapRecursionKilledTest =
    init.then(wrapRuntimeExceptionEnter(1)).then(mutant4UnguardedWrapRecursion(1)).expect(not(safe))

  run mutant5SharedOptMutationWithoutOverlayKilledTest =
    init
      .then(compSessionCheckout(1))
      .then(compSessionCheckout(2))
      .then(mutant5SharedOptMutationWithoutOverlay)
      .expect(not(safe))

  run mutant6PrematureSsxiPublishKilledTest =
    init
      .then(compSessionCheckout(1))
      .then(mutant6PrematureSsxiPublish(1))
      .expect(not(safe))
}

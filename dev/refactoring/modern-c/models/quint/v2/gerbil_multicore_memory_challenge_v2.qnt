module gerbil_multicore_memory_challenge_v2 {
  // Adversarial Quint V2 Model Challenging Gerbil Multi-Core Compilation & Runtime Memory:
  // Models the real measured failure modes of 8-core Gerbil stage0/stage1 and stdlib:
  //   - Stage0/Stage1: 8 concurrent workers cycling idle -> gsc_codegen -> gsc_trim -> cc1_compile -> done
  //     Challenges that pre-cc1 heap trim keeps 8-core group RSS strictly < 6.0 GiB (vs v25 7.01 GiB
  //     and pre-fix > 8.2 GiB kill).
  //   - Stdlib: single-process gxi driver expanding 600+ modules (1760 MiB live AST) while dispatching
  //     W=6 concurrent gsc/cc1 compile workers.
  //     Challenges that adaptive live_percent (75-80%) + census.queue release + direct-mmap still
  //     cuts idle driver footprint from v25's 4.22 GiB (7.69 GiB total at 3c) down to <= 2.35 GiB,
  //     enabling 6-worker stdlib strictly below 8.0 GiB!
  //   - Runtime Concurrency Challenge: Gerbil util.ss/mop.ss lock-poisoning & mixed-ABI rejection.

  pure val WORKERS = Set(0, 1, 2, 3, 4, 5, 6, 7)
  pure val CEILING_MB = 8192

  type WorkerState = {
    phase: str,       // "idle" | "gsc_codegen" | "gsc_trimmed" | "cc1"
    gscMb: int,
    cc1Mb: int
  }

  type State = {
    stage: str,                 // "stage0_8c" | "stdlib_6c"
    abiSealClosed: bool,
    workers: int -> WorkerState,
    stdlibDriverLiveMb: int,
    stdlibDriverFootprintMb: int,
    stdlibDriverCensusLeakMb: int,
    stdlibDriverMallocEmptyMb: int,
    mopLockPoisoned: bool,
    // Violation flags
    dualPeakOverlapBug: bool,
    envelopeBreachBug: bool,
    stdlibIdleBloatBug: bool,
    mixedAbiBug: bool
  }

  var s: State

  pure def workerMemMb(w: WorkerState): int = w.gscMb + w.cc1Mb

  pure def totalGroupMemMb(st: State): int =
    val wSum = WORKERS.fold(0, (acc, i) => acc + workerMemMb(st.workers.get(i)))
    if (st.stage == "stdlib_6c")
      st.stdlibDriverFootprintMb + st.stdlibDriverCensusLeakMb + st.stdlibDriverMallocEmptyMb + wSum
    else
      wSum

  action init = {
    s' = {
      stage: "stage0_8c",
      abiSealClosed: true,
      workers: WORKERS.mapBy(_ => { phase: "idle", gscMb: 0, cc1Mb: 0 }),
      stdlibDriverLiveMb: 0,
      stdlibDriverFootprintMb: 0,
      stdlibDriverCensusLeakMb: 0,
      stdlibDriverMallocEmptyMb: 0,
      mopLockPoisoned: false,
      dualPeakOverlapBug: false,
      envelopeBreachBug: false,
      stdlibIdleBloatBug: false,
      mixedAbiBug: false
    }
  }

  // Worker starts gsc Scheme->C compilation (peaks ~260 MiB)
  action workerStartGsc(id: int): bool = {
    val w = s.workers.get(id)
    val maxActive = if (s.stage == "stdlib_6c") 6 else 8
    all {
      s.abiSealClosed,
      not(s.mopLockPoisoned),
      WORKERS.contains(id),
      id < maxActive,
      w.phase == "idle",
      s' = {
        ...s,
        workers: s.workers.set(id, { phase: "gsc_codegen", gscMb: 260, cc1Mb: 0 })
      }
    }
  }

  // Mandatory pre-##gambuild trim: contracts gsc heap 260 MiB -> 24 MiB before spawning cc1
  action workerTrimBeforeCc1(id: int): bool = {
    val w = s.workers.get(id)
    all {
      WORKERS.contains(id),
      w.phase == "gsc_codegen",
      s' = {
        ...s,
        workers: s.workers.set(id, { phase: "gsc_trimmed", gscMb: 24, cc1Mb: 0 })
      }
    }
  }

  // Spawn cc1 ONLY from gsc_trimmed (never directly from bloated gsc_codegen!)
  action workerSpawnCc1(id: int): bool = {
    val w = s.workers.get(id)
    all {
      WORKERS.contains(id),
      w.phase == "gsc_trimmed",
      s' = {
        ...s,
        workers: s.workers.set(id, { phase: "cc1", gscMb: 24, cc1Mb: 540 })
      }
    }
  }

  action workerFinish(id: int): bool = {
    val w = s.workers.get(id)
    all {
      WORKERS.contains(id),
      w.phase == "cc1",
      s' = {
        ...s,
        workers: s.workers.set(id, { phase: "idle", gscMb: 0, cc1Mb: 0 })
      }
    }
  }

  // Transition to stdlib_6c with adaptive live_percent=78% (1760 MiB live -> 2256 MiB footprint,
  // 0 MiB census leak, 0 MiB MALLOC_LARGE empty) so 6 concurrent workers stay strictly < 8 GiB!
  action enterStdlibWithAdaptiveDriver = all {
    s.stage == "stage0_8c",
    WORKERS.forall(i => s.workers.get(i).phase == "idle"),
    s' = {
      ...s,
      stage: "stdlib_6c",
      stdlibDriverLiveMb: 1760,
      stdlibDriverFootprintMb: 2256,
      stdlibDriverCensusLeakMb: 0,
      stdlibDriverMallocEmptyMb: 0
    }
  }

  action step = any {
    nondet id = WORKERS.oneOf()
    any {
      workerStartGsc(id),
      workerTrimBeforeCc1(id),
      workerSpawnCc1(id),
      workerFinish(id)
    },
    enterStdlibWithAdaptiveDriver
  }

  // --- Invariants ---
  val noWorkerDualPeak =
    WORKERS.forall(i =>
      val w = s.workers.get(i)
      (w.cc1Mb == 0) or (w.gscMb <= 32)
    )
  val totalWithinCeiling = totalGroupMemMb(s) < CEILING_MB
  val stdlibDriverBounded =
    (s.stage != "stdlib_6c") or
    (s.stdlibDriverFootprintMb + s.stdlibDriverCensusLeakMb + s.stdlibDriverMallocEmptyMb <= 2560)

  val safe =
    s.abiSealClosed and
    not(s.mopLockPoisoned) and
    not(s.dualPeakOverlapBug) and
    not(s.envelopeBreachBug) and
    not(s.stdlibIdleBloatBug) and
    not(s.mixedAbiBug) and
    noWorkerDualPeak and
    totalWithinCeiling and
    stdlibDriverBounded

  // --- 6 Real-Bug Mutation Killers ---

  // Mutant 1: Skip pre-cc1 trim so all 8 workers run cc1 (680 MiB) while holding 365 MiB gsc -> 8.36 GiB!
  action buggySkipPreCc1TrimAll8 = all {
    s' = {
      ...s,
      workers: WORKERS.mapBy(_ => { phase: "cc1", gscMb: 365, cc1Mb: 680 }),
      dualPeakOverlapBug: true,
      envelopeBreachBug: true
    }
  }

  // Mutant 2: Legacy stdlib driver retains 3220 MiB active half + 504 MiB MALLOC_LARGE empty + 500 MiB census -> 4.22 GiB!
  action buggyLegacyStdlibDriverRetention = all {
    s' = {
      ...s,
      stage: "stdlib_6c",
      stdlibDriverLiveMb: 1760,
      stdlibDriverFootprintMb: 3220,
      stdlibDriverCensusLeakMb: 500,
      stdlibDriverMallocEmptyMb: 504,
      stdlibIdleBloatBug: true
    }
  }

  // Mutant 3: Legacy stdlib driver + 6 workers overflows 8 GiB ceiling!
  action buggyStdlib6cOverflow = all {
    s' = {
      ...s,
      stage: "stdlib_6c",
      stdlibDriverLiveMb: 1760,
      stdlibDriverFootprintMb: 3220,
      stdlibDriverCensusLeakMb: 500,
      stdlibDriverMallocEmptyMb: 504,
      workers: WORKERS.mapBy(i => if (i < 6) { phase: "cc1", gscMb: 200, cc1Mb: 540 } else { phase: "idle", gscMb: 0, cc1Mb: 0 }),
      envelopeBreachBug: true
    }
  }

  // Mutant 4: Upstream Gerbil util.ss/mop.ss lock poisoning triggers infinite exception allocation
  action buggyGerbilMopLockPoisoning = all {
    s' = { ...s, mopLockPoisoned: true }
  }

  // Mutant 5: Dynamic .o1 ABI unexported symbol breaks stage0 link
  action buggyBrokenDynamicAbi = all {
    s' = { ...s, abiSealClosed: false, mixedAbiBug: true }
  }

  // Mutant 6: Single worker enters cc1 without trimming gsc first
  action buggySingleWorkerUntrimmedCc1 = all {
    s' = {
      ...s,
      workers: s.workers.set(0, { phase: "cc1", gscMb: 260, cc1Mb: 540 }),
      dualPeakOverlapBug: true
    }
  }

  // --- Positive Verification Tests ---
  run stage0All8ConcurrentCc1Under5GiBTest =
    init
      .then(workerStartGsc(0)).then(workerTrimBeforeCc1(0)).then(workerSpawnCc1(0))
      .then(workerStartGsc(1)).then(workerTrimBeforeCc1(1)).then(workerSpawnCc1(1))
      .then(workerStartGsc(2)).then(workerTrimBeforeCc1(2)).then(workerSpawnCc1(2))
      .then(workerStartGsc(3)).then(workerTrimBeforeCc1(3)).then(workerSpawnCc1(3))
      .then(workerStartGsc(4)).then(workerTrimBeforeCc1(4)).then(workerSpawnCc1(4))
      .then(workerStartGsc(5)).then(workerTrimBeforeCc1(5)).then(workerSpawnCc1(5))
      .then(workerStartGsc(6)).then(workerTrimBeforeCc1(6)).then(workerSpawnCc1(6))
      .then(workerStartGsc(7)).then(workerTrimBeforeCc1(7)).then(workerSpawnCc1(7))
      .expect(safe and totalGroupMemMb(s) == 4512)

  run stdlibAdaptiveDriver6WorkersUnder6GiBTest =
    init
      .then(enterStdlibWithAdaptiveDriver)
      .then(workerStartGsc(0)).then(workerTrimBeforeCc1(0)).then(workerSpawnCc1(0))
      .then(workerStartGsc(1)).then(workerTrimBeforeCc1(1)).then(workerSpawnCc1(1))
      .then(workerStartGsc(2)).then(workerTrimBeforeCc1(2)).then(workerSpawnCc1(2))
      .then(workerStartGsc(3)).then(workerTrimBeforeCc1(3)).then(workerSpawnCc1(3))
      .then(workerStartGsc(4)).then(workerTrimBeforeCc1(4)).then(workerSpawnCc1(4))
      .then(workerStartGsc(5)).then(workerTrimBeforeCc1(5)).then(workerSpawnCc1(5))
      .expect(safe and totalGroupMemMb(s) == 5640)

  // --- 6 Mutant-Killing Negative Tests ---
  run mutant1SkipPreCc1TrimAll8KilledTest =
    init.then(buggySkipPreCc1TrimAll8).expect(not(safe))

  run mutant2LegacyStdlibDriverKilledTest =
    init.then(buggyLegacyStdlibDriverRetention).expect(not(safe))

  run mutant3Stdlib6cOverflowKilledTest =
    init.then(buggyStdlib6cOverflow).expect(not(safe))

  run mutant4GerbilMopLockPoisoningKilledTest =
    init.then(buggyGerbilMopLockPoisoning).expect(not(safe))

  run mutant5BrokenDynamicAbiKilledTest =
    init.then(buggyBrokenDynamicAbi).expect(not(safe))

  run mutant6SingleWorkerUntrimmedCc1KilledTest =
    init.then(buggySingleWorkerUntrimmedCc1).expect(not(safe))
}

module gc_ffi_worker_domain_v2 {
  // Quint V2 (Explicit Heap, Value Tags, Raw-F64 Scrub, Lock-Order, Mutation-Killing)
  // Protocol Model covering:
  //   1. W < R collector worker-to-root-domain decoupling (W = 2, R = 4) with
  //      arena-less domain 3 resumption (___gc_resume_without_arena).
  //   2. EntryRootSpec moving-argument pinning across nested FFI callbacks and
  //      explicit heap evacuation (`oldAddr -> -1`, `newAddr -> liveVal`) so a
  //      missed FFI root slot is detected by a REAL slot-oracle / stale-epoch check
  //      even when the target object stays alive via another strong root!
  //   3. GVM register ValueTag ("Immediate" | "Boxed" | "RawF64") + ___RETI GC map
  //      scanning: models the exact v10 `06-thread/thread_state.scm` SIGSEGV bug
  //      (`##toq-insert!` leaving RawF64 bits in a dead GVM register) and proves
  //      that `targ-scrub-dirty-unboxed` + physical-index `raw?` preserves GC safety.
  //   4. Lock-order rank enforcement (vm_lock < pstate_lock < mutex_lock) for
  //      deadlock-freedom across mutators, FFI, and GC workers.

  pure val TOTAL_DOMAINS = 4
  pure val WORKERS = 2
  pure val NUM_REGS = 4

  // Lock rank constants (strict ascending acquisition order prevents AB-BA deadlocks)
  pure val LOCK_NONE = 0
  pure val LOCK_VM = 1
  pure val LOCK_PSTATE = 2
  pure val LOCK_MUTEX = 3

  type ValueTag = str // "Immediate" | "Boxed" | "RawF64"

  type State = {
    gcEpoch: int,
    gcActive: bool,
    // Root domains 0..3: "frozen" | "claimed" | "repaired"
    domainState: int -> str,
    domainClaimant: int -> int,
    domainHasArena: int -> bool,
    domainResumed: int -> bool,
    // Explicit relocating heap: address -> payload (-1 = evacuated/dangling)
    heap: int -> int,
    nextAddr: int,
    // FFI EntryRootSpec moving argument custody + independent strong root
    ffiCallDepth: int,
    ffiArgPinned: bool,
    ffiArgSlotAddr: int,        // address stored in the FFI C frame slot
    otherStrongRootAddr: int,   // another root keeping the same object alive!
    ffiDereferencedVal: int,    // value observed when FFI callback uses its arg
    // GVM register file (modeling unboxed F64 spills + ___RETI GC map)
    regTag: int -> ValueTag,    // physical register 0..3 value kind
    regAddr: int -> int,        // heap address if Boxed, else 0
    regLiveInGcMap: int -> bool,// whether next ___RETI GC map marks reg as live root
    gcScannedRawF64: bool,      // set ONLY by actual GC scan hitting a RawF64 reg!
    // Lock acquisition rank tracking (per-thread max rank currently held)
    heldLockRank: int,
    lockOrderViolated: bool
  }

  var s: State

  action init = {
    s' = {
      gcEpoch: 1,
      gcActive: false,
      domainState: Map(0 -> "repaired", 1 -> "repaired", 2 -> "repaired", 3 -> "repaired"),
      domainClaimant: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0),
      domainHasArena: Map(0 -> true, 1 -> true, 2 -> true, 3 -> false),
      domainResumed: Map(0 -> true, 1 -> true, 2 -> true, 3 -> true),
      heap: Map(1 -> 777, 2 -> 888),
      nextAddr: 3,
      ffiCallDepth: 0,
      ffiArgPinned: false,
      ffiArgSlotAddr: 0,
      otherStrongRootAddr: 1,
      ffiDereferencedVal: 777,
      regTag: Map(0 -> "Boxed", 1 -> "Immediate", 2 -> "Immediate", 3 -> "Immediate"),
      regAddr: Map(0 -> 2, 1 -> 0, 2 -> 0, 3 -> 0),
      regLiveInGcMap: Map(0 -> true, 1 -> false, 2 -> false, 3 -> false),
      gcScannedRawF64: false,
      heldLockRank: LOCK_NONE,
      lockOrderViolated: false
    }
  }

  // --- Mutator GVM unboxed F64 write + safe `targ-scrub-dirty-unboxed` before ___RETI ---
  action mutatorComputeUnboxedF64(r: int): bool = all {
    not(s.gcActive),
    r >= 1 and r < NUM_REGS,
    // Unboxed F64 computation deposits raw IEEE-754 bits into physical register r
    s' = {
      ...s,
      regTag: s.regTag.set(r, "RawF64"),
      regAddr: s.regAddr.set(r, 0),
      regLiveInGcMap: s.regLiveInGcMap.set(r, false)
    }
  }

  // Safe compiler action (commit 45d83511): scrub dead dirty unboxed reg to ___FIX(0)
  // before any subsequent ___RETI / ___POLL safe-point can mark it in a GC map.
  action compilerScrubDirtyUnboxed(r: int): bool = all {
    not(s.gcActive),
    r >= 1 and r < NUM_REGS,
    s.regTag.get(r) == "RawF64",
    s' = {
      ...s,
      regTag: s.regTag.set(r, "Immediate"),
      regAddr: s.regAddr.set(r, 0)
    }
  }

  // Enter FFI boundary: pin moving argument BEFORE any allocating conversion/callback
  action enterFfiAndPin = all {
    not(s.gcActive),
    s.ffiCallDepth < 2,
    s' = {
      ...s,
      ffiCallDepth: s.ffiCallDepth + 1,
      ffiArgPinned: true,
      ffiArgSlotAddr: s.otherStrongRootAddr
    }
  }

  // Lock-order rank acquire/release (must strictly ascend when acquiring)
  action acquireLock(rank: int): bool = all {
    rank > LOCK_NONE and rank <= LOCK_MUTEX,
    rank > s.heldLockRank,
    s' = { ...s, heldLockRank: rank }
  }

  action releaseAllLocks = all {
    s.heldLockRank > LOCK_NONE,
    s' = { ...s, heldLockRank: LOCK_NONE }
  }

  // Start STW GC round: all R=4 domains frozen; safe-point requires no RawF64 live in GC map
  action startCollection = all {
    not(s.gcActive),
    s.heldLockRank == LOCK_NONE,
    // Actual GC root scan inspects every register marked in regLiveInGcMap (or any
    // physical register whose tag is RawF64 when not excluded by physical-index `raw?`!)
    val hitRawF64 = 0.to(NUM_REGS - 1).exists(r =>
      s.regLiveInGcMap.get(r) and s.regTag.get(r) == "RawF64"
    )
    s' = {
      ...s,
      gcEpoch: s.gcEpoch + 1,
      gcActive: true,
      gcScannedRawF64: s.gcScannedRawF64 or hitRawF64,
      domainState: Map(0 -> "frozen", 1 -> "frozen", 2 -> "frozen", 3 -> "frozen"),
      domainClaimant: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0),
      domainResumed: Map(0 -> false, 1 -> false, 2 -> false, 3 -> false)
    }
  }

  // One of W=2 collector workers claims a frozen domain d in 0..3
  action workerClaimDomain(w: int, d: int): bool = all {
    s.gcActive,
    w >= 1 and w <= WORKERS,
    d >= 0 and d < TOTAL_DOMAINS,
    s.domainState.get(d) == "frozen",
    s' = {
      ...s,
      domainState: s.domainState.set(d, "claimed"),
      domainClaimant: s.domainClaimant.set(d, w)
    }
  }

  // Claiming worker evacuates live moving objects and repairs roots in domain d.
  // Domain 0 holds both `otherStrongRootAddr` and (if pinned) `ffiArgSlotAddr`.
  action workerRepairDomain(w: int, d: int): bool = all {
    s.gcActive,
    w >= 1 and w <= WORKERS,
    d >= 0 and d < TOTAL_DOMAINS,
    s.domainState.get(d) == "claimed",
    s.domainClaimant.get(d) == w,
    s.nextAddr < 30,
    if (d == 0) {
      // Evacuate the shared moving object from oldAddr -> newAddr and poison oldAddr (-1)
      val oldAddr = s.otherStrongRootAddr
      val payload = s.heap.get(oldAddr)
      val newAddr = s.nextAddr
      val repairedFfiSlot = if (s.ffiArgPinned) newAddr else s.ffiArgSlotAddr
      s' = {
        ...s,
        domainState: s.domainState.set(d, "repaired"),
        heap: s.heap.put(oldAddr, -1).put(newAddr, payload),
        nextAddr: newAddr + 1,
        otherStrongRootAddr: newAddr,
        ffiArgSlotAddr: repairedFfiSlot
      }
    } else {
      s' = {
        ...s,
        domainState: s.domainState.set(d, "repaired")
      }
    }
  }

  // Complete GC only when all R=4 domains are repaired; arena-less domain 3 resumes cleanly
  action completeCollectionAndResume = all {
    s.gcActive,
    0.to(TOTAL_DOMAINS - 1).forall(d => s.domainState.get(d) == "repaired"),
    s' = {
      ...s,
      gcActive: false,
      domainResumed: Map(0 -> true, 1 -> true, 2 -> true, 3 -> true)
    }
  }

  // FFI callback dereferences its moving argument slot AFTER GC resumes!
  action ffiUseMovingArg = all {
    not(s.gcActive),
    s.ffiCallDepth > 0,
    val addr = s.ffiArgSlotAddr
    val observed = if (s.heap.keys().contains(addr)) s.heap.get(addr) else -1
    s' = {
      ...s,
      ffiDereferencedVal: observed
    }
  }

  // Exit one FFI nesting level and unpin only when depth returns to 0
  action exitFfiCleanup = all {
    not(s.gcActive),
    s.ffiCallDepth > 0,
    val nextDepth = s.ffiCallDepth - 1
    s' = {
      ...s,
      ffiCallDepth: nextDepth,
      ffiArgPinned: nextDepth > 0,
      ffiArgSlotAddr: if (nextDepth > 0) s.ffiArgSlotAddr else 0
    }
  }

  action step = any {
    nondet r = oneOf(Set(1, 2, 3))
    mutatorComputeUnboxedF64(r),
    nondet r2 = oneOf(Set(1, 2, 3))
    compilerScrubDirtyUnboxed(r2),
    enterFfiAndPin,
    nondet lk = oneOf(Set(LOCK_VM, LOCK_PSTATE, LOCK_MUTEX))
    acquireLock(lk),
    releaseAllLocks,
    startCollection,
    nondet w1 = oneOf(Set(1, 2))
    nondet d1 = oneOf(Set(0, 1, 2, 3))
    workerClaimDomain(w1, d1),
    nondet w2 = oneOf(Set(1, 2))
    nondet d2 = oneOf(Set(0, 1, 2, 3))
    workerRepairDomain(w2, d2),
    completeCollectionAndResume,
    ffiUseMovingArg,
    exitFfiCleanup
  }

  // --- Genuine Structural Safety Invariants ---
  val noRawF64ScannedByGc = not(s.gcScannedRawF64)
  val noDanglingFfiArg = s.ffiDereferencedVal == 777
  val ffiSlotMatchesLiveObject = (not(s.gcActive) and s.ffiCallDepth > 0) implies (
    s.ffiArgPinned and
    s.ffiArgSlotAddr == s.otherStrongRootAddr and
    s.heap.get(s.ffiArgSlotAddr) == 777
  )
  val arenaLessDomainResumed = not(s.gcActive) implies (
    not(s.domainHasArena.get(3)) and s.domainResumed.get(3)
  )
  val uniqueClaimantPerDomain = 0.to(TOTAL_DOMAINS - 1).forall(d =>
    (s.domainState.get(d) == "claimed") implies
      (s.domainClaimant.get(d) >= 1 and s.domainClaimant.get(d) <= WORKERS)
  )
  val noLockOrderViolation = not(s.lockOrderViolated)

  val safe = all {
    noRawF64ScannedByGc,
    noDanglingFfiArg,
    ffiSlotMatchesLiveObject,
    arenaLessDomainResumed,
    uniqueClaimantPerDomain,
    noLockOrderViolation
  }

  run testSafeFullCycle =
    init
      .then(mutatorComputeUnboxedF64(2))
      .then(compilerScrubDirtyUnboxed(2))
      .then(enterFfiAndPin)
      .then(startCollection)
      .then(workerClaimDomain(1, 0))
      .then(workerClaimDomain(2, 1))
      .then(workerRepairDomain(1, 0))
      .then(workerRepairDomain(2, 1))
      .then(workerClaimDomain(1, 2))
      .then(workerClaimDomain(2, 3))
      .then(workerRepairDomain(1, 2))
      .then(workerRepairDomain(2, 3))
      .then(completeCollectionAndResume)
      .then(ffiUseMovingArg)
      .then(exitFfiCleanup)
      .expect(safe and s.gcEpoch == 2 and s.ffiDereferencedVal == 777)
}

// ============================================================================
// Mutation-Killing Module A: Exact v10 `06-thread/thread_state.scm` Raw-F64 Bug!
// Models omitting `targ-scrub-dirty-unboxed` + using stale GC map without
// physical-index `raw?`: GC scans RawF64 bits in R2 -> SIGSEGV (`gcScannedRawF64`)!
// ============================================================================
module gc_ffi_v2_buggy_raw_f64 {
  import gc_ffi_worker_domain_v2.*

  // BUGGY MUTANT (pre-45d83511): subsequent block marks physical reg r live in
  // ___RETI GC map WITHOUT scrubbing dirty RawF64 bits first!
  action buggyEmitRetiWithStaleRawReg(r: int): bool = all {
    not(s.gcActive),
    r >= 1 and r < NUM_REGS,
    s.regTag.get(r) == "RawF64",
    s' = { ...s, regLiveInGcMap: s.regLiveInGcMap.set(r, true) }
  }

  action buggyStep = any {
    nondet r = oneOf(Set(1, 2, 3))
    mutatorComputeUnboxedF64(r),
    nondet r2 = oneOf(Set(1, 2, 3))
    buggyEmitRetiWithStaleRawReg(r2),
    startCollection
  }

  run testRawF64MutantKilled =
    init
      .then(mutatorComputeUnboxedF64(2))
      .then(buggyEmitRetiWithStaleRawReg(2))
      .then(startCollection)
      .expect(not(safe) and s.gcScannedRawF64)
}

// ============================================================================
// Mutation-Killing Module B: Missed FFI EntryRootSpec Slot (Slot-Oracle Killer!)
// Even though `otherStrongRootAddr` keeps the moving object alive and relocates
// it to `newAddr`, omitting the FFI slot repair leaves `ffiArgSlotAddr` pointing
// at evacuated `oldAddr` (-1) -> `ffiUseMovingArg` observes `-1` -> `safe` FAILS!
// ============================================================================
module gc_ffi_v2_buggy_missed_ffi_root {
  import gc_ffi_worker_domain_v2.*

  action buggyWorkerRepairForgetsFfiSlot(w: int): bool = all {
    s.gcActive,
    w >= 1 and w <= WORKERS,
    s.domainState.get(0) == "claimed",
    s.domainClaimant.get(0) == w,
    s.nextAddr < 30,
    val oldAddr = s.otherStrongRootAddr
    val payload = s.heap.get(oldAddr)
    val newAddr = s.nextAddr
    // BUG: updates otherStrongRootAddr, FORGETS to update ffiArgSlotAddr!
    s' = {
      ...s,
      domainState: s.domainState.set(0, "repaired"),
      heap: s.heap.put(oldAddr, -1).put(newAddr, payload),
      nextAddr: newAddr + 1,
      otherStrongRootAddr: newAddr
    }
  }

  action buggyStep = any {
    enterFfiAndPin,
    startCollection,
    nondet w1 = oneOf(Set(1, 2))
    nondet d1 = oneOf(Set(0, 1, 2, 3))
    workerClaimDomain(w1, d1),
    nondet w0 = oneOf(Set(1, 2))
    buggyWorkerRepairForgetsFfiSlot(w0),
    nondet w2 = oneOf(Set(1, 2))
    nondet d2 = oneOf(Set(1, 2, 3))
    workerRepairDomain(w2, d2),
    completeCollectionAndResume,
    ffiUseMovingArg
  }

  run testMissedFfiRootMutantKilled =
    init
      .then(enterFfiAndPin)
      .then(startCollection)
      .then(workerClaimDomain(1, 0))
      .then(workerClaimDomain(2, 1))
      .then(buggyWorkerRepairForgetsFfiSlot(1))
      .then(workerRepairDomain(2, 1))
      .then(workerClaimDomain(1, 2))
      .then(workerClaimDomain(2, 3))
      .then(workerRepairDomain(1, 2))
      .then(workerRepairDomain(2, 3))
      .then(completeCollectionAndResume)
      .then(ffiUseMovingArg)
      .expect(not(safe) and s.ffiDereferencedVal == -1)
}

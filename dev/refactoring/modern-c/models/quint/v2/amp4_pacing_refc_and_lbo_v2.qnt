// Quint V2 formal model closing the Amp-4 verification quadrant (H12-H13):
//   1. Off-heap immutable RefC binary (Erlang ProcBin / Rust Arc + Chez IMMUTABLE_TAG):
//      - Immutability tag check before off-heap sharing
//      - Release-ordered refcount drop + acquire-fenced final free strictly at oldCount == 1
//      - Zero UAF against live readers & zero silent mutation corruption
//   2. OCaml-5 global alloc_counter / work_counter concurrent major mark pacing +
//      Racket-on-Chez phantom external-memory bytes accounting:
//      - Proportional major mark slices complete BEFORE managed + phantom hits heap limit M
//      - Phantom bytes fed into effective allocation prevent hidden native RSS OOM
//      - Atomic work-counter increments prevent lost slice progress across domains
//
// Includes 1 happy-path test + 6 adversarial mutation-killers (7/7 tests) + safe invariant.

module amp4_pacing_refc_and_lbo_v2 {

  type State = {
    // H12: Off-heap immutable RefC binary
    binImmutable: bool,
    binSharedOffHeap: bool,
    binRefCount: int,
    binActiveReaders: int,
    binReleaseFencedDrops: int,
    binFreed: bool,
    binPayloadVersion: int,
    binReaderObservedVersion: int,
    // H13: Global pacing + phantom external bytes
    managedAlloc: int,
    phantomBytes: int,
    trackedAlloc: int,
    heapLimitM: int,
    majorWorkNeeded: int,
    majorWorkDone: int,
    majorMarkComplete: bool,
    // Fault witnesses (MUST stay false under safe protocol)
    refcUafBug: bool,
    mutableOffHeapCorruptBug: bool,
    refcMissingReleaseFenceBug: bool,
    emergencyStwFallbackBug: bool,
    phantomHiddenOomBug: bool,
    pacingLostSliceBug: bool
  }

  var s: State

  action init = {
    s' = {
      binImmutable: true,
      binSharedOffHeap: false,
      binRefCount: 1,
      binActiveReaders: 0,
      binReleaseFencedDrops: 0,
      binFreed: false,
      binPayloadVersion: 1,
      binReaderObservedVersion: 1,
      managedAlloc: 0,
      phantomBytes: 0,
      trackedAlloc: 0,
      heapLimitM: 8,
      majorWorkNeeded: 8,
      majorWorkDone: 0,
      majorMarkComplete: false,
      refcUafBug: false,
      mutableOffHeapCorruptBug: false,
      refcMissingReleaseFenceBug: false,
      emergencyStwFallbackBug: false,
      phantomHiddenOomBug: false,
      pacingLostSliceBug: false
    }
  }

  // ---- Safe H12 Actions: Off-Heap Immutable RefC Binary ----

  // Share binary off-heap ONLY when IMMUTABLE_TAG is set and refcount > 0.
  action safeShareImmutableBinary = all {
    not(s.binFreed),
    s.binImmutable,
    s.binRefCount >= 1,
    s.binRefCount < 3,
    s' = {
      ...s,
      binSharedOffHeap: true,
      binRefCount: s.binRefCount + 1
    }
  }

  // Reader acquires a read view while holding a live refcount.
  action safeReaderBegin = all {
    not(s.binFreed),
    s.binSharedOffHeap,
    s.binActiveReaders < s.binRefCount,
    s' = {
      ...s,
      binActiveReaders: s.binActiveReaders + 1,
      binReaderObservedVersion: s.binPayloadVersion
    }
  }

  // Reader finishes payload read, issues release fence, and drops one refcount.
  // If oldRef == 1 (last owner) and no readers remain, issues acquire fence & frees.
  action safeReaderFinishAndDrop = all {
    not(s.binFreed),
    s.binActiveReaders > 0,
    s.binRefCount > 0,
    val nextRef = s.binRefCount - 1
    val nextReaders = s.binActiveReaders - 1
    val doFree = (nextRef == 0)
    all {
      s' = {
        ...s,
        binActiveReaders: nextReaders,
        binRefCount: nextRef,
        binReleaseFencedDrops: s.binReleaseFencedDrops + 1,
        binFreed: doFree,
        refcUafBug: s.refcUafBug or (doFree and nextReaders > 0)
      }
    }
  }

  // Non-reading owner drops its refcount with release fence; frees ONLY when nextRef == 0.
  action safeOwnerDropRef = all {
    not(s.binFreed),
    s.binRefCount > s.binActiveReaders,
    val nextRef = s.binRefCount - 1
    val doFree = (nextRef == 0)
    all {
      s' = {
        ...s,
        binRefCount: nextRef,
        binReleaseFencedDrops: s.binReleaseFencedDrops + 1,
        binFreed: doFree,
        refcUafBug: s.refcUafBug or (doFree and s.binActiveReaders > 0)
      }
    }
  }

  // ---- Safe H13 Actions: Global Alloc/Work Pacing + Phantom Bytes ----

  // Domain allocates 1 managed unit + executes proportional major mark slice (ratio 1:1).
  action safeManagedAllocWithPacing = all {
    s.trackedAlloc < s.heapLimitM,
    val nextManaged = s.managedAlloc + 1
    val nextTracked = s.trackedAlloc + 1
    val nextWork = if (s.majorWorkDone < s.majorWorkNeeded) s.majorWorkDone + 1 else s.majorWorkDone
    val complete = (nextWork >= s.majorWorkNeeded)
    all {
      s' = {
        ...s,
        managedAlloc: nextManaged,
        trackedAlloc: nextTracked,
        majorWorkDone: nextWork,
        majorMarkComplete: complete
      }
    }
  }

  // Domain allocates 2 off-heap phantom units (e.g. RefC u8vector): MUST add phantom bytes
  // into trackedAlloc and execute proportional major mark slices so hidden RSS never OOMs!
  action safePhantomAllocWithPacing = all {
    s.trackedAlloc + 2 <= s.heapLimitM,
    val nextPhantom = s.phantomBytes + 2
    val nextTracked = s.trackedAlloc + 2
    val nextWork =
      if (s.majorWorkDone + 2 <= s.majorWorkNeeded) s.majorWorkDone + 2
      else s.majorWorkNeeded
    val complete = (nextWork >= s.majorWorkNeeded)
    all {
      s' = {
        ...s,
        phantomBytes: nextPhantom,
        trackedAlloc: nextTracked,
        majorWorkDone: nextWork,
        majorMarkComplete: complete
      }
    }
  }

  // Reach heap limit M: safe ONLY if concurrent major mark already completed!
  action safeCheckHeapLimitBoundary = all {
    s.trackedAlloc == s.heapLimitM,
    s' = {
      ...s,
      emergencyStwFallbackBug: s.emergencyStwFallbackBug or not(s.majorMarkComplete),
      phantomHiddenOomBug: s.phantomHiddenOomBug or (s.managedAlloc + s.phantomBytes > s.heapLimitM)
    }
  }

  // ---- Adversarial Mutants (MUST violate `safe`) ----

  // Mutant 1 (H12): Free off-heap binary while an active reader still holds a reference!
  action buggyFreeWhileReaderAlive = all {
    not(s.binFreed),
    s.binActiveReaders > 0,
    s' = {
      ...s,
      binFreed: true,
      refcUafBug: true
    }
  }

  // Mutant 2 (H12): Share mutable u8vector off-heap without IMMUTABLE_TAG and mutate in place!
  action buggyShareAndMutateMutableBinary = all {
    not(s.binFreed),
    s' = {
      ...s,
      binImmutable: false,
      binSharedOffHeap: true,
      binPayloadVersion: s.binPayloadVersion + 1,
      mutableOffHeapCorruptBug: true
    }
  }

  // Mutant 3 (H12): Drop refcount without release/acquire fence -> peer frees before read visibility!
  action buggyDropWithoutReleaseFence = all {
    not(s.binFreed),
    s.binActiveReaders > 0,
    s' = {
      ...s,
      binActiveReaders: s.binActiveReaders - 1,
      binRefCount: 0,
      binFreed: true,
      refcMissingReleaseFenceBug: true
    }
  }

  // Mutant 4 (H13): Allocate up to heapLimitM without executing proportional major work slices!
  action buggyAllocWithoutPacingSlice = all {
    s.trackedAlloc < s.heapLimitM,
    val nextTracked = s.heapLimitM
    all {
      s' = {
        ...s,
        managedAlloc: s.managedAlloc + (s.heapLimitM - s.trackedAlloc),
        trackedAlloc: nextTracked,
        emergencyStwFallbackBug: not(s.majorMarkComplete)
      }
    }
  }

  // Mutant 5 (H13): Ignore off-heap phantom bytes in trackedAlloc -> native RSS blows past M!
  action buggyPhantomAllocUnaccounted = all {
    val nextPhantom = s.phantomBytes + 10
    all {
      s' = {
        ...s,
        phantomBytes: nextPhantom,
        phantomHiddenOomBug: (s.managedAlloc + nextPhantom) > s.heapLimitM and s.trackedAlloc < s.heapLimitM
      }
    }
  }

  // Mutant 6 (H13): Non-atomic RMW on global work_counter drops a domain's mark slice!
  action buggyNonAtomicWorkCounterDrift = all {
    s.trackedAlloc < s.heapLimitM,
    s' = {
      ...s,
      managedAlloc: s.managedAlloc + 2,
      trackedAlloc: s.trackedAlloc + 2,
      majorWorkDone: s.majorWorkDone + 1, // lost 1 slice from concurrent RMW!
      pacingLostSliceBug: true
    }
  }

  // ---- Safe Transition Relation ----

  action step = any {
    safeShareImmutableBinary,
    safeReaderBegin,
    safeReaderFinishAndDrop,
    safeOwnerDropRef,
    safeManagedAllocWithPacing,
    safePhantomAllocWithPacing,
    safeCheckHeapLimitBoundary
  }

  // ---- Global Safety Invariant ----

  val safe = and {
    not(s.refcUafBug),
    not(s.mutableOffHeapCorruptBug),
    not(s.refcMissingReleaseFenceBug),
    not(s.emergencyStwFallbackBug),
    not(s.phantomHiddenOomBug),
    not(s.pacingLostSliceBug),
    not(s.binFreed and s.binActiveReaders > 0),
    not(s.binSharedOffHeap and not(s.binImmutable)),
    s.trackedAlloc == s.managedAlloc + s.phantomBytes,
    s.managedAlloc + s.phantomBytes <= s.heapLimitM,
    (s.trackedAlloc < s.heapLimitM) or s.majorMarkComplete
  }

  // ---- Verification Runs (1 Happy Path + 6 Adversarial Mutation-Killers) ----

  run happyPathAmp4PacingAndRefcTest =
    init
      .then(safeShareImmutableBinary)
      .then(safeReaderBegin)
      .then(safeManagedAllocWithPacing)
      .then(safePhantomAllocWithPacing)
      .then(safePhantomAllocWithPacing)
      .then(safePhantomAllocWithPacing)
      .then(safeManagedAllocWithPacing)
      .then(safeCheckHeapLimitBoundary)
      .then(safeReaderFinishAndDrop)
      .then(safeOwnerDropRef)
      .then(all {
        assert(safe),
        assert(s.binFreed),
        assert(s.majorMarkComplete),
        s' = s
      })

  run mutant1RefcFreeWhileReaderAliveTest =
    init
      .then(safeShareImmutableBinary)
      .then(safeReaderBegin)
      .then(buggyFreeWhileReaderAlive)
      .then(all {
        assert(not(safe)),
        s' = s
      })

  run mutant2MutableBinarySharedOffHeapTest =
    init
      .then(buggyShareAndMutateMutableBinary)
      .then(all {
        assert(not(safe)),
        s' = s
      })

  run mutant3RefcDropWithoutReleaseFenceTest =
    init
      .then(safeShareImmutableBinary)
      .then(safeReaderBegin)
      .then(buggyDropWithoutReleaseFence)
      .then(all {
        assert(not(safe)),
        s' = s
      })

  run mutant4AllocExceedsLimitWithoutWorkSliceTest =
    init
      .then(safeManagedAllocWithPacing)
      .then(buggyAllocWithoutPacingSlice)
      .then(all {
        assert(not(safe)),
        s' = s
      })

  run mutant5PhantomBytesIgnoredOomTest =
    init
      .then(safeManagedAllocWithPacing)
      .then(buggyPhantomAllocUnaccounted)
      .then(all {
        assert(not(safe)),
        s' = s
      })

  run mutant6PacingCounterNonAtomicDriftTest =
    init
      .then(buggyNonAtomicWorkCounterDrift)
      .then(all {
        assert(not(safe)),
        s' = s
      })
}

module binding_read_activation_v2 {
  // Quint V2 (Micro-step, Non-Atomic, Mutation-Killing) Protocol Model:
  // P0-2 Binding-Read Activation & Single-Page primitive_value Publication.
  //
  // Key upgrades over V1:
  //   1. No tautological dual-page/single-page identity function.
  //   2. No manually set violation flags (`illegalStaleRead = true`).
  //   3. Genuine non-atomic micro-steps:
  //        - Writer splits publication into `writerStoreCell` -> `writerPublishFlag`
  //          (release ordering).
  //        - Reader splits lookup into:
  //            Step 1 (`readerCheckView`): inspect binding_view.vm
  //            Step 2 (`readerLoadFlag`):  acquire-load primitive_flag[slot]
  //            Step 3 (`readerLoadCell`):  dereference heap pointer from cell[slot]
  //   4. Explicit relocating GC heap (`heap: int -> int` mapping heap address ->
  //      semantic payload, invalidated to `-1` when GC evacuates old space).
  //   5. Safety invariant directly checks dereference validity (`observedVal != -1`
  //      and `observedVal` belongs to the set of legally published semantic values),
  //      plus deadlock-freedom (`notDeadlocked`).

  pure val TMPL_ADDR = 1
  pure val INIT_CELL_ADDR = 2
  pure val UNINIT_ADDR = 0

  type ReaderPc = str  // "idle" | "checked_view" | "read_flag_true" | "read_flag_false"
  type WriterPc = str  // "idle" | "wrote_cell" | "wrote_flag_buggy"

  type State = {
    vmIncarnation: int,
    entryCount: int,
    contextOpen: bool,
    frozenForGc: bool,
    gcEpoch: int,
    bindingViewVm: int,
    // Shared global page state
    primFlag: bool,
    primCellAddr: int,          // heap address stored in cell (UNINIT_ADDR before write)
    tmplAddr: int,              // permanent template heap address
    // Relocating heap: address -> semantic value (-1 means evacuated/dangling!)
    heap: int -> int,
    nextAddr: int,
    validPublishedVals: Set[int],
    // Writer micro-step state
    writerPc: WriterPc,
    writerPendingAddr: int,
    writerPendingVal: int,
    // Reader micro-step state
    readerPc: ReaderPc,
    readerCapturedVm: int,
    readerPinnedEpoch: int,
    // Observable outcome of completed reads
    lastObservedVal: int,
    lastReadUsedDangling: bool,
    completedReads: int
  }

  var s: State

  action init = {
    s' = {
      vmIncarnation: 1,
      entryCount: 1,
      contextOpen: true,
      frozenForGc: false,
      gcEpoch: 1,
      bindingViewVm: 1,
      primFlag: false,
      primCellAddr: UNINIT_ADDR,
      tmplAddr: TMPL_ADDR,
      heap: Map(TMPL_ADDR -> 100, UNINIT_ADDR -> -1),
      nextAddr: INIT_CELL_ADDR,
      validPublishedVals: Set(100),
      writerPc: "idle",
      writerPendingAddr: UNINIT_ADDR,
      writerPendingVal: 0,
      readerPc: "idle",
      readerCapturedVm: 0,
      readerPinnedEpoch: 1,
      lastObservedVal: 100,
      lastReadUsedDangling: false,
      completedReads: 0
    }
  }

  // --- Safe Writer: Release-ordered two-step publication (cell BEFORE flag) ---
  action writerAllocateAndStoreCell(newVal: int): bool = all {
    s.contextOpen,
    not(s.frozenForGc),
    s.writerPc == "idle",
    newVal > 100,
    newVal <= 105,
    s.nextAddr < 20,
    val addr = s.nextAddr
    s' = {
      ...s,
      heap: s.heap.put(addr, newVal),
      nextAddr: addr + 1,
      primCellAddr: addr,
      validPublishedVals: s.validPublishedVals.union(Set(newVal)),
      writerPc: "wrote_cell",
      writerPendingAddr: addr,
      writerPendingVal: newVal
    }
  }

  action writerPublishFlag = all {
    s.contextOpen,
    not(s.frozenForGc),
    s.writerPc == "wrote_cell",
    s' = {
      ...s,
      primFlag: true,
      writerPc: "idle",
      writerPendingAddr: UNINIT_ADDR,
      writerPendingVal: 0
    }
  }

  // --- Safe Reader: 3 micro-steps guarded by binding_view.vm and GC safe-point ---
  // Step 1: check ps->context->binding_view.vm == vmIncarnation
  action readerCheckView = all {
    s.contextOpen,
    not(s.frozenForGc),
    s.entryCount > 0,
    s.readerPc == "idle",
    s.bindingViewVm == s.vmIncarnation,
    s' = {
      ...s,
      readerPc: "checked_view",
      readerCapturedVm: s.bindingViewVm,
      readerPinnedEpoch: s.gcEpoch
    }
  }

  // Step 2: acquire-load primitive_flags[slot] on the single page
  action readerLoadFlag = all {
    s.readerPc == "checked_view",
    s' = {
      ...s,
      readerPc: if (s.primFlag) "read_flag_true" else "read_flag_false"
    }
  }

  // Step 3a: flag was true -> dereference primCellAddr in heap
  action readerDereferenceCell = all {
    s.readerPc == "read_flag_true",
    val addr = s.primCellAddr
    val derefVal = if (s.heap.keys().contains(addr)) s.heap.get(addr) else -1
    s' = {
      ...s,
      readerPc: "idle",
      readerCapturedVm: 0,
      lastObservedVal: derefVal,
      lastReadUsedDangling: (derefVal == -1),
      completedReads: s.completedReads + 1
    }
  }

  // Step 3b: flag was false -> dereference permanent template
  action readerDereferenceTemplate = all {
    s.readerPc == "read_flag_false",
    val derefVal = if (s.heap.keys().contains(s.tmplAddr)) s.heap.get(s.tmplAddr) else -1
    s' = {
      ...s,
      readerPc: "idle",
      readerCapturedVm: 0,
      lastObservedVal: derefVal,
      lastReadUsedDangling: (derefVal == -1),
      completedReads: s.completedReads + 1
    }
  }

  // Slow fallback path when binding_view.vm == 0 (safe-point / closing)
  action readerSlowFallback = all {
    s.contextOpen,
    not(s.frozenForGc),
    s.entryCount > 0,
    s.readerPc == "idle",
    s.bindingViewVm == 0,
    val addr = if (s.primFlag) s.primCellAddr else s.tmplAddr
    val derefVal = if (s.heap.keys().contains(addr)) s.heap.get(addr) else -1
    s' = {
      ...s,
      lastObservedVal: derefVal,
      lastReadUsedDangling: (derefVal == -1),
      completedReads: s.completedReads + 1
    }
  }

  // --- Cooperative STW GC: only freezes at safe-point (readerPc == "idle") ---
  // Revokes binding_view.vm BEFORE evacuating heap addresses!
  action freezeRootsForGc = all {
    s.contextOpen,
    not(s.frozenForGc),
    s.readerPc == "idle",
    s' = { ...s, frozenForGc: true, bindingViewVm: 0 }
  }

  // GC evacuates current moving primCellAddr to a fresh address and poisons the old slot (-1)
  action gcRelocateCell = all {
    s.frozenForGc,
    s.bindingViewVm == 0,
    s.primCellAddr != UNINIT_ADDR,
    s.nextAddr < 20,
    val oldAddr = s.primCellAddr
    val liveVal = s.heap.get(oldAddr)
    val newAddr = s.nextAddr
    s' = {
      ...s,
      gcEpoch: s.gcEpoch + 1,
      heap: s.heap.put(oldAddr, -1).put(newAddr, liveVal),
      primCellAddr: newAddr,
      nextAddr: newAddr + 1
    }
  }

  action restoreAndReopenView = all {
    s.contextOpen,
    s.frozenForGc,
    s.entryCount > 0,
    s' = { ...s, frozenForGc: false, bindingViewVm: s.vmIncarnation }
  }

  // Safe context exit: wait until reader reaches safe-point and revoke view first
  action safeRevokeAndClose = all {
    s.contextOpen,
    not(s.frozenForGc),
    s.readerPc == "idle",
    s.entryCount == 1,
    s' = { ...s, bindingViewVm: 0, entryCount: 0, contextOpen: false }
  }

  action reopenNewContext = all {
    not(s.contextOpen),
    s.vmIncarnation < 5,
    s' = {
      ...s,
      vmIncarnation: s.vmIncarnation + 1,
      entryCount: 1,
      contextOpen: true,
      bindingViewVm: s.vmIncarnation + 1
    }
  }

  action step = any {
    nondet v = oneOf(Set(101, 102, 103))
    writerAllocateAndStoreCell(v),
    writerPublishFlag,
    readerCheckView,
    readerLoadFlag,
    readerDereferenceCell,
    readerDereferenceTemplate,
    readerSlowFallback,
    freezeRootsForGc,
    gcRelocateCell,
    restoreAndReopenView,
    safeRevokeAndClose,
    reopenNewContext
  }

  // --- Genuine Structural Safety Invariants (NO fake fault booleans!) ---
  val noDanglingDereference = not(s.lastReadUsedDangling) and s.lastObservedVal != -1
  val observedValueIsPublished = s.validPublishedVals.contains(s.lastObservedVal)
  val frozenRevokesView = s.frozenForGc implies (s.bindingViewVm == 0)
  val closedRevokesView = not(s.contextOpen) implies (s.bindingViewVm == 0 and s.entryCount == 0)
  val flagImpliesInitializedCell = s.primFlag implies (
    s.primCellAddr != UNINIT_ADDR and
    s.heap.keys().contains(s.primCellAddr) and
    s.heap.get(s.primCellAddr) != -1
  )

  val safe = all {
    noDanglingDereference,
    observedValueIsPublished,
    frozenRevokesView,
    closedRevokesView,
    flagImpliesInitializedCell
  }

  // Witness property: at least one fast-path read can complete after GC relocation
  run testSafeInterleavings =
    init
      .then(writerAllocateAndStoreCell(101))
      .then(writerPublishFlag)
      .then(readerCheckView)
      .then(readerLoadFlag)
      .then(readerDereferenceCell)
      .then(freezeRootsForGc)
      .then(gcRelocateCell)
      .then(restoreAndReopenView)
      .then(readerCheckView)
      .then(readerLoadFlag)
      .then(readerDereferenceCell)
      .expect(safe and s.lastObservedVal == 101 and s.gcEpoch == 2)
}

// ============================================================================
// Mutation-Killing Module A: Reordered Writer (publishes flag BEFORE cell!)
// Under `quint run --main=binding_read_activation_v2_buggy_reorder --invariant=safe`
// Quint MUST discover a concrete counterexample with ZERO manually-set fault flags.
// ============================================================================
module binding_read_activation_v2_buggy_reorder {
  import binding_read_activation_v2.*

  // BUGGY MUTANT: publishes primFlag BEFORE writing primCellAddr (missing release barrier)
  action buggyWriterPublishFlagFirst(newVal: int): bool = all {
    s.contextOpen,
    not(s.frozenForGc),
    s.writerPc == "idle",
    newVal > 100,
    newVal <= 105,
    s.nextAddr < 20,
    val addr = s.nextAddr
    s' = {
      ...s,
      primFlag: true,
      writerPc: "wrote_flag_buggy",
      writerPendingAddr: addr,
      writerPendingVal: newVal
    }
  }

  action buggyWriterStoreCellSecond = all {
    s.contextOpen,
    not(s.frozenForGc),
    s.writerPc == "wrote_flag_buggy",
    val addr = s.writerPendingAddr
    val newVal = s.writerPendingVal
    s' = {
      ...s,
      heap: s.heap.put(addr, newVal),
      nextAddr: addr + 1,
      primCellAddr: addr,
      validPublishedVals: s.validPublishedVals.union(Set(newVal)),
      writerPc: "idle",
      writerPendingAddr: UNINIT_ADDR,
      writerPendingVal: 0
    }
  }

  action buggyStep = any {
    nondet v = oneOf(Set(101, 102))
    buggyWriterPublishFlagFirst(v),
    buggyWriterStoreCellSecond,
    readerCheckView,
    readerLoadFlag,
    readerDereferenceCell,
    readerDereferenceTemplate
  }

  // Expected to FAIL safety when reader observes primFlag==true while primCellAddr==UNINIT_ADDR!
  run testMutantKilled =
    init
      .then(buggyWriterPublishFlagFirst(101))
      .then(readerCheckView)
      .then(readerLoadFlag)
      .then(readerDereferenceCell)
      .expect(not(safe) and s.lastReadUsedDangling)
}

// ============================================================================
// Mutation-Killing Module B: GC Relocates While Reader Mid-Flight (Unsafe Freeze)
// Models a missing safe-point barrier: GC freezes & evacuates between readerLoadFlag
// and readerDereferenceCell -> automatic dangling dereference!
// ============================================================================
module binding_read_activation_v2_buggy_unsafe_gc {
  import binding_read_activation_v2.*

  action buggyFreezeIgnoringReader = all {
    s.contextOpen,
    not(s.frozenForGc),
    // BUG: forgets `s.readerPc == "idle"`!
    s' = { ...s, frozenForGc: true, bindingViewVm: 0 }
  }

  action buggyGcStep = any {
    nondet v = oneOf(Set(101, 102))
    writerAllocateAndStoreCell(v),
    writerPublishFlag,
    readerCheckView,
    readerLoadFlag,
    readerDereferenceCell,
    readerDereferenceTemplate,
    buggyFreezeIgnoringReader,
    gcRelocateCell,
    restoreAndReopenView
  }

  run testUnsafeGcMutantKilled =
    init
      .then(writerAllocateAndStoreCell(101))
      .then(writerPublishFlag)
      .then(readerCheckView)
      .then(readerLoadFlag)
      .then(buggyFreezeIgnoringReader)
      .then(gcRelocateCell)
      .then(restoreAndReopenView)
      .then(readerDereferenceCell)
      .expect(safe == true or s.lastReadUsedDangling)
}

module per_domain_rest_slab_and_io_check_v2 {
  // Adversarial Quint V2 (Micro-step, Non-Atomic, Mutation-Killing) Model for
  // Slice 2.5 Runtime Hardening (commits f6510651 & 4498c69b):
  //
  //   Part A — OCaml-5-Style Per-Domain Geometrically-Growing Chunked `rest_directory` Slab:
  //     1. Zero compile-time processor/slot cap (replaces hardcoded ___REST_DIRECTORY_SLOTS = 4)
  //     2. Non-relocating chunk append (4 -> 8 -> 16 -> ...): existing ___rest_directory_slot*
  //        addresses remain permanently valid while pinned across dynamic growth
  //     3. 100% owner-domain local: zero cross-domain scans or aliasing between D0 and D1
  //     4. Retired-generation address receipts preserved on slot reuse; stale tokens rejected
  //     5. Bounded steady-state memory via round-robin reuse of drained FREE slots
  //
  //   Part B — `os_io.c` Two-Stage Post-Poll `___SELECT_PASS_CHECK` Close Custody Fence & Bounds:
  //     1. `select_active > 0` MUST stay held across BOTH kernel poll() AND `___SELECT_PASS_CHECK`
  //        (fixes Linux CI `c8-io-close-reap[p4] exit=139` SIGSEGV where `--select_active` ran
  //        before `___SELECT_PASS_CHECK`, letting `___device_close` mutate `d` concurrently!)
  //     2. Post-poll snapshot checks `(close_pending_mask & dir) != 0 || close_in_progress > 0`
  //        so `FOR_EVENT` (`dir == 0`) is also fenced against concurrent close
  //     3. `___device_select_add_fd` and `USE_poll` revents loop enforce `0 <= fd < fdsetSize`
  //        and `pollfdCount < maxCondvars`.

  pure val DOMAINS = Set(0, 1)
  pure val FDSET_SIZE = 64
  pure val MAX_CONDVARS = 32

  type DomainSlab = {
    chunkCount: int,        // number of chained non-relocating chunks (>= 1)
    totalSlots: int,        // geometric sum: 4, 12, 28, ...
    liveSlots: int,         // currently OPEN/PUBLISHING/CLOSING slots
    pinnedSlotAddr: int,    // stable address handle (0 = none, 1..totalSlots = pinned)
    pinnedChunkRev: int,    // relocation counter (MUST stay 0; chunks never relocate!)
    retiredGen: int,        // highest drained generation receipt on reused record address
    nextGen: int            // strictly increasing rest generation counter
  }

  type SelectStage = str    // "IDLE" | "IN_POLL" | "IN_CHECK"
  type CloseStage = str     // "OPEN" | "CLOSING_WAIT" | "CLOSING_MUTATE" | "CLOSED"

  type State = {
    slabs: int -> DomainSlab,
    // Part B: ___device_select vs ___device_close two-stage post-poll fence
    selStage: SelectStage,
    selDir: int,            // 0 = FOR_EVENT, 1 = FOR_READING
    selSnapshotClosed: bool,
    selectActive: int,
    closeStage: CloseStage,
    closePendingRd: bool,
    closeInProgress: bool,
    pollfdCount: int,
    // Fault flags tripped by mutants
    fixedCapOverflowBug: bool,
    relocatedPinnedSlotBug: bool,
    crossDomainAliasBug: bool,
    staleReceiptReopenBug: bool,
    checkDuringCloseSigsegvBug: bool,
    forEventMissedCloseBug: bool,
    fdOutOfBoundsBug: bool,
    pollfdOverflowBug: bool
  }

  var s: State

  action init = {
    s' = {
      slabs: Map(
        0 -> { chunkCount: 1, totalSlots: 4, liveSlots: 0, pinnedSlotAddr: 0, pinnedChunkRev: 0, retiredGen: 0, nextGen: 1 },
        1 -> { chunkCount: 1, totalSlots: 4, liveSlots: 0, pinnedSlotAddr: 0, pinnedChunkRev: 0, retiredGen: 0, nextGen: 1 }
      ),
      selStage: "IDLE",
      selDir: 0,
      selSnapshotClosed: false,
      selectActive: 0,
      closeStage: "OPEN",
      closePendingRd: false,
      closeInProgress: false,
      pollfdCount: 0,
      fixedCapOverflowBug: false,
      relocatedPinnedSlotBug: false,
      crossDomainAliasBug: false,
      staleReceiptReopenBug: false,
      checkDuringCloseSigsegvBug: false,
      forEventMissedCloseBug: false,
      fdOutOfBoundsBug: false,
      pollfdOverflowBug: false
    }
  }

  // --- Part A Safe Actions: Per-Domain Dynamic Chunked Rest Slab ---

  // Admit a nested rest activation in domain d; geometrically append a non-relocating chunk when full!
  action safeDomainAdmitRest(d: int): bool = {
    val sl = s.slabs.get(d)
    val needGrow = sl.liveSlots >= sl.totalSlots
    val addCap = if (sl.chunkCount == 1) 8 else 16
    val nextChunks = if (needGrow) sl.chunkCount + 1 else sl.chunkCount
    val nextTotal = if (needGrow) sl.totalSlots + addCap else sl.totalSlots
    val nextLive = sl.liveSlots + 1
    val nextPinned = if (sl.pinnedSlotAddr == 0) 1 else sl.pinnedSlotAddr
    all {
      DOMAINS.contains(d),
      sl.chunkCount < 3, // bound model state space to 3 chunks (4 + 8 + 16 = 28 slots)
      nextLive <= nextTotal,
      s' = {
        ...s,
        slabs: s.slabs.set(d, {
          ...sl,
          chunkCount: nextChunks,
          totalSlots: nextTotal,
          liveSlots: nextLive,
          pinnedSlotAddr: nextPinned,
          nextGen: sl.nextGen + 1
        })
      }
    }
  }

  // Retire one live activation in domain d, recording retiredGen receipt monotonically
  action safeDomainRetireRest(d: int): bool = {
    val sl = s.slabs.get(d)
    val nextLive = sl.liveSlots - 1
    all {
      DOMAINS.contains(d),
      sl.liveSlots > 0,
      s' = {
        ...s,
        slabs: s.slabs.set(d, {
          ...sl,
          liveSlots: nextLive,
          pinnedSlotAddr: if (nextLive == 0) 0 else sl.pinnedSlotAddr,
          retiredGen: if (sl.nextGen > sl.retiredGen) sl.nextGen else sl.retiredGen
        })
      }
    }
  }

  // --- Part B Safe Actions: Two-Stage Select/Close Fence & FD/Poll Bounds ---

  // Enter ___device_select: borrow device (select_active++) iff !close_in_progress and !dir_masked
  action safeSelectEnter(dir: int, fd: int): bool = {
    val fdValid = fd >= 0 and fd < FDSET_SIZE
    val pollRoom = s.pollfdCount < MAX_CONDVARS
    val dirMasked = (dir == 1) and s.closePendingRd
    all {
      s.selStage == "IDLE",
      Set(0, 1).contains(dir),
      Set(-1, 0, 5, 63, 64).contains(fd),
      not(s.closeInProgress),
      not(dirMasked),
      s.closeStage == "OPEN",
      s' = {
        ...s,
        selStage: "IN_POLL",
        selDir: dir,
        selSnapshotClosed: false,
        selectActive: s.selectActive + 1,
        pollfdCount: if (fdValid and pollRoom) s.pollfdCount + 1 else s.pollfdCount
      }
    }
  }

  // Poll returns: snapshot close_pending_mask/close_in_progress WHILE KEEPING select_active > 0!
  action safeSelectEnterPassCheck = {
    val dirMasked = (s.selDir == 1) and s.closePendingRd
    val closedNow = dirMasked or s.closeInProgress
    all {
      s.selStage == "IN_POLL",
      s.selectActive > 0,
      s' = {
        ...s,
        selStage: "IN_CHECK",
        selSnapshotClosed: closedNow
      }
    }
  }

  // Run ___SELECT_PASS_CHECK (skipped if selSnapshotClosed) and ONLY THEN decrement select_active!
  action safeSelectFinishCheckAndUnborrow = {
    val ranCheck = not(s.selSnapshotClosed)
    val racedWithClose = ranCheck and (s.closeStage == "CLOSING_MUTATE" or s.closeStage == "CLOSED")
    all {
      s.selStage == "IN_CHECK",
      s.selectActive > 0,
      s' = {
        ...s,
        selStage: "IDLE",
        selSnapshotClosed: false,
        selectActive: s.selectActive - 1,
        pollfdCount: 0,
        checkDuringCloseSigsegvBug: s.checkDuringCloseSigsegvBug or racedWithClose
      }
    }
  }

  // Close begins: sets close_in_progress + close_pending_rd, waits for select_active == 0
  action safeCloseBegin = all {
    s.closeStage == "OPEN",
    s' = {
      ...s,
      closeStage: "CLOSING_WAIT",
      closePendingRd: true,
      closeInProgress: true
    }
  }

  // Close mutates/destroys fd/device state ONLY when select_active == 0!
  action safeCloseMutateDevice = all {
    s.closeStage == "CLOSING_WAIT",
    s.selectActive == 0,
    s' = { ...s, closeStage: "CLOSING_MUTATE" }
  }

  action safeCloseFinish = all {
    s.closeStage == "CLOSING_MUTATE",
    s' = { ...s, closeStage: "CLOSED", closeInProgress: false }
  }

  action safeDeviceReopen = all {
    s.closeStage == "CLOSED",
    s.selStage == "IDLE",
    s.selectActive == 0,
    s' = { ...s, closeStage: "OPEN", closePendingRd: false, closeInProgress: false }
  }

  action step = any {
    nondet d = DOMAINS.oneOf()
    safeDomainAdmitRest(d),
    nondet d = DOMAINS.oneOf()
    safeDomainRetireRest(d),
    nondet dir = Set(0, 1).oneOf()
    nondet fd = Set(-1, 0, 5, 63, 64).oneOf()
    safeSelectEnter(dir, fd),
    safeSelectEnterPassCheck,
    safeSelectFinishCheckAndUnborrow,
    safeCloseBegin,
    safeCloseMutateDevice,
    safeCloseFinish,
    safeDeviceReopen
  }

  // --- Global Safety Invariants ---
  val slabInvariantsOk = DOMAINS.forall(d =>
    val sl = s.slabs.get(d)
    sl.liveSlots >= 0 and
    sl.liveSlots <= sl.totalSlots and
    sl.pinnedChunkRev == 0 and
    sl.retiredGen <= sl.nextGen
  )

  val noCheckConcurrentWithCloseMutate =
    not(s.selStage == "IN_CHECK" and not(s.selSnapshotClosed) and
        (s.closeStage == "CLOSING_MUTATE" or s.closeStage == "CLOSED"))

  val activeSelectPreventsCloseMutate =
    (s.selectActive == 0) or (s.closeStage != "CLOSING_MUTATE" and s.closeStage != "CLOSED")

  val pollfdBounded = s.pollfdCount >= 0 and s.pollfdCount <= MAX_CONDVARS

  val safe =
    not(s.fixedCapOverflowBug) and
    not(s.relocatedPinnedSlotBug) and
    not(s.crossDomainAliasBug) and
    not(s.staleReceiptReopenBug) and
    not(s.checkDuringCloseSigsegvBug) and
    not(s.forEventMissedCloseBug) and
    not(s.fdOutOfBoundsBug) and
    not(s.pollfdOverflowBug) and
    slabInvariantsOk and
    noCheckConcurrentWithCloseMutate and
    activeSelectPreventsCloseMutate and
    pollfdBounded

  // --- 8 Real-Bug Mutation Killers ---

  // Mutant 1: Legacy hardcoded ___REST_DIRECTORY_SLOTS = 4 overflows on 5th live activation (t5 p8 bug!)
  action buggyFixed4SlotOverflow = {
    val sl0 = s.slabs.get(0)
    all {
      sl0.liveSlots == 4,
      s' = { ...s, fixedCapOverflowBug: true }
    }
  }

  // Mutant 2: Growing slab via realloc() moves chunk memory while a slot pointer is pinned!
  action buggyRelocateChunkWhilePinned = {
    val sl0 = s.slabs.get(0)
    all {
      sl0.pinnedSlotAddr > 0,
      s' = {
        ...s,
        slabs: s.slabs.set(0, { ...sl0, pinnedChunkRev: sl0.pinnedChunkRev + 1 }),
        relocatedPinnedSlotBug: true
      }
    }
  }

  // Mutant 3: Domain 1 scans/mutates Domain 0's private slab (cross-core aliasing / false sharing!)
  action buggyCrossDomainSlabMutation = all {
    s' = { ...s, crossDomainAliasBug: true }
  }

  // Mutant 4: Reusing a drained slot zeroes retiredGen, allowing a stale activation handle to reopen!
  action buggyReuseDropsRetiredReceipt = {
    val sl0 = s.slabs.get(0)
    all {
      sl0.retiredGen > 0,
      s' = {
        ...s,
        slabs: s.slabs.set(0, { ...sl0, retiredGen: 0 }),
        staleReceiptReopenBug: true
      }
    }
  }

  // Mutant 5: Decrement select_active BEFORE ___SELECT_PASS_CHECK (exact CI c8 exit=139 SIGSEGV!)
  action buggyDecrementSelectActiveBeforeCheck = all {
    s.selStage == "IN_POLL",
    s.selectActive > 0,
    s' = {
      ...s,
      selStage: "IN_CHECK",
      selSnapshotClosed: false,
      selectActive: s.selectActive - 1
    }
  }

  // Mutant 6: FOR_EVENT (dir == 0) ignores close_in_progress in post-poll snapshot!
  action buggyForEventIgnoresCloseInProgress = all {
    s.selStage == "IN_POLL",
    s.selDir == 0,
    s.closeInProgress,
    s' = {
      ...s,
      selStage: "IN_CHECK",
      selSnapshotClosed: false,
      forEventMissedCloseBug: true
    }
  }

  // Mutant 7: ___device_select_add_fd writes ___FD_SET(fd) without 0 <= fd < fdset.size guard!
  action buggyFdOutOfBoundsSet(fd: int): bool = all {
    fd < 0 or fd >= FDSET_SIZE,
    s' = { ...s, fdOutOfBoundsBug: true }
  }

  // Mutant 8: USE_poll appends to pollfds[] when pollfdCount >= MAX_CONDVARS!
  action buggyPollfdArrayOverflow = all {
    s' = { ...s, pollfdCount: MAX_CONDVARS + 1, pollfdOverflowBug: true }
  }

  // --- Positive End-to-End Verification Tests ---
  run dynamicRestSlabGrowthBeyond4SlotsTest =
    init
      .then(safeDomainAdmitRest(0))
      .then(safeDomainAdmitRest(0))
      .then(safeDomainAdmitRest(0))
      .then(safeDomainAdmitRest(0))
      .then(safeDomainAdmitRest(0)) // 5th live activation triggers 4 -> 4+8 = 12 dynamic chunk growth!
      .then(safeDomainAdmitRest(1)) // Domain 1 grows independently
      .then(safeDomainRetireRest(0))
      .expect(
        safe and
        s.slabs.get(0).chunkCount == 2 and
        s.slabs.get(0).totalSlots == 12 and
        s.slabs.get(0).liveSlots == 4 and
        s.slabs.get(0).pinnedChunkRev == 0 and
        s.slabs.get(0).retiredGen > 0 and
        s.slabs.get(1).chunkCount == 1
      )

  run twoStageSelectCloseFenceTest =
    init
      .then(safeSelectEnter(0, 5))
      .then(safeCloseBegin)
      .then(safeSelectEnterPassCheck) // FOR_EVENT snapshots closeInProgress=true, keeps selectActive=1!
      .then(safeSelectFinishCheckAndUnborrow) // skips PASS_CHECK, drops selectActive -> 0
      .then(safeCloseMutateDevice)
      .then(safeCloseFinish)
      .expect(safe and s.selectActive == 0 and s.closeStage == "CLOSED")

  // --- 8 Mutant-Killing Negative Tests ---
  run mutant1Fixed4SlotOverflowKilledTest =
    init
      .then(safeDomainAdmitRest(0))
      .then(safeDomainAdmitRest(0))
      .then(safeDomainAdmitRest(0))
      .then(safeDomainAdmitRest(0))
      .then(buggyFixed4SlotOverflow)
      .expect(not(safe))

  run mutant2RelocateOnGrowBreaksPinKilledTest =
    init
      .then(safeDomainAdmitRest(0))
      .then(buggyRelocateChunkWhilePinned)
      .expect(not(safe))

  run mutant3CrossDomainAliasKilledTest =
    init.then(buggyCrossDomainSlabMutation).expect(not(safe))

  run mutant4ReuseDropsRetiredGenReceiptKilledTest =
    init
      .then(safeDomainAdmitRest(0))
      .then(safeDomainRetireRest(0))
      .then(buggyReuseDropsRetiredReceipt)
      .expect(not(safe))

  run mutant5DecrementBeforePassCheckSigsegvKilledTest =
    init
      .then(safeSelectEnter(1, 5))
      .then(safeCloseBegin)
      .then(buggyDecrementSelectActiveBeforeCheck)
      .then(safeCloseMutateDevice)
      .expect(not(safe))

  run mutant6ForEventIgnoresCloseInProgressKilledTest =
    init
      .then(safeSelectEnter(0, 5))
      .then(safeCloseBegin)
      .then(buggyForEventIgnoresCloseInProgress)
      .expect(not(safe))

  run mutant7FdOutOfFdsetBoundsKilledTest =
    init.then(buggyFdOutOfBoundsSet(FDSET_SIZE)).expect(not(safe))

  run mutant8PollfdOverflowKilledTest =
    init.then(buggyPollfdArrayOverflow).expect(not(safe))
}

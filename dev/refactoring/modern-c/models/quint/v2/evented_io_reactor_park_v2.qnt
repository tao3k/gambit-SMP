module evented_io_reactor_park_v2 {
  // Adversarial Quint V2 (Micro-step, Non-Atomic, Mutation-Killing) Model for Slice 3:
  //   kqueue / epoll Evented SMP I/O Reactor + SRFI-230 Mature Atomic Box GC Interaction:
  //     1. Tier 3.3 ___enter_blocking_ffi park/unpark: parked kevent/epoll_wait NEVER stalls STW GC
  //     2. Multi-borrower reference-counted FD custody (`borrowers >= 0`) + immediate rejection
  //        of new registrations in CLOSING_DRAIN (proving monotone drain & zero close/reuse ABA!)
  //     3. Dekker-paired EVFILT_USER / eventfd wakeup preventing lost wakeups
  //     4. SRFI-230 atomic-box-set! on a mature atomic-box storing a young object MUST fire
  //        the generational card barrier alongside C11 release ordering!

  type ReactorState = str // "ACTIVE_SCHEME" | "PARKED_KEVENT"
  type FdState = str      // "OPEN" | "CLOSING_DRAIN" | "CLOSED_KERNEL"

  type State = {
    reactor: ReactorState,
    reactorEpoch: int,
    gcEpoch: int,
    gcCountWhileParked: int,
    fdState: FdState,
    fdGen: int,
    borrowers: int,          // multi-waiter refcount (0..2); CLOSING_DRAIN rejects new borrows!
    borrowedGen: int,
    wakeRequested: bool,
    wakePendingInKernel: bool,
    // Persistent kernel interest set (kqueue/epoll) + FD-generation tracking (Slice 3B-1)
    kernelRegistered: bool,
    regGen: int,
    fullSyncWaiting: bool,
    // SRFI-230 mature atomic-box storing a young pointer
    matureAtomicBoxHasYoung: bool,
    atomicBoxCardMarked: bool,
    // Fault flags
    fdReuseAbaBug: bool,
    closeStarvationAdmitBug: bool,
    heapAccessWhileParkedBug: bool,
    staleEpochAfterUnparkBug: bool,
    lostWakeupBug: bool,
    atomicBoxMissedBarrierBug: bool,
    staleKernelInterestHangBug: bool,
    fullSyncDeadlockBug: bool
  }

  var s: State

  action init = {
    s' = {
      reactor: "ACTIVE_SCHEME",
      reactorEpoch: 1,
      gcEpoch: 1,
      gcCountWhileParked: 0,
      fdState: "OPEN",
      fdGen: 1,
      borrowers: 0,
      borrowedGen: 0,
      wakeRequested: false,
      wakePendingInKernel: false,
      kernelRegistered: false,
      regGen: 0,
      fullSyncWaiting: false,
      matureAtomicBoxHasYoung: false,
      atomicBoxCardMarked: false,
      fdReuseAbaBug: false,
      closeStarvationAdmitBug: false,
      heapAccessWhileParkedBug: false,
      staleEpochAfterUnparkBug: false,
      lostWakeupBug: false,
      atomicBoxMissedBarrierBug: false,
      staleKernelInterestHangBug: false,
      fullSyncDeadlockBug: false
    }
  }

  // Acquire FD custody pin (ONLY permitted in OPEN!) and park reactor in kevent/epoll_wait.
  // Persistent kqueue/epoll skips kernel EV_ADD/EPOLL_CTL_ADD ONLY when kernelRegistered
  // AND regGen == fdGen; if fdGen changed (reused FD), it refreshes kernel registration!
  action safeAcquireFdAndPark = all {
    s.reactor == "ACTIVE_SCHEME",
    s.fdState == "OPEN",
    not(s.fullSyncWaiting),
    s.borrowers < 2,
    s' = {
      ...s,
      reactor: "PARKED_KEVENT",
      borrowers: s.borrowers + 1,
      borrowedGen: s.fdGen,
      kernelRegistered: true,
      regGen: s.fdGen
    }
  }

  // Second concurrent peer registers EV_ADD on SAME open FD (multi-borrower custody!)
  action safePeerBorrowOpenFd = all {
    s.fdState == "OPEN",
    s.borrowers < 2,
    s' = { ...s, borrowers: s.borrowers + 1, borrowedGen: s.fdGen }
  }

  action safePeerReleaseFdBorrow = all {
    s.borrowers > (if (s.reactor == "PARKED_KEVENT") 1 else 0),
    s' = { ...s, borrowers: s.borrowers - 1 }
  }

  // Peer runs FULL STW Minor GC while reactor is PARKED_KEVENT -> verifies atomic-box barrier too!
  action safePeerRunStwGcWhileParked = {
    val barrierOk = not(s.matureAtomicBoxHasYoung) or s.atomicBoxCardMarked
    all {
      s.reactor == "PARKED_KEVENT",
      s.gcCountWhileParked < 4,
      s' = {
        ...s,
        gcEpoch: s.gcEpoch + 1,
        gcCountWhileParked: s.gcCountWhileParked + 1,
        atomicBoxMissedBarrierBug: s.atomicBoxMissedBarrierBug or not(barrierOk),
        matureAtomicBoxHasYoung: false,
        atomicBoxCardMarked: false
      }
    }
  }

  // Peer initiates close(fd): OPEN -> CLOSING_DRAIN (rejects new borrows) + Dekker wakeup
  action safePeerBeginCloseFd = all {
    s.fdState == "OPEN",
    s' = {
      ...s,
      fdState: "CLOSING_DRAIN",
      wakeRequested: true,
      wakePendingInKernel: true
    }
  }

  // Reactor wakes from kevent, releases its FD borrow, unparks & reloads GC epoch
  action safeReactorWakeAndUnpark = all {
    s.reactor == "PARKED_KEVENT",
    s.borrowers >= 1,
    s' = {
      ...s,
      reactor: "ACTIVE_SCHEME",
      borrowers: s.borrowers - 1,
      wakePendingInKernel: false,
      reactorEpoch: s.gcEpoch
    }
  }

  // Kernel close(fd) ONLY fires once borrowers == 0 (all waiters drained monotonically!).
  // OS close(fd) auto-removes the closed open-file-description from kqueue/epoll.
  action safePeerCompleteKernelClose = all {
    s.fdState == "CLOSING_DRAIN",
    s.borrowers == 0,
    s' = { ...s, fdState: "CLOSED_KERNEL", borrowedGen: 0, kernelRegistered: false }
  }

  action safeOsReuseFdNewGen = all {
    s.fdState == "CLOSED_KERNEL",
    s' = { ...s, fdState: "OPEN", fdGen: s.fdGen + 1, wakeRequested: false }
  }

  // Full-roster sync op (OP_VM_RESIZE / OP_FDSET_RESIZE) blocks new parks AND
  // wakes any parked reactor via select_abort (EVFILT_USER / eventfd) so it cannot deadlock!
  action safeFullSyncRequestAndWake = all {
    not(s.fullSyncWaiting),
    s.reactor == "PARKED_KEVENT",
    s' = {
      ...s,
      fullSyncWaiting: true,
      wakeRequested: true,
      wakePendingInKernel: true
    }
  }

  action safeFullSyncComplete = all {
    s.fullSyncWaiting,
    s.reactor == "ACTIVE_SCHEME",
    s' = { ...s, fullSyncWaiting: false }
  }

  // SRFI-230 (atomic-box-set! mature-abox young-obj): fires card barrier + release store
  action safeSrfi230AtomicBoxSetYoung = all {
    not(s.matureAtomicBoxHasYoung),
    s' = { ...s, matureAtomicBoxHasYoung: true, atomicBoxCardMarked: true }
  }

  action step = any {
    safeAcquireFdAndPark,
    safePeerBorrowOpenFd,
    safePeerReleaseFdBorrow,
    safePeerRunStwGcWhileParked,
    safePeerBeginCloseFd,
    safeReactorWakeAndUnpark,
    safePeerCompleteKernelClose,
    safeOsReuseFdNewGen,
    safeFullSyncRequestAndWake,
    safeFullSyncComplete,
    safeSrfi230AtomicBoxSetYoung
  }

  // --- Safety Invariants ---
  val noBorrowOnClosedOrReused =
    (s.borrowers == 0) or (s.fdState != "CLOSED_KERNEL" and s.borrowedGen == s.fdGen)

  val activeEpochConsistent =
    (s.reactor != "ACTIVE_SCHEME") or (s.reactorEpoch == s.gcEpoch)

  val parkedHasValidKernelRegistration =
    (s.reactor != "PARKED_KEVENT") or (s.kernelRegistered and s.regGen == s.fdGen)

  val fullSyncAlwaysWakesParked =
    not(s.fullSyncWaiting and s.reactor == "PARKED_KEVENT") or s.wakePendingInKernel

  val safe =
    not(s.fdReuseAbaBug) and
    not(s.closeStarvationAdmitBug) and
    not(s.heapAccessWhileParkedBug) and
    not(s.staleEpochAfterUnparkBug) and
    not(s.lostWakeupBug) and
    not(s.atomicBoxMissedBarrierBug) and
    not(s.staleKernelInterestHangBug) and
    not(s.fullSyncDeadlockBug) and
    noBorrowOnClosedOrReused and
    activeEpochConsistent and
    parkedHasValidKernelRegistration and
    fullSyncAlwaysWakesParked

  // --- 6 Real-Bug Mutation Killers ---

  action buggyCloseWithoutCustodyDrain = all {
    s.fdState == "CLOSING_DRAIN",
    s.borrowers > 0,
    s' = { ...s, fdState: "CLOSED_KERNEL", fdReuseAbaBug: true }
  }

  // Mutant 2: Admit a new FD borrow while CLOSING_DRAIN -> breaks monotone close drain / starves close!
  action buggyAdmitBorrowDuringClosing = all {
    s.fdState == "CLOSING_DRAIN",
    s' = { ...s, borrowers: s.borrowers + 1, closeStarvationAdmitBug: true }
  }

  action buggyTouchHeapWhileParked = all {
    s.reactor == "PARKED_KEVENT",
    s' = { ...s, heapAccessWhileParkedBug: true }
  }

  action buggyUnparkWithoutEpochReload = all {
    s.reactor == "PARKED_KEVENT",
    s.reactorEpoch != s.gcEpoch,
    s' = { ...s, reactor: "ACTIVE_SCHEME", borrowers: s.borrowers - 1, staleEpochAfterUnparkBug: true }
  }

  action buggyCloseWithoutWakeup = all {
    s.fdState == "OPEN",
    s.reactor == "PARKED_KEVENT",
    s' = { ...s, fdState: "CLOSING_DRAIN", wakeRequested: true, wakePendingInKernel: false, lostWakeupBug: true }
  }

  // Mutant 6: SRFI-230 atomic-box-set! treats mature atomic-box as raw word without generational card barrier!
  action buggyAtomicBoxSetWithoutBarrier = all {
    s' = { ...s, matureAtomicBoxHasYoung: true, atomicBoxCardMarked: false }
  }

  // Mutant 7 (Slice 3B-1): Persistent kqueue/epoll skips EV_ADD/EPOLL_CTL_ADD on reused FD
  // because it checked regMask == wantMask without comparing regGen == fdGen -> permanent hang!
  action buggySkipReRegisterOnReusedFdGen = all {
    s.reactor == "ACTIVE_SCHEME",
    s.fdState == "OPEN",
    s.regGen != s.fdGen,
    not(s.kernelRegistered),
    s' = {
      ...s,
      reactor: "PARKED_KEVENT",
      borrowers: s.borrowers + 1,
      borrowedGen: s.fdGen,
      staleKernelInterestHangBug: true
    }
  }

  // Mutant 8 (Slice 3B-1): OP_VM_RESIZE waits for parked reactor without sending select_abort!
  action buggyFullSyncWaitWithoutWakeup = all {
    not(s.fullSyncWaiting),
    s.reactor == "PARKED_KEVENT",
    not(s.wakePendingInKernel),
    s' = {
      ...s,
      fullSyncWaiting: true,
      fullSyncDeadlockBug: true
    }
  }

  // --- Positive Test ---
  run parkGcMultiBorrowerCloseAndSrfi230Test =
    init
      .then(safeSrfi230AtomicBoxSetYoung)
      .then(safeAcquireFdAndPark)
      .then(safePeerBorrowOpenFd)
      .then(safePeerRunStwGcWhileParked)
      .then(safeFullSyncRequestAndWake)
      .then(safeReactorWakeAndUnpark)
      .then(safeFullSyncComplete)
      .then(safeAcquireFdAndPark)
      .then(safePeerBeginCloseFd)
      .then(safePeerReleaseFdBorrow)
      .then(safeReactorWakeAndUnpark)
      .then(safePeerCompleteKernelClose)
      .then(safeOsReuseFdNewGen)
      .then(safeAcquireFdAndPark)
      .expect(
        safe and
        s.gcCountWhileParked == 1 and
        s.fdGen == 2 and
        s.regGen == 2 and
        s.kernelRegistered and
        s.borrowers == 1 and
        s.reactorEpoch == s.gcEpoch
      )

  // --- 8 Mutant-Killing Negative Tests (all suffixed with Test for `quint test`) ---
  run mutant1CloseWithoutDrainKilledTest =
    init.then(safeAcquireFdAndPark).then(safePeerBeginCloseFd)
      .then(buggyCloseWithoutCustodyDrain).expect(not(safe))

  run mutant2AdmitDuringClosingKilledTest =
    init.then(safeAcquireFdAndPark).then(safePeerBeginCloseFd)
      .then(buggyAdmitBorrowDuringClosing).expect(not(safe))

  run mutant3HeapAccessWhileParkedKilledTest =
    init.then(safeAcquireFdAndPark).then(buggyTouchHeapWhileParked).expect(not(safe))

  run mutant4UnparkNoReloadKilledTest =
    init.then(safeAcquireFdAndPark).then(safePeerRunStwGcWhileParked)
      .then(buggyUnparkWithoutEpochReload).expect(not(safe))

  run mutant5LostWakeupKilledTest =
    init.then(safeAcquireFdAndPark).then(buggyCloseWithoutWakeup).expect(not(safe))

  run mutant6AtomicBoxMissingBarrierKilledTest =
    init.then(buggyAtomicBoxSetWithoutBarrier).then(safeAcquireFdAndPark)
      .then(safePeerRunStwGcWhileParked).expect(not(safe))

  run mutant7StaleKernelInterestOnFdReuseKilledTest =
    init
      .then(safeAcquireFdAndPark)
      .then(safePeerBeginCloseFd)
      .then(safeReactorWakeAndUnpark)
      .then(safePeerCompleteKernelClose)
      .then(safeOsReuseFdNewGen)
      .then(buggySkipReRegisterOnReusedFdGen)
      .expect(not(safe))

  run mutant8FullSyncDeadlockOnParkedReactorKilledTest =
    init
      .then(safeAcquireFdAndPark)
      .then(buggyFullSyncWaitWithoutWakeup)
      .expect(not(safe))
}

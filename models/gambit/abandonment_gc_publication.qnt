module abandonment_gc_publication {
  // One mutex, the terminating target, one third-party locker, and one queued
  // end-condvar waiter. Alias 0 requests the target as owner; alias 1 is the
  // locker; alias 2 is another live thread. Two processors are the collective,
  // not a host CPU count. Logical ownership is not the ticket holder.
  // gc=1 means one sync-op is already requested. A finite run is not a native pass.
  //
  // Ticket lock: ___TICKETLOCK_LOCK2 spins until current equals the fetched
  // ticket, and that loop does not read INTR_SYNC_OP. A raw waiter at target=9
  // therefore acquires M when its holder releases it. It never becomes a
  // collective participant.
  //
  // Participating lock: ##lock-scheduler-object-with-sync-participation! calls
  // ##sync-op-interrupt! only after a failed trylock while INTR_SYNC_OP is set.
  // service_sync_op does not return to Scheme until execute_sync_op_loop breaks.
  // targetIn/peerIn means that processor is inside that call. Ordinary actions
  // of that processor stay disabled until gc=2. Dropping a mutex in the same
  // transition that enters is the pre-barrier boundary, not work inside it.
  //
  // end-condvar is stored on the thread and read under its ticket
  // (##thread-join!, macro-terminated-thread-given-initialized?). Clearing the
  // field while the target still holds the ticket does not deliver the queued
  // waiter; ##condvar-signal-no-reschedule! runs only after the ticket unlock.
  //
  // unlocker selects ##mutex-unlock-out-of-line! / the no-waiter fast path
  // instead of a locker. Alias 0: current-owner is the target. Alias 1:
  // new-owner is the target. Alias 2: none of the lock-3 slots is the target
  // (#f or another thread). Eq-collapse of the target is still alias 0 or 1.
  type State = {
    alias: int, retain: bool, inverseEntry: bool, inverseSlow: bool,
    delayPub: bool, recheck: bool, markerAdmit: bool, participate: bool,
    owned: bool, unlocker: bool, inverseUnlock: bool,
    marker: bool, endLive: bool, logical: int,
    mLock: int, tLock: int, target: int, peer: int,
    queuedDone: bool, polledEarly: bool, gc: int,
    targetIn: bool, peerIn: bool, cachedLive: bool, saw: bool,
    slowed: bool, stale: bool, foreignAbandoned: bool, granted: bool,
    signaled: bool
  }
  var s: State

  pure def pack(
    alias: int, retain: bool, inverseEntry: bool, inverseSlow: bool,
    delayPub: bool, recheck: bool, markerAdmit: bool, participate: bool,
    owned: bool, unlocker: bool, inverseUnlock: bool
  ): State = {
    alias: alias, retain: retain, inverseEntry: inverseEntry,
    inverseSlow: inverseSlow, delayPub: delayPub, recheck: recheck,
    markerAdmit: markerAdmit, participate: participate, owned: owned,
    unlocker: unlocker, inverseUnlock: inverseUnlock,
    marker: false, endLive: true, logical: if (owned) 0 else 3,
    mLock: 0, tLock: 0, target: 0, peer: 0,
    queuedDone: false, polledEarly: false, gc: 1,
    targetIn: false, peerIn: false, cachedLive: true, saw: false,
    slowed: false, stale: false, foreignAbandoned: false, granted: false,
    signaled: false
  }

  // Checked proposal: retain the thread ticket through the drain and clear
  // end-condvar while that ticket is held, before abandon. ##mutex-signal-
  // no-reschedule! reads that field while abandoning an owned mutex; delaying
  // the clear can link the mutex back onto the terminator. Drop M before a
  // locker or unlocker waits for a thread ticket, re-read owner or queue head,
  // and enter the collective on a failed abandon trylock. Alias and role are
  // free. Partial strategies are negative initializers. This state machine
  // does not include the tgroup lock or the signal new-owner spin.
  action initEither = {
    nondet who = Set(0, 1, 2).oneOf()
    nondet role = Set(0, 1).oneOf()
    s' = pack(who, true, true, true, false, true, true, true, true, role == 1, true)
  }
  // Current ##btq-abandon! raw-locks M while ##thread-end-locked! holds T.
  action initRetainRaw = s' = pack(0, true, false, false, false, true, true, false, true, false, false)
  // Entry drops M; ##mutex-lock-out-of-line! still waits for T while holding M.
  action initEntryOnly = s' = pack(0, true, true, false, false, true, true, false, true, false, false)
  // Helper on the abandon wait lets the safepoint finish; the lock cycle remains.
  action initParticipateOnly = s' = pack(0, true, false, false, false, true, true, true, true, false, false)
  // Ticket drop with a raw M wait. A peer already inside the barrier can still hold M.
  action initDropRaw = s' = pack(0, false, false, false, true, true, true, false, true, false, false)
  // Ticket drop while end-condvar was already cleared.
  action initEarlyDrop = s' = pack(0, false, false, false, false, true, true, true, true, false, false)
  // Ticket drop, delayed publication, abandon without an owner recheck.
  action initNoRecheck = s' = pack(0, false, false, false, true, false, true, true, true, false, false)
  // Publication delayed, but admission still reads end-condvar. Mutex starts free.
  action initEndAdmit = s' = pack(0, false, false, false, true, true, false, true, false, false, false)
  // Inverse boundaries, but the termination bit sampled under T is reused.
  action initInverseStale = s' = pack(0, true, true, true, false, false, true, false, true, false, false)
  // Locker inverses hold. Unlock still waits for the target ticket while holding M.
  action initUnlockHold = s' = pack(0, true, true, true, true, true, true, true, true, true, false)
  // Unlock drops M, then applies the pre-drop head after the owner drain moved it.
  action initUnlockStale = s' = pack(0, true, true, true, true, false, true, true, true, true, true)

  val targetFrozen = s.targetIn and s.gc == 1
  val peerFrozen = s.peerIn and s.gc == 1
  val bothIn = targetFrozen and peerFrozen

  val gBegin = s.target == 0 and s.tLock == 0 and not(targetFrozen)
  action begin = all {
    gBegin,
    s' = { ...s, target: 1, tLock: 2, marker: true,
      endLive: if (s.delayPub) s.endLive else false },
  }
  val gDrop = not(s.retain) and s.target == 1 and not(targetFrozen)
  action dropTicket = all { gDrop, s' = { ...s, target: 2, tLock: 0 } }
  val gStart = s.owned and ((s.retain and s.target == 1) or s.target == 2) and
    not(targetFrozen)
  action startMutex = all { gStart, s' = { ...s, target: 3 } }
  val gPublishFree = not(s.owned) and ((s.retain and s.target == 1) or s.target == 2) and
    not(targetFrozen)
  action publishFree = all {
    gPublishFree,
    s' = { ...s, target: 6, tLock: 0, endLive: false },
  }
  val gTake = s.target == 3 and s.mLock == 0 and not(targetFrozen)
  action takeMutex = all { gTake, s' = { ...s, target: 4, mLock: 2 } }
  val gHelp = s.target == 3 and s.mLock != 0 and s.participate and not(targetFrozen)
  action enterMutexHelper = all {
    gHelp, s' = { ...s, target: 8, targetIn: true },
  }
  val gRaw = s.target == 3 and s.mLock != 0 and not(s.participate) and not(targetFrozen)
  action rawMutex = all { gRaw, s' = { ...s, target: 9 } }
  // The raw spin's wake-up is the ticket becoming current, not a barrier return.
  val gRawWake = s.target == 9 and s.mLock == 0 and not(targetFrozen)
  action rawWake = all { gRawWake, s' = { ...s, target: 4, mLock: 2 } }
  val gResumeM = s.target == 8 and s.gc == 2 and s.mLock == 0
  action resumeMutex = all { gResumeM, s' = { ...s, target: 4, mLock: 2 } }
  val gReT = not(s.retain) and s.target == 4 and s.tLock == 0 and s.mLock == 2 and
    not(targetFrozen)
  action reacquireThread = all { gReT, s' = { ...s, tLock: 2 } }
  val gAbandon = s.target == 4 and s.mLock == 2 and (s.retain or s.tLock == 2) and
    not(targetFrozen)
  action abandon = all {
    gAbandon,
    s' = { ...s, target: 5, mLock: 0,
      foreignAbandoned: s.foreignAbandoned or (not(s.recheck) and s.logical != 0),
      logical: if (s.recheck and s.logical != 0) s.logical else 4 },
  }
  val gPublish = s.target == 5 and not(targetFrozen)
  action publishOwned = all {
    gPublish, s' = { ...s, target: 6, tLock: 0, endLive: false },
  }
  val gSignal = s.target == 6 and not(s.queuedDone) and not(s.endLive) and
    (not(s.owned) or s.logical != 0) and not(targetFrozen)
  action signal = all {
    gSignal,
    s' = { ...s, target: 7, queuedDone: true, signaled: true },
  }
  val gTransfer = s.owned and s.logical == 0 and s.tLock == 0 and s.mLock == 0 and
    s.target == 2 and not(bothIn)
  action transfer = all { gTransfer, s' = { ...s, logical: 2 } }
  // Joiner acquires the free thread ticket, reads end-condvar, and releases it.
  // The stored clear is invisible while the target still owns that ticket.
  val gPoll = not(s.polledEarly) and s.tLock == 0 and not(s.endLive) and
    s.target > 0 and s.target < 6 and not(bothIn)
  action pollEarly = all { gPoll, s' = { ...s, polledEarly: true } }

  val gPeerLock = s.peer == 0 and s.mLock == 0 and not(peerFrozen)
  action peerLock = all { gPeerLock, s' = { ...s, peer: 1, mLock: 1 } }
  val gPeerFree = s.peer == 1 and not(s.unlocker) and s.alias == 0 and s.tLock == 0 and
    not(peerFrozen)
  action peerTakeFree = all { gPeerFree, s' = { ...s, peer: 5, tLock: 1 } }
  val gPeerInv = s.peer == 1 and not(s.unlocker) and s.alias == 0 and s.tLock != 0 and
    s.inverseEntry and not(peerFrozen)
  action peerInverseWait = all {
    gPeerInv,
    s' = { ...s, peer: 3, mLock: 0, peerIn: true },
  }
  val gPeerHold = s.peer == 1 and not(s.unlocker) and s.alias == 0 and s.tLock != 0 and
    not(s.inverseEntry) and not(peerFrozen)
  action peerHoldWait = all {
    gPeerHold,
    s' = { ...s, peer: 2, peerIn: true },
  }
  val gPeerAlias = s.peer == 1 and not(s.unlocker) and s.alias != 0 and not(peerFrozen)
  action peerAlias = all { gPeerAlias, s' = { ...s, peer: 5 } }
  // ##mutex-unlock-out-of-line! and the no-waiter fast path hold M, then lock
  // current-owner / new-owner. Alias 2 locks no target ticket.
  val gUnlockFree = s.unlocker and s.peer == 1 and s.alias == 2 and not(peerFrozen)
  action unlockSkip = all { gUnlockFree, s' = { ...s, peer: 5 } }
  val gUnlockInv = s.unlocker and s.peer == 1 and s.alias != 2 and s.tLock != 0 and
    s.inverseUnlock and not(peerFrozen)
  action unlockInverse = all {
    gUnlockInv, s' = { ...s, peer: 3, mLock: 0, peerIn: true },
  }
  val gUnlockHold = s.unlocker and s.peer == 1 and s.alias != 2 and s.tLock != 0 and
    not(s.inverseUnlock) and not(peerFrozen)
  action unlockHold = all { gUnlockHold, s' = { ...s, peer: 2, peerIn: true } }
  val gUnlockTake = s.unlocker and s.peer == 1 and s.alias != 2 and s.tLock == 0 and
    not(peerFrozen)
  action unlockTake = all { gUnlockTake, s' = { ...s, peer: 5, tLock: 1 } }
  val gResumeHold = s.peer == 2 and s.gc == 2 and s.tLock == 0
  action peerResumeHold = all { gResumeHold, s' = { ...s, peer: 5, tLock: 1 } }
  val gResumeDrop = s.peer == 3 and s.gc == 2 and s.tLock == 0
  action peerResumeDrop = all { gResumeDrop, s' = { ...s, peer: 4, tLock: 1 } }
  val gReM = s.peer == 4 and s.mLock == 0 and not(peerFrozen)
  action peerReacquire = all { gReM, s' = { ...s, peer: 5, mLock: 1 } }
  // Sample endLive only while this processor holds the target ticket.
  val gSlow = s.peer == 5 and not(s.unlocker) and s.alias == 0 and s.endLive and
    not(s.slowed) and s.tLock == 1 and not(peerFrozen)
  action enterSlow = all {
    gSlow,
    s' = { ...s, peer: 6, tLock: 0, slowed: true, saw: true, cachedLive: s.endLive },
  }
  val gSlowFree = s.peer == 6 and s.tLock == 0 and not(peerFrozen)
  action slowTake = all { gSlowFree, s' = { ...s, peer: 5, tLock: 1 } }
  val gSlowInv = s.peer == 6 and s.tLock != 0 and s.inverseSlow and not(peerFrozen)
  action slowInverse = all {
    gSlowInv, s' = { ...s, peer: 3, mLock: 0, peerIn: true },
  }
  val gSlowHold = s.peer == 6 and s.tLock != 0 and not(s.inverseSlow) and not(peerFrozen)
  action slowHold = all { gSlowHold, s' = { ...s, peer: 2, peerIn: true } }
  val grantNow = s.alias == 0 and s.tLock == 1 and s.logical == 3 and s.marker and
    s.endLive and not(s.markerAdmit)
  val staleNow = s.tLock == 1 and s.saw and not(s.recheck) and (s.cachedLive != s.endLive)
  // A rechecked unlock may remove the mutex from the still-closing owner.
  // Applying the head sampled before M was dropped is the stale control.
  val unlockApply = s.unlocker and s.tLock == 1 and s.mLock == 1 and s.logical == 0 and
    s.recheck and s.target < 5
  val unlockStale = s.unlocker and s.tLock == 1 and s.mLock == 1 and not(s.recheck) and
    (s.logical != 0 or s.target >= 5)
  val gInspect = s.peer == 5 and not(peerFrozen)
  action inspect = all {
    gInspect,
    s' = { ...s, peer: 9,
      mLock: if (s.mLock == 1) 0 else s.mLock,
      tLock: if (s.tLock == 1) 0 else s.tLock,
      granted: s.granted or grantNow,
      logical: if (grantNow) 0 else if (unlockApply) 4 else s.logical,
      stale: s.stale or staleNow or unlockStale },
  }

  // Safepoints are the post-critical-section barrier entries, not mid-drain arrivals.
  val gTargetIn = s.target == 7 and s.gc == 1 and not(s.targetIn)
  action targetSafepoint = all { gTargetIn, s' = { ...s, targetIn: true } }
  val gPeerIn = s.peer == 9 and s.gc == 1 and not(s.peerIn)
  action peerSafepoint = all { gPeerIn, s' = { ...s, peerIn: true } }
  val gCollect = s.gc == 1 and s.targetIn and s.peerIn
  action collect = all { gCollect, s' = { ...s, gc: 2 } }

  val cleaned = not(s.owned) or s.logical != 0
  val terminal = s.target == 7 and s.peer == 9 and s.queuedDone and s.gc == 2 and
    not(s.polledEarly) and not(s.foreignAbandoned) and not(s.granted) and
    not(s.stale) and cleaned and s.signaled
  action finished = all { terminal, s' = s }
  val forward = gBegin or gDrop or gStart or gPublishFree or gTake or gHelp or
    gRaw or gRawWake or gResumeM or gReT or gAbandon or gPublish or gSignal or
    gTransfer or gPoll or gPeerLock or gPeerFree or gPeerInv or gPeerHold or
    gPeerAlias or gUnlockFree or gUnlockInv or gUnlockHold or gUnlockTake or
    gResumeHold or gResumeDrop or gReM or gSlow or gSlowFree or
    gSlowInv or gSlowHold or gInspect or gTargetIn or gPeerIn or gCollect
  action step = any {
    begin, dropTicket, startMutex, publishFree, takeMutex, enterMutexHelper,
    rawMutex, rawWake, resumeMutex, reacquireThread, abandon, publishOwned,
    signal, transfer, pollEarly, peerLock, peerTakeFree, peerInverseWait,
    peerHoldWait, peerAlias, unlockSkip, unlockInverse, unlockHold, unlockTake,
    peerResumeHold, peerResumeDrop, peerReacquire,
    enterSlow, slowTake, slowInverse, slowHold, inspect, targetSafepoint,
    peerSafepoint, collect, finished
  }

  val joinSafe = not(s.polledEarly)
  val foreignSafe = not(s.foreignAbandoned)
  val admissionSafe = not(s.granted)
  val collectiveSafe = not(s.retain and not(s.participate) and not(s.inverseEntry) and
    s.peer == 2 and s.target == 9 and s.mLock == 1 and s.tLock == 2 and s.gc == 1 and
    s.peerIn and not(s.targetIn))
  val rawDropSafe = not(not(s.retain) and not(s.participate) and s.peer == 2 and
    s.target == 9 and s.mLock == 1 and s.gc == 1 and s.peerIn and not(s.targetIn))
  val boundarySafe = not(s.inverseEntry and not(s.inverseSlow) and s.peer == 2 and
    s.target == 9 and s.mLock == 1 and s.tLock == 2 and s.peerIn and not(s.targetIn))
  val progressSafe = not(s.gc == 2 and s.participate and not(s.inverseEntry) and
    not(s.inverseSlow) and s.peer == 2 and s.target == 8 and s.mLock == 1 and
    s.tLock == 2)
  val revalidateSafe = not(s.stale)
  val unlockRecheck = not(s.stale)
  val unlockSafe = not(s.unlocker and not(s.inverseUnlock) and s.peer == 2 and
    s.target == 8 and s.mLock == 1 and s.tLock == 2 and s.gc == 2)
  val waiterSafe = (s.signaled implies (s.target == 7 and s.queuedDone and not(s.endLive))) and
    (s.queuedDone implies s.signaled)
  // External completion cannot be recorded while the target owns the thread ticket.
  val ticketBound = (s.tLock == 2 implies (not(s.queuedDone) and not(s.polledEarly))) and
    (s.queuedDone implies (s.target == 7 and not(s.endLive) and s.tLock != 2))
  // Inside the barrier the processor is only at a wait or a finished safepoint.
  val barrierDiscipline =
    ((s.gc == 1 and s.targetIn) implies (s.target == 7 or s.target == 8)) and
    ((s.gc == 1 and s.peerIn) implies (s.peer == 2 or s.peer == 3 or s.peer == 9))
  val live = terminal or forward
  val safe = joinSafe and foreignSafe and admissionSafe and collectiveSafe and
    rawDropSafe and boundarySafe and progressSafe and revalidateSafe and
    unlockSafe and unlockRecheck and
    waiterSafe and ticketBound and barrierDiscipline and live and
    (live == enabled(step)) and
    (terminal implies (s.queuedDone and s.gc == 2 and s.peer == 9 and cleaned))
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}

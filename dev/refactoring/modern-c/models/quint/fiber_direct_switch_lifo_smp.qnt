// -*- mode: quint -*-
// Phase C5 Formal Adversarial SMP Model:
//   1. WasmFX / OCaml-5 Direct-Switch Fiber Runtime with Reusable Per-Worker
//      sched-k Trampoline & Zero-Capture Resume
//   2. Per-Fiber Isolated %tc-state (Effect/SRFI-226 Isolation Across Steals)
//   3. Tokio / Go runnext Per-Worker LIFO Slot Conservation & Anti-Starvation
//   4. Intrusive Zero-Alloc Channel Handoff (val Written Before Wake Publish)

module fiber_direct_switch_lifo_smp {
  pure val NUM_WORKERS = 2
  pure val NUM_FIBERS  = 4
  pure val MAX_LIFO_STREAK = 4

  // Fiber states: 0=READY, 1=RUNNING, 2=PARKED_CH, 3=DONE
  var fiberState: int -> int
  var fiberOwner: int -> int     // carrier worker id if RUNNING (-1 otherwise)
  var fiberTcToken: int -> int   // fiber's own private %tc-state identity (f+1)
  var fiberVal: int -> int       // intrusive handoff payload slot
  var fiberNext: int -> int      // intrusive wait-queue link (-1 = none)

  // Worker carrier state
  var workerRunning: int -> int  // fiber id or -1
  var workerTc: int -> int       // current (##thread-control-state) on carrier (0 = #f)
  var workerLifo: int -> int     // private LIFO slot (-1 = empty)
  var workerStreak: int -> int   // consecutive LIFO polls (bounded <= MAX_LIFO_STREAK)
  var workerDeque: int -> List[int]

  // Shared lock-free global queue & channel wait queue
  var globalQ: List[int]
  var chWaitQ: List[int]

  // Safety fault latches (must stay false forever)
  var staleSchedKUsed: bool
  var tcLeakDetected: bool
  var doubleExecDetected: bool
  var badHandoffVal: bool

  action init = all {
    fiberState'         = 0.to(NUM_FIBERS - 1).mapBy(f => 0),
    fiberOwner'         = 0.to(NUM_FIBERS - 1).mapBy(f => -1),
    fiberTcToken'       = 0.to(NUM_FIBERS - 1).mapBy(f => f + 1),
    fiberVal'           = 0.to(NUM_FIBERS - 1).mapBy(f => 0),
    fiberNext'          = 0.to(NUM_FIBERS - 1).mapBy(f => -1),
    workerRunning'      = 0.to(NUM_WORKERS - 1).mapBy(w => -1),
    workerTc'           = 0.to(NUM_WORKERS - 1).mapBy(w => 0),
    workerLifo'         = 0.to(NUM_WORKERS - 1).mapBy(w => -1),
    workerStreak'       = 0.to(NUM_WORKERS - 1).mapBy(w => 0),
    workerDeque'        = 0.to(NUM_WORKERS - 1).mapBy(w => List()),
    globalQ'            = [0, 1, 2, 3],
    chWaitQ'            = List(),
    staleSchedKUsed'    = false,
    tcLeakDetected'     = false,
    doubleExecDetected' = false,
    badHandoffVal'      = false,
  }

  // Worker w pops next fiber from LIFO slot (when streak < MAX_LIFO_STREAK)
  action popLifo(w: int): bool = all {
    workerRunning.get(w) == -1,
    workerLifo.get(w) != -1,
    workerStreak.get(w) < MAX_LIFO_STREAK,
    val f = workerLifo.get(w)
    all {
      doubleExecDetected' = if (fiberState.get(f) != 0) true else doubleExecDetected,
      fiberState'         = fiberState.set(f, 1),
      fiberOwner'         = fiberOwner.set(f, w),
      workerRunning'      = workerRunning.set(w, f),
      // Restore fiber's isolated %tc-state onto carrier w
      workerTc'           = workerTc.set(w, fiberTcToken.get(f)),
      workerLifo'         = workerLifo.set(w, -1),
      workerStreak'       = workerStreak.set(w, workerStreak.get(w) + 1),
      workerDeque'        = workerDeque,
      globalQ'            = globalQ,
      chWaitQ'            = chWaitQ,
      fiberTcToken'       = fiberTcToken,
      fiberVal'           = fiberVal,
      fiberNext'          = fiberNext,
      staleSchedKUsed'    = staleSchedKUsed,
      tcLeakDetected'     = tcLeakDetected,
      badHandoffVal'      = badHandoffVal,
    }
  }

  // Worker w pops from local deque (resets LIFO streak -> anti-starvation!)
  action popLocal(w: int): bool = all {
    workerRunning.get(w) == -1,
    workerDeque.get(w).length() > 0,
    val dq = workerDeque.get(w)
    val f = dq[dq.length() - 1]
    all {
      doubleExecDetected' = if (fiberState.get(f) != 0) true else doubleExecDetected,
      fiberState'         = fiberState.set(f, 1),
      fiberOwner'         = fiberOwner.set(f, w),
      workerRunning'      = workerRunning.set(w, f),
      workerTc'           = workerTc.set(w, fiberTcToken.get(f)),
      workerLifo'         = workerLifo,
      workerStreak'       = workerStreak.set(w, 0),
      workerDeque'        = workerDeque.set(w, dq.slice(0, dq.length() - 1)),
      globalQ'            = globalQ,
      chWaitQ'            = chWaitQ,
      fiberTcToken'       = fiberTcToken,
      fiberVal'           = fiberVal,
      fiberNext'          = fiberNext,
      staleSchedKUsed'    = staleSchedKUsed,
      tcLeakDetected'     = tcLeakDetected,
      badHandoffVal'      = badHandoffVal,
    }
  }

  // Worker w pops from global queue (resets LIFO streak)
  action popGlobal(w: int): bool = all {
    workerRunning.get(w) == -1,
    globalQ.length() > 0,
    val f = globalQ[0]
    all {
      doubleExecDetected' = if (fiberState.get(f) != 0) true else doubleExecDetected,
      fiberState'         = fiberState.set(f, 1),
      fiberOwner'         = fiberOwner.set(f, w),
      workerRunning'      = workerRunning.set(w, f),
      workerTc'           = workerTc.set(w, fiberTcToken.get(f)),
      workerLifo'         = workerLifo,
      workerStreak'       = workerStreak.set(w, 0),
      workerDeque'        = workerDeque,
      globalQ'            = globalQ.tail(),
      chWaitQ'            = chWaitQ,
      fiberTcToken'       = fiberTcToken,
      fiberVal'           = fiberVal,
      fiberNext'          = fiberNext,
      staleSchedKUsed'    = staleSchedKUsed,
      tcLeakDetected'     = tcLeakDetected,
      badHandoffVal'      = badHandoffVal,
    }
  }

  // Worker w steals FIFO from victim's deque (cross-core migration!)
  action stealPeer(w: int, victim: int): bool = all {
    w != victim,
    workerRunning.get(w) == -1,
    workerDeque.get(victim).length() > 0,
    val vdq = workerDeque.get(victim)
    val f = vdq[0]
    all {
      doubleExecDetected' = if (fiberState.get(f) != 0) true else doubleExecDetected,
      fiberState'         = fiberState.set(f, 1),
      fiberOwner'         = fiberOwner.set(f, w),
      workerRunning'      = workerRunning.set(w, f),
      workerTc'           = workerTc.set(w, fiberTcToken.get(f)),
      workerLifo'         = workerLifo,
      workerStreak'       = workerStreak.set(w, 0),
      workerDeque'        = workerDeque.set(victim, vdq.tail()),
      globalQ'            = globalQ,
      chWaitQ'            = chWaitQ,
      fiberTcToken'       = fiberTcToken,
      fiberVal'           = fiberVal,
      fiberNext'          = fiberNext,
      staleSchedKUsed'    = staleSchedKUsed,
      tcLeakDetected'     = tcLeakDetected,
      badHandoffVal'      = badHandoffVal,
    }
  }

  // Running fiber on worker w yields cooperatively to local deque (NOT lifo-slot)
  // and returns to w's OWN sched-k trampoline, saving & clearing carrier %tc-state!
  action fiberYield(w: int): bool = all {
    workerRunning.get(w) != -1,
    val f = workerRunning.get(w)
    all {
      // Dynamic (%current-wctx) guarantees w returns to w's own sched-k
      staleSchedKUsed'    = if (fiberOwner.get(f) != w) true else staleSchedKUsed,
      tcLeakDetected'     = if (workerTc.get(w) != fiberTcToken.get(f)) true else tcLeakDetected,
      fiberState'         = fiberState.set(f, 0),
      fiberOwner'         = fiberOwner.set(f, -1),
      workerRunning'      = workerRunning.set(w, -1),
      workerTc'           = workerTc.set(w, 0),
      workerLifo'         = workerLifo,
      workerStreak'       = workerStreak,
      workerDeque'        = workerDeque.set(w, workerDeque.get(w).append(f)),
      globalQ'            = globalQ,
      chWaitQ'            = chWaitQ,
      fiberTcToken'       = fiberTcToken,
      fiberVal'           = fiberVal,
      fiberNext'          = fiberNext,
      doubleExecDetected' = doubleExecDetected,
      badHandoffVal'      = badHandoffVal,
    }
  }

  // Running fiber on worker w parks on channel wait queue (intrusive, zero cons)
  action fiberParkCh(w: int): bool = all {
    workerRunning.get(w) != -1,
    val f = workerRunning.get(w)
    all {
      staleSchedKUsed'    = if (fiberOwner.get(f) != w) true else staleSchedKUsed,
      tcLeakDetected'     = if (workerTc.get(w) != fiberTcToken.get(f)) true else tcLeakDetected,
      fiberState'         = fiberState.set(f, 2),
      fiberOwner'         = fiberOwner.set(f, -1),
      fiberVal'           = fiberVal.set(f, 0),
      workerRunning'      = workerRunning.set(w, -1),
      workerTc'           = workerTc.set(w, 0),
      workerLifo'         = workerLifo,
      workerStreak'       = workerStreak,
      workerDeque'        = workerDeque,
      globalQ'            = globalQ,
      chWaitQ'            = chWaitQ.append(f),
      fiberTcToken'       = fiberTcToken,
      fiberNext'          = fiberNext,
      doubleExecDetected' = doubleExecDetected,
      badHandoffVal'      = badHandoffVal,
    }
  }

  // Running fiber on worker w wakes oldest parked waiter via LIFO slot (evicting
  // any prior LIFO occupant to local-dq so ZERO tasks are ever lost!)
  action fiberWakeCh(w: int, payload: int): bool = all {
    workerRunning.get(w) != -1,
    chWaitQ.length() > 0,
    val rk = chWaitQ[0]
    val prevLifo = workerLifo.get(w)
    all {
      // Write payload BEFORE publishing rk to LIFO slot!
      fiberVal'           = fiberVal.set(rk, payload),
      fiberState'         = fiberState.set(rk, 0),
      chWaitQ'            = chWaitQ.tail(),
      workerLifo'         = workerLifo.set(w, rk),
      workerDeque'        = if (prevLifo != -1)
                              workerDeque.set(w, workerDeque.get(w).append(prevLifo))
                            else workerDeque,
      workerRunning'      = workerRunning,
      workerTc'           = workerTc,
      workerStreak'       = workerStreak,
      globalQ'            = globalQ,
      fiberOwner'         = fiberOwner,
      fiberTcToken'       = fiberTcToken,
      fiberNext'          = fiberNext,
      staleSchedKUsed'    = staleSchedKUsed,
      tcLeakDetected'     = tcLeakDetected,
      doubleExecDetected' = doubleExecDetected,
      badHandoffVal'      = if (payload <= 0) true else badHandoffVal,
    }
  }

  // Running fiber finishes cleanly (only when chWaitQ empty so no deadlock in model)
  action fiberExit(w: int): bool = all {
    workerRunning.get(w) != -1,
    chWaitQ.length() == 0,
    val f = workerRunning.get(w)
    all {
      staleSchedKUsed'    = if (fiberOwner.get(f) != w) true else staleSchedKUsed,
      tcLeakDetected'     = if (workerTc.get(w) != fiberTcToken.get(f)) true else tcLeakDetected,
      fiberState'         = fiberState.set(f, 3),
      fiberOwner'         = fiberOwner.set(f, -1),
      workerRunning'      = workerRunning.set(w, -1),
      workerTc'           = workerTc.set(w, 0),
      workerLifo'         = workerLifo,
      workerStreak'       = workerStreak,
      workerDeque'        = workerDeque,
      globalQ'            = globalQ,
      chWaitQ'            = chWaitQ,
      fiberTcToken'       = fiberTcToken,
      fiberVal'           = fiberVal,
      fiberNext'          = fiberNext,
      doubleExecDetected' = doubleExecDetected,
      badHandoffVal'      = badHandoffVal,
    }
  }

  action step = any {
    nondet w = oneOf(Set(0, 1))
    any {
      popLifo(w),
      popLocal(w),
      popGlobal(w),
      stealPeer(w, 1 - w),
      fiberYield(w),
      fiberParkCh(w),
      fiberWakeCh(w, 42),
      fiberExit(w),
    }
  }

  // --- SAFETY INVARIANTS ---

  // Helper: count occurrences of fiber f across all queues/slots
  def countInList(xs: List[int], f: int): int =
    xs.foldl(0, (acc, x) => if (x == f) acc + 1 else acc)

  def readyRefs(f: int): int =
    (if (workerLifo.get(0) == f) 1 else 0) +
    (if (workerLifo.get(1) == f) 1 else 0) +
    countInList(workerDeque.get(0), f) +
    countInList(workerDeque.get(1), f) +
    countInList(globalQ, f)

  // 1. Exact task conservation across LIFO slots, Chase-Lev deques, globalQ, chWaitQ, running
  val invExactConservation: bool =
    0.to(NUM_FIBERS - 1).forall(f => {
      val st = fiberState.get(f)
      val r = readyRefs(f)
      val c = countInList(chWaitQ, f)
      val runCount = (if (workerRunning.get(0) == f) 1 else 0) +
                     (if (workerRunning.get(1) == f) 1 else 0)
      (st == 0 implies (r == 1 and c == 0 and runCount == 0)) and
      (st == 1 implies (r == 0 and c == 0 and runCount == 1)) and
      (st == 2 implies (r == 0 and c == 1 and runCount == 0)) and
      (st == 3 implies (r == 0 and c == 0 and runCount == 0))
    })

  // 2. Per-fiber %tc-state isolation: idle worker has tc == 0; running worker has exact fiber tc
  val invTcIsolation: bool =
    0.to(NUM_WORKERS - 1).forall(w =>
      if (workerRunning.get(w) == -1) workerTc.get(w) == 0
      else workerTc.get(w) == fiberTcToken.get(workerRunning.get(w))
    )

  // 3. Anti-starvation LIFO streak bound & zero fault latches
  val invNoFaults: bool =
    not(staleSchedKUsed) and not(tcLeakDetected) and
    not(doubleExecDetected) and not(badHandoffVal) and
    workerStreak.get(0) <= MAX_LIFO_STREAK and
    workerStreak.get(1) <= MAX_LIFO_STREAK

  val allInvariants: bool =
    invExactConservation and invTcIsolation and invNoFaults
}

// Phase C9 Formal Model: Inline Chase-Lev Deque + Global-Queue Pending Hint +
// Lazy #f Thread Control-State Isolation + Sticky Victim Work-Stealing Cursor (SMP)

module inline_dq_global_hint_and_lazy_tc_smp {
  pure val DQ_CAP = 2
  pure val MAX_TASKS = 4
  pure val NUM_WORKERS = 3

  // Local Chase-Lev deque (Worker 0) + Global overflow queue
  var dqTop: int
  var dqBot: int
  var globalLen: int
  var globalPending: int  // incremented BEFORE enqueue, decremented AFTER dequeue
  var spawned: int
  var completed: int

  // Lazy #f control-state isolation model on carrier 0
  // Carrier runs either IDLE (0), Fiber A (tc=101), or Fiber B (tc=0)
  var carrierActive: int   // 0=idle, 1=A, 2=B
  var carrierTc: int       // actual thread.control-state register
  var savedTcA: int        // saved tc on A's %fiber-k (always 101)
  var savedTcB: int        // saved tc on B's %fiber-k (always 0)

  // Sticky victim cursor model for Worker 0 (must visit 1, 2 and never 0)
  var stealCursor: int

  action init = all {
    dqTop' = 0,
    dqBot' = 0,
    globalLen' = 0,
    globalPending' = 0,
    spawned' = 0,
    completed' = 0,
    carrierActive' = 0,
    carrierTc' = 0,
    savedTcA' = 101,
    savedTcB' = 0,
    stealCursor' = 1,
  }

  // Spawn pushes into local Chase-Lev deque if room, else spills to global queue
  // incrementing globalPending BEFORE enqueueing.
  action spawn_local = all {
    spawned < MAX_TASKS,
    (dqBot - dqTop) < DQ_CAP,
    dqBot' = dqBot + 1,
    spawned' = spawned + 1,
    dqTop' = dqTop, globalLen' = globalLen, globalPending' = globalPending,
    completed' = completed, carrierActive' = carrierActive, carrierTc' = carrierTc,
    savedTcA' = savedTcA, savedTcB' = savedTcB, stealCursor' = stealCursor,
  }

  action spawn_overflow_global = all {
    spawned < MAX_TASKS,
    (dqBot - dqTop) >= DQ_CAP,
    globalLen' = globalLen + 1,
    globalPending' = globalPending + 1,
    spawned' = spawned + 1,
    dqTop' = dqTop, dqBot' = dqBot, completed' = completed,
    carrierActive' = carrierActive, carrierTc' = carrierTc,
    savedTcA' = savedTcA, savedTcB' = savedTcB, stealCursor' = stealCursor,
  }

  // Local owner pops from Chase-Lev deque
  action local_pop = all {
    dqBot > dqTop,
    dqBot' = dqBot - 1,
    completed' = completed + 1,
    dqTop' = dqTop, globalLen' = globalLen, globalPending' = globalPending,
    spawned' = spawned, carrierActive' = carrierActive, carrierTc' = carrierTc,
    savedTcA' = savedTcA, savedTcB' = savedTcB, stealCursor' = stealCursor,
  }

  // Thief steals FIFO from Chase-Lev deque
  action thief_steal = all {
    dqTop < dqBot,
    dqTop' = dqTop + 1,
    completed' = completed + 1,
    // Keep sticky victim cursor on productive victim (valid peer 1..NUM_WORKERS-1)
    stealCursor' = stealCursor,
    dqBot' = dqBot, globalLen' = globalLen, globalPending' = globalPending,
    spawned' = spawned, carrierActive' = carrierActive, carrierTc' = carrierTc,
    savedTcA' = savedTcA, savedTcB' = savedTcB,
  }

  // Steal miss rotates sticky cursor to next peer (skipping self = 0)
  action steal_miss_rotate = {
    val nxtCursor = if (stealCursor + 1 >= NUM_WORKERS) 1 else stealCursor + 1
    all {
      stealCursor' = nxtCursor,
      dqTop' = dqTop, dqBot' = dqBot, globalLen' = globalLen,
      globalPending' = globalPending, spawned' = spawned, completed' = completed,
      carrierActive' = carrierActive, carrierTc' = carrierTc,
      savedTcA' = savedTcA, savedTcB' = savedTcB,
    }
  }

  // Worker polls global queue ONLY when globalPending > 0 (fast-path hint)
  action global_dequeue = all {
    globalPending > 0,
    globalLen > 0,
    globalLen' = globalLen - 1,
    globalPending' = globalPending - 1,
    completed' = completed + 1,
    dqTop' = dqTop, dqBot' = dqBot, spawned' = spawned,
    carrierActive' = carrierActive, carrierTc' = carrierTc,
    savedTcA' = savedTcA, savedTcB' = savedTcB, stealCursor' = stealCursor,
  }

  // Resume Fiber A (savedTcA = 101 != 0 -> MUST write carrierTc = 101)
  action resume_fiber_a = all {
    carrierActive == 0,
    carrierActive' = 1,
    carrierTc' = if (savedTcA != 0) savedTcA else carrierTc,
    savedTcA' = savedTcA, savedTcB' = savedTcB,
    dqTop' = dqTop, dqBot' = dqBot, globalLen' = globalLen,
    globalPending' = globalPending, spawned' = spawned, completed' = completed,
    stealCursor' = stealCursor,
  }

  // Suspend Fiber A: saves carrierTc, clears carrierTc to 0 ONLY if non-zero
  action suspend_fiber_a = all {
    carrierActive == 1,
    carrierActive' = 0,
    savedTcA' = carrierTc,
    carrierTc' = if (carrierTc != 0) 0 else carrierTc,
    savedTcB' = savedTcB,
    dqTop' = dqTop, dqBot' = dqBot, globalLen' = globalLen,
    globalPending' = globalPending, spawned' = spawned, completed' = completed,
    stealCursor' = stealCursor,
  }

  // Resume Fiber B (savedTcB == 0 -> SKIPS write barrier; relies on carrierTc == 0!)
  action resume_fiber_b = all {
    carrierActive == 0,
    carrierActive' = 2,
    carrierTc' = if (savedTcB != 0) savedTcB else carrierTc,
    savedTcA' = savedTcA, savedTcB' = savedTcB,
    dqTop' = dqTop, dqBot' = dqBot, globalLen' = globalLen,
    globalPending' = globalPending, spawned' = spawned, completed' = completed,
    stealCursor' = stealCursor,
  }

  // Suspend Fiber B: saves carrierTc (0), skips clearing write barrier since already 0
  action suspend_fiber_b = all {
    carrierActive == 2,
    carrierActive' = 0,
    savedTcB' = carrierTc,
    carrierTc' = if (carrierTc != 0) 0 else carrierTc,
    savedTcA' = savedTcA,
    dqTop' = dqTop, dqBot' = dqBot, globalLen' = globalLen,
    globalPending' = globalPending, spawned' = spawned, completed' = completed,
    stealCursor' = stealCursor,
  }

  action step = any {
    spawn_local,
    spawn_overflow_global,
    local_pop,
    thief_steal,
    steal_miss_rotate,
    global_dequeue,
    resume_fiber_a,
    suspend_fiber_a,
    resume_fiber_b,
    suspend_fiber_b,
  }

  // INVARIANT 1: Exact task conservation across local deque + global queue + completed
  val inv_task_conservation =
    dqTop <= dqBot and
    (dqBot - dqTop) <= DQ_CAP and
    (dqBot - dqTop) + globalLen + completed == spawned

  // INVARIANT 2: Global hint soundness: globalPending == 0 implies globalLen == 0
  // (skipping global-q poll when globalPending == 0 can NEVER miss an enqueued task!)
  val inv_global_hint_sound =
    (globalPending == 0) implies (globalLen == 0) and
    globalPending >= globalLen

  // INVARIANT 3: Lazy #f control-state isolation (zero cross-fiber tc leakage!)
  val inv_lazy_tc_isolation =
    ((carrierActive == 0) implies (carrierTc == 0)) and
    ((carrierActive == 1) implies (carrierTc == 101)) and
    ((carrierActive == 2) implies (carrierTc == 0))

  // INVARIANT 4: Sticky work-steal cursor is always a valid peer worker (never self=0)
  val inv_steal_cursor_valid =
    stealCursor >= 1 and stealCursor < NUM_WORKERS

  val inv_all =
    inv_task_conservation and
    inv_global_hint_sound and
    inv_lazy_tc_isolation and
    inv_steal_cursor_valid
}

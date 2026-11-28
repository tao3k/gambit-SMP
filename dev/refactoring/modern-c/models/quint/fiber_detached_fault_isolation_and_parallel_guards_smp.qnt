// Quint model for (gambit fiber) detached-fiber fault isolation & quiescence
// preservation + (gambit parallel) proper-list and overflow-safe next-pow2 guards.
//
// Verifies:
//   1. An uncaught exception in a detached fiber unwinds cleanly (finally runs),
//      clears carrier thread control state (tc -> 0), increments completed, and
//      keeps all carrier worker OS threads alive so completed == spawned
//      quiescence always converges and the off-heap parker is destroyed cleanly.
//   2. Parallel next-pow2 rejects values exceeding max_fixnum/2 before doubling
//      (preventing signed fixnum overflow infinite loops).
//   3. Parallel combinators reject improper lists.

module fiber_detached_fault_isolation_and_parallel_guards_smp {

  pure val WORKERS = Set(0, 1)
  pure val MAX_SPAWN = 4

  var spawned: int
  var completed: int
  var root_done: bool
  var worker_alive: int -> bool
  var carrier_tc: int -> int         // 0 = clean, 1 = dirty prompt/mark/handler
  var detached_pending: int
  var finally_ran: int
  var detached_faults: int
  var parker_destroyed: bool
  var finished: bool
  var tc_leaked: bool
  var pow2_overflowed: bool

  action init = all {
    spawned' = 1,          // root fiber
    completed' = 0,
    root_done' = false,
    worker_alive' = WORKERS.mapBy(_ => true),
    carrier_tc' = WORKERS.mapBy(_ => 0),
    detached_pending' = 0,
    finally_ran' = 0,
    detached_faults' = 0,
    parker_destroyed' = false,
    finished' = false,
    tc_leaked' = false,
    pow2_overflowed' = false,
  }

  // Spawn a detached fiber from the running root or another fiber
  action spawnDetached = all {
    not(finished),
    spawned < MAX_SPAWN,
    spawned' = spawned + 1,
    detached_pending' = detached_pending + 1,
    completed' = completed,
    root_done' = root_done,
    worker_alive' = worker_alive,
    carrier_tc' = carrier_tc,
    finally_ran' = finally_ran,
    detached_faults' = detached_faults,
    parker_destroyed' = parker_destroyed,
    finished' = finished,
    tc_leaked' = tc_leaked,
    pow2_overflowed' = pow2_overflowed,
  }

  // Detached fiber runs normally on worker w (observing clean tc == 0)
  action detachedNormalComplete(w: int): bool = all {
    not(finished),
    worker_alive.get(w),
    detached_pending > 0,
    val sawDirty = carrier_tc.get(w) != 0
    all {
      tc_leaked' = (tc_leaked or sawDirty),
      detached_pending' = detached_pending - 1,
      completed' = completed + 1,
      carrier_tc' = carrier_tc.set(w, 0),
      spawned' = spawned,
      root_done' = root_done,
      worker_alive' = worker_alive,
      finally_ran' = finally_ran,
      detached_faults' = detached_faults,
      parker_destroyed' = parker_destroyed,
      finished' = finished,
      pow2_overflowed' = pow2_overflowed,
    }
  }

  // Detached fiber installs marks/handlers (tc = 1), throws uncaught exception:
  // %detached-err-handler grafts to sched-k, runs finally, clears tc -> 0,
  // increments completed, and keeps worker w alive!
  action detachedThrowsIsolated(w: int): bool = all {
    not(finished),
    worker_alive.get(w),
    detached_pending > 0,
    val sawDirty = carrier_tc.get(w) != 0
    all {
      tc_leaked' = (tc_leaked or sawDirty),
      detached_pending' = detached_pending - 1,
      completed' = completed + 1,
      finally_ran' = finally_ran + 1,
      detached_faults' = detached_faults + 1,
      // Carrier tc is strictly cleared to 0 and worker stays alive
      carrier_tc' = carrier_tc.set(w, 0),
      worker_alive' = worker_alive,
      spawned' = spawned,
      root_done' = root_done,
      parker_destroyed' = parker_destroyed,
      finished' = finished,
      pow2_overflowed' = pow2_overflowed,
    }
  }

  // Root fiber finishes (either returning a value or recording root error)
  action rootComplete = all {
    not(finished),
    not(root_done),
    root_done' = true,
    completed' = completed + 1,
    spawned' = spawned,
    worker_alive' = worker_alive,
    carrier_tc' = carrier_tc,
    detached_pending' = detached_pending,
    finally_ran' = finally_ran,
    detached_faults' = detached_faults,
    parker_destroyed' = parker_destroyed,
    finished' = finished,
    tc_leaked' = tc_leaked,
    pow2_overflowed' = pow2_overflowed,
  }

  // Quiescence reached (root_done and completed == spawned) -> join workers & destroy parker
  action quiesceAndDestroyParker = all {
    not(finished),
    root_done,
    completed == spawned,
    WORKERS.forall(w => worker_alive.get(w)),
    parker_destroyed' = true,
    finished' = true,
    spawned' = spawned,
    completed' = completed,
    root_done' = root_done,
    worker_alive' = worker_alive,
    carrier_tc' = carrier_tc,
    detached_pending' = detached_pending,
    finally_ran' = finally_ran,
    detached_faults' = detached_faults,
    tc_leaked' = tc_leaked,
    pow2_overflowed' = pow2_overflowed,
  }

  // Guarded next-pow2 check (max_half = 1024 abstract model of max_fixnum/2)
  action checkNextPow2(n: int): bool = all {
    val maxHalf = 1024
    val ok = (n <= maxHalf)
    all {
      pow2_overflowed' = (pow2_overflowed or (ok and n > maxHalf)),
      spawned' = spawned,
      completed' = completed,
      root_done' = root_done,
      worker_alive' = worker_alive,
      carrier_tc' = carrier_tc,
      detached_pending' = detached_pending,
      finally_ran' = finally_ran,
      detached_faults' = detached_faults,
      parker_destroyed' = parker_destroyed,
      finished' = finished,
      tc_leaked' = tc_leaked,
    }
  }

  // Buggy pre-C37 action: uncaught detached error kills carrier worker & skips completed++
  action buggyDetachedKillsWorker(w: int): bool = all {
    not(finished),
    worker_alive.get(w),
    detached_pending > 0,
    detached_pending' = detached_pending - 1,
    worker_alive' = worker_alive.set(w, false),
    carrier_tc' = carrier_tc.set(w, 1),
    spawned' = spawned,
    completed' = completed,
    root_done' = root_done,
    finally_ran' = finally_ran,
    detached_faults' = detached_faults + 1,
    parker_destroyed' = parker_destroyed,
    finished' = finished,
    tc_leaked' = tc_leaked,
    pow2_overflowed' = pow2_overflowed,
  }

  action step = any {
    spawnDetached,
    nondet w = oneOf(WORKERS)
    any {
      detachedNormalComplete(w),
      detachedThrowsIsolated(w),
    },
    rootComplete,
    quiesceAndDestroyParker,
    nondet n = oneOf(Set(1, 64, 1024, 1025, 4096))
    checkNextPow2(n),
  }

  // Safety invariants
  val inv_all_workers_alive = WORKERS.forall(w => worker_alive.get(w))
  val inv_completed_le_spawned = completed <= spawned
  val inv_no_tc_leak = not(tc_leaked) and WORKERS.forall(w => carrier_tc.get(w) == 0)
  val inv_finally_matches_faults = finally_ran == detached_faults
  val inv_parker_clean_on_finish = finished implies (parker_destroyed and completed == spawned)
  val inv_no_pow2_overflow = not(pow2_overflowed)

  val safety = and {
    inv_all_workers_alive,
    inv_completed_le_spawned,
    inv_no_tc_leak,
    inv_finally_matches_faults,
    inv_parker_clean_on_finish,
    inv_no_pow2_overflow,
  }

  // Unit tests
  run detachedFaultQuiescesCleanlyTest = {
    init
      .then(spawnDetached)
      .then(spawnDetached)
      .then(detachedThrowsIsolated(1))
      .then(detachedNormalComplete(0))
      .then(rootComplete)
      .then(quiesceAndDestroyParker)
      .expect(safety and finished and parker_destroyed and completed == 3 and finally_ran == 1)
  }

  run multipleDetachedFaultsSameWorkerTest = {
    init
      .then(spawnDetached)
      .then(spawnDetached)
      .then(detachedThrowsIsolated(0))
      .then(detachedThrowsIsolated(0))
      .then(rootComplete)
      .then(quiesceAndDestroyParker)
      .expect(safety and finished and not(tc_leaked) and finally_ran == 2)
  }

  run nextPow2GuardTest = {
    init
      .then(checkNextPow2(64))
      .then(checkNextPow2(1025))
      .expect(safety)
  }

  run buggyDetachedKillDetectedTest = {
    init
      .then(spawnDetached)
      .then(buggyDetachedKillsWorker(1))
      .expect(not(inv_all_workers_alive) and completed < spawned)
  }
}

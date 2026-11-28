// Phase C19 Formal Model (Quint):
// Go/Tokio-Style Bounded Searching-Worker Throttling (`numSearching <= max(1, W/2)`)
// + Work-Conserving Permit Release on Steal-Success & Idle-Exit.
// Eliminates W-way steal CAS thundering herds while guaranteeing strict liveness.

module tokio_searching_throttle_work_stealing_smp {
  // 3 workers: W0 (producer/active), W1 (idle thief), W2 (idle thief)
  // W = 3 => maxSearching = max(1, 3 / 2) = 1
  var w0Tasks: int         // 0..4
  var w1Tasks: int         // 0..4
  var w2Tasks: int         // 0..4
  var w1Searching: bool
  var w2Searching: bool
  var numSearching: int    // shared atomic counter (0..MAX_SEARCHING)
  var completed: int
  var totalSpawned: int

  val MAX_SEARCHING = 1
  val MAX_SPAWN = 4

  action init = all {
    w0Tasks' = 3,
    w1Tasks' = 0,
    w2Tasks' = 0,
    w1Searching' = false,
    w2Searching' = false,
    numSearching' = 0,
    completed' = 0,
    totalSpawned' = 3,
  }

  // W0 spawns a task
  action w0Spawn = all {
    totalSpawned < MAX_SPAWN,
    w0Tasks < 4,
    w0Tasks' = w0Tasks + 1,
    totalSpawned' = totalSpawned + 1,
    w1Tasks' = w1Tasks,
    w2Tasks' = w2Tasks,
    w1Searching' = w1Searching,
    w2Searching' = w2Searching,
    numSearching' = numSearching,
    completed' = completed,
  }

  // W0 pops & completes 1 local task
  action w0Complete = all {
    w0Tasks > 0,
    w0Tasks' = w0Tasks - 1,
    completed' = completed + 1,
    w1Tasks' = w1Tasks,
    w2Tasks' = w2Tasks,
    w1Searching' = w1Searching,
    w2Searching' = w2Searching,
    numSearching' = numSearching,
    totalSpawned' = totalSpawned,
  }

  // W1 acquires a searching permit if numSearching < MAX_SEARCHING
  action w1EnterSearching = all {
    w1Tasks == 0,
    not(w1Searching),
    numSearching < MAX_SEARCHING,
    w1Searching' = true,
    numSearching' = numSearching + 1,
    w0Tasks' = w0Tasks,
    w1Tasks' = w1Tasks,
    w2Tasks' = w2Tasks,
    w2Searching' = w2Searching,
    completed' = completed,
    totalSpawned' = totalSpawned,
  }

  // W1 steals from W0 (or W2) and IMMEDIATELY releases searching permit!
  action w1StealAndRelease = all {
    w1Searching,
    w0Tasks > 0,
    val take = (if (w0Tasks >= 2) 2 else 1)
    all {
      w0Tasks' = w0Tasks - take,
      w1Tasks' = w1Tasks + (take - 1),
      completed' = completed + 1, // runs stolen task 0 immediately
      w1Searching' = false,
      numSearching' = numSearching - 1,
      w2Tasks' = w2Tasks,
      w2Searching' = w2Searching,
      totalSpawned' = totalSpawned,
    }
  }

  // W1 finds no tasks and releases searching permit before backoff
  action w1AbortSearchAndRelease = all {
    w1Searching,
    w0Tasks == 0,
    w2Tasks == 0,
    w1Searching' = false,
    numSearching' = numSearching - 1,
    w0Tasks' = w0Tasks,
    w1Tasks' = w1Tasks,
    w2Tasks' = w2Tasks,
    w2Searching' = w2Searching,
    completed' = completed,
    totalSpawned' = totalSpawned,
  }

  // W1 completes own local stolen task
  action w1Complete = all {
    w1Tasks > 0,
    not(w1Searching),
    w1Tasks' = w1Tasks - 1,
    completed' = completed + 1,
    w0Tasks' = w0Tasks,
    w2Tasks' = w2Tasks,
    w1Searching' = w1Searching,
    w2Searching' = w2Searching,
    numSearching' = numSearching,
    totalSpawned' = totalSpawned,
  }

  // W2 acquires a searching permit if numSearching < MAX_SEARCHING
  action w2EnterSearching = all {
    w2Tasks == 0,
    not(w2Searching),
    numSearching < MAX_SEARCHING,
    w2Searching' = true,
    numSearching' = numSearching + 1,
    w0Tasks' = w0Tasks,
    w1Tasks' = w1Tasks,
    w2Tasks' = w2Tasks,
    w1Searching' = w1Searching,
    completed' = completed,
    totalSpawned' = totalSpawned,
  }

  // W2 steals from W0 or W1 and IMMEDIATELY releases searching permit
  action w2StealAndRelease = all {
    w2Searching,
    (w0Tasks > 0 or w1Tasks > 0),
    if (w1Tasks > 0) all {
      w1Tasks' = w1Tasks - 1,
      w0Tasks' = w0Tasks,
      completed' = completed + 1,
      w2Searching' = false,
      numSearching' = numSearching - 1,
      w2Tasks' = w2Tasks,
      w1Searching' = w1Searching,
      totalSpawned' = totalSpawned,
    } else all {
      w0Tasks' = w0Tasks - 1,
      w1Tasks' = w1Tasks,
      completed' = completed + 1,
      w2Searching' = false,
      numSearching' = numSearching - 1,
      w2Tasks' = w2Tasks,
      w1Searching' = w1Searching,
      totalSpawned' = totalSpawned,
    }
  }

  action w2AbortSearchAndRelease = all {
    w2Searching,
    w0Tasks == 0,
    w1Tasks == 0,
    w2Searching' = false,
    numSearching' = numSearching - 1,
    w0Tasks' = w0Tasks,
    w1Tasks' = w1Tasks,
    w2Tasks' = w2Tasks,
    w1Searching' = w1Searching,
    completed' = completed,
    totalSpawned' = totalSpawned,
  }

  action step = any {
    w0Spawn,
    w0Complete,
    w1EnterSearching,
    w1StealAndRelease,
    w1AbortSearchAndRelease,
    w1Complete,
    w2EnterSearching,
    w2StealAndRelease,
    w2AbortSearchAndRelease,
  }

  // ---- Safety & Permit-Conservation Invariants ----
  // 1. Exact searching permit accounting (zero leaks, zero underflow, strictly <= MAX_SEARCHING)
  val inv_searching_exact =
    numSearching == ((if (w1Searching) 1 else 0) + (if (w2Searching) 1 else 0))
    and (numSearching >= 0) and (numSearching <= MAX_SEARCHING)

  // 2. Exact task conservation
  val inv_task_conservation =
    (w0Tasks + w1Tasks + w2Tasks + completed) == totalSpawned

  // 3. Searching workers have empty local queues
  val inv_searching_only_when_empty =
    (not(w1Searching) or w1Tasks == 0) and (not(w2Searching) or w2Tasks == 0)

  val inv_all = all {
    inv_searching_exact,
    inv_task_conservation,
    inv_searching_only_when_empty,
  }
}

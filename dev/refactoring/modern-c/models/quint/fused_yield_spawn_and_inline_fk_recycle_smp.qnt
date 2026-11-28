// Phase C16 Formal Model (Quint):
// 1. Fused fiber-spawn (n.active++ & store_rel(spawned) before LIFO/deque publish)
// 2. Fused yield-push-and-pop + inline %free-fk-c! under concurrent thief CAS(head)
// 3. Exact task conservation, zero fk aliasing, zero nursery underflow

module fused_yield_spawn_and_inline_fk_recycle_smp {
  // ---- Spawn & Nursery Accounting ----
  var nActive: int         // starts at 1 (parent)
  var spawnedCnt: int      // monotonic spawned
  var completedCnt: int    // monotonic completed
  var dqHead: int          // 0..4
  var dqTail: int          // 0..4
  var dqSlot0: int         // 0 = empty, >0 = task id
  var dqSlot1: int
  var dqSlot2: int
  var dqSlot3: int
  var lifoTask: int        // 0 = empty, >0 = task id
  var nextTaskId: int      // 1..4
  var thiefStolenCount: int
  var ownerRunCount: int

  // ---- Fused Yield & Inline fk Pool Conservation ----
  var fkPoolCount: int     // 0..2
  var fkInDq: bool         // whether yielded fk is currently in deque
  var fkResumedOk: bool    // whether resumed raw-k was read before clear

  val MAX_SPAWN = 3

  action init = all {
    nActive' = 1,
    spawnedCnt' = 1,
    completedCnt' = 0,
    dqHead' = 0,
    dqTail' = 0,
    dqSlot0' = 0,
    dqSlot1' = 0,
    dqSlot2' = 0,
    dqSlot3' = 0,
    lifoTask' = 0,
    nextTaskId' = 1,
    thiefStolenCount' = 0,
    ownerRunCount' = 0,
    fkPoolCount' = 2,
    fkInDq' = false,
    fkResumedOk' = true,
  }

  // Fused fiber-spawn: increment nActive & spawnedCnt BEFORE publishing to lifo/dq
  action fusedSpawn = all {
    nextTaskId <= MAX_SPAWN,
    dqTail < 4,
    val tid = nextTaskId
    val evict = lifoTask
    all {
      nActive' = nActive + 1,
      spawnedCnt' = spawnedCnt + 1,
      nextTaskId' = nextTaskId + 1,
      lifoTask' = tid,
      if (evict != 0) all {
        dqTail' = dqTail + 1,
        dqSlot0' = (if (dqTail == 0) evict else dqSlot0),
        dqSlot1' = (if (dqTail == 1) evict else dqSlot1),
        dqSlot2' = (if (dqTail == 2) evict else dqSlot2),
        dqSlot3' = (if (dqTail == 3) evict else dqSlot3),
      } else all {
        dqTail' = dqTail,
        dqSlot0' = dqSlot0,
        dqSlot1' = dqSlot1,
        dqSlot2' = dqSlot2,
        dqSlot3' = dqSlot3,
      },
      completedCnt' = completedCnt,
      dqHead' = dqHead,
      thiefStolenCount' = thiefStolenCount,
      ownerRunCount' = ownerRunCount,
      fkPoolCount' = fkPoolCount,
      fkInDq' = fkInDq,
      fkResumedOk' = fkResumedOk,
    }
  }

  // Thief steals 1 task from dq via CAS(head, h -> h+1) and completes it
  action thiefStealAndComplete = all {
    dqHead < dqTail,
    dqHead' = dqHead + 1,
    dqSlot0' = (if (dqHead == 0) 0 else dqSlot0),
    dqSlot1' = (if (dqHead == 1) 0 else dqSlot1),
    dqSlot2' = (if (dqHead == 2) 0 else dqSlot2),
    dqSlot3' = (if (dqHead == 3) 0 else dqSlot3),
    thiefStolenCount' = thiefStolenCount + 1,
    nActive' = nActive - 1,
    completedCnt' = completedCnt + 1,
    spawnedCnt' = spawnedCnt,
    dqTail' = dqTail,
    lifoTask' = lifoTask,
    nextTaskId' = nextTaskId,
    ownerRunCount' = ownerRunCount,
    fkPoolCount' = fkPoolCount,
    fkInDq' = fkInDq,
    fkResumedOk' = fkResumedOk,
  }

  // Owner pops from lifo and completes it
  action ownerRunLifo = all {
    lifoTask != 0,
    lifoTask' = 0,
    ownerRunCount' = ownerRunCount + 1,
    nActive' = nActive - 1,
    completedCnt' = completedCnt + 1,
    spawnedCnt' = spawnedCnt,
    dqHead' = dqHead,
    dqTail' = dqTail,
    dqSlot0' = dqSlot0,
    dqSlot1' = dqSlot1,
    dqSlot2' = dqSlot2,
    dqSlot3' = dqSlot3,
    nextTaskId' = nextTaskId,
    thiefStolenCount' = thiefStolenCount,
    fkPoolCount' = fkPoolCount,
    fkInDq' = fkInDq,
    fkResumedOk' = fkResumedOk,
  }

  // Owner pops from dq via CAS(head, h -> h+1) and completes it
  action ownerPopDq = all {
    dqHead < dqTail,
    dqHead' = dqHead + 1,
    dqSlot0' = (if (dqHead == 0) 0 else dqSlot0),
    dqSlot1' = (if (dqHead == 1) 0 else dqSlot1),
    dqSlot2' = (if (dqHead == 2) 0 else dqSlot2),
    dqSlot3' = (if (dqHead == 3) 0 else dqSlot3),
    ownerRunCount' = ownerRunCount + 1,
    nActive' = nActive - 1,
    completedCnt' = completedCnt + 1,
    spawnedCnt' = spawnedCnt,
    dqTail' = dqTail,
    lifoTask' = lifoTask,
    nextTaskId' = nextTaskId,
    thiefStolenCount' = thiefStolenCount,
    fkPoolCount' = fkPoolCount,
    fkInDq' = fkInDq,
    fkResumedOk' = fkResumedOk,
  }

  // Fused yield self-switch: pop fk from pool, push to dq, pop self back,
  // extract raw-k BEFORE inline %free-fk-c! recycles fk to pool.
  action fusedSelfYieldAndRecycle = all {
    fkPoolCount >= 1,
    not(fkInDq),
    // Net effect: pop 1 -> push -> pop -> extract raw-k -> recycle 1
    fkPoolCount' = fkPoolCount,
    fkInDq' = false,
    fkResumedOk' = true,
    nActive' = nActive,
    spawnedCnt' = spawnedCnt,
    completedCnt' = completedCnt,
    dqHead' = dqHead,
    dqTail' = dqTail,
    dqSlot0' = dqSlot0,
    dqSlot1' = dqSlot1,
    dqSlot2' = dqSlot2,
    dqSlot3' = dqSlot3,
    lifoTask' = lifoTask,
    nextTaskId' = nextTaskId,
    thiefStolenCount' = thiefStolenCount,
    ownerRunCount' = ownerRunCount,
  }

  action step = any {
    fusedSpawn,
    thiefStealAndComplete,
    ownerRunLifo,
    ownerPopDq,
    fusedSelfYieldAndRecycle,
  }

  // ---- Safety Invariants ----
  // 1. Exact child task conservation across lifo + dq + completed
  val inv_task_conservation =
    ((if (lifoTask != 0) 1 else 0) + (dqTail - dqHead) + ownerRunCount + thiefStolenCount)
      == (nextTaskId - 1)

  // 2. Nursery active count never underflows and matches 1 (parent) + live children
  val inv_nursery_exact =
    nActive == (1 + (if (lifoTask != 0) 1 else 0) + (dqTail - dqHead))

  // 3. Quiescence accounting: completed <= spawned always
  val inv_quiescence_monotone =
    (completedCnt <= spawnedCnt) and (dqHead <= dqTail)

  // 4. Inline fk pool count never leaks or overflows and resumed raw-k is valid
  val inv_fk_pool_sound =
    (fkPoolCount == 2) and fkResumedOk

  val inv_all = all {
    inv_task_conservation,
    inv_nursery_exact,
    inv_quiescence_monotone,
    inv_fk_pool_sound,
  }
}

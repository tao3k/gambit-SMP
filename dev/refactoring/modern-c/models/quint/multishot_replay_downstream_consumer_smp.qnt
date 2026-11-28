// -*- mode: quint -*-
// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//
// Concurrency Protocol Bug Counterexample & Safe Resolution Model (DEV SMP):
//   Multi-Shot Delimited Continuation (MULTISHOT_COW) In-Place Replay vs.
//   Concurrent Downstream Consumer Read-Write Race
//
// Origin:
//   Caught by Quint in Kontinuum (`tile_task_effect_safety.qnt`, seed
//   `0x67ad584bee771187`, 84ms) when pure multi-shot producer `task 3`
//   replayed in-place onto `buf[3]` while downstream consumer `task 4` was
//   already `"running"` and actively reading `buf[3]`.
//
// Companion to `frontier_continuation_smp.qnt` (ONE_SHOT_LIVE ->
// ONE_SHOT_CONSUMED | MULTISHOT_COW). Demonstrates:
//   1. Reproducible negative counterexample tests (`quint test`) and
//      randomized fault-injection step (`--step=stepBuggyUnprotectedReplay`)
//      exposing BOTH:
//        (a) In-place multi-shot replay racing with an active downstream
//            reader (`invNoReadWriteRace` & `invDependencyOrderPreserved`);
//        (b) Multi-shot replay of a linear-one-shot side-effecting task
//            (`invNoLinearEffectReplay`).
//   2. Two formally sound SMP protocol resolutions:
//        (a) In-place reuse ONLY when all downstream consumers are `"pending"`
//            and `bufReaders[slot]` is empty (`replayPureInPlace`);
//        (b) Concurrent multi-shot replay via fresh COW buffer allocation
//            leaving the published snapshot immutable (`replayPureWithCowFork`).

module multishot_replay_downstream_consumer_smp {
  type TaskId = int
  type BufId = int
  type State = str      // "pending" | "running" | "done" | "aborted"
  type ContState = int  // 0 = ONE_SHOT_LIVE, 1 = ONE_SHOT_CONSUMED, 2 = MULTISHOT_COW

  // Canonical 4-task cross-core / cross-device DAG:
  //   1: upstream-producer  (linear-one-shot, deps={})
  //   2: side-effect-xfer   (linear-one-shot, deps={1})   -- e.g., RDMA / IO / C-FFI commit
  //   3: pure-multishot-k   (pure MULTISHOT_COW, deps={}) -- e.g., pure prefix/projection
  //   4: downstream-reader  (linear-one-shot, deps={2,3}) -- concurrently reads buf[2] & buf[3]
  pure val TASK_IDS: Set[TaskId]     = Set(1, 2, 3, 4)
  pure val LINEAR_TASKS: Set[TaskId] = Set(1, 2, 4)
  pure val PURE_TASKS: Set[TaskId]   = Set(3)

  // Physical buffer slots: 1..4 are initial task outputs; 5..6 are fresh COW fork slots.
  pure val BASE_BUFS: Set[BufId] = Set(1, 2, 3, 4)
  pure val ALL_BUFS: Set[BufId]  = Set(1, 2, 3, 4, 5, 6)
  pure val MAX_COW_SLOT: BufId   = 6

  pure def taskDeps(t: TaskId): Set[TaskId] =
    if (t == 2) Set(1)
    else if (t == 4) Set(2, 3)
    else Set()

  var taskState: TaskId -> State
  var contState: TaskId -> ContState
  var execCount: TaskId -> int
  var activeBuf: TaskId -> BufId          // latest published/writing buffer slot for task t
  var readBufs: TaskId -> Set[BufId]      // exact buffer slots currently pinned for reading by running task t
  var bufWriter: BufId -> int             // 0 = unowned, >0 = TaskId actively writing slot
  var bufReaders: BufId -> Set[TaskId]    // active running consumers reading slot
  var nextCowSlot: BufId                  // next fresh COW slot (starts at 5)
  var nurseryCancelled: bool

  // Explicit protocol fault latches (must remain false on all safe traces)
  var rwRaceFault: bool
  var linearReplayFault: bool

  action init = all {
    taskState'        = TASK_IDS.mapBy(_ => "pending"),
    contState'        = TASK_IDS.mapBy(t => if (PURE_TASKS.contains(t)) 2 else 0),
    execCount'        = TASK_IDS.mapBy(_ => 0),
    activeBuf'        = TASK_IDS.mapBy(t => t),
    readBufs'         = TASK_IDS.mapBy(_ => Set()),
    bufWriter'        = ALL_BUFS.mapBy(_ => 0),
    bufReaders'       = ALL_BUFS.mapBy(_ => Set()),
    nextCowSlot'      = 5,
    nurseryCancelled' = false,
    rwRaceFault'      = false,
    linearReplayFault' = false,
  }

  // Launch a ready task once all predecessor dependencies are "done",
  // pinning each dependency's current published snapshot in `bufReaders`
  // and claiming exclusive write ownership of its own output buffer.
  action startTask(t: TaskId): bool = all {
    not(nurseryCancelled),
    taskState.get(t) == "pending",
    taskDeps(t).forall(d => taskState.get(d) == "done"),
    val outBuf = activeBuf.get(t)
    val depBufs = taskDeps(t).map(d => activeBuf.get(d))
    all {
      bufWriter.get(outBuf) == 0,
      bufReaders.get(outBuf).size() == 0,
      depBufs.forall(b => bufWriter.get(b) == 0),
      LINEAR_TASKS.contains(t) implies (contState.get(t) == 0 and execCount.get(t) == 0),
      taskState' = taskState.set(t, "running"),
      contState' = if (LINEAR_TASKS.contains(t)) contState.set(t, 1) else contState,
      execCount' = execCount.set(t, execCount.get(t) + 1),
      activeBuf' = activeBuf,
      readBufs'  = readBufs.set(t, depBufs),
      bufWriter' = bufWriter.set(outBuf, t),
      bufReaders' = ALL_BUFS.mapBy(b =>
        if (depBufs.contains(b)) bufReaders.get(b).union(Set(t))
        else bufReaders.get(b)
      ),
      nextCowSlot'       = nextCowSlot,
      nurseryCancelled'  = nurseryCancelled,
      rwRaceFault'       = rwRaceFault,
      linearReplayFault' = linearReplayFault,
    }
  }

  // Complete a running task: release exclusive writer lock on its output buffer
  // and release all reader pins on its predecessor snapshot buffers.
  action completeTask(t: TaskId): bool = all {
    taskState.get(t) == "running",
    val outBuf = activeBuf.get(t)
    val myReads = readBufs.get(t)
    all {
      bufWriter.get(outBuf) == t,
      taskState' = taskState.set(t, "done"),
      contState' = contState,
      execCount' = execCount,
      activeBuf' = activeBuf,
      readBufs'  = readBufs.set(t, Set()),
      bufWriter' = bufWriter.set(outBuf, 0),
      bufReaders' = ALL_BUFS.mapBy(b =>
        if (myReads.contains(b)) bufReaders.get(b).exclude(Set(t))
        else bufReaders.get(b)
      ),
      nextCowSlot'       = nextCowSlot,
      nurseryCancelled'  = nurseryCancelled,
      rwRaceFault'       = rwRaceFault,
      linearReplayFault' = linearReplayFault,
    }
  }

  // SAFE RESOLUTION (A): In-place multi-shot replay of a pure continuation task.
  // Admissible ONLY IF every downstream consumer is still "pending" AND
  // zero active readers hold a pin on the buffer slot.
  action replayPureInPlace(t: TaskId): bool = all {
    not(nurseryCancelled),
    PURE_TASKS.contains(t),
    contState.get(t) == 2,
    taskState.get(t) == "done",
    execCount.get(t) < 3,
    val outBuf = activeBuf.get(t)
    all {
      bufWriter.get(outBuf) == 0,
      bufReaders.get(outBuf).size() == 0,
      TASK_IDS.forall(u => taskDeps(u).contains(t) implies taskState.get(u) == "pending"),
      taskState'         = taskState.set(t, "running"),
      contState'         = contState,
      execCount'         = execCount.set(t, execCount.get(t) + 1),
      activeBuf'         = activeBuf,
      readBufs'          = readBufs,
      bufWriter'         = bufWriter.set(outBuf, t),
      bufReaders'        = bufReaders,
      nextCowSlot'       = nextCowSlot,
      nurseryCancelled'  = nurseryCancelled,
      rwRaceFault'       = rwRaceFault,
      linearReplayFault' = linearReplayFault,
    }
  }

  // SAFE RESOLUTION (B): Concurrent multi-shot replay via fresh COW buffer fork.
  // Even while downstream `task 4` is actively `"running"` reading the published
  // snapshot `buf[3]`, the replayed shot allocates a fresh exclusive COW slot
  // (`nextCowSlot`), preserving immutability of `buf[3]` with zero R/W race!
  action replayPureWithCowFork(t: TaskId): bool = all {
    not(nurseryCancelled),
    PURE_TASKS.contains(t),
    contState.get(t) == 2,
    taskState.get(t) == "done",
    execCount.get(t) < 3,
    nextCowSlot <= MAX_COW_SLOT,
    val newBuf = nextCowSlot
    all {
      bufWriter.get(newBuf) == 0,
      bufReaders.get(newBuf).size() == 0,
      taskState'         = taskState.set(t, "running"),
      contState'         = contState,
      execCount'         = execCount.set(t, execCount.get(t) + 1),
      activeBuf'         = activeBuf.set(t, newBuf),
      readBufs'          = readBufs,
      bufWriter'         = bufWriter.set(newBuf, t),
      bufReaders'        = bufReaders,
      nextCowSlot'       = nextCowSlot + 1,
      nurseryCancelled'  = nurseryCancelled,
      rwRaceFault'       = rwRaceFault,
      linearReplayFault' = linearReplayFault,
    }
  }

  // Cooperative structured nursery cancellation: aborts non-done tasks and
  // reclaims all active write locks and reader pins deterministically.
  action cancelNursery: bool = all {
    not(nurseryCancelled),
    nurseryCancelled'  = true,
    taskState'         = TASK_IDS.mapBy(t => if (taskState.get(t) == "done") "done" else "aborted"),
    contState'         = contState,
    execCount'         = execCount,
    activeBuf'         = activeBuf,
    readBufs'          = TASK_IDS.mapBy(_ => Set()),
    bufWriter'         = ALL_BUFS.mapBy(_ => 0),
    bufReaders'        = ALL_BUFS.mapBy(_ => Set()),
    nextCowSlot'       = nextCowSlot,
    rwRaceFault'       = rwRaceFault,
    linearReplayFault' = linearReplayFault,
  }

  // -------------------------------------------------------------------------
  // NEGATIVE CONTROLS / BUG REPRODUCTION ACTIONS (NOT IN SAFE `step`)
  // -------------------------------------------------------------------------

  // BUG REPRO 1 (Exact Kontinuum Quint counterexample `seed=0x67ad584bee771187`):
  // Omits both the downstream-"pending" guard and `bufReaders == empty` check,
  // allowing pure multi-shot `task 3` to overwrite `buf[3]` IN-PLACE while
  // downstream consumer `task 4` is actively `"running"` and reading `buf[3]`.
  action unsafeReplayInPlaceWhileConsumerActive(t: TaskId): bool = all {
    not(nurseryCancelled),
    PURE_TASKS.contains(t),
    contState.get(t) == 2,
    taskState.get(t) == "done",
    execCount.get(t) < 3,
    val outBuf = activeBuf.get(t)
    all {
      bufWriter.get(outBuf) == 0,
      // BUG: does NOT check `bufReaders.get(outBuf).size() == 0` or downstream `"pending"`!
      taskState'         = taskState.set(t, "running"),
      contState'         = contState,
      execCount'         = execCount.set(t, execCount.get(t) + 1),
      activeBuf'         = activeBuf,
      readBufs'          = readBufs,
      bufWriter'         = bufWriter.set(outBuf, t),
      bufReaders'        = bufReaders,
      nextCowSlot'       = nextCowSlot,
      nurseryCancelled'  = nurseryCancelled,
      rwRaceFault'       = (rwRaceFault or (bufReaders.get(outBuf).size() > 0)),
      linearReplayFault' = linearReplayFault,
    }
  }

  // BUG REPRO 2: Unchecked multi-shot resume of a linear-one-shot task
  // (e.g., duplicating RDMA transfer or C-FFI commit after `ONE_SHOT_CONSUMED`).
  action unsafeReplayLinearEffect(t: TaskId): bool = all {
    not(nurseryCancelled),
    LINEAR_TASKS.contains(t),
    taskState.get(t) == "done",
    val outBuf = activeBuf.get(t)
    all {
      bufWriter.get(outBuf) == 0,
      taskState'         = taskState.set(t, "running"),
      contState'         = contState,
      execCount'         = execCount.set(t, execCount.get(t) + 1),
      activeBuf'         = activeBuf,
      readBufs'          = readBufs,
      bufWriter'         = bufWriter.set(outBuf, t),
      bufReaders'        = bufReaders,
      nextCowSlot'       = nextCowSlot,
      nurseryCancelled'  = nurseryCancelled,
      rwRaceFault'       = (rwRaceFault or (bufReaders.get(outBuf).size() > 0)),
      linearReplayFault' = true,
    }
  }

  // Safe protocol step relation (verified zero-violation with `quint run`)
  action step = any {
    nondet t = TASK_IDS.oneOf()
    startTask(t),
    nondet t = TASK_IDS.oneOf()
    completeTask(t),
    nondet t = TASK_IDS.oneOf()
    replayPureInPlace(t),
    nondet t = TASK_IDS.oneOf()
    replayPureWithCowFork(t),
    cancelNursery,
  }

  // Buggy step relation for live randomized counterexample synthesis:
  //   quint run --step=stepBuggyUnprotectedReplay --invariant=allInvariants ...
  action stepBuggyUnprotectedReplay = any {
    nondet t = TASK_IDS.oneOf()
    startTask(t),
    nondet t = TASK_IDS.oneOf()
    completeTask(t),
    nondet t = TASK_IDS.oneOf()
    unsafeReplayInPlaceWhileConsumerActive(t),
    cancelNursery,
  }

  // -------------------------------------------------------------------------
  // SAFETY INVARIANTS
  // -------------------------------------------------------------------------

  // 1. No linear-one-shot side-effecting task executes more than once.
  val invNoLinearEffectReplay: bool =
    not(linearReplayFault) and
    LINEAR_TASKS.forall(t => execCount.get(t) <= 1)

  // 2. Zero concurrent read-write races on any shared continuation/device buffer:
  //    if a slot has an active writer, it MUST have zero active readers!
  val invNoReadWriteRace: bool =
    not(rwRaceFault) and
    ALL_BUFS.forall(b => bufWriter.get(b) != 0 implies bufReaders.get(b).size() == 0)

  // 3. Snapshot stability for in-place buffers: if a downstream consumer is
  //    running and reading a predecessor's current `activeBuf`, that predecessor
  //    MUST NOT be concurrently writing to that same slot.
  val invSnapshotImmutability: bool =
    TASK_IDS.forall(u =>
      taskState.get(u) == "running" implies
        readBufs.get(u).forall(b => bufWriter.get(b) == 0)
    )

  // 4. Exclusive writer ownership matches running tasks 1:1.
  val invExclusiveBufferOwnership: bool =
    TASK_IDS.forall(t =>
      (taskState.get(t) == "running") == (bufWriter.get(activeBuf.get(t)) == t)
    )

  // 5. Nursery cancellation reclaims every writer lock and reader pin.
  val invCancelReclaimsAll: bool =
    nurseryCancelled implies ALL_BUFS.forall(b =>
      bufWriter.get(b) == 0 and bufReaders.get(b).size() == 0
    )

  val allInvariants: bool = all {
    invNoLinearEffectReplay,
    invNoReadWriteRace,
    invSnapshotImmutability,
    invExclusiveBufferOwnership,
    invCancelReclaimsAll,
  }

  // -------------------------------------------------------------------------
  // EXECUTABLE COUNTEREXAMPLE & WITNESS TESTS (`quint test`)
  // -------------------------------------------------------------------------

  // Exact deterministic reproduction of Kontinuum seed `0x67ad584bee771187`:
  //   1. task 1, 2, 3 complete -> buf[3] published
  //   2. task 4 starts `"running"` and pins buf[3] in `bufReaders`
  //   3. unguarded `unsafeReplayInPlaceWhileConsumerActive(3)` overwrites buf[3]
  //   4. `invNoReadWriteRace` and `invSnapshotImmutability` BOTH FAIL!
  run inPlaceReplayWhileDownstreamReadingCounterexampleTest =
    init
      .then(startTask(1)).then(completeTask(1))
      .then(startTask(2)).then(completeTask(2))
      .then(startTask(3)).then(completeTask(3))
      .then(startTask(4))
      .then(unsafeReplayInPlaceWhileConsumerActive(3))
      .expect(not(invNoReadWriteRace) and not(invSnapshotImmutability) and not(allInvariants))

  // Negative control: replaying a consumed linear-one-shot RDMA/IO task (task 2)
  // immediately violates `invNoLinearEffectReplay`.
  run linearEffectReplayCounterexampleTest =
    init
      .then(startTask(1)).then(completeTask(1))
      .then(startTask(2)).then(completeTask(2))
      .then(unsafeReplayLinearEffect(2))
      .expect(not(invNoLinearEffectReplay) and not(allInvariants))

  // Positive witness (Resolution B): while `task 4` is actively reading `buf[3]`,
  // `replayPureWithCowFork(3)` allocates fresh COW slot `buf[5]` — zero R/W race!
  run cowForkReplayWhileDownstreamReadingSafeTest =
    init
      .then(startTask(1)).then(completeTask(1))
      .then(startTask(2)).then(completeTask(2))
      .then(startTask(3)).then(completeTask(3))
      .then(startTask(4))
      .then(replayPureWithCowFork(3))
      .then(completeTask(3))
      .then(completeTask(4))
      .expect(allInvariants and activeBuf.get(3) == 5 and execCount.get(3) == 2)

  // Positive witness (Resolution A): in-place replay BEFORE downstream `task 4`
  // starts (`task 4 == "pending"`, `bufReaders[3] == {}`) is strictly safe.
  run quiescentInPlaceReplaySafeTest =
    init
      .then(startTask(3)).then(completeTask(3))
      .then(replayPureInPlace(3)).then(completeTask(3))
      .then(startTask(1)).then(completeTask(1))
      .then(startTask(2)).then(completeTask(2))
      .then(startTask(4)).then(completeTask(4))
      .expect(allInvariants and activeBuf.get(3) == 3 and execCount.get(3) == 2)

  // Positive witness: cooperative cancellation while task 4 & COW replay are in flight.
  run nurseryCancelReclaimsAllTest =
    init
      .then(startTask(1)).then(completeTask(1))
      .then(startTask(2)).then(completeTask(2))
      .then(startTask(3)).then(completeTask(3))
      .then(startTask(4))
      .then(replayPureWithCowFork(3))
      .then(cancelNursery)
      .expect(allInvariants and nurseryCancelled)
}

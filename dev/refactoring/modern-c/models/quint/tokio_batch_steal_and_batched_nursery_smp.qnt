// Phase C13 Formal Model:
//   1. Tokio/Go SPSC-Push + MPMC-FIFO CAS(head) Local Runqueue with Batch Work-Stealing
//      (owner_pop claims [h, h+1), thief steal_batch claims [h, h+n) on the SAME head!)
//   2. Per-Worker Batched Nursery Completion Flushing (eliminates 16x ldaddal contention)
//      with strict zero-premature-wakeup and zero-deadlock guarantees.

module tokio_batch_steal_and_batched_nursery_smp {
  pure val Q_CAP = 4
  pure val MAX_TASKS = 6
  pure val MAX_BATCH = 2

  // Worker 0's Tokio-style local runqueue (head, tail)
  var qHead: int
  var qTail: int
  var spawned: int
  var ownerPopped: int
  var thiefStolen: int

  // Batched nursery completion model (3 children spawned + 1 parent scope = initial active 4)
  var nurseryActive: int   // atomic nursery.active counter
  var liveChildren: int    // children not yet finished
  var parentExited: bool   // parent exited proc and decremented its own 1
  var w0Batch: int         // un-flushed completions held privately by Worker 0
  var w1Batch: int         // un-flushed completions held privately by Worker 1
  var parentWoken: bool

  action init = all {
    qHead' = 0,
    qTail' = 0,
    spawned' = 0,
    ownerPopped' = 0,
    thiefStolen' = 0,
    nurseryActive' = 4, // 1 parent + 3 children
    liveChildren' = 3,
    parentExited' = false,
    w0Batch' = 0,
    w1Batch' = 0,
    parentWoken' = false,
  }

  // Worker 0 SPSC push (owner-only tail advance)
  action owner_push = all {
    spawned < MAX_TASKS,
    (qTail - qHead) < Q_CAP,
    qTail' = qTail + 1,
    spawned' = spawned + 1,
    qHead' = qHead, ownerPopped' = ownerPopped, thiefStolen' = thiefStolen,
    nurseryActive' = nurseryActive, liveChildren' = liveChildren,
    parentExited' = parentExited, w0Batch' = w0Batch, w1Batch' = w1Batch,
    parentWoken' = parentWoken,
  }

  // Worker 0 FIFO pop via CAS(qHead, h -> h + 1)
  action owner_pop = all {
    qHead < qTail,
    qHead' = qHead + 1,
    ownerPopped' = ownerPopped + 1,
    qTail' = qTail, spawned' = spawned, thiefStolen' = thiefStolen,
    nurseryActive' = nurseryActive, liveChildren' = liveChildren,
    parentExited' = parentExited, w0Batch' = w0Batch, w1Batch' = w1Batch,
    parentWoken' = parentWoken,
  }

  // Thief batch-steal via ONE CAS(qHead, h -> h + n) where n = min((avail+1)/2, 2)
  action thief_steal_batch = {
    val avail = qTail - qHead
    val half = (avail + 1) / 2
    val n = if (half > 2) 2 else half
    all {
      avail > 0,
      n >= 1,
      qHead' = qHead + n,
      thiefStolen' = thiefStolen + n,
      qTail' = qTail, spawned' = spawned, ownerPopped' = ownerPopped,
      nurseryActive' = nurseryActive, liveChildren' = liveChildren,
      parentExited' = parentExited, w0Batch' = w0Batch, w1Batch' = w1Batch,
      parentWoken' = parentWoken,
    }
  }

  // Nursery parent finishes proc body and decrements its own 1 from nurseryActive
  action nursery_parent_exit = all {
    not(parentExited),
    parentExited' = true,
    nurseryActive' = nurseryActive - 1,
    parentWoken' = (nurseryActive - 1 == 0),
    liveChildren' = liveChildren, w0Batch' = w0Batch, w1Batch' = w1Batch,
    qHead' = qHead, qTail' = qTail, spawned' = spawned,
    ownerPopped' = ownerPopped, thiefStolen' = thiefStolen,
  }

  // Worker 0 finishes a nursery child: accumulates into w0Batch (flushes if hits MAX_BATCH)
  action w0_child_done = {
    val nextB = w0Batch + 1
    val doFlush = (nextB >= MAX_BATCH)
    all {
      liveChildren > 0,
      liveChildren' = liveChildren - 1,
      w0Batch' = if (doFlush) 0 else nextB,
      nurseryActive' = if (doFlush) nurseryActive - nextB else nurseryActive,
      parentWoken' = (parentWoken or (doFlush and (nurseryActive - nextB == 0))),
      parentExited' = parentExited, w1Batch' = w1Batch,
      qHead' = qHead, qTail' = qTail, spawned' = spawned,
      ownerPopped' = ownerPopped, thiefStolen' = thiefStolen,
    }
  }

  // Worker 1 finishes a nursery child: accumulates into w1Batch (flushes if hits MAX_BATCH)
  action w1_child_done = {
    val nextB = w1Batch + 1
    val doFlush = (nextB >= MAX_BATCH)
    all {
      liveChildren > 0,
      liveChildren' = liveChildren - 1,
      w1Batch' = if (doFlush) 0 else nextB,
      nurseryActive' = if (doFlush) nurseryActive - nextB else nurseryActive,
      parentWoken' = (parentWoken or (doFlush and (nurseryActive - nextB == 0))),
      parentExited' = parentExited, w0Batch' = w0Batch,
      qHead' = qHead, qTail' = qTail, spawned' = spawned,
      ownerPopped' = ownerPopped, thiefStolen' = thiefStolen,
    }
  }

  // Mandatory flush on park / yield / tick / idle for W0 and W1
  action w0_flush_batch = all {
    w0Batch > 0,
    nurseryActive' = nurseryActive - w0Batch,
    parentWoken' = (parentWoken or (nurseryActive - w0Batch == 0)),
    w0Batch' = 0,
    liveChildren' = liveChildren, parentExited' = parentExited, w1Batch' = w1Batch,
    qHead' = qHead, qTail' = qTail, spawned' = spawned,
    ownerPopped' = ownerPopped, thiefStolen' = thiefStolen,
  }

  action w1_flush_batch = all {
    w1Batch > 0,
    nurseryActive' = nurseryActive - w1Batch,
    parentWoken' = (parentWoken or (nurseryActive - w1Batch == 0)),
    w1Batch' = 0,
    liveChildren' = liveChildren, parentExited' = parentExited, w0Batch' = w0Batch,
    qHead' = qHead, qTail' = qTail, spawned' = spawned,
    ownerPopped' = ownerPopped, thiefStolen' = thiefStolen,
  }

  action step = any {
    owner_push,
    owner_pop,
    thief_steal_batch,
    nursery_parent_exit,
    w0_child_done,
    w1_child_done,
    w0_flush_batch,
    w1_flush_batch,
  }

  // INVARIANT 1: Exact task conservation in Tokio-style batch-steal queue (0 loss, 0 double-consume)
  val inv_tokio_queue_conservation =
    qHead <= qTail and
    (qTail - qHead) <= Q_CAP and
    (qTail - qHead) + ownerPopped + thiefStolen == spawned

  // INVARIANT 2: Exact nursery active accounting across live children + parent + all private batches
  val inv_nursery_exact_accounting =
    nurseryActive == liveChildren + (if (parentExited) 0 else 1) + w0Batch + w1Batch and
    nurseryActive >= 0

  // INVARIANT 3: Zero premature parent wakeup (parentWoken => 0 live children & parent exited & 0 batches)
  val inv_no_premature_wakeup =
    parentWoken implies (liveChildren == 0 and parentExited and w0Batch == 0 and w1Batch == 0 and nurseryActive == 0)

  val inv_all =
    inv_tokio_queue_conservation and
    inv_nursery_exact_accounting and
    inv_no_premature_wakeup
}

module gc_rank_values {
  import gc_recursive_queue_wait.* from "../../models/gambit/gc_recursive_queue_wait"
  import gc_recursive_queue_rank.* from "../../models/gambit/gc_recursive_queue_rank"

  val initialMeasureTest = measureOf(initial("source", "none")) == 5148
  val copyProgressTest = {
    val before = initial("source", "none")
    val after = before.with("copied", before.copied.set(0, 1))
    measureOf(after) - measureOf(before) == 256
  }
  val pendingQueueOrderTest = {
    val before = initial("source", "none")
    val after = { ...before, work: before.work.set(0, 1), queueOf: before.queueOf.set(0, 3) }
    firstPending(before) == 4 and firstPending(after) == 2
  }
  val retryWithPendingTest = {
    val before = initial("combined", "none")
    val queued = { ...before, work: before.work.set(0, 1), queueOf: before.queueOf.set(0, 0),
      remaining: before.remaining.set(2, Set()), found: before.found.set(2, true),
      mode: before.mode.set(2, "recheck") }
    workerProgress(queued.with("mode", queued.mode.set(2, "active")), 2) > workerProgress(queued, 2)
  }
  val retryWithoutPendingTest = {
    val before = initial("combined", "none")
    val rechecking = { ...before, remaining: before.remaining.set(2, Set()),
      found: before.found.set(2, true), mode: before.mode.set(2, "recheck") }
    workerProgress(rechecking.with("mode", rechecking.mode.set(2, "active")), 2) > workerProgress(rechecking, 2)
  }
  val terminalMeasureTest = {
    val before = initial("source", "none")
    val after = { ...before, work: objects.mapBy(o => 3), copied: objects.mapBy(o => 2),
      headDone: objects, tailDone: objects, spuriousUsed: workers,
      mode: workers.mapBy(w => "done"), terminated: true }
    measureOf(after) == 51540 and measureOf(after) <= 51588
  }
}

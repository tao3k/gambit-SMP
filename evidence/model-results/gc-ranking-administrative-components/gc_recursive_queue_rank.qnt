module gc_recursive_queue_rank {
  import gc_recursive_queue_wait.* from "./gc_recursive_queue_wait"
  import gc_recursive_queue_induction.* from "./gc_recursive_queue_induction"

  // Proof-only history. No guard or assignment of the original state is added.
  var priorPrimary: int
  var priorWorkers: int -> int
  var advanced: bool

  pure def pendingAt(st: State, q: int): bool = objects.exists(o =>
    st.work.get(o) == 1 and st.queueOf.get(o) == q)

  pure def firstPending(st: State): int =
    if (pendingAt(st, 2)) 0 else if (pendingAt(st, 0)) 1 else
    if (pendingAt(st, 3)) 2 else if (pendingAt(st, 1)) 3 else 4

  pure def objectContribution(st: State, o: int): int = {
    val publication = if (st.pub.get(o) == 0 and st.work.get(o) >= 2) 5 else st.pub.get(o)
    (st.work.get(o) + 1) * 10 + st.copied.get(o) + publication +
      (if (st.headDone.contains(o)) 1 else 0) + (if (st.tailDone.contains(o)) 1 else 0)
  }
  // Explicit sums avoid unordered-set fold expansion for these fixed roles.
  pure def objectProgress(st: State): int = objectContribution(st, 0) +
    objectContribution(st, 1) + objectContribution(st, 2) + objectContribution(st, 3) +
    st.spuriousUsed.size() + (if (st.terminated) 1 else 0)

  pure def workerProgress(st: State, w: int): int = {
    val mode = st.mode.get(w)
    val first = firstPending(st)
    val checked = 4 - st.remaining.get(w).size()
    if (first == 4) {
      if (mode == "active") 1 else
      if (mode == "probe") 2 + st.probeIndex.get(w) else
      if (mode == "probed") 7 else
      if (mode == "recheck") (if (st.found.get(w)) -5 + checked else 8 + checked) else
      if (mode == "pre-wait") 13 else if (mode == "waiting") 14 else
      if (mode == "woken") 0 else if (mode == "done") 15 else
      if (mode == "claim-locked") 25 else 16
    } else {
      if (mode == "active") 20 else
      if (mode == "probe") (if (st.probeIndex.get(w) <= first)
        21 + st.probeIndex.get(w) else -6 + st.probeIndex.get(w)) else
      if (mode == "probed") 0 else
      if (mode == "recheck") (if (st.found.get(w)) 6 + checked else 1 + checked) else
      if (mode == "pre-wait") 14 else if (mode == "waiting") 15 else
      if (mode == "woken") 0 else if (mode == "done") 27 else
      if (mode == "claim-locked") 25 else 26
    }
  }

  // Primary <= 201; shifted secondary is in [0,132]. Weight 256 makes any
  // primary increase dominate every possible secondary decrease.
  pure def measureOf(st: State): int = 256 * objectProgress(st) +
    workerProgress(st, 0) + workerProgress(st, 1) + workerProgress(st, 2) +
    workerProgress(st, 3) + 24
  pure def workerVectorOf(st: State): int -> int = Map(
    0 -> workerProgress(st, 0), 1 -> workerProgress(st, 1),
    2 -> workerProgress(st, 2), 3 -> workerProgress(st, 3))
  val rankBound = measureOf(s) >= 0 and measureOf(s) <= 51588
  // Safety preservation is bound to a separate complete transition receipt.
  val rankStep = rankBound and
    (not(advanced) or terminal or objectProgress(s) > priorPrimary or
      (objectProgress(s) == priorPrimary and
        workers.forall(w => workerProgress(s, w) >= priorWorkers.get(w)) and
        workers.exists(w => workerProgress(s, w) > priorWorkers.get(w))))
  action initRank = all { initSafetyCandidate, priorPrimary' = 0,
    priorWorkers' = Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0), advanced' = false }

  action ranked_copyWord = all { copyWord, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_beginPublish = all { beginPublish, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_publish = all { publish, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_releasePublication = all { releasePublication, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_acquireSignalMutex = all { acquireSignalMutex, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_signalWork = all { signalWork, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_finishHead = all { finishHead, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_claimLocal = all { claimLocal, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_claimQueue = all { claimQueue, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_popQueue = all { popQueue, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_markTail = all { markTail, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_finishScan = all { finishScan, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_startProbe = all { startProbe, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_probeEmptyQueue = all { probeEmptyQueue, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_finishProbe = all { finishProbe, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_lockTermination = all { lockTermination, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_probeRecheckQueue = all { probeRecheckQueue, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_countOrRetry = all { countOrRetry, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_registerWait = all { registerWait, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_spuriousWake = all { spuriousWake, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_resume = all { resume, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action ranked_finished = all { finished, priorPrimary' = objectProgress(s), priorWorkers' = workerVectorOf(s), advanced' = true }
  action rankAll = any { ranked_copyWord, ranked_beginPublish, ranked_publish,
    ranked_releasePublication, ranked_acquireSignalMutex, ranked_signalWork,
    ranked_finishHead, ranked_claimLocal, ranked_claimQueue, ranked_popQueue,
    ranked_markTail, ranked_finishScan, ranked_startProbe, ranked_probeEmptyQueue,
    ranked_finishProbe, ranked_lockTermination, ranked_probeRecheckQueue,
    ranked_countOrRetry, ranked_registerWait, ranked_spuriousWake, ranked_resume,
    ranked_finished }
}

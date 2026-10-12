module gc_recursive_queue_guards {
  import gc_recursive_queue_wait.* from "./gc_recursive_queue_wait"
  import gc_recursive_queue_induction.* from "./gc_recursive_queue_induction"
  val guard_copyWord = exists(objects, ((o) => val w = get(field(s, "owner"), o) { and(eq(get(field(s, "work"), o), 0), eq(get(field(s, "pub"), o), 0), contains(Set("active", "scanning"), get(field(s, "mode"), w)), ilt(get(field(s, "copied"), o), 2)) }))
  val guard_beginPublish = exists(objects, ((o) => val w = get(field(s, "owner"), o) { val q = ite(eq(field(s, "fault"), "origin-queue"), get(originQueue, o), w) { and(eq(get(field(s, "pub"), o), 0), or(and(eq(get(field(s, "work"), o), 0), contains(Set("active", "scanning"), get(field(s, "mode"), w))), and(and(eq(field(s, "fault"), "local-reexport"), eq(get(field(s, "work"), o), 2)), eq(get(field(s, "route"), o), "local"))), or(eq(get(field(s, "copied"), o), 2), eq(field(s, "fault"), "early-publication")), eq(get(field(s, "queueOwner"), q), iuminus(1))) } }))
  val guard_publish = exists(objects, ((o) => eq(get(field(s, "pub"), o), 1)))
  val guard_releasePublication = exists(objects, ((o) => eq(get(field(s, "pub"), o), 2)))
  val guard_acquireSignalMutex = exists(objects, ((o) => and(eq(field(s, "policy"), "combined"), eq(get(field(s, "pub"), o), 3), eq(field(s, "mutex"), iuminus(1)))))
  val guard_signalWork = exists(objects, ((o) => val w = get(field(s, "owner"), o) { val waiting = filter(workers, ((x) => eq(get(field(s, "mode"), x), "waiting"))) { exists(ite(eq(waiting, Set()), Set(iuminus(1)), waiting), ((wake) => or(and(eq(field(s, "policy"), "source"), eq(get(field(s, "pub"), o), 3)), and(and(eq(field(s, "policy"), "combined"), eq(get(field(s, "pub"), o), 4)), eq(field(s, "mutex"), w))))) } }))
  val guard_finishHead = exists(objects, ((o) => val w = get(field(s, "owner"), o) { and(not(contains(field(s, "headDone"), o)), contains(workers, w), eq(get(field(s, "copied"), o), 2), contains(Set("active", "scanning"), get(field(s, "mode"), w))) }))
  val guard_claimLocal = exists(workers, ((w) => exists(objects, ((o) => and(eq(get(field(s, "mode"), w), "active"), eq(get(field(s, "owner"), o), w), eq(get(field(s, "work"), o), 0), eq(get(field(s, "pub"), o), 0), eq(get(field(s, "copied"), o), 2), not(markingWork(w)), not(queuePending(w)))))))
  val guard_claimQueue = exists(workers, ((w) => exists(queued, ((o) => val q = get(field(s, "queueOf"), o) { and(or(and(and(eq(get(field(s, "mode"), w), "active"), eq(q, w)), not(markingWork(w))), and(eq(get(field(s, "mode"), w), "probe"), ready(w))), eq(get(field(s, "queueOwner"), q), iuminus(1))) }))))
  val guard_popQueue = exists(workers, ((w) => val o = get(field(s, "target"), w) { and(eq(get(field(s, "mode"), w), "claim-locked"), eq(get(field(s, "work"), o), 1)) }))
  val guard_markTail = exists(workers, ((w) => val o = get(field(s, "target"), w) { and(eq(get(field(s, "mode"), w), "scanning"), not(contains(field(s, "tailDone"), o))) }))
  val guard_finishScan = exists(workers, ((w) => val o = get(field(s, "target"), w) { and(eq(get(field(s, "mode"), w), "scanning"), contains(field(s, "tailDone"), o), not(markingWork(w))) }))
  val guard_startProbe = exists(workers, ((w) => and(eq(get(field(s, "mode"), w), "active"), or(or(and(ready(w), not(queuePending(w))), eq(field(s, "fault"), "early-idle")), and(ready(w), eq(field(s, "fault"), "skip-local-drain"))))))
  val guard_probeEmptyQueue = exists(workers, ((w) => val index = get(field(s, "probeIndex"), w) { and(eq(get(field(s, "mode"), w), "probe"), ilt(index, 4), not(queuePending(nth(probeOrder, index)))) }))
  val guard_finishProbe = exists(workers, ((w) => and(eq(get(field(s, "mode"), w), "probe"), eq(get(field(s, "probeIndex"), w), 4))))
  val guard_lockTermination = exists(workers, ((w) => and(eq(get(field(s, "mode"), w), "probed"), eq(field(s, "mutex"), iuminus(1)))))
  val guard_probeRecheckQueue = exists(workers, ((w) => exists(get(field(s, "remaining"), w), ((q) => and(eq(get(field(s, "mode"), w), "recheck"), eq(field(s, "mutex"), w), eq(get(field(s, "queueOwner"), q), iuminus(1)))))))
  val guard_countOrRetry = exists(workers, ((w) => and(eq(get(field(s, "mode"), w), "recheck"), eq(get(field(s, "remaining"), w), Set()), eq(field(s, "mutex"), w))))
  val guard_registerWait = exists(workers, ((w) => and(eq(get(field(s, "mode"), w), "pre-wait"), eq(field(s, "mutex"), w))))
  val guard_spuriousWake = exists(workers, ((w) => and(eq(get(field(s, "mode"), w), "waiting"), not(contains(field(s, "spuriousUsed"), w)))))
  val guard_resume = exists(workers, ((w) => and(eq(get(field(s, "mode"), w), "woken"), eq(field(s, "mutex"), iuminus(1)))))
  val guard_finished = terminal
  val guardCoverage = or(terminal, guard_copyWord, guard_beginPublish, guard_publish, guard_releasePublication, guard_acquireSignalMutex, guard_signalWork, guard_finishHead, guard_claimLocal, guard_claimQueue, guard_popQueue, guard_markTail, guard_finishScan, guard_startProbe, guard_probeEmptyQueue, guard_finishProbe, guard_lockTermination, guard_probeRecheckQueue, guard_countOrRetry, guard_registerWait, guard_spuriousWake, guard_resume, guard_finished)
  val rejectsTerminalOnly = terminal
}

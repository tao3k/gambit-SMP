module source029_recheck {
  import gc_recursive_source029.* from "../../models/gambit/gc_recursive_source029"

  pure def atRecheck(pending: bool, busy: bool): State = {
    val st = initial("combined", "none")
    { ...st, mode: st.mode.set(2, "recheck"), mutex: 2,
      remaining: st.remaining.set(2, queues),
      work: if (pending) st.work.set(2, 1) else st.work,
      owner: if (pending) st.owner.set(2, 3) else st.owner,
      queueOf: if (pending) st.queueOf.set(2, 3) else st.queueOf,
      queueOwner: if (busy) st.queueOwner.set(3, 1) else st.queueOwner }
  }
  action initPending = s' = atRecheck(true, false)
  action initEmpty = s' = atRecheck(false, false)
  action initBusy = s' = atRecheck(false, true)

  run pendingReleasesMutexTest = initPending.then(recheck029(2, 3))
    .expect(s.mode.get(2) == "active" and s.mutex == -1 and s.count == 4 and
      s.remaining.get(2) == Set())
  run emptyKeepsMutexTest = initEmpty.then(recheck029(2, 3))
    .expect(s.mode.get(2) == "recheck" and s.mutex == 2 and s.count == 4 and
      s.remaining.get(2) == Set(0, 1, 2))
  run lowerQueueCannotJumpTest = initEmpty.then(recheck029(2, 0).fail())
    .expect(s == atRecheck(false, false))
  run busyQueueCannotBeReadTest = initBusy.then(recheck029(2, 3).fail())
    .expect(s == atRecheck(false, true))

  action initAlreadyWoken = {
    val st = initial("combined", "none")
    s' = { ...st, mode: st.mode.set(2, "waiting"), count: 3,
      spuriousUsed: Set(2) }
  }
  run repeatedWakeAllowedTest = initAlreadyWoken.then(wake029(2))
    .expect(s.mode.get(2) == "woken" and s.count == 3 and s.spuriousUsed == Set(2))
}

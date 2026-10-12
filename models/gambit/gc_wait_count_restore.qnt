module gc_wait_count_restore {
  // Two roles and at most two spurious wakes: finite protocol bounds, not CPUs.
  type State = { policy: str, producer: str, helper: str, mutex: str,
    count: int, wakes: int, terminated: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, producer: "active", helper: "active", mutex: "none",
    count: 2, wakes: 0, terminated: false,
  }
  action initOld = s' = initial("omit-restore")
  action initRestoreZero = s' = initial("restore-zero")
  action init = s' = initial("source")

  action helperLocks = all {
    s.helper == "active", s.mutex == "none",
    s' = { ...s, helper: "locked", mutex: "helper" },
  }
  // All work for this activation has completed before decrementing.
  action helperCounts = all {
    s.helper == "locked", s.mutex == "helper",
    s' = if (s.count == 1)
      { ...s, helper: "done", producer: "done", count: 0,
        mutex: "none", terminated: true }
    else { ...s, helper: "pre-wait", count: s.count - 1 },
  }
  action registerWait = all {
    s.helper == "pre-wait", s.mutex == "helper",
    s' = { ...s, helper: "waiting", mutex: "none" },
  }
  action spuriousWake = all {
    s.helper == "waiting", s.wakes < 2,
    s' = { ...s, helper: "woken", wakes: s.wakes + 1 },
  }
  // Fold producer lock/count/signal/unlock; no publication occurs in this step.
  action producerFinishes = all {
    s.producer == "active", s.mutex == "none",
    s' = if (s.count == 1)
      { ...s, producer: "done", count: 0, terminated: true,
        helper: if (s.helper == "waiting") "woken" else s.helper }
    else { ...s, producer: "waiting", count: s.count - 1 },
  }
  action reacquire = all {
    s.helper == "woken", s.mutex == "none",
    s' = { ...s, helper: "resume-locked", mutex: "helper" },
  }
  // A wake notification does not reserve activity: test count after reacquire.
  action resume = all {
    s.helper == "resume-locked", s.mutex == "helper",
    s' = if (s.count == 0 and s.policy != "restore-zero")
      { ...s, helper: "done", mutex: "none" }
    else { ...s, helper: "active", mutex: "none",
      count: if (s.policy == "omit-restore") s.count else s.count + 1 },
  }
  val counted = (if (s.producer == "active") 1 else 0) +
    (if (Set("active", "locked").contains(s.helper)) 1 else 0)
  val safe = s.count == counted and s.count >= 0 and s.count <= 2 and
    (not(s.terminated) or s.count == 0)
  val nonzeroRestoreSafe = safe
  val zeroExitSafe = safe
  val terminal = s.producer == "done" and s.helper == "done"
  action finished = all { terminal, s' = s }
  action step = any { helperLocks, helperCounts, registerWait, spuriousWake,
    producerFinishes, reacquire, resume, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

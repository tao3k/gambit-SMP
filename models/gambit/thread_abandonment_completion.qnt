module thread_abandonment_completion {
  // Two mutex identities are a finite ownership bound, not a host CPU setting.
  // owner 0 is closing; owner 1 is a distinct live thread; -1 is abandoned.
  type State = { latePublish: bool, checkOwner: bool, closeAdmission: bool,
    phase: int, selected: int, owners: int -> int, transferred: Set[int],
    endPublished: bool, joined: bool, admittedClosing: bool }
  var s: State
  pure def initialState(late: bool, check: bool, close: bool): State = {
    latePublish: late, checkOwner: check, closeAdmission: close,
    phase: 0, selected: -1, owners: Map(0 -> 0, 1 -> 0),
    transferred: Set(), endPublished: false, joined: false,
    admittedClosing: false,
  }
  // Incomplete repairs, not claims of new native observations.
  action initOld = s' = initialState(false, true, true)
  action initNoRecheck = s' = initialState(true, false, true)
  action initAllowClosing = s' = initialState(true, true, false)
  action initFixed = s' = initialState(true, true, true)
  val owned = Set(0, 1).filter(id => s.owners.get(id) == 0)

  action beginTermination = all {
    s.phase == 0,
    s' = { ...s, phase: 1, endPublished: not(s.latePublish) },
  }
  // Select under the owner lock, then release it before taking the mutex lock.
  action selectAndDrop = {
    nondet id = owned.oneOf()
    all { s.phase == 1, s' = { ...s, phase: 2, selected: id } }
  }
  // Public unlock/transfer can intervene while the termination lock is dropped.
  action transfer = all {
    s.phase == 2, s.owners.get(s.selected) == 0,
    s' = { ...s, owners: s.owners.set(s.selected, 1),
      transferred: s.transferred.union(Set(s.selected)) },
  }
  // Holding mutex then owner lock, revalidate the selected mutex's owner.
  action abandon = all {
    s.phase == 2,
    s' = { ...s, phase: 3, owners:
      if (not(s.checkOwner) or s.owners.get(s.selected) == 0)
        s.owners.set(s.selected, -1) else s.owners },
  }
  action resumeCleanup = all {
    s.phase == 3, s' = { ...s, phase: 1, selected: -1 },
  }
  action publishCompletion = all {
    s.phase == 1, owned == Set(),
    s' = { ...s, phase: 4, endPublished: true },
  }
  // Delaying end-condvar clearing alone admits a closing owner if all callers
  // continue using that field instead of the already-set continuation marker.
  action grantToClosing = {
    nondet id = Set(0, 1).exclude(owned).oneOf()
    all {
      s.phase == 2, not(s.closeAdmission), not(s.admittedClosing),
      not(s.endPublished),
      s' = { ...s, owners: s.owners.set(id, 0), admittedClosing: true },
    }
  }
  // Join observes the public completion field only with the thread lock free.
  action join = all {
    s.endPublished, not(s.joined), s.phase == 2 or s.phase == 4,
    s' = { ...s, joined: true },
  }
  val terminal = s.phase == 4 and s.joined
  action finished = all { terminal, s' = s }
  action step = any { beginTermination, selectAndDrop, transfer, abandon,
    resumeCleanup, publishCompletion, grantToClosing, join, finished }
  val joinSafe = not(s.joined) or owned == Set()
  val foreignOwnerSafe = s.transferred.forall(id => s.owners.get(id) == 1)
  val admissionSafe = not(s.admittedClosing)
  val safe = joinSafe and foreignOwnerSafe and admissionSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

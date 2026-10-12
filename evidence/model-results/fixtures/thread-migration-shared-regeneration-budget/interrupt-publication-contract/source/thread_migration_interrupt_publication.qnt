module thread_migration_interrupt_publication {
  // One migrating thread and one interrupt sender; no CPU limit is implied.
  // Queue mutations are atomic abstractions of processor-locked tree updates.
  type State = { fixed: bool, migration: int, sender: int, threadLock: int,
    executing: bool, queueEntries: int }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, migration: 0, sender: 0, threadLock: 0,
    executing: true, queueEntries: 0,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action migrationCapture = all {
    s.migration == 0, not(s.fixed) or s.threadLock == 0,
    s' = { ...s, migration: 1,
      threadLock: if (s.fixed) 1 else s.threadLock },
  }
  action migrationDetach = all {
    s.migration == 1, s' = { ...s, migration: 2, executing: false },
  }
  action migrationPublish = all {
    s.migration == 2,
    s' = { ...s, migration: 3, queueEntries: s.queueEntries + 1 },
  }
  action migrationRelease = all {
    s.migration == 3,
    s' = { ...s, migration: 4,
      threadLock: if (s.fixed) 0 else s.threadLock },
  }
  action senderAcquire = all {
    s.sender == 0, s.threadLock == 0,
    s' = { ...s, sender: 1, threadLock: 2 },
  }
  // The helper removes any observed entry, then calls its callback still locked.
  action senderRemove = all {
    s.sender == 1, s' = { ...s, sender: 2, queueEntries: 0 },
  }
  // Callback reads execution ownership later, not at the queue-removal instant.
  action senderRoute = all {
    s.sender == 2,
    s' = { ...s, sender: 3,
      queueEntries: if (s.executing) s.queueEntries else s.queueEntries + 1 },
  }
  action senderRelease = all {
    s.sender == 3, s' = { ...s, sender: 4, threadLock: 0 },
  }
  val finished = s.migration == 4 and s.sender == 4
  action terminal = all { finished, s' = s }
  action step = any { migrationCapture, migrationDetach, migrationPublish,
    migrationRelease, senderAcquire, senderRemove, senderRoute, senderRelease, terminal }
  val singleQueueMembership = s.queueEntries <= 1
  val publicationLocked = not(s.fixed and s.migration > 0 and s.migration < 4)
    or s.threadLock == 1
  val safe = singleQueueMembership and publicationLocked
  temporal completion = weakFair(step, Set(s)).implies(eventually(finished))
}

module continuation_scan_lock_order {
  // One producer, one scanner, one already eligible chunk and a later publish.
  // Owners: 0=unowned, 1=producer, 2=scanner. Not machine CPU counts.
  type State = { retainQueue: bool, producer: int, consumer: int,
    miscOwner: int, queueOwner: int, linkReady: bool, earlyRead: bool }
  var s: State
  pure def initialState(retainQueue: bool): State = {
    retainQueue: retainQueue, producer: 0, consumer: 0,
    miscOwner: 1, queueOwner: 0, linkReady: false, earlyRead: false,
  }
  // Rejected placement: acquire MISC while retaining the dequeue lock.
  action initOld = s' = initialState(true)
  // Proposed frame-only MISC lock, after the existing dequeue unlock.
  action initFixed = s' = initialState(false)

  // The copier owns MISC across rollover and end_heap_chunk publication.
  action producerQueueLock = all {
    s.producer == 0, s.queueOwner == 0,
    s' = { ...s, producer: 1, queueOwner: 1 },
  }
  action producerPublish = all {
    s.producer == 1, s.queueOwner == 1,
    s' = { ...s, producer: 2, queueOwner: 0 },
  }
  action completeLink = all {
    s.producer == 2, s.miscOwner == 1,
    s' = { ...s, producer: 3, linkReady: true },
  }
  action producerUnlock = all {
    s.producer == 3, s.miscOwner == 1,
    s' = { ...s, producer: 4, miscOwner: 0 },
  }

  action dequeue = all {
    s.consumer == 0, s.queueOwner == 0,
    s' = { ...s, consumer: 1, queueOwner: 2 },
  }
  action leaveQueue = all {
    s.consumer == 1, s.queueOwner == 2,
    s' = { ...s, consumer: 2,
      queueOwner: if (s.retainQueue) 2 else 0 },
  }
  action scannerLock = all {
    s.consumer == 2, s.miscOwner == 0,
    s' = { ...s, consumer: 3, miscOwner: 2 },
  }
  // Entire link read/mask/mark/restore interval must be inside this lock.
  action scanFrame = all {
    s.consumer == 3, s.miscOwner == 2,
    s' = { ...s, consumer: 4, earlyRead: not(s.linkReady) },
  }
  action scannerUnlock = all {
    s.consumer == 4, s.miscOwner == 2,
    s' = { ...s, consumer: 5, miscOwner: 0, queueOwner: 0 },
  }

  val terminal = s.producer == 4 and s.consumer == 5
  action finished = all { terminal, s' = s }
  action step = any { producerQueueLock, producerPublish, completeLink,
    producerUnlock, dequeue, leaveQueue, scannerLock, scanFrame,
    scannerUnlock, finished }
  val noDeadlock = terminal or enabled(step)
  val readySafe = not(s.earlyRead)
  val ownership = (s.producer < 4).implies(s.miscOwner == 1) and
    (s.consumer == 3 or s.consumer == 4).implies(s.miscOwner == 2)
  val safe = noDeadlock and readySafe and ownership
  temporal progress = always(noDeadlock) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

module gc_scan_termination {
  // Source characterization with a detached-publisher fault control, not a
  // claim that Gambit contains that fault. Two workers, one produced chunk,
  // strong then weak phase. Count/wait updates use one abstract mutex;
  // queue operations and publication are coherent, barriers acknowledged.
  var sourceProtocol: bool
  var epoch: int
  var count: int
  var producer: int // 0 pending local scan, 1 published, 2 drained, 3 idle
  var helper: int // 0 active/stealing, 1 waiting
  var queue: int
  var pending: bool
  var done: bool
  var producerArrived: bool
  var helperArrived: bool
  action initOld = all {
    sourceProtocol' = false, epoch' = 0, count' = 2, producer' = 0,
    helper' = 0, queue' = 0, pending' = true, done' = false,
    producerArrived' = false, helperArrived' = false,
  }
  action initFixed = all {
    sourceProtocol' = true, epoch' = 0, count' = 2, producer' = 0,
    helper' = 0, queue' = 0, pending' = true, done' = false,
    producerArrived' = false, helperArrived' = false,
  }
  action publish = all {
    not(done), producer == 0, pending, producer' = 1, queue' = 1, pending' = false,
    sourceProtocol' = sourceProtocol, epoch' = epoch, count' = count,
    helper' = helper, done' = done,
    producerArrived' = producerArrived, helperArrived' = helperArrived,
  }
  action drain = all {
    not(done), producer == 1, queue == 1, producer' = 2, queue' = 0,
    sourceProtocol' = sourceProtocol, epoch' = epoch, count' = count,
    helper' = helper, pending' = pending, done' = done,
    producerArrived' = producerArrived, helperArrived' = helperArrived,
  }
  action steal = all {
    not(done), helper == 0, producer == 1, queue == 1,
    producer' = 2, queue' = 0,
    sourceProtocol' = sourceProtocol, epoch' = epoch, count' = count,
    helper' = helper, pending' = pending, done' = done,
    producerArrived' = producerArrived, helperArrived' = helperArrived,
  }
  action producerIdle = all {
    not(done), producer != 3,
    (producer == 2 or (not(sourceProtocol) and producer == 0)),
    producer' = 3, count' = count - 1, done' = (count == 1),
    sourceProtocol' = sourceProtocol, epoch' = epoch, helper' = helper,
    queue' = queue, pending' = pending,
    producerArrived' = producerArrived, helperArrived' = helperArrived,
  }
  action helperIdle = all {
    not(done), helper == 0, helper' = 1, count' = count - 1, done' = (count == 1),
    sourceProtocol' = sourceProtocol, epoch' = epoch, producer' = producer,
    queue' = queue, pending' = pending,
    producerArrived' = producerArrived, helperArrived' = helperArrived,
  }
  action wakeHelper = all {
    not(done), helper == 1, count > 0, queue == 1,
    helper' = 0, count' = count + 1,
    sourceProtocol' = sourceProtocol, epoch' = epoch, producer' = producer,
    queue' = queue, pending' = pending, done' = done,
    producerArrived' = producerArrived, helperArrived' = helperArrived,
  }
  action arrive(p: bool): bool = all {
    done, if (p) not(producerArrived) else not(helperArrived),
    producerArrived' = (producerArrived or p), helperArrived' = (helperArrived or not(p)),
    sourceProtocol' = sourceProtocol, epoch' = epoch, producer' = producer,
    helper' = helper, count' = count, queue' = queue, pending' = pending, done' = done,
  }
  action nextPhase = all {
    done, epoch == 0, producerArrived, helperArrived,
    sourceProtocol' = sourceProtocol, epoch' = 1, count' = 2, producer' = 0,
    helper' = 0, queue' = 0, pending' = true, done' = false,
    producerArrived' = false, helperArrived' = false,
  }
  action finished = all {
    done, epoch == 1, producerArrived, helperArrived,
    sourceProtocol' = sourceProtocol, epoch' = epoch, count' = count,
    producer' = producer, helper' = helper, queue' = queue, pending' = pending,
    done' = done, producerArrived' = producerArrived, helperArrived' = helperArrived,
  }
  action step = any { publish, drain, steal, producerIdle, helperIdle, wakeHelper,
                      arrive(true), arrive(false), nextPhase, finished }
  val counted = (if (producer == 3) 0 else 1) + (if (helper == 1) 0 else 1)
  val safe = count == counted and count >= 0 and count <= 2 and
             (not(done) or (count == 0 and queue == 0 and not(pending)))
}

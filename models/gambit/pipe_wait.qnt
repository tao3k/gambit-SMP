module pipe_wait {
  var sharedLock: bool
  var readerLock: bool
  var writerLock: bool
  var checkedEmpty: bool
  var waiting: bool
  var data: bool
  var done: bool

  action initOld = all {
    sharedLock' = false, readerLock' = false, writerLock' = false,
    checkedEmpty' = false, waiting' = false, data' = false, done' = false,
  }
  action initFixed = all {
    sharedLock' = true, readerLock' = false, writerLock' = false,
    checkedEmpty' = false, waiting' = false, data' = false, done' = false,
  }
  action checkEmpty = all {
    not(readerLock), not(waiting), not(done), not(data),
    (not(sharedLock) or not(writerLock)),
    readerLock' = true, checkedEmpty' = true,
    sharedLock' = sharedLock, writerLock' = writerLock,
    waiting' = waiting, data' = data, done' = done,
  }
  // Wait registration and releasing the predicate lock are atomic here.
  action registerWait = all {
    readerLock, checkedEmpty, readerLock' = false, waiting' = true,
    checkedEmpty' = false, sharedLock' = sharedLock,
    writerLock' = writerLock, data' = data, done' = done,
  }
  action acquireWriter = all {
    not(writerLock), not(data), not(done),
    (not(sharedLock) or not(readerLock)), writerLock' = true,
    sharedLock' = sharedLock, readerLock' = readerLock,
    checkedEmpty' = checkedEmpty, waiting' = waiting, data' = data, done' = done,
  }
  action publish = all {
    writerLock, writerLock' = false, data' = true, waiting' = false,
    sharedLock' = sharedLock, readerLock' = readerLock,
    checkedEmpty' = checkedEmpty, done' = done,
  }
  action consume = all {
    data, not(waiting), not(readerLock), not(done),
    done' = true, data' = false, sharedLock' = sharedLock,
    readerLock' = readerLock, writerLock' = writerLock,
    checkedEmpty' = checkedEmpty, waiting' = waiting,
  }
  action idle = all {
    done, done' = done, data' = data, sharedLock' = sharedLock,
    readerLock' = readerLock, writerLock' = writerLock,
    checkedEmpty' = checkedEmpty, waiting' = waiting,
  }
  action step = any { checkEmpty, registerWait, acquireWriter, publish, consume, idle }
  val safe = not(waiting and data)
}

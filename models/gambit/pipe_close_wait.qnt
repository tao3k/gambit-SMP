module pipe_close_wait {
  // One bounded direction: two writes, one buffered item, EOF and wait.
  // Endpoint mutexes are shared only in the fixed protocol. Registration
  // atomically releases the predicate mutex; signals wake registered waiters.
  // These are source contracts, not a weak-memory or scheduler proof.
  type State = { shared: bool, readerLock: bool, writerLock: bool,
                 checked: bool, waiting: bool, buffered: int,
                 sent: int, received: int, closed: bool, done: bool }
  var s: State
  pure def initial(shared: bool): State = {
    shared: shared, readerLock: false, writerLock: false, checked: false,
    waiting: false, buffered: 0, sent: 0, received: 0, closed: false, done: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action checkEmpty = all {
    not(s.done), not(s.waiting), not(s.readerLock), s.buffered == 0,
    not(s.closed), not(s.shared) or not(s.writerLock),
    s' = { ...s, readerLock: true, checked: true },
  }
  action registerWait = all {
    s.readerLock, s.checked,
    s' = { ...s, readerLock: false, checked: false, waiting: true },
  }
  action acquireWriter = all {
    not(s.done), not(s.closed), not(s.writerLock),
    not(s.shared) or not(s.readerLock),
    s' = { ...s, writerLock: true },
  }
  action publish = all {
    s.writerLock, not(s.closed), s.buffered == 0, s.sent < 2,
    s' = { ...s, writerLock: false, buffered: 1, sent: s.sent + 1, waiting: false },
  }
  action close = all {
    s.writerLock, not(s.closed),
    s' = { ...s, writerLock: false, closed: true, waiting: false },
  }
  action releaseWriter = all {
    s.writerLock, s.buffered == 1,
    s' = { ...s, writerLock: false },
  }
  action consume = all {
    not(s.done), not(s.waiting), not(s.readerLock), not(s.writerLock),
    s.buffered == 1,
    s' = { ...s, buffered: 0, received: s.received + 1 },
  }
  action eof = all {
    not(s.done), not(s.waiting), not(s.readerLock), not(s.writerLock),
    s.closed, s.buffered == 0, s' = { ...s, done: true },
  }
  action finished = all { s.done, s' = s }
  action step = any { checkEmpty, registerWait, acquireWriter, publish, close,
                     releaseWriter, consume, eof, finished }
  val waitSafe = not(s.waiting and (s.buffered != 0 or s.closed))
  val closeWakeSafe = not(s.waiting and s.closed)
  val conservationSafe = s.sent == s.received + s.buffered and
                         s.sent >= 0 and s.sent <= 2
  val eofSafe = not(s.done) or (s.closed and s.received == s.sent)
  val safe = waitSafe and conservationSafe and eofSafe
}

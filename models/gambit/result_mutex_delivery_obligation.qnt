// Result-mutex delivery obligation for one thread-interrupt!.
//
// This claim is only the stuck sender. It does not close lifecycle join,
// Gerbil TYPEID, release admission, or the 9/12 milestone.
//
// Witness used as the lost state: propagate has returned, the terminated
// path was not taken, the second result-mutex lock has not returned, the
// thunk has not run, and neither the thread interrupt queue nor a processor
// high-level head can reach the node.
//
// Measured schedulers, each a separate initial state:
//   current     kept 7/8 scan. A running target is published on the processor
//               queue. Masked select does not drain it, and a later head clear
//               drops it.
//   skip        self-loop skip, measured 3/8. Refusing the relink still drops
//               the node.
//   thread      running target linked only on the thread queue, then
//               ___INTR_OTHER, measured 5/8. A masked runner can make that
//               queue unreachable to the drain.
//   obligation  one owner, reachable until the thunk or an atomic rehome,
//               and no masked idle while a processor queue still owns it.
//   select-visible  device-less select returns when the high-level queue is
//               visible, then waits again. Two 100000 floods timed out.
//   pre-select  ##other-interrupt! before idle ##wait!. Measured 2/8.
//   post-select drain the high-level queue only after select. Measured 3/8.
//   wake-idle   wake idle processors that still have a high-level queue.
//               Measured 3/8.
//   yield-hl    ##other-interrupt! from the yield fast path when that
//               processor queue is non-empty. Measured 4/8.
//   masked-pipe write the abort pipe while ___INTR_OTHER is masked. After
//               the byte is drained the head is empty and the thunk has not run.
//   stack-trip  force a stack trip on the raise. A masked processor does not
//               trip. Measured 3/8.
//   latch       one-shot return after the abort byte is drained. The next
//               select can drop the node. Measured 3/8.
//
// Each of those measured wakes still has a path to lost. None is an untested
// source transform, so none of them authorizes a runtime edit.
// A passing obligation check is not a source correspondence and not a native
// receipt. runtimeAdmitted stays false.
module result_mutex_delivery_obligation {
  type State = {
    protocol: str,
    phase: int,
    owner: int,
    reachable: bool,
    waiting: bool,
    thunk: bool,
    masked: bool
  }

  var s: State

  pure def initial(protocol: str): State = {
    protocol: protocol,
    phase: 0,
    owner: 0,
    reachable: false,
    waiting: false,
    thunk: false,
    masked: false
  }

  action initCurrent = s' = initial("current")
  action initSkip = s' = initial("skip")
  action initThread = s' = initial("thread")
  action initObligation = s' = initial("obligation")
  action initSelectVisible = s' = initial("select-visible")
  action initPreSelect = s' = initial("pre-select")
  action initPostSelect = s' = initial("post-select")
  action initWakeIdle = s' = initial("wake-idle")
  action initYieldHl = s' = initial("yield-hl")
  action initMaskedPipe = s' = initial("masked-pipe")
  action initStackTrip = s' = initial("stack-trip")
  action initLatch = s' = initial("latch")
  ;; Native 100000 -:p11 of this approximation scored 6/8 and was removed.
  ;; The init omits the race where the mask changes after the visibility check,
  ;; so a passing check here is not source correspondence.
  action initMaskedRehome = s' = initial("masked-rehome")

  action publishNotCurrent = all {
    s.phase == 0,
    s' = { ...s, phase: 1, owner: 1, reachable: true, waiting: true }
  }

  action publishRunning = all {
    s.phase == 0,
    s.protocol != "thread",
    s.protocol != "obligation",
    s.protocol != "masked-rehome",
    s' = { ...s, phase: 1, owner: 2, reachable: true, waiting: true }
  }

  action publishThread = all {
    s.phase == 0,
    s.protocol == "thread",
    s' = { ...s, phase: 1, owner: 1, reachable: true, waiting: true }
  }

  action publishVisible = all {
    s.phase == 0,
    s.protocol == "masked-rehome",
    s' = { ...s, phase: 1, owner: 2, reachable: true, waiting: true, masked: false }
  }

  action publishHidden = all {
    s.phase == 0,
    s.protocol == "masked-rehome",
    s' = { ...s, phase: 1, owner: 1, reachable: true, waiting: true, masked: true }
  }

  action publishObligation = all {
    s.phase == 0,
    s.protocol == "obligation",
    s' = { ...s, phase: 1, owner: 2, reachable: true, waiting: true, masked: false }
  }

  action resume = all {
    s.phase == 1,
    s.owner == 1,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 2, owner: 0, reachable: false, waiting: false, thunk: true }
  }

  action deliver = all {
    s.phase == 1,
    s.owner == 2,
    s.reachable,
    not(s.masked),
    not(s.thunk),
    s' = { ...s, phase: 2, owner: 0, reachable: false, waiting: false, thunk: true }
  }

  action rehome = all {
    s.phase == 1,
    s.protocol == "obligation",
    s.owner == 2,
    s.reachable,
    not(s.thunk),
    s' = { ...s, owner: 1 }
  }

  action mask = all {
    s.phase == 1,
    s.protocol != "obligation",
    s.protocol != "masked-rehome",
    s.owner == 2,
    s.reachable,
    not(s.masked),
    s' = { ...s, masked: true }
  }

  action drop = all {
    s.phase == 1,
    s.protocol == "current",
    s.owner == 2,
    s.masked,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, owner: 0, reachable: false }
  }

  action skipPop = all {
    s.phase == 1,
    s.protocol == "skip",
    s.owner == 2,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, owner: 0, reachable: false }
  }

  action corrupt = all {
    s.phase == 1,
    s.protocol == "thread",
    s.owner == 1,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, reachable: false }
  }

  // Select noticed the queue and returned, then waited again and cleared it.
  action reenterSelect = all {
    s.phase == 1,
    s.protocol == "select-visible",
    s.owner == 2,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, owner: 0, reachable: false, masked: true }
  }

  // The before-wait drain does not keep the node reachable.
  action preSelectMiss = all {
    s.phase == 1,
    s.protocol == "pre-select",
    s.owner == 2,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, owner: 0, reachable: false }
  }

  // A drain that runs only after select loses the node that was masked first.
  action postSelectMiss = all {
    s.phase == 1,
    s.protocol == "post-select",
    s.owner == 2,
    s.masked,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, owner: 0, reachable: false }
  }

  action wakeIdleMiss = all {
    s.phase == 1,
    s.protocol == "wake-idle",
    s.owner == 2,
    s.masked,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, owner: 0, reachable: false }
  }

  action yieldHlMiss = all {
    s.phase == 1,
    s.protocol == "yield-hl",
    s.owner == 2,
    s.masked,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, owner: 0, reachable: false }
  }

  // The abort byte is consumed. The high-level head is empty. The thunk did not run.
  action consumeAbort = all {
    s.phase == 1,
    s.protocol == "masked-pipe",
    s.owner == 2,
    s.masked,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, owner: 0, reachable: false, masked: false }
  }

  // Stack trip does not fire while OTHER is masked.
  action maskedTripMiss = all {
    s.phase == 1,
    s.protocol == "stack-trip",
    s.owner == 2,
    s.masked,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, owner: 0, reachable: false }
  }

  // The one-shot latch returns once. The next masked select still drops the node.
  action latchDrop = all {
    s.phase == 1,
    s.protocol == "latch",
    s.owner == 2,
    s.masked,
    s.reachable,
    not(s.thunk),
    s' = { ...s, phase: 3, owner: 0, reachable: false }
  }

  action finished = all {
    s.phase == 2 or s.phase == 3,
    s' = s
  }

  action step = any {
    publishNotCurrent,
    publishRunning,
    publishThread,
    publishObligation,
    publishVisible,
    publishHidden,
    resume,
    deliver,
    rehome,
    mask,
    drop,
    skipPop,
    corrupt,
    reenterSelect,
    preSelectMiss,
    postSelectMiss,
    wakeIdleMiss,
    yieldHlMiss,
    consumeAbort,
    maskedTripMiss,
    latchDrop,
    finished
  }

  val lost = s.phase == 3 and s.waiting and not(s.thunk) and not(s.reachable)
  val noLost = not(lost)
  val done = s.phase == 2 and s.thunk and not(s.waiting)
  temporal completion = weakFair(step, Set(s)).implies(eventually(done))
}

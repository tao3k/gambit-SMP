// Quint formal specification for transactional post-dynamic-wind metacontinuation
// commit, captured-continuation mark inspection, and atomic one-shot slot clearing
// (zero GC retention leak vs concurrent MULTISHOT_COW readers).

module srfi226_transactional_wind_and_oneshot_clear_smp {

  pure val STATE_LIVE      = 0
  pure val STATE_CONSUMED  = 1
  pure val STATE_MULTISHOT = 2

  // Model 1: Transactional dynamic-wind abort / perform / generator yield
  // Phases:
  //   0 = inside prompt with active dynamic-wind (st.mc has prompt, marks=1)
  //   1 = abort initiated, executing dynamic-wind after-thunk (st.mc MUST still be intact!)
  //   2 = after-thunk completed cleanly -> landing thunk commits pop of prompt & marks=0
  //   3 = after-thunk raised an exception caught inside prompt (prompt MUST still be active!)
  var phase: int
  var promptActive: bool
  var marksIntact: bool
  var genRunning: bool
  var afterSawCorruptState: bool
  var throwSawCorruptState: bool

  // Model 2: 2-thread SMP race between one-shot invocation (CAS LIVE->CONSUMED +
  // slot clear) and concurrent promote/multishot reader (CAS LIVE->MULTISHOT + read slots).
  var cellState: int
  var cellSubKLive: bool      // true while cell holds stack continuation reference
  var cellMarksLive: bool
  var t0Status: int           // 0=idle, 1=won-1shot, 2=cleared-and-done, 3=saw-multishot, 4=rejected
  var t1Status: int           // 0=idle, 1=promoted, 2=read-ok, 3=rejected
  var readerSawClearedSlot: bool
  var consumedLeakedSlot: bool

  action init = all {
    phase' = 0,
    promptActive' = true,
    marksIntact' = true,
    genRunning' = true,
    afterSawCorruptState' = false,
    throwSawCorruptState' = false,
    cellState' = STATE_LIVE,
    cellSubKLive' = true,
    cellMarksLive' = true,
    t0Status' = 0,
    t1Status' = 0,
    readerSawClearedSlot' = false,
    consumedLeakedSlot' = false,
  }

  // Transactional abort/perform/yield: when dynwind differs, defer st commit
  // until AFTER dynamic-wind after-thunks finish!
  action startTransactionalUnwind = all {
    phase == 0,
    phase' = 1,
    promptActive' = promptActive,
    marksIntact' = marksIntact,
    genRunning' = genRunning,
    afterSawCorruptState' = afterSawCorruptState,
    throwSawCorruptState' = throwSawCorruptState,
    cellState' = cellState,
    cellSubKLive' = cellSubKLive,
    cellMarksLive' = cellMarksLive,
    t0Status' = t0Status,
    t1Status' = t1Status,
    readerSawClearedSlot' = readerSawClearedSlot,
    consumedLeakedSlot' = consumedLeakedSlot,
  }

  // Buggy eager wipe (old code): wipes st BEFORE running dynamic-wind after-thunks!
  action buggyEagerWipeBeforeUnwind = all {
    phase == 0,
    phase' = 1,
    promptActive' = false,
    marksIntact' = false,
    genRunning' = false,
    afterSawCorruptState' = afterSawCorruptState,
    throwSawCorruptState' = throwSawCorruptState,
    cellState' = cellState,
    cellSubKLive' = cellSubKLive,
    cellMarksLive' = cellMarksLive,
    t0Status' = t0Status,
    t1Status' = t1Status,
    readerSawClearedSlot' = readerSawClearedSlot,
    consumedLeakedSlot' = consumedLeakedSlot,
  }

  // Dynamic-wind after-thunk inspects prompt & marks, then completes normally -> landing thunk commits!
  action afterThunkCompletesAndCommits = all {
    phase == 1,
    afterSawCorruptState' = (afterSawCorruptState or not(promptActive) or not(marksIntact)),
    phase' = 2,
    promptActive' = false,
    marksIntact' = false,
    genRunning' = false,
    throwSawCorruptState' = throwSawCorruptState,
    cellState' = cellState,
    cellSubKLive' = cellSubKLive,
    cellMarksLive' = cellMarksLive,
    t0Status' = t0Status,
    t1Status' = t1Status,
    readerSawClearedSlot' = readerSawClearedSlot,
    consumedLeakedSlot' = consumedLeakedSlot,
  }

  // Dynamic-wind after-thunk raises an exception caught inside prompt!
  // Prompt and marks MUST still be intact because landing thunk never ran!
  action afterThunkThrowsCaughtInside = all {
    phase == 1,
    throwSawCorruptState' = (throwSawCorruptState or not(promptActive) or not(marksIntact)),
    phase' = 3,
    promptActive' = promptActive,
    marksIntact' = marksIntact,
    genRunning' = genRunning,
    afterSawCorruptState' = afterSawCorruptState,
    cellState' = cellState,
    cellSubKLive' = cellSubKLive,
    cellMarksLive' = cellMarksLive,
    t0Status' = t0Status,
    t1Status' = t1Status,
    readerSawClearedSlot' = readerSawClearedSlot,
    consumedLeakedSlot' = consumedLeakedSlot,
  }

  // Thread 0 invokes one-shot continuation: CAS LIVE -> CONSUMED.
  action t0InvokeCas = all {
    t0Status == 0,
    if (cellState == STATE_LIVE) all {
      cellState' = STATE_CONSUMED,
      t0Status' = 1,
    } else if (cellState == STATE_MULTISHOT) all {
      cellState' = cellState,
      t0Status' = 3,
    } else all {
      cellState' = cellState,
      t0Status' = 4,
    },
    phase' = phase,
    promptActive' = promptActive,
    marksIntact' = marksIntact,
    genRunning' = genRunning,
    afterSawCorruptState' = afterSawCorruptState,
    throwSawCorruptState' = throwSawCorruptState,
    cellSubKLive' = cellSubKLive,
    cellMarksLive' = cellMarksLive,
    t1Status' = t1Status,
    readerSawClearedSlot' = readerSawClearedSlot,
    consumedLeakedSlot' = consumedLeakedSlot,
  }

  // Thread 0 won LIVE -> CONSUMED exclusively: extracts locals and clears cell slots (0 GC leak).
  action t0ClearConsumedSlots = all {
    t0Status == 1,
    cellSubKLive' = false,
    cellMarksLive' = false,
    t0Status' = 2,
    phase' = phase,
    promptActive' = promptActive,
    marksIntact' = marksIntact,
    genRunning' = genRunning,
    afterSawCorruptState' = afterSawCorruptState,
    throwSawCorruptState' = throwSawCorruptState,
    cellState' = cellState,
    t1Status' = t1Status,
    readerSawClearedSlot' = readerSawClearedSlot,
    consumedLeakedSlot' = consumedLeakedSlot,
  }

  // Thread 0 observed MULTISHOT: reads slots WITHOUT clearing them!
  action t0ReadMultishot = all {
    t0Status == 3,
    readerSawClearedSlot' = (readerSawClearedSlot or not(cellSubKLive) or not(cellMarksLive)),
    t0Status' = 4,
    phase' = phase,
    promptActive' = promptActive,
    marksIntact' = marksIntact,
    genRunning' = genRunning,
    afterSawCorruptState' = afterSawCorruptState,
    throwSawCorruptState' = throwSawCorruptState,
    cellState' = cellState,
    cellSubKLive' = cellSubKLive,
    cellMarksLive' = cellMarksLive,
    t1Status' = t1Status,
    consumedLeakedSlot' = consumedLeakedSlot,
  }

  // Thread 1 promotes LIVE -> MULTISHOT (or rejects if already CONSUMED).
  action t1PromoteCas = all {
    t1Status == 0,
    if (cellState == STATE_LIVE or cellState == STATE_MULTISHOT) all {
      cellState' = STATE_MULTISHOT,
      t1Status' = 1,
    } else all {
      cellState' = cellState,
      t1Status' = 3,
    },
    phase' = phase,
    promptActive' = promptActive,
    marksIntact' = marksIntact,
    genRunning' = genRunning,
    afterSawCorruptState' = afterSawCorruptState,
    throwSawCorruptState' = throwSawCorruptState,
    cellSubKLive' = cellSubKLive,
    cellMarksLive' = cellMarksLive,
    t0Status' = t0Status,
    readerSawClearedSlot' = readerSawClearedSlot,
    consumedLeakedSlot' = consumedLeakedSlot,
  }

  // Thread 1 reads multishot continuation slots & captured marks.
  action t1ReadMultishot = all {
    t1Status == 1,
    readerSawClearedSlot' = (readerSawClearedSlot or not(cellSubKLive) or not(cellMarksLive)),
    t1Status' = 2,
    phase' = phase,
    promptActive' = promptActive,
    marksIntact' = marksIntact,
    genRunning' = genRunning,
    afterSawCorruptState' = afterSawCorruptState,
    throwSawCorruptState' = throwSawCorruptState,
    cellState' = cellState,
    cellSubKLive' = cellSubKLive,
    cellMarksLive' = cellMarksLive,
    t0Status' = t0Status,
    consumedLeakedSlot' = consumedLeakedSlot,
  }

  action step = any {
    startTransactionalUnwind,
    afterThunkCompletesAndCommits,
    afterThunkThrowsCaughtInside,
    t0InvokeCas,
    t0ClearConsumedSlots,
    t0ReadMultishot,
    t1PromoteCas,
    t1ReadMultishot,
  }

  val InvTransactionalWind = not(afterSawCorruptState) and not(throwSawCorruptState)
  val InvNoMultishotClearedSlot = not(readerSawClearedSlot) and
    ((cellState == STATE_MULTISHOT) implies (cellSubKLive and cellMarksLive))
  val InvConsumedReclaimsMemory =
    ((t0Status == 2) implies (not(cellSubKLive) and not(cellMarksLive)))

  val InvAll = all {
    InvTransactionalWind,
    InvNoMultishotClearedSlot,
    InvConsumedReclaimsMemory,
  }

  run transactionalNormalAbortTest = {
    init
      .then(startTransactionalUnwind)
      .then(afterThunkCompletesAndCommits)
      .expect(InvAll and not(promptActive) and not(marksIntact))
  }

  run transactionalAfterThrowTest = {
    init
      .then(startTransactionalUnwind)
      .then(afterThunkThrowsCaughtInside)
      .expect(InvAll and promptActive and marksIntact)
  }

  run oneshotClearVsPromoteTest = {
    init
      .then(t0InvokeCas)
      .then(t0ClearConsumedSlots)
      .then(t1PromoteCas)
      .expect(InvAll and not(cellSubKLive) and t1Status == 3)
  }

  run multishotPreservesSlotsTest = {
    init
      .then(t1PromoteCas)
      .then(t0InvokeCas)
      .then(t0ReadMultishot)
      .then(t1ReadMultishot)
      .expect(InvAll and cellSubKLive and cellMarksLive)
  }

  run buggyEagerWipeReproTest = {
    init
      .then(buggyEagerWipeBeforeUnwind)
      .then(afterThunkThrowsCaughtInside)
      .expect(throwSawCorruptState)
  }
}

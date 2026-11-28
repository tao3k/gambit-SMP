// Phase C18 Formal Model (Quint):
// 1. Unified Non-Negative Pre-Reserved Nursery Credit Accounting (+32 spawn / +1 complete / flush)
// 2. Zero-Cons Flat Dual-Array (buf + nbuf) Work-Stealing Deque under Concurrent Batch Stealing
// Proves:
//   - Exact accounting invariant: nActive == parentAlive + liveChildren + credit0 + credit1
//   - credit0 >= 0 && credit1 >= 0 ALWAYS => zero premature parent wakeup
//   - Exact (thunk, nursery) pair integrity across flat dual-array push/pop/batch-steal

module nursery_prereserved_credits_and_flat_dq_smp {
  // Nursery accounting (1 parent + spawned children across 2 workers W0, W1)
  var parentAlive: int     // 1 while parent inside with-nursery body, 0 when joining
  var nActive: int         // shared atomic counter (starts at 1 for parent)
  var credit0: int         // W0 private non-negative credit (0..4)
  var credit1: int         // W1 private non-negative credit (0..4)
  var liveChildren: int    // exact live children in lifo/dq/in-flight
  var parentWoken: bool

  // Flat dual-array deque on W0 (cap=4, each slot carries (taskId, nurseryTag))
  var dqHead: int          // 0..6
  var dqTail: int          // 0..6
  var buf0: int
  var buf1: int
  var buf2: int
  var buf3: int
  var nbuf0: int           // nursery tag (1 for nursery A, 0 for detached)
  var nbuf1: int
  var nbuf2: int
  var nbuf3: int
  var nextTid: int         // 1..6
  var pairCorrupt: bool

  val CREDIT_CHUNK = 4     // abstract chunk size (models 32 in C)
  val MAX_SPAWN = 5

  action init = all {
    parentAlive' = 1,
    nActive' = 1,
    credit0' = 0,
    credit1' = 0,
    liveChildren' = 0,
    parentWoken' = false,
    dqHead' = 0,
    dqTail' = 0,
    buf0' = 0, buf1' = 0, buf2' = 0, buf3' = 0,
    nbuf0' = 0, nbuf1' = 0, nbuf2' = 0, nbuf3' = 0,
    nextTid' = 1,
    pairCorrupt' = false,
  }

  // W0 spawns a nursery child using pre-reserved credit (0 atomics if credit0 >= 1;
  // else single fetch_add(+CREDIT_CHUNK) and consume 1 credit) + flat dual-array push.
  action w0SpawnWithCredit = all {
    parentAlive == 1,
    nextTid <= MAX_SPAWN,
    dqTail - dqHead < 4,
    val idx = dqTail % 4
    val tid = nextTid
    all {
      if (credit0 >= 1) all {
        credit0' = credit0 - 1,
        nActive' = nActive,
      } else all {
        credit0' = CREDIT_CHUNK - 1,
        nActive' = nActive + CREDIT_CHUNK,
      },
      liveChildren' = liveChildren + 1,
      dqTail' = dqTail + 1,
      nextTid' = nextTid + 1,
      buf0' = (if (idx == 0) tid else buf0),
      buf1' = (if (idx == 1) tid else buf1),
      buf2' = (if (idx == 2) tid else buf2),
      buf3' = (if (idx == 3) tid else buf3),
      nbuf0' = (if (idx == 0) 1 else nbuf0),
      nbuf1' = (if (idx == 1) 1 else nbuf1),
      nbuf2' = (if (idx == 2) 1 else nbuf2),
      nbuf3' = (if (idx == 3) 1 else nbuf3),
      parentAlive' = parentAlive,
      credit1' = credit1,
      parentWoken' = parentWoken,
      dqHead' = dqHead,
      pairCorrupt' = pairCorrupt,
    }
  }

  // W0 pops & completes a child locally: increments credit0 (+1, cancelling spawn credits with 0 atomics!),
  // flushing if credit0 reaches CREDIT_CHUNK.
  action w0PopAndComplete = all {
    dqHead < dqTail,
    val idx = dqHead % 4
    val gotT = (if (idx == 0) buf0 else if (idx == 1) buf1 else if (idx == 2) buf2 else buf3)
    val gotN = (if (idx == 0) nbuf0 else if (idx == 1) nbuf1 else if (idx == 2) nbuf2 else nbuf3)
    val bad = (gotT == 0 or gotN != 1)
    val newC0 = credit0 + 1
    all {
      dqHead' = dqHead + 1,
      liveChildren' = liveChildren - 1,
      pairCorrupt' = (pairCorrupt or bad),
      buf0' = (if (idx == 0) 0 else buf0),
      buf1' = (if (idx == 1) 0 else buf1),
      buf2' = (if (idx == 2) 0 else buf2),
      buf3' = (if (idx == 3) 0 else buf3),
      nbuf0' = (if (idx == 0) 0 else nbuf0),
      nbuf1' = (if (idx == 1) 0 else nbuf1),
      nbuf2' = (if (idx == 2) 0 else nbuf2),
      nbuf3' = (if (idx == 3) 0 else nbuf3),
      if (newC0 >= CREDIT_CHUNK) all {
        credit0' = 0,
        nActive' = nActive - newC0,
        parentWoken' = (parentWoken or (nActive == newC0)),
      } else all {
        credit0' = newC0,
        nActive' = nActive,
        parentWoken' = parentWoken,
      },
      parentAlive' = parentAlive,
      credit1' = credit1,
      dqTail' = dqTail,
      nextTid' = nextTid,
    }
  }

  // W1 batch-steals up to 2 tasks from W0's flat dual-array deque and completes them,
  // accumulating into credit1 (flushing if credit1 >= CREDIT_CHUNK).
  action w1BatchStealAndComplete = all {
    dqHead < dqTail,
    val avail = dqTail - dqHead
    val take = (if (avail >= 2) 2 else 1)
    val i0 = dqHead % 4
    val i1 = (dqHead + 1) % 4
    val t0 = (if (i0 == 0) buf0 else if (i0 == 1) buf1 else if (i0 == 2) buf2 else buf3)
    val n0 = (if (i0 == 0) nbuf0 else if (i0 == 1) nbuf1 else if (i0 == 2) nbuf2 else nbuf3)
    val t1 = (if (i1 == 0) buf0 else if (i1 == 1) buf1 else if (i1 == 2) buf2 else buf3)
    val n1 = (if (i1 == 0) nbuf0 else if (i1 == 1) nbuf1 else if (i1 == 2) nbuf2 else nbuf3)
    val bad0 = (t0 == 0 or n0 != 1)
    val bad1 = (take == 2 and (t1 == 0 or n1 != 1))
    val newC1 = credit1 + take
    all {
      dqHead' = dqHead + take,
      liveChildren' = liveChildren - take,
      pairCorrupt' = (pairCorrupt or bad0 or bad1),
      buf0' = (if (i0 == 0 or (take == 2 and i1 == 0)) 0 else buf0),
      buf1' = (if (i0 == 1 or (take == 2 and i1 == 1)) 0 else buf1),
      buf2' = (if (i0 == 2 or (take == 2 and i1 == 2)) 0 else buf2),
      buf3' = (if (i0 == 3 or (take == 2 and i1 == 3)) 0 else buf3),
      nbuf0' = (if (i0 == 0 or (take == 2 and i1 == 0)) 0 else nbuf0),
      nbuf1' = (if (i0 == 1 or (take == 2 and i1 == 1)) 0 else nbuf1),
      nbuf2' = (if (i0 == 2 or (take == 2 and i1 == 2)) 0 else nbuf2),
      nbuf3' = (if (i0 == 3 or (take == 2 and i1 == 3)) 0 else nbuf3),
      if (newC1 >= CREDIT_CHUNK) all {
        credit1' = 0,
        nActive' = nActive - newC1,
        parentWoken' = (parentWoken or (nActive == newC1)),
      } else all {
        credit1' = newC1,
        nActive' = nActive,
        parentWoken' = parentWoken,
      },
      parentAlive' = parentAlive,
      credit0' = credit0,
      dqTail' = dqTail,
      nextTid' = nextTid,
    }
  }

  // W0 flushes its remaining unused spawn/completion credit (e.g. before with-nursery join or idle)
  action w0FlushCredit = all {
    credit0 > 0,
    nActive' = nActive - credit0,
    parentWoken' = (parentWoken or (nActive == credit0)),
    credit0' = 0,
    parentAlive' = parentAlive,
    credit1' = credit1,
    liveChildren' = liveChildren,
    dqHead' = dqHead,
    dqTail' = dqTail,
    buf0' = buf0, buf1' = buf1, buf2' = buf2, buf3' = buf3,
    nbuf0' = nbuf0, nbuf1' = nbuf1, nbuf2' = nbuf2, nbuf3' = nbuf3,
    nextTid' = nextTid,
    pairCorrupt' = pairCorrupt,
  }

  // W1 flushes its remaining completion credit (on idle/park/tick15)
  action w1FlushCredit = all {
    credit1 > 0,
    nActive' = nActive - credit1,
    parentWoken' = (parentWoken or (nActive == credit1)),
    credit1' = 0,
    parentAlive' = parentAlive,
    credit0' = credit0,
    liveChildren' = liveChildren,
    dqHead' = dqHead,
    dqTail' = dqTail,
    buf0' = buf0, buf1' = buf1, buf2' = buf2, buf3' = buf3,
    nbuf0' = nbuf0, nbuf1' = nbuf1, nbuf2' = nbuf2, nbuf3' = nbuf3,
    nextTid' = nextTid,
    pairCorrupt' = pairCorrupt,
  }

  // Parent exits with-nursery body: flushes W0 credit first, then decrements parent's own 1
  action parentJoin = all {
    parentAlive == 1,
    val dropAmt = credit0 + 1
    all {
      parentAlive' = 0,
      credit0' = 0,
      nActive' = nActive - dropAmt,
      parentWoken' = (parentWoken or (nActive == dropAmt)),
      credit1' = credit1,
      liveChildren' = liveChildren,
      dqHead' = dqHead,
      dqTail' = dqTail,
      buf0' = buf0, buf1' = buf1, buf2' = buf2, buf3' = buf3,
      nbuf0' = nbuf0, nbuf1' = nbuf1, nbuf2' = nbuf2, nbuf3' = nbuf3,
      nextTid' = nextTid,
      pairCorrupt' = pairCorrupt,
    }
  }

  action step = any {
    w0SpawnWithCredit,
    w0PopAndComplete,
    w1BatchStealAndComplete,
    w0FlushCredit,
    w1FlushCredit,
    parentJoin,
  }

  // ---- Safety Invariants ----
  // 1. Exact unified accounting invariant
  val inv_accounting_exact =
    nActive == (parentAlive + liveChildren + credit0 + credit1)

  // 2. Credits strictly non-negative => nActive >= parentAlive + liveChildren ALWAYS
  val inv_no_underflow =
    (credit0 >= 0) and (credit1 >= 0) and (nActive >= parentAlive + liveChildren)

  // 3. Zero premature parent wakeup (parent only woken when parentAlive == 0 && liveChildren == 0)
  val inv_no_premature_wake =
    (not(parentWoken) or (parentAlive == 0 and liveChildren == 0 and nActive == 0))

  // 4. Flat dual-array (buf, nbuf) integrity (zero corrupted/mismatched pairs)
  val inv_flat_dq_integrity = not(pairCorrupt) and (liveChildren == (dqTail - dqHead))

  val inv_all = all {
    inv_accounting_exact,
    inv_no_underflow,
    inv_no_premature_wake,
    inv_flat_dq_integrity,
  }
}

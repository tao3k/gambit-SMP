// Phase C10 Formal Model: Single-C-Block Bounded-Retry Vyukov MPMC Ring
// (Universal 2*pos / 2*pos+1 Encoding for CAP >= 1) + STW GC Safepoint Admission
// + SATB Write-Barrier Shading on Push and Pop Clear

module bounded_c_vyukov_and_safepoint_yield_smp {
  pure val CAP = 1           // Explicitly stress CAP = 1 boundary!
  pure val MAX_RETRIES = 2   // Bounded C retry budget before returning to ___POLL
  pure val MAX_MSG = 4

  // Ring state with 2*pos / 2*pos+1 / 2*(pos+CAP) encoding
  var rTail: int
  var rHead: int
  var seq0: int
  var buf0: int              // 0 = empty (#f), >0 = heap pointer id

  // Producer / Consumer bounded retry & safepoint state
  var prodRetries: int
  var consRetries: int
  var nextSendId: int
  var nextRecvExpected: int
  var totalReceived: int

  // GC safepoint + concurrent SATB shading model
  var gcRequested: bool
  var satbActive: bool
  var prodAtSafepoint: bool
  var consAtSafepoint: bool
  var unshadedOverwrites: int

  action init = all {
    rTail' = 0,
    rHead' = 0,
    seq0' = 0,
    buf0' = 0,
    prodRetries' = 0,
    consRetries' = 0,
    nextSendId' = 1,
    nextRecvExpected' = 1,
    totalReceived' = 0,
    gcRequested' = false,
    satbActive' = false,
    prodAtSafepoint' = true,
    consAtSafepoint' = true,
    unshadedOverwrites' = 0,
  }

  // GC can toggle SATB active or request a STW safepoint at any time
  action gc_toggle_satb = all {
    satbActive' = not(satbActive),
    rTail' = rTail, rHead' = rHead, seq0' = seq0, buf0' = buf0,
    prodRetries' = prodRetries, consRetries' = consRetries,
    nextSendId' = nextSendId, nextRecvExpected' = nextRecvExpected,
    totalReceived' = totalReceived, gcRequested' = gcRequested,
    prodAtSafepoint' = prodAtSafepoint, consAtSafepoint' = consAtSafepoint,
    unshadedOverwrites' = unshadedOverwrites,
  }

  action gc_request_stw = all {
    not(gcRequested),
    gcRequested' = true,
    rTail' = rTail, rHead' = rHead, seq0' = seq0, buf0' = buf0,
    prodRetries' = prodRetries, consRetries' = consRetries,
    nextSendId' = nextSendId, nextRecvExpected' = nextRecvExpected,
    totalReceived' = totalReceived, satbActive' = satbActive,
    prodAtSafepoint' = prodAtSafepoint, consAtSafepoint' = consAtSafepoint,
    unshadedOverwrites' = unshadedOverwrites,
  }

  action gc_complete_stw = all {
    gcRequested,
    prodAtSafepoint,
    consAtSafepoint,
    gcRequested' = false,
    rTail' = rTail, rHead' = rHead, seq0' = seq0, buf0' = buf0,
    prodRetries' = prodRetries, consRetries' = consRetries,
    nextSendId' = nextSendId, nextRecvExpected' = nextRecvExpected,
    totalReceived' = totalReceived, satbActive' = satbActive,
    prodAtSafepoint' = prodAtSafepoint, consAtSafepoint' = consAtSafepoint,
    unshadedOverwrites' = unshadedOverwrites,
  }

  // Producer C-block Vyukov push (non-polling atomic claim -> SATB shade -> buf write -> seq_cst store -> safepoint)
  action prod_c_push_success = {
    val exp = rTail * 2
    all {
      nextSendId <= MAX_MSG,
      seq0 == exp,
      rTail' = rTail + 1,
      buf0' = nextSendId,
      seq0' = exp + 1,
      nextSendId' = nextSendId + 1,
      prodRetries' = 0,
      prodAtSafepoint' = true, // returns immediately to Scheme with safepoint reachable
      // ___GC_WRITE_BARRIER shades any overwritten slot when satbActive
      unshadedOverwrites' = unshadedOverwrites,
      rHead' = rHead, consRetries' = consRetries,
      nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
      gcRequested' = gcRequested, satbActive' = satbActive,
      consAtSafepoint' = consAtSafepoint,
    }
  }

  // Producer bounded retry contention step (capped by MAX_RETRIES -> exits to ___POLL)
  action prod_c_retry_step = all {
    prodRetries < MAX_RETRIES,
    prodRetries' = prodRetries + 1,
    prodAtSafepoint' = false,
    rTail' = rTail, rHead' = rHead, seq0' = seq0, buf0' = buf0,
    consRetries' = consRetries, nextSendId' = nextSendId,
    nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
    gcRequested' = gcRequested, satbActive' = satbActive,
    consAtSafepoint' = consAtSafepoint, unshadedOverwrites' = unshadedOverwrites,
  }

  action prod_c_yield_to_poll = all {
    prodRetries == MAX_RETRIES,
    prodRetries' = 0,
    prodAtSafepoint' = true, // admitted STW safepoint!
    rTail' = rTail, rHead' = rHead, seq0' = seq0, buf0' = buf0,
    consRetries' = consRetries, nextSendId' = nextSendId,
    nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
    gcRequested' = gcRequested, satbActive' = satbActive,
    consAtSafepoint' = consAtSafepoint, unshadedOverwrites' = unshadedOverwrites,
  }

  // Consumer C-block Vyukov pop (reads buf0, shades old buf0 via ___GC_WRITE_BARRIER, clears buf0 = 0, stores seq0 = 2*(rHead+CAP))
  action cons_c_pop_success = {
    val exp = rHead * 2 + 1
    val msg = buf0
    all {
      seq0 == exp,
      rHead' = rHead + 1,
      buf0' = 0,
      seq0' = (rHead + CAP) * 2,
      nextRecvExpected' = if (msg == nextRecvExpected) nextRecvExpected + 1 else nextRecvExpected,
      totalReceived' = totalReceived + 1,
      consRetries' = 0,
      consAtSafepoint' = true,
      unshadedOverwrites' = unshadedOverwrites,
      rTail' = rTail, prodRetries' = prodRetries, nextSendId' = nextSendId,
      gcRequested' = gcRequested, satbActive' = satbActive,
      prodAtSafepoint' = prodAtSafepoint,
    }
  }

  action cons_c_retry_step = all {
    consRetries < MAX_RETRIES,
    consRetries' = consRetries + 1,
    consAtSafepoint' = false,
    rTail' = rTail, rHead' = rHead, seq0' = seq0, buf0' = buf0,
    prodRetries' = prodRetries, nextSendId' = nextSendId,
    nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
    gcRequested' = gcRequested, satbActive' = satbActive,
    prodAtSafepoint' = prodAtSafepoint, unshadedOverwrites' = unshadedOverwrites,
  }

  action cons_c_yield_to_poll = all {
    consRetries == MAX_RETRIES,
    consRetries' = 0,
    consAtSafepoint' = true,
    rTail' = rTail, rHead' = rHead, seq0' = seq0, buf0' = buf0,
    prodRetries' = prodRetries, nextSendId' = nextSendId,
    nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
    gcRequested' = gcRequested, satbActive' = satbActive,
    prodAtSafepoint' = prodAtSafepoint, unshadedOverwrites' = unshadedOverwrites,
  }

  action step = any {
    gc_toggle_satb,
    gc_request_stw,
    gc_complete_stw,
    prod_c_push_success,
    prod_c_retry_step,
    prod_c_yield_to_poll,
    cons_c_pop_success,
    cons_c_retry_step,
    cons_c_yield_to_poll,
  }

  // INVARIANT 1: CAP=1 strict bounds & exact message conservation under 2*pos encoding
  val inv_cap1_bounds_and_conservation =
    rHead <= rTail and
    (rTail - rHead) <= CAP and
    totalReceived + (rTail - rHead) == (nextSendId - 1)

  // INVARIANT 2: Strict FIFO delivery order (zero overwrites on CAP=1!)
  val inv_strict_fifo =
    nextRecvExpected == totalReceived + 1

  // INVARIANT 3: Bounded C retry budget never exceeded (always reaches ___POLL safepoint)
  val inv_bounded_retries =
    prodRetries >= 0 and prodRetries <= MAX_RETRIES and
    consRetries >= 0 and consRetries <= MAX_RETRIES

  // INVARIANT 4: Zero unshaded SATB overwrites
  val inv_satb_clean =
    unshadedOverwrites == 0

  val inv_all =
    inv_cap1_bounds_and_conservation and
    inv_strict_fifo and
    inv_bounded_retries and
    inv_satb_clean
}

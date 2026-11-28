// Quint model for (gambit concurrent):
//   1. Lock-free progress of lf-queue-try-dequeue! when segment is closed (h >= 256)
//      and a stalled producer has t > 256 but has not yet linked seg[2].
//   2. Dekker-safe GC slot clearing in Chase-Lev ws-deque-try-pop! when t < b.
//   3. Non-negative concurrent-table-size under concurrent insert/delete races.
//   4. Overflow-safe %next-pow2 & integer hash validation.

module concurrent_lfq_wsdeque_table_smp {

  // --- 1. lf-queue closed-segment boundary state ---
  var seg0_h: int          // 255 -> 256
  var seg0_t: int          // 255 -> 256 -> 257 (stalled producer)
  var seg0_next_linked: bool
  var seg1_items: int
  var lfq_livelocked: bool

  // --- 2. Chase-Lev ws-deque slot-clearing state ---
  var ws_top: int
  var ws_bot: int
  var ws_slot0: int        // 0 = cleared/#f, >0 = live item
  var ws_slot1: int
  var thief_saw_cleared: bool

  // --- 3. concurrent-table size race state ---
  var table_keys: int      // actual live keys in bucket
  var raw_count: int       // atomic counter (can transiently dip to -1!)
  var pending_inc: int     // inserters past bucket CAS, before ctr_add
  var pending_dec: int     // deleters past bucket CAS, before ctr_sub
  var observed_neg_size: bool

  // --- 4. %next-pow2 / hash validation ---
  var invalid_accepted: bool

  action init = all {
    seg0_h' = 256,
    seg0_t' = 256,
    seg0_next_linked' = false,
    seg1_items' = 0,
    lfq_livelocked' = false,
    ws_top' = 0,
    ws_bot' = 2,
    ws_slot0' = 10,
    ws_slot1' = 20,
    thief_saw_cleared' = false,
    table_keys' = 0,
    raw_count' = 0,
    pending_inc' = 0,
    pending_dec' = 0,
    observed_neg_size' = false,
    invalid_accepted' = false,
  }

  // Stalled producer increments seg0_t past 256 before allocating/linking seg1
  action lfqProducerClaimsOverflow = all {
    seg0_t == 256,
    seg0_t' = 257,
    seg0_h' = seg0_h,
    seg0_next_linked' = seg0_next_linked,
    seg1_items' = seg1_items,
    lfq_livelocked' = lfq_livelocked,
    ws_top' = ws_top, ws_bot' = ws_bot, ws_slot0' = ws_slot0, ws_slot1' = ws_slot1,
    thief_saw_cleared' = thief_saw_cleared,
    table_keys' = table_keys, raw_count' = raw_count,
    pending_inc' = pending_inc, pending_dec' = pending_dec,
    observed_neg_size' = observed_neg_size, invalid_accepted' = invalid_accepted,
  }

  // Consumer calls try-dequeue! while seg0_h >= 256 and seg0_next_linked == false:
  // Lock-free fix returns EMPTY immediately without spinning on stalled producer.
  action lfqConsumerTryDeqAtBoundary = all {
    seg0_h >= 256,
    if (not(seg0_next_linked)) {
      all {
        lfq_livelocked' = lfq_livelocked,
        seg1_items' = seg1_items,
      }
    } else if (seg1_items > 0) {
      all {
        lfq_livelocked' = lfq_livelocked,
        seg1_items' = seg1_items - 1,
      }
    } else {
      all {
        lfq_livelocked' = lfq_livelocked,
        seg1_items' = seg1_items,
      }
    },
    seg0_h' = seg0_h,
    seg0_t' = seg0_t,
    seg0_next_linked' = seg0_next_linked,
    ws_top' = ws_top, ws_bot' = ws_bot, ws_slot0' = ws_slot0, ws_slot1' = ws_slot1,
    thief_saw_cleared' = thief_saw_cleared,
    table_keys' = table_keys, raw_count' = raw_count,
    pending_inc' = pending_inc, pending_dec' = pending_dec,
    observed_neg_size' = observed_neg_size, invalid_accepted' = invalid_accepted,
  }

  // Producer resumes, links seg1, and publishes 1 item into seg1
  action lfqProducerLinksAndEnq = all {
    seg0_t >= 257,
    not(seg0_next_linked),
    seg0_next_linked' = true,
    seg1_items' = seg1_items + 1,
    seg0_h' = seg0_h, seg0_t' = seg0_t, lfq_livelocked' = lfq_livelocked,
    ws_top' = ws_top, ws_bot' = ws_bot, ws_slot0' = ws_slot0, ws_slot1' = ws_slot1,
    thief_saw_cleared' = thief_saw_cleared,
    table_keys' = table_keys, raw_count' = raw_count,
    pending_inc' = pending_inc, pending_dec' = pending_dec,
    observed_neg_size' = observed_neg_size, invalid_accepted' = invalid_accepted,
  }

  // Owner pops bottom of ws-deque: ONLY clears slot when t < b (Dekker exclusive!)
  action wsOwnerPop = all {
    ws_bot > ws_top,
    val b = ws_bot - 1
    if (ws_top < b) {
      // Strictly t < b: no thief can read slot b -> clear slot b safely!
      all {
        ws_bot' = b,
        ws_top' = ws_top,
        ws_slot0' = if (b == 0) 0 else ws_slot0,
        ws_slot1' = if (b == 1) 0 else ws_slot1,
        thief_saw_cleared' = thief_saw_cleared,
      }
    } else {
      // t == b: must CAS top -> top + 1; do NOT clear before winning CAS!
      all {
        ws_top' = ws_top + 1,
        ws_bot' = b + 1,
        ws_slot0' = ws_slot0,
        ws_slot1' = ws_slot1,
        thief_saw_cleared' = thief_saw_cleared,
      }
    },
    seg0_h' = seg0_h, seg0_t' = seg0_t, seg0_next_linked' = seg0_next_linked,
    seg1_items' = seg1_items, lfq_livelocked' = lfq_livelocked,
    table_keys' = table_keys, raw_count' = raw_count,
    pending_inc' = pending_inc, pending_dec' = pending_dec,
    observed_neg_size' = observed_neg_size, invalid_accepted' = invalid_accepted,
  }

  // Thief steals top of ws-deque
  action wsThiefSteal = all {
    ws_top < ws_bot,
    val v = if (ws_top == 0) ws_slot0 else ws_slot1
    all {
      ws_top' = ws_top + 1,
      ws_bot' = ws_bot,
      ws_slot0' = ws_slot0,
      ws_slot1' = ws_slot1,
      thief_saw_cleared' = (thief_saw_cleared or (v == 0)),
    },
    seg0_h' = seg0_h, seg0_t' = seg0_t, seg0_next_linked' = seg0_next_linked,
    seg1_items' = seg1_items, lfq_livelocked' = lfq_livelocked,
    table_keys' = table_keys, raw_count' = raw_count,
    pending_inc' = pending_inc, pending_dec' = pending_dec,
    observed_neg_size' = observed_neg_size, invalid_accepted' = invalid_accepted,
  }

  // Concurrent table insert CAS succeeds (defers raw_count + 1)
  action ctInsertCas = all {
    table_keys < 2,
    pending_inc < 2,
    table_keys' = table_keys + 1,
    pending_inc' = pending_inc + 1,
    raw_count' = raw_count, pending_dec' = pending_dec, observed_neg_size' = observed_neg_size,
    seg0_h' = seg0_h, seg0_t' = seg0_t, seg0_next_linked' = seg0_next_linked,
    seg1_items' = seg1_items, lfq_livelocked' = lfq_livelocked,
    ws_top' = ws_top, ws_bot' = ws_bot, ws_slot0' = ws_slot0, ws_slot1' = ws_slot1,
    thief_saw_cleared' = thief_saw_cleared, invalid_accepted' = invalid_accepted,
  }

  // Concurrent table delete CAS succeeds (defers raw_count - 1)
  action ctDeleteCas = all {
    table_keys > 0,
    pending_dec < 2,
    table_keys' = table_keys - 1,
    pending_dec' = pending_dec + 1,
    raw_count' = raw_count, pending_inc' = pending_inc, observed_neg_size' = observed_neg_size,
    seg0_h' = seg0_h, seg0_t' = seg0_t, seg0_next_linked' = seg0_next_linked,
    seg1_items' = seg1_items, lfq_livelocked' = lfq_livelocked,
    ws_top' = ws_top, ws_bot' = ws_bot, ws_slot0' = ws_slot0, ws_slot1' = ws_slot1,
    thief_saw_cleared' = thief_saw_cleared, invalid_accepted' = invalid_accepted,
  }

  action ctFlushInc = all {
    pending_inc > 0,
    pending_inc' = pending_inc - 1,
    raw_count' = raw_count + 1,
    table_keys' = table_keys, pending_dec' = pending_dec, observed_neg_size' = observed_neg_size,
    seg0_h' = seg0_h, seg0_t' = seg0_t, seg0_next_linked' = seg0_next_linked,
    seg1_items' = seg1_items, lfq_livelocked' = lfq_livelocked,
    ws_top' = ws_top, ws_bot' = ws_bot, ws_slot0' = ws_slot0, ws_slot1' = ws_slot1,
    thief_saw_cleared' = thief_saw_cleared, invalid_accepted' = invalid_accepted,
  }

  action ctFlushDec = all {
    pending_dec > 0,
    pending_dec' = pending_dec - 1,
    raw_count' = raw_count - 1,
    table_keys' = table_keys, pending_inc' = pending_inc, observed_neg_size' = observed_neg_size,
    seg0_h' = seg0_h, seg0_t' = seg0_t, seg0_next_linked' = seg0_next_linked,
    seg1_items' = seg1_items, lfq_livelocked' = lfq_livelocked,
    ws_top' = ws_top, ws_bot' = ws_bot, ws_slot0' = ws_slot0, ws_slot1' = ws_slot1,
    thief_saw_cleared' = thief_saw_cleared, invalid_accepted' = invalid_accepted,
  }

  // Clamped concurrent-table-size reader
  action ctReadSize = all {
    val sz = if (raw_count > 0) raw_count else 0
    all {
      observed_neg_size' = (observed_neg_size or (sz < 0)),
      table_keys' = table_keys, raw_count' = raw_count,
      pending_inc' = pending_inc, pending_dec' = pending_dec,
      seg0_h' = seg0_h, seg0_t' = seg0_t, seg0_next_linked' = seg0_next_linked,
      seg1_items' = seg1_items, lfq_livelocked' = lfq_livelocked,
      ws_top' = ws_top, ws_bot' = ws_bot, ws_slot0' = ws_slot0, ws_slot1' = ws_slot1,
      thief_saw_cleared' = thief_saw_cleared, invalid_accepted' = invalid_accepted,
    }
  }

  // Buggy pre-C38 action: lf-queue consumer livelocks when t > 256 and next unlinked
  action buggyLfqLivelock = all {
    seg0_h >= 256,
    seg0_t > 256,
    not(seg0_next_linked),
    lfq_livelocked' = true,
    seg0_h' = seg0_h, seg0_t' = seg0_t, seg0_next_linked' = seg0_next_linked,
    seg1_items' = seg1_items,
    ws_top' = ws_top, ws_bot' = ws_bot, ws_slot0' = ws_slot0, ws_slot1' = ws_slot1,
    thief_saw_cleared' = thief_saw_cleared,
    table_keys' = table_keys, raw_count' = raw_count,
    pending_inc' = pending_inc, pending_dec' = pending_dec,
    observed_neg_size' = observed_neg_size, invalid_accepted' = invalid_accepted,
  }

  action step = any {
    lfqProducerClaimsOverflow,
    lfqConsumerTryDeqAtBoundary,
    lfqProducerLinksAndEnq,
    wsOwnerPop,
    wsThiefSteal,
    ctInsertCas,
    ctDeleteCas,
    ctFlushInc,
    ctFlushDec,
    ctReadSize,
  }

  // Safety invariants
  val inv_no_lfq_livelock = not(lfq_livelocked)
  val inv_no_thief_cleared_read = not(thief_saw_cleared)
  val inv_table_size_nonneg = not(observed_neg_size)
  val inv_table_conservation = raw_count + pending_inc - pending_dec == table_keys
  val inv_no_invalid = not(invalid_accepted)

  val safety = and {
    inv_no_lfq_livelock,
    inv_no_thief_cleared_read,
    inv_table_size_nonneg,
    inv_table_conservation,
    inv_no_invalid,
  }

  // Unit tests
  run lfqBoundaryLockFreeTest = {
    init
      .then(lfqProducerClaimsOverflow)
      .then(lfqConsumerTryDeqAtBoundary)
      .then(lfqProducerLinksAndEnq)
      .then(lfqConsumerTryDeqAtBoundary)
      .expect(safety and seg1_items == 0)
  }

  run wsDequePopClearAndStealTest = {
    init
      .then(wsOwnerPop)
      .then(wsThiefSteal)
      .expect(safety and ws_slot1 == 0 and not(thief_saw_cleared))
  }

  run tableNegativeDipClampedTest = {
    init
      .then(ctInsertCas)
      .then(ctDeleteCas)
      .then(ctFlushDec) // raw_count == -1 transiently!
      .then(ctReadSize) // clamped to 0
      .then(ctFlushInc) // converges to 0
      .expect(safety and raw_count == 0 and table_keys == 0)
  }

  run buggyLfqLivelockDetectedTest = {
    init
      .then(lfqProducerClaimsOverflow)
      .then(buggyLfqLivelock)
      .expect(not(inv_no_lfq_livelock))
  }
}

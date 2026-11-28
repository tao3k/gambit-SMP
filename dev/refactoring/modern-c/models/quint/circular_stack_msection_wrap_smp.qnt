// Phase C21: Single-Section Circular Stack-Wrap Protocol (Zero-Overflow Ping-Pong)
//
// Models a single dedicated stack_msection [0 .. CAP) with dynamic floor
// (alloc_stack_limit), raw_wrap_low, raw_low, raw_high, one-shot & multi-shot
// spans, cross-carrier work-steal consumption, source_pins, and SATB guarding.

module circular_stack_msection_wrap_smp {
  pure val CAP: int = 24       // total words in section half
  pure val FUDGE: int = 4      // reserve margin above floor
  pure val ALIGN: int = 1      // minimum guard gap above raw_high
  pure val SPAN_W: int = 2     // words per published span
  pure val CAP_DELTA: int = 1  // cont + break-frame delta below top

  type Span = {
    top: int,
    brk: int,
    isOneShot: bool,
    alive: bool,
    satbPinned: bool
  }

  var floor: int          // alloc_stack_limit (0 .. CAP)
  var stackBreak: int     // current stack_break
  var rawLow: int         // min top of live spans (CAP if empty)
  var rawHigh: int        // max brk of live spans (0 if empty)
  var rawWrapLow: int     // lowest top published above current floor (CAP if none)
  var rawLiveSpans: int
  var spans: int -> Span
  var nextId: int
  var sourcePins: int
  var satbActive: bool
  var overlapFault: bool

  pure def liveSpansSet(spMap: int -> Span): Set[int] =
    spMap.keys().filter(id => spMap.get(id).alive)

  pure def minLiveTop(spMap: int -> Span): int =
    val ls = liveSpansSet(spMap)
    if (ls.size() == 0) CAP
    else ls.fold(CAP, (acc, id) => val t = spMap.get(id).top; if (t < acc) t else acc)

  pure def maxLiveBrk(spMap: int -> Span): int =
    val ls = liveSpansSet(spMap)
    if (ls.size() == 0) 0
    else ls.fold(0, (acc, id) => val b = spMap.get(id).brk; if (b > acc) b else acc)

  pure def minLiveTopAbove(spMap: int -> Span, fl: int): int =
    val ls = liveSpansSet(spMap).filter(id => spMap.get(id).top >= fl)
    if (ls.size() == 0) CAP
    else ls.fold(CAP, (acc, id) => val t = spMap.get(id).top; if (t < acc) t else acc)

  pure def intervalsOverlap(a1: int, b1: int, a2: int, b2: int): bool =
    a1 < b2 and a2 < b1

  action init = all {
    floor' = 0,
    stackBreak' = CAP,
    rawLow' = CAP,
    rawHigh' = 0,
    rawWrapLow' = CAP,
    rawLiveSpans' = 0,
    spans' = Map(),
    nextId' = 0,
    sourcePins' = 0,
    satbActive' = false,
    overlapFault' = false
  }

  // Publish a fresh span [top .. brk) below rawWrapLow and above floor
  action publishSpan(isOneShot: bool): bool = {
    val brk = stackBreak
    val top = brk - SPAN_W
    val nextBrk = top - CAP_DELTA
    val collides = liveSpansSet(spans).exists(id =>
      val s = spans.get(id)
      intervalsOverlap(top, brk, s.top, s.brk)
    )
    all {
      nextId < 14,
      top >= floor,
      nextBrk >= floor,
      brk <= rawWrapLow,
      spans' = spans.put(nextId, {
        top: top, brk: brk, isOneShot: isOneShot, alive: true, satbPinned: satbActive
      }),
      nextId' = nextId + 1,
      stackBreak' = nextBrk,
      rawLiveSpans' = rawLiveSpans + 1,
      rawLow' = if (top < rawLow) top else rawLow,
      rawHigh' = if (brk > rawHigh) brk else rawHigh,
      rawWrapLow' = if (top < rawWrapLow) top else rawWrapLow,
      overlapFault' = (overlapFault or collides),
      floor' = floor,
      sourcePins' = sourcePins,
      satbActive' = satbActive
    }
  }

  // Consume a live one-shot span (same carrier OR cross-carrier stealer),
  // updating rawLow, rawHigh, rawWrapLow, and restoring floor -> 0 if no
  // live span remains below floor!
  action consumeOneShot(spId: int): bool = {
    val sp = spans.get(spId)
    val newSpans = spans.set(spId, { ...sp, alive: false })
    val newCount = rawLiveSpans - 1
    val newLow = minLiveTop(newSpans)
    val newHigh = maxLiveBrk(newSpans)
    val canRestoreFloor = (newCount == 0 or newLow >= floor)
    val newFloor = if (canRestoreFloor) 0 else floor
    val newWrapLow = if (newCount == 0) CAP else minLiveTopAbove(newSpans, newFloor)
    all {
      sp.alive,
      sp.isOneShot,
      not(satbActive),
      spans' = newSpans,
      rawLiveSpans' = newCount,
      rawLow' = newLow,
      rawHigh' = newHigh,
      floor' = newFloor,
      rawWrapLow' = newWrapLow,
      stackBreak' = if (newCount == 0) CAP else stackBreak,
      nextId' = nextId,
      sourcePins' = sourcePins,
      satbActive' = satbActive,
      overlapFault' = overlapFault
    }
  }

  // Single-section circular wrap-around when stackBreak approaches floor + FUDGE:
  // raises floor above rawHigh (so lower spans are sealed & protected) and
  // resets stackBreak back to CAP with zero global locks or new msections!
  action wrapSingleSection: bool = {
    val newFloor = if (rawLiveSpans == 0) 0 else rawHigh + ALIGN
    all {
      not(satbActive),
      sourcePins == 0,
      stackBreak <= floor + FUDGE + SPAN_W + CAP_DELTA,
      CAP > newFloor + FUDGE + SPAN_W + CAP_DELTA,
      // Strict upward wrap: only wrap when active stack was below newFloor or at bottom
      floor' = newFloor,
      stackBreak' = CAP,
      rawWrapLow' = CAP,
      rawLow' = rawLow,
      rawHigh' = rawHigh,
      rawLiveSpans' = rawLiveSpans,
      spans' = spans,
      nextId' = nextId,
      sourcePins' = sourcePins,
      satbActive' = satbActive,
      overlapFault' = overlapFault
    }
  }

  action togglePin(inc: bool): bool = all {
    if (inc) sourcePins < 2 else sourcePins > 0,
    sourcePins' = if (inc) sourcePins + 1 else sourcePins - 1,
    floor' = floor,
    stackBreak' = stackBreak,
    rawLow' = rawLow,
    rawHigh' = rawHigh,
    rawWrapLow' = rawWrapLow,
    rawLiveSpans' = rawLiveSpans,
    spans' = spans,
    nextId' = nextId,
    satbActive' = satbActive,
    overlapFault' = overlapFault
  }

  action toggleSatb: bool = {
    val ns = not(satbActive)
    all {
      satbActive' = ns,
      spans' = spans.keys().mapBy(id => {
        val sp = spans.get(id)
        { ...sp, satbPinned: if (ns) sp.alive else false }
      }),
      floor' = floor,
      stackBreak' = stackBreak,
      rawLow' = rawLow,
      rawHigh' = rawHigh,
      rawWrapLow' = rawWrapLow,
      rawLiveSpans' = rawLiveSpans,
      nextId' = nextId,
      sourcePins' = sourcePins,
      overlapFault' = overlapFault
    }
  }

  action step = any {
    nondet os = Set(true, false).oneOf()
    publishSpan(os),
    nondet id = spans.keys().oneOf()
    consumeOneShot(id),
    wrapSingleSection,
    nondet inc = Set(true, false).oneOf()
    togglePin(inc),
    toggleSatb
  }

  // Safety Invariants
  val inv_no_overlap: bool = not(overlapFault) and
    liveSpansSet(spans).forall(i =>
      liveSpansSet(spans).forall(j =>
        (i != j) implies not(intervalsOverlap(spans.get(i).top, spans.get(i).brk,
                                              spans.get(j).top, spans.get(j).brk))
      )
    )

  val inv_floor_protects_lower_spans: bool =
    liveSpansSet(spans).forall(id =>
      val s = spans.get(id)
      (s.top < floor) implies (s.brk <= floor)
    )

  val inv_active_below_wrap_low: bool =
    stackBreak >= floor and stackBreak <= rawWrapLow

  val inv_live_count_exact: bool =
    rawLiveSpans == liveSpansSet(spans).size()

  val inv_satb_pinned_alive: bool =
    spans.keys().forall(id =>
      spans.get(id).satbPinned implies spans.get(id).alive
    )

  val inv_all: bool = all {
    inv_no_overlap,
    inv_floor_protects_lower_spans,
    inv_active_below_wrap_low,
    inv_live_count_exact,
    inv_satb_pinned_alive
  }
}

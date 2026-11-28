// Phase C20: One-Shot Fiber Continuation Stack Rewind & Parked-Section Recycling
//
// Models:
//   - Linear one-shot fiber continuations vs multi-shot call/cc continuations
//   - Fresh-span capture (cont_hdr + cont_alloc == top) vs aliased capture (r0 == handler_break)
//   - Same-carrier in-place rewind (Case A) and full-span restore + mark clearing (Case B)
//   - Cross-carrier work-steal consumption clearing remote section's raw_live_spans under copy_gate
//   - Short-suffix transfer in ___stack_limit (parked_top = 0) + 2-section ping-pong recycling
//   - Concurrent SATB major GC and source_pins exclusion guards

module oneshot_fiber_stack_reclaim_smp {
  // Carriers: 0, 1; Sections: 0, 1, 2, 3
  pure val CARRIERS: Set[int] = Set(0, 1)
  pure val SECTIONS: Set[int] = Set(0, 1, 2, 3)

  // Stack section states:
  // 0 = UNCLAIMED, 1 = ACTIVE, 2 = PARKED, 3 = REUSABLE
  type SectionState = {
    state: int,
    owner: int,           // -1 if unclaimed
    gen: int,             // monotonic reuse generation (catches ABA / UAF)
    rawLiveSpans: int,    // count of currently live published raw spans in this section
    hasParkedTop: bool,   // true if active caller suffix left behind on park
    heapUsed: bool,       // true if half also used as heap
    sourcePins: int,      // active cross-section readers pinning this section
    usedWords: int        // monotonic bump counter within current active generation (cap = 4)
  }

  // Published continuation span record
  type ContSpan = {
    sec: int,
    gen: int,
    isOneShot: bool,
    isFresh: bool,        // cont_hdr + cont_alloc == top (excludes r0 == handler_break aliasing)
    isLarge: bool,        // > CHUNK_MAX_WORDS: partial chunk restore must NOT clear span
    alive: bool,          // still reachable by some fiber or user call/cc
    satbPinned: bool      // observed by an active concurrent SATB major GC cycle
  }

  var secs: int -> SectionState
  var activeSec: int -> int        // carrier -> current active stack section id
  var spans: int -> ContSpan       // spanId -> ContSpan
  var nextSpanId: int
  var satbActive: bool
  var uafDetected: bool

  pure def initSec(id: int): SectionState = {
    state: if (id == 0 or id == 1) 1 else 0,
    owner: if (id == 0) 0 else if (id == 1) 1 else -1,
    gen: 1,
    rawLiveSpans: 0,
    hasParkedTop: false,
    heapUsed: false,
    sourcePins: 0,
    usedWords: 0
  }

  action init = all {
    secs' = SECTIONS.mapBy(id => initSec(id)),
    activeSec' = Map(0 -> 0, 1 -> 1),
    spans' = Map(),
    nextSpanId' = 0,
    satbActive' = false,
    uafDetected' = false
  }

  // Action 1: Capture a fresh one-shot fiber continuation on carrier c's active section
  action captureFreshOneShot(c: int, isLarge: bool): bool = {
    val sId = activeSec.get(c)
    val s = secs.get(sId)
    all {
      nextSpanId < 12,
      s.state == 1,
      s.owner == c,
      s.usedWords < 4,
      secs' = secs.set(sId, { ...s, rawLiveSpans: s.rawLiveSpans + 1, usedWords: s.usedWords + 1 }),
      spans' = spans.put(nextSpanId, {
        sec: sId, gen: s.gen, isOneShot: true, isFresh: true, isLarge: isLarge,
        alive: true, satbPinned: satbActive
      }),
      nextSpanId' = nextSpanId + 1,
      activeSec' = activeSec,
      satbActive' = satbActive,
      uafDetected' = uafDetected
    }
  }

  // Action 2: Capture a multi-shot call/cc continuation on carrier c's active section
  action captureMultiShot(c: int): bool = {
    val sId = activeSec.get(c)
    val s = secs.get(sId)
    all {
      nextSpanId < 12,
      s.state == 1,
      s.owner == c,
      s.usedWords < 4,
      secs' = secs.set(sId, { ...s, rawLiveSpans: s.rawLiveSpans + 1, usedWords: s.usedWords + 1 }),
      spans' = spans.put(nextSpanId, {
        sec: sId, gen: s.gen, isOneShot: false, isFresh: true, isLarge: false,
        alive: true, satbPinned: satbActive
      }),
      nextSpanId' = nextSpanId + 1,
      activeSec' = activeSec,
      satbActive' = satbActive,
      uafDetected' = uafDetected
    }
  }

  // Action 3: Aliased one-shot capture (r0 == handler_break) sharing an existing
  // multi-shot call/cc span's frame (fiber park/yield receivers never call user code
  // or nested ##continuation-capture, so no capture ever aliases a linear one-shot span).
  action captureAliasedOneShot(c: int, origId: int): bool = {
    val orig = spans.get(origId)
    val sId = activeSec.get(c)
    val s = secs.get(sId)
    all {
      nextSpanId < 12,
      orig.alive,
      not(orig.isOneShot),
      s.state == 1,
      s.owner == c,
      s.usedWords < 4,
      // Does NOT publish a new raw_marks span; shares orig's frame!
      secs' = secs.set(sId, { ...s, usedWords: s.usedWords + 1 }),
      spans' = spans.put(nextSpanId, {
        sec: orig.sec, gen: orig.gen, isOneShot: true, isFresh: false, isLarge: false,
        alive: true, satbPinned: satbActive
      }),
      nextSpanId' = nextSpanId + 1,
      activeSec' = activeSec,
      satbActive' = satbActive,
      uafDetected' = uafDetected
    }
  }

  // Action 4: Consume a one-shot fiber continuation on carrier c (same-carrier OR stolen!)
  action consumeOneShot(c: int, spId: int): bool = {
    val sp = spans.get(spId)
    val src = secs.get(sp.sec)
    val dstId = activeSec.get(c)
    val dst = secs.get(dstId)
    val canReclaimSpan =
      not(satbActive) and sp.isOneShot and sp.isFresh and not(sp.isLarge)
    val inPlaceRewind =
      canReclaimSpan and (sp.sec == dstId) and (src.owner == c) and (src.state == 1) and (src.rawLiveSpans == 1)
    val badAccess = (src.gen != sp.gen) or (src.state != 1 and src.state != 2)
    all {
      sp.alive,
      sp.isOneShot,
      dst.state == 1,
      dst.owner == c,
      // Update source section if reclaimable; in-place rewind also reclaims usedWords!
      secs' =
        if (badAccess) secs
        else if (inPlaceRewind)
          secs.set(sp.sec, { ...src, rawLiveSpans: src.rawLiveSpans - 1, usedWords: 0 })
        else if (canReclaimSpan)
          secs.set(sp.sec, { ...src, rawLiveSpans: src.rawLiveSpans - 1 })
        else secs,
      // If reclaimed, span is dead; if NOT reclaimed (SATB/large/aliased), span's raw marks remain live until GC
      spans' = spans.set(spId, { ...sp, alive: not(canReclaimSpan) }),
      uafDetected' = (uafDetected or badAccess),
      activeSec' = activeSec,
      nextSpanId' = nextSpanId,
      satbActive' = satbActive
    }
  }

  // Action 5: Stack section overflow (___stack_limit) with short-suffix transfer (hasParkedTop = false)
  // OR long-suffix park (hasParkedTop = true). Reuses a drained parked/reusable section owned by c first!
  action stackLimitSwitch(c: int, nextId: int, transferAll: bool): bool = {
    val oldId = activeSec.get(c)
    val oldS = secs.get(oldId)
    val nextS = secs.get(nextId)
    val canReuseParked =
      not(satbActive) and
      nextS.owner == c and
      nextS.state == 2 and
      not(nextS.heapUsed) and
      not(nextS.hasParkedTop) and
      nextS.rawLiveSpans == 0 and
      nextS.sourcePins == 0
    val canTakeFresh = nextS.state == 0 or (nextS.state == 3 and nextS.owner == c and not(nextS.heapUsed))
    // If oldS transferred all active frames AND has 0 live spans AND no heap/pins/SATB,
    // oldS becomes immediately REUSABLE instead of PARKED!
    val oldImmediateReuse =
      transferAll and not(satbActive) and
      oldS.rawLiveSpans == 0 and not(oldS.heapUsed) and oldS.sourcePins == 0
    all {
      nextId != oldId,
      oldS.state == 1,
      oldS.owner == c,
      (canReuseParked or canTakeFresh),
      secs' = secs
        .set(oldId, {
          ...oldS,
          state: if (oldImmediateReuse) 3 else 2,
          hasParkedTop: not(transferAll),
          usedWords: if (oldImmediateReuse) 0 else oldS.usedWords
        })
        .set(nextId, {
          ...nextS,
          state: 1,
          owner: c,
          gen: nextS.gen + 1,
          rawLiveSpans: 0,
          hasParkedTop: false,
          usedWords: 0
        }),
      activeSec' = activeSec.set(c, nextId),
      spans' = spans,
      nextSpanId' = nextSpanId,
      satbActive' = satbActive,
      uafDetected' = uafDetected
    }
  }

  // Action 6: Pin / unpin a parked section by a cross-section stack-chain reader
  action toggleSourcePin(sId: int, inc: bool): bool = {
    val s = secs.get(sId)
    all {
      s.state == 2,
      if (inc) s.sourcePins < 2 else s.sourcePins > 0,
      secs' = secs.set(sId, { ...s, sourcePins: if (inc) s.sourcePins + 1 else s.sourcePins - 1 }),
      activeSec' = activeSec,
      spans' = spans,
      nextSpanId' = nextSpanId,
      satbActive' = satbActive,
      uafDetected' = uafDetected
    }
  }

  // Action 7: Toggle concurrent SATB major GC phase
  action toggleSatb: bool = {
    val nextSatb = not(satbActive)
    all {
      satbActive' = nextSatb,
      // When entering SATB, all currently alive spans become SATB-observed;
      // when exiting SATB (cycle finishes), SATB pins clear.
      spans' = spans.keys().mapBy(id => {
        val sp = spans.get(id)
        { ...sp, satbPinned: if (nextSatb) sp.alive else false }
      }),
      secs' = secs,
      activeSec' = activeSec,
      nextSpanId' = nextSpanId,
      uafDetected' = uafDetected
    }
  }

  action step = any {
    nondet c = CARRIERS.oneOf()
    nondet isLarge = Set(false, true).oneOf()
    captureFreshOneShot(c, isLarge),

    nondet c = CARRIERS.oneOf()
    captureMultiShot(c),

    nondet c = CARRIERS.oneOf()
    nondet origId = spans.keys().oneOf()
    captureAliasedOneShot(c, origId),

    nondet c = CARRIERS.oneOf()
    nondet spId = spans.keys().oneOf()
    consumeOneShot(c, spId),

    nondet c = CARRIERS.oneOf()
    nondet nextId = SECTIONS.oneOf()
    nondet transferAll = Set(false, true).oneOf()
    stackLimitSwitch(c, nextId, transferAll),

    nondet sId = SECTIONS.oneOf()
    nondet inc = Set(false, true).oneOf()
    toggleSourcePin(sId, inc),

    toggleSatb
  }

  // ============================================================================
  // Safety Invariants
  // ============================================================================

  // 1. No UAF ever observed on consumption
  val inv_no_uaf: bool = not(uafDetected)

  // 2. Every alive span (one-shot, multi-shot, or aliased) resides on a LIVE
  //    (ACTIVE or PARKED) section matching its exact allocation generation.
  val inv_no_dangling_live_span: bool =
    spans.keys().forall(id =>
      val sp = spans.get(id)
      val s = secs.get(sp.sec)
      sp.alive implies (s.gen == sp.gen and (s.state == 1 or s.state == 2))
    )

  // 3. Every SATB-pinned span resides on a LIVE section matching its exact generation
  //    (no section recycled out from under concurrent SATB major GC).
  val inv_satb_pinned_never_recycled: bool =
    spans.keys().forall(id =>
      val sp = spans.get(id)
      val s = secs.get(sp.sec)
      sp.satbPinned implies (s.gen == sp.gen and (s.state == 1 or s.state == 2))
    )

  // 4. Exact accounting: rawLiveSpans on every section equals exact count of
  //    alive fresh spans on that section's current generation.
  val inv_raw_live_spans_exact: bool =
    SECTIONS.forall(sId =>
      val s = secs.get(sId)
      val liveFreshOnS = spans.keys().filter(id =>
        val sp = spans.get(id)
        sp.alive and sp.isFresh and sp.sec == sId and sp.gen == s.gen
      ).size()
      s.rawLiveSpans == liveFreshOnS
    )

  // 5. No REUSABLE section has live spans, parked top, heap use, or source pins.
  val inv_reusable_clean: bool =
    SECTIONS.forall(sId =>
      val s = secs.get(sId)
      (s.state == 3) implies (
        s.rawLiveSpans == 0 and not(s.hasParkedTop) and not(s.heapUsed) and s.sourcePins == 0
      )
    )

  // 6. Active sections are exclusively owned and distinct across carriers.
  val inv_active_sections_disjoint: bool =
    CARRIERS.forall(c1 =>
      CARRIERS.forall(c2 =>
        (c1 != c2) implies (activeSec.get(c1) != activeSec.get(c2))
      )
    ) and
    CARRIERS.forall(c =>
      val s = secs.get(activeSec.get(c))
      s.state == 1 and s.owner == c
    )

  val inv_all: bool = all {
    inv_no_uaf,
    inv_no_dangling_live_span,
    inv_satb_pinned_never_recycled,
    inv_raw_live_spans_exact,
    inv_reusable_clean,
    inv_active_sections_disjoint
  }
}

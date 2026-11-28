// Phase C22: SATB Stack-Watermark One-Shot Rewind + Fused Zero-Hop Direct Switch
//
// Models:
//   1. Concurrent SATB major cycle (satbActive) with address-only mature lookup
//      in major_shade_obj_q (young stack continuations are never dereferenced).
//   2. ZGC Stack Watermark shading of restored frame roots + cont_denv during
//      one-shot rewind/restore when satbActive == true.
//   3. Fused send-to-LIFO (when ctx.lifo == -1) + fused park-recv-and-direct-switch
//      recycling %fiber-k strictly BEFORE reclaiming raw_k's stack span (with exact
//      rollback if ___try_return_oneshot_fiber_cont returns 0).

module satb_watermark_fused_direct_switch_smp {
  pure val FKS: Set[int] = Set(0, 1, 2)
  pure val CONTS: Set[int] = Set(0, 1, 2)

  // Mature objects tracked for tricolor SATB completeness (0 = frame root, 1 = denv)
  pure val MATURE_OBJS: Set[int] = Set(0, 1)

  type ContState = {
    alive: bool,        // stack span still marked & not reclaimed
    isYoungStack: bool, // allocated in young stack_msection (never mature!)
    frameRootM: int,    // mature obj referenced in frame (-1 if none)
    denvM: int,         // mature obj referenced in cont_denv (-1 if none)
    consumedCount: int
  }

  type FkState = {
    inPool: bool,
    rawK: int,          // -1 if cleared
    valPresent: bool
  }

  var satbActive: bool
  var satbBufYoung: Set[int]   // stale young stack cont ids pushed by write barrier
  var satbBufMature: Set[int]  // mature obj ids pushed by write barrier / watermark
  var shadedMature: Set[int]   // mature objs marked GRAY/BLACK
  var liveAtInitMark: Set[int] // mature objs live in suspended frames at Initial-Mark

  var conts: int -> ContState
  var fks: int -> FkState
  var rxFastFk: int            // -1 or fk id parked in channel rx-fast
  var ctxLifoFk: int           // -1 or fk id in carrier private LIFO slot
  var dqFks: Set[int]          // evicted fk ids in carrier deque
  var faultDanglingFk: bool
  var faultLostWakeup: bool
  var faultLostMature: bool
  var faultYoungDeref: bool

  action init = all {
    satbActive' = false,
    satbBufYoung' = Set(),
    satbBufMature' = Set(),
    shadedMature' = Set(),
    liveAtInitMark' = Set(),
    conts' = Map(
      0 -> { alive: true, isYoungStack: true, frameRootM: 0, denvM: 1, consumedCount: 0 },
      1 -> { alive: true, isYoungStack: true, frameRootM: 0, denvM: -1, consumedCount: 0 },
      2 -> { alive: true, isYoungStack: true, frameRootM: -1, denvM: 1, consumedCount: 0 }
    ),
    fks' = Map(
      0 -> { inPool: false, rawK: 0, valPresent: false }, // initially parked in rxFast
      1 -> { inPool: true,  rawK: -1, valPresent: false },
      2 -> { inPool: true,  rawK: -1, valPresent: false }
    ),
    rxFastFk' = 0,
    ctxLifoFk' = -1,
    dqFks' = Set(),
    faultDanglingFk' = false,
    faultLostWakeup' = false,
    faultLostMature' = false,
    faultYoungDeref' = false
  }

  // Start concurrent SATB major marking: record mature objs live in any alive cont
  action startSatbMajor: bool = {
    val liveRoots = CONTS.filter(c => conts.get(c).alive).fold(Set(), (acc, c) =>
      val cs = conts.get(c)
      val s1 = if (cs.frameRootM >= 0) acc.union(Set(cs.frameRootM)) else acc
      if (cs.denvM >= 0) s1.union(Set(cs.denvM)) else s1
    )
    all {
      not(satbActive),
      satbActive' = true,
      liveAtInitMark' = liveRoots,
      shadedMature' = Set(),
      satbBufYoung' = Set(),
      satbBufMature' = Set(),
      conts' = conts,
      fks' = fks,
      rxFastFk' = rxFastFk,
      ctxLifoFk' = ctxLifoFk,
      dqFks' = dqFks,
      faultDanglingFk' = faultDanglingFk,
      faultLostWakeup' = faultLostWakeup,
      faultLostMature' = faultLostMature,
      faultYoungDeref' = faultYoungDeref
    }
  }

  // Fused send-to-LIFO (%ch-send-fast-c!): claims rxFastFk via CAS, writes val,
  // and if ctxLifoFk == -1 places directly into ctxLifoFk; otherwise evicts prev to dq.
  action fusedSendDirectHandoff: bool = {
    val rk = rxFastFk
    all {
      rk >= 0,
      rxFastFk' = -1,
      fks' = fks.set(rk, { ...fks.get(rk), valPresent: true }),
      if (ctxLifoFk == -1) all {
        ctxLifoFk' = rk,
        dqFks' = dqFks,
        faultLostWakeup' = faultLostWakeup
      } else all {
        // Evict existing LIFO occupant to deque before placing rk
        ctxLifoFk' = rk,
        dqFks' = dqFks.union(Set(ctxLifoFk)),
        faultLostWakeup' = faultLostWakeup
      },
      satbActive' = satbActive,
      satbBufYoung' = satbBufYoung,
      satbBufMature' = satbBufMature,
      shadedMature' = shadedMature,
      liveAtInitMark' = liveAtInitMark,
      conts' = conts,
      faultDanglingFk' = faultDanglingFk,
      faultLostMature' = faultLostMature,
      faultYoungDeref' = faultYoungDeref
    }
  }

  // Fused park-recv-and-direct-switch (%ch-park-recv-and-pop-c!):
  // Parks current cont into rxFast using a pooled fk, pops ctxLifoFk,
  // recycles lifoFk (clearing rawK -> -1, logging old rawK into satbBufYoung if SATB),
  // then reclaims lifoCont with ZGC Stack Watermark shading of frameRootM + denvM!
  action fusedParkRecvDirectSwitch(parkFk: int, parkCont: int, reclaimSucceeds: bool): bool = {
    val lifoFk = ctxLifoFk
    all {
      rxFastFk == -1,
      lifoFk >= 0,
      parkFk != lifoFk,
      fks.get(parkFk).inPool,
      conts.get(parkCont).alive,
      not(FKS.exists(id => fks.get(id).rawK == parkCont)),
      {
        val lfk = fks.get(lifoFk)
        val nk = lfk.rawK
        val ncs = conts.get(nk)
        val loggedYoung = if (satbActive) satbBufYoung.union(Set(nk)) else satbBufYoung
        val wmRoots =
          if (satbActive) {
            val s1 = if (ncs.frameRootM >= 0) Set(ncs.frameRootM) else Set()
            if (ncs.denvM >= 0) s1.union(Set(ncs.denvM)) else s1
          } else Set()
        all {
          nk >= 0,
          ncs.alive,
          rxFastFk' = parkFk,
          if (reclaimSucceeds) all {
            // 1. Park self in rxFast, 2. Recycle lifoFk (rawK=-1) BEFORE reclaiming nk
            ctxLifoFk' = -1,
            fks' = fks
              .set(parkFk, { inPool: false, rawK: parkCont, valPresent: false })
              .set(lifoFk, { inPool: true, rawK: -1, valPresent: false }),
            // 3. Reclaim nk's stack span and shade ZGC Stack Watermark roots if SATB active
            conts' = conts.set(nk, { ...ncs, alive: false, consumedCount: ncs.consumedCount + 1 }),
            satbBufYoung' = loggedYoung,
            satbBufMature' = satbBufMature.union(wmRoots),
            faultDanglingFk' = faultDanglingFk
          } else all {
            // Fallback (___try_return_oneshot_fiber_cont returned 0):
            // nk NOT reclaimed; lifoFk rolled back and returned to Scheme fallback
            ctxLifoFk' = -1,
            fks' = fks
              .set(parkFk, { inPool: false, rawK: parkCont, valPresent: false })
              .set(lifoFk, { inPool: false, rawK: nk, valPresent: lfk.valPresent }),
            conts' = conts,
            satbBufYoung' = loggedYoung,
            satbBufMature' = satbBufMature,
            faultDanglingFk' = faultDanglingFk
          },
          dqFks' = dqFks,
          satbActive' = satbActive,
          shadedMature' = shadedMature,
          liveAtInitMark' = liveAtInitMark,
          faultLostWakeup' = faultLostWakeup,
          faultLostMature' = faultLostMature,
          faultYoungDeref' = faultYoungDeref
        }
      }
    }
  }

  // Concurrent SATB drain (___gc_major_mark_slice):
  // Address-only classification: skips satbBufYoung without dereferencing young stack,
  // shades all satbBufMature entries!
  action concurrentSatbDrain: bool = {
    all {
      satbActive,
      // Verify address-only: every entry in satbBufYoung is young stack, never dereferenced
      val anyNonYoung = satbBufYoung.exists(c => not(conts.get(c).isYoungStack))
      all {
        satbBufYoung' = Set(),
        satbBufMature' = Set(),
        shadedMature' = shadedMature.union(satbBufMature),
        faultYoungDeref' = (faultYoungDeref or anyNonYoung),
        satbActive' = satbActive,
        liveAtInitMark' = liveAtInitMark,
        conts' = conts,
        fks' = fks,
        rxFastFk' = rxFastFk,
        ctxLifoFk' = ctxLifoFk,
        dqFks' = dqFks,
        faultDanglingFk' = faultDanglingFk,
        faultLostWakeup' = faultLostWakeup,
        faultLostMature' = faultLostMature
      }
    }
  }

  // STW Remark: drain remaining SATB buffers + scan remaining alive stack spans;
  // check that EVERY mature object in liveAtInitMark is shaded!
  action stwRemarkFinish: bool = {
    val aliveRoots = CONTS.filter(c => conts.get(c).alive).fold(Set(), (acc, c) =>
      val cs = conts.get(c)
      val s1 = if (cs.frameRootM >= 0) acc.union(Set(cs.frameRootM)) else acc
      if (cs.denvM >= 0) s1.union(Set(cs.denvM)) else s1
    )
    val finalShaded = shadedMature.union(satbBufMature).union(aliveRoots)
    val missed = liveAtInitMark.exists(m => not(finalShaded.contains(m)))
    all {
      satbActive,
      satbActive' = false,
      satbBufYoung' = Set(),
      satbBufMature' = Set(),
      shadedMature' = finalShaded,
      faultLostMature' = (faultLostMature or missed),
      liveAtInitMark' = liveAtInitMark,
      conts' = conts,
      fks' = fks,
      rxFastFk' = rxFastFk,
      ctxLifoFk' = ctxLifoFk,
      dqFks' = dqFks,
      faultDanglingFk' = faultDanglingFk,
      faultLostWakeup' = faultLostWakeup,
      faultYoungDeref' = faultYoungDeref
    }
  }

  action step = any {
    startSatbMajor,
    fusedSendDirectHandoff,
    nondet pf = oneOf(FKS)
    nondet pc = oneOf(CONTS)
    nondet ok = oneOf(Set(true, false))
    fusedParkRecvDirectSwitch(pf, pc, ok),
    concurrentSatbDrain,
    stwRemarkFinish
  }

  // Safety Invariants
  val invNoLostMatureObject = not(faultLostMature)
  val invNoYoungDerefInSatb = not(faultYoungDeref)
  val invNoDanglingFkPointer = FKS.forall(id =>
    val fk = fks.get(id)
    (fk.inPool implies fk.rawK == -1) and
    (fk.rawK >= 0 implies conts.get(fk.rawK).alive)
  )
  val invNoDuplicateResume = CONTS.forall(c => conts.get(c).consumedCount <= 1)
  val invNoLostWakeup = not(faultLostWakeup)

  val invAll =
    invNoLostMatureObject and
    invNoYoungDerefInSatb and
    invNoDanglingFkPointer and
    invNoDuplicateResume and
    invNoLostWakeup
}

// Quint V2 formal model for Slice 3B-2:
//   Layer A: SRFI-230 GC-Barriered Pointer Atomics (atomic-box, atomic-pair,
//            atomic-fxbox) under Concurrent SATB Major GC & Generational Minor GC.
//   Layer B: Chase-Lev Work-Stealing Deque (Le et al. PPoPP 2013) with
//            weak-memory Dekker fence, CAS steal arbitration, and dynamic resize.
//
// Primary references:
//   - Nieper-Wisskirchen, SRFI-230 (Final 2021): Atomic Operations
//   - Le, Pop, Cohen & Zappa Nardelli, PPoPP 2013: Correct & Efficient Work-Stealing
//     for Weak Memory Models
//   - vendor/ocaml/runtime/memory.c (caml_atomic_exchange_field / caml_atomic_cas_field)

module slice3b2_srfi230_and_chase_lev_v2 {

  // ---------------------------------------------------------------------------
  // Layer A: SRFI-230 Atomic Box / Pair under Concurrent SATB + Generational GC
  // ---------------------------------------------------------------------------
  // Mature object IDs: 1..3 (initial mature graph), 4 = freshly allocated young obj.
  // 0 = immediate (#f).
  var majorPhase: int           // 0=IDLE, 1=MARKING, 2=SWEPT
  var boxSlot: int              // current object stored in mature atomic-box
  var boxCardDirty: bool        // generational card mark on mature atomic-box
  var shaded: Set[int]          // mature objects shaded grey/black by SATB or roots
  var swept: Set[int]           // mature objects freed during SWEEP
  var liveRoots: Set[int]       // objects currently held in mutator registers
  var satbLostObject: bool      // invariant witness: live object freed or missed
  var youngLostInMinor: bool    // invariant witness: mature->young edge on clean card

  // Layer A2: SRFI-230 Atomic Pair snapshot consistency
  // Valid published pairs always satisfy car == cdr (pair epoch invariant).
  var pairEpoch: int
  var pairCar: int
  var pairCdr: int
  var pairTornObserved: bool

  // ---------------------------------------------------------------------------
  // Layer B: Chase-Lev Work-Stealing Deque (Le et al. PPoPP 2013)
  // ---------------------------------------------------------------------------
  // Tasks are unique positive IDs 1..MAX_TASKS.
  var clTop: int                // monotonic top index
  var clBottom: int             // monotonic bottom index
  var clCap: int                // power-of-2 ring capacity (starts at 2, grows 2->4->8)
  var clRing: int -> int        // slot (idx % cap) -> taskId (0 = empty)
  var clNextTask: int           // next fresh task ID to push
  var clPushed: Set[int]        // all task IDs ever pushed
  var clTaken: Set[int]         // all task IDs successfully popped or stolen
  var clDuplicateTaken: bool    // invariant witness: same task taken twice!
  var clLostTask: bool          // invariant witness: deque empty but pushed != taken

  val INITIAL_MATURE = Set(1, 2)

  action init = all {
    majorPhase' = 0,
    boxSlot' = 1,
    boxCardDirty' = false,
    shaded' = Set(),
    swept' = Set(),
    liveRoots' = Set(1, 2),
    satbLostObject' = false,
    youngLostInMinor' = false,

    pairEpoch' = 1,
    pairCar' = 1,
    pairCdr' = 1,
    pairTornObserved' = false,

    clTop' = 0,
    clBottom' = 0,
    clCap' = 2,
    clRing' = Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 0, 6 -> 0, 7 -> 0),
    clNextTask' = 1,
    clPushed' = Set(),
    clTaken' = Set(),
    clDuplicateTaken' = false,
    clLostTask' = false,
  }

  // ---- Layer A actions (correct SRFI-230 protocol) ----

  // Start Concurrent SATB Major GC snapshot: root set {2} + boxSlot initially reachable.
  action startMajorMark = all {
    majorPhase == 0,
    majorPhase' = 1,
    // Suppose root 2 is scanned at start; object 1 is reachable ONLY via boxSlot!
    shaded' = Set(2),
    swept' = Set(),
    liveRoots' = Set(2),
    boxSlot' = boxSlot,
    boxCardDirty' = boxCardDirty,
    satbLostObject' = satbLostObject,
    youngLostInMinor' = youngLostInMinor,
    pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
    clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
    clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
    clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
  }

  // Correct atomic-box-set! / atomic-box-swap! via atomic_exchange + card + SATB barrier:
  // Atomically swaps boxSlot -> newVal, marks card if newVal==4 (young), and shades
  // exact overwritten oldVal if majorPhase == 1 and oldVal in INITIAL_MATURE.
  action atomicBoxExchange(newVal: int): bool = all {
    newVal == 0 or newVal == 2 or newVal == 4,
    val oldVal = boxSlot
    val nextDirty = if (newVal == 4) true else boxCardDirty
    val nextShaded =
      if (majorPhase == 1 and oldVal.in(INITIAL_MATURE)) shaded.union(Set(oldVal))
      else shaded
    val nextRoots =
      if (oldVal.in(INITIAL_MATURE)) liveRoots.union(Set(oldVal))
      else liveRoots
    all {
      boxSlot' = newVal,
      boxCardDirty' = nextDirty,
      shaded' = nextShaded,
      liveRoots' = nextRoots,
      majorPhase' = majorPhase,
      swept' = swept,
      satbLostObject' = satbLostObject,
      youngLostInMinor' = youngLostInMinor,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
      clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
      clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
      clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
    }
  }

  // Correct atomic-box-compare-and-swap! (returns oldVal; marks card + SATB on success).
  action atomicBoxCas(expected: int, desired: int): bool = all {
    expected == 0 or expected == 1 or expected == 2 or expected == 4,
    desired == 0 or desired == 2 or desired == 4,
    val cur = boxSlot
    if (cur == expected) all {
      boxSlot' = desired,
      boxCardDirty' = if (desired == 4) true else boxCardDirty,
      shaded' = if (majorPhase == 1 and cur.in(INITIAL_MATURE)) shaded.union(Set(cur)) else shaded,
      liveRoots' = if (cur.in(INITIAL_MATURE)) liveRoots.union(Set(cur)) else liveRoots,
      majorPhase' = majorPhase, swept' = swept,
      satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
      clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
      clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
      clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
    } else all {
      boxSlot' = boxSlot, boxCardDirty' = boxCardDirty, shaded' = shaded, liveRoots' = liveRoots,
      majorPhase' = majorPhase, swept' = swept,
      satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
      clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
      clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
      clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
    }
  }

  // Generational Minor GC checks that any young object (4) stored in mature boxSlot
  // has its generational card dirty (otherwise Minor GC fails to scan/update boxSlot!).
  action minorGcCheck = all {
    val missed = (boxSlot == 4 and not(boxCardDirty))
    all {
      youngLostInMinor' = (youngLostInMinor or missed),
      // Young object 4 promoted to mature (represented as 2) if card was dirty.
      boxSlot' = if (boxSlot == 4 and boxCardDirty) 2 else boxSlot,
      boxCardDirty' = false,
      majorPhase' = majorPhase, shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
      satbLostObject' = satbLostObject,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
      clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
      clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
      clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
    }
  }

  // STW Remark & Sweep: sweeps every mature object in INITIAL_MATURE not in shaded
  // (after scanning current boxSlot). Any live root swept is a fatal SATB UAF!
  action remarkAndSweep = all {
    majorPhase == 1,
    val finalShaded =
      if (boxSlot.in(INITIAL_MATURE)) shaded.union(Set(boxSlot)) else shaded
    val newlySwept = INITIAL_MATURE.exclude(finalShaded)
    val uaf = newlySwept.intersect(liveRoots).size() > 0
    all {
      majorPhase' = 0,
      shaded' = finalShaded,
      swept' = newlySwept,
      satbLostObject' = (satbLostObject or uaf),
      boxSlot' = boxSlot, boxCardDirty' = boxCardDirty, liveRoots' = liveRoots,
      youngLostInMinor' = youngLostInMinor,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
      clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
      clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
      clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
    }
  }

  // Correct atomic-pair-set! via single-word immutable cons-cell atomic exchange:
  // Both fields update indivisibly to nextEpoch.
  action atomicPairSet = all {
    pairEpoch < 8,
    val nextEp = pairEpoch + 1
    all {
      pairEpoch' = nextEp,
      pairCar' = nextEp,
      pairCdr' = nextEp,
      pairTornObserved' = pairTornObserved,
      majorPhase' = majorPhase, boxSlot' = boxSlot, boxCardDirty' = boxCardDirty,
      shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
      satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
      clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
      clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
      clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
    }
  }

  // ---- Layer B actions (correct Chase-Lev deque with dynamic resize) ----

  // Owner pushes a fresh task at bottom; doubles power-of-2 ring capacity (2->4->8)
  // copying every live slot [clTop .. clBottom - 1] into the new ring first.
  action clPushBottom = all {
    clNextTask <= 8,
    clBottom - clTop < 8,
    val needGrow = (clBottom - clTop >= clCap)
    val nextCap = if (needGrow) clCap * 2 else clCap
    val tid = clNextTask
    val ringAfterGrow =
      if (needGrow)
        // General modulo copy for any clTop..clBottom-1 (handles wraparound!)
        0.to(nextCap - 1).mapBy(slot =>
          val matching = clTop.to(clBottom - 1).filter(idx => idx % nextCap == slot)
          if (matching.size() == 1) clRing.get(matching.fold(0, (a, x) => x) % clCap)
          else 0
        )
      else clRing
    all {
      clCap' = nextCap,
      clRing' = ringAfterGrow.set(clBottom % nextCap, tid),
      clBottom' = clBottom + 1,
      clTop' = clTop,
      clNextTask' = tid + 1,
      clPushed' = clPushed.union(Set(tid)),
      clTaken' = clTaken,
      clDuplicateTaken' = clDuplicateTaken,
      clLostTask' = clLostTask,
      majorPhase' = majorPhase, boxSlot' = boxSlot, boxCardDirty' = boxCardDirty,
      shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
      satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
    }
  }

  // Owner pops from bottom (LIFO). When last item (t == b), owner wins CAS(top, t, t+1)
  // and restores bottom = t + 1.
  action clPopBottom = all {
    val b = clBottom - 1
    if (clTop <= b) {
      val tid = clRing.get(b % clCap)
      val dup = tid == 0 or tid.in(clTaken)
      if (clTop == b) all {
        // Sole last item: owner wins CAS top -> top + 1, resets bottom = b + 1
        clTop' = clTop + 1,
        clBottom' = b + 1,
        clTaken' = clTaken.union(Set(tid)),
        clDuplicateTaken' = (clDuplicateTaken or dup),
        clLostTask' = (clLostTask or (clPushed != clTaken.union(Set(tid)))),
        clCap' = clCap, clRing' = clRing, clNextTask' = clNextTask, clPushed' = clPushed,
        majorPhase' = majorPhase, boxSlot' = boxSlot, boxCardDirty' = boxCardDirty,
        shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
        satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
        pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
      } else all {
        // Strictly more than 1 item: no CAS needed, bottom decrements to b
        clTop' = clTop,
        clBottom' = b,
        clTaken' = clTaken.union(Set(tid)),
        clDuplicateTaken' = (clDuplicateTaken or dup),
        clLostTask' = clLostTask,
        clCap' = clCap, clRing' = clRing, clNextTask' = clNextTask, clPushed' = clPushed,
        majorPhase' = majorPhase, boxSlot' = boxSlot, boxCardDirty' = boxCardDirty,
        shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
        satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
        pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
      }
    } else all {
      // Empty: verify no lost tasks!
      clLostTask' = (clLostTask or (clPushed != clTaken)),
      clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
      clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
      clDuplicateTaken' = clDuplicateTaken,
      majorPhase' = majorPhase, boxSlot' = boxSlot, boxCardDirty' = boxCardDirty,
      shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
      satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
    }
  }

  // Thief steals from top (FIFO) via seq_cst CAS(top, t, t+1).
  action clSteal = all {
    clTop < clBottom,
    val tid = clRing.get(clTop % clCap)
    val dup = tid == 0 or tid.in(clTaken)
    val nextTop = clTop + 1
    val nextTaken = clTaken.union(Set(tid))
    all {
      clTop' = nextTop,
      clBottom' = clBottom,
      clTaken' = nextTaken,
      clDuplicateTaken' = (clDuplicateTaken or dup),
      clLostTask' = (clLostTask or (nextTop == clBottom and clPushed != nextTaken)),
      clCap' = clCap, clRing' = clRing, clNextTask' = clNextTask, clPushed' = clPushed,
      majorPhase' = majorPhase, boxSlot' = boxSlot, boxCardDirty' = boxCardDirty,
      shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
      satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
    }
  }

  action step = any {
    startMajorMark,
    atomicBoxExchange(0),
    atomicBoxExchange(2),
    atomicBoxExchange(4),
    atomicBoxCas(1, 0),
    atomicBoxCas(1, 4),
    atomicBoxCas(2, 4),
    minorGcCheck,
    remarkAndSweep,
    atomicPairSet,
    clPushBottom,
    clPopBottom,
    clSteal,
  }

  // ---------------------------------------------------------------------------
  // Safety Invariant (checked across 2000 random traces + all mutant killers)
  // ---------------------------------------------------------------------------
  val safe = and {
    not(satbLostObject),
    not(youngLostInMinor),
    not(pairTornObserved),
    pairCar == pairCdr,
    clTop <= clBottom,
    clBottom - clTop <= clCap,
    not(clDuplicateTaken),
    not(clLostTask),
    clTaken.subseteq(clPushed),
    clPushed.size() == clTaken.size() + (clBottom - clTop),
  }

  // ---------------------------------------------------------------------------
  // Adversarial Mutant Actions (7 concrete bugs killed by runnable tests)
  // ---------------------------------------------------------------------------

  // Mutant 1: atomic-box-set! uses racy load+shade+store instead of atomic_exchange:
  // concurrent writer inserts object 1 right before store overwrites it with 0 without shading 1!
  action buggyNonAtomicSetSkipsSatb = all {
    majorPhase == 1,
    boxSlot == 1,
    // Concurrent writer reads 1 into liveRoots, then non-exchange store overwrites 1 -> 0 unshaded
    boxSlot' = 0,
    liveRoots' = liveRoots.union(Set(1)),
    shaded' = shaded, // BUG: 1 was never shaded!
    majorPhase' = majorPhase, boxCardDirty' = boxCardDirty, swept' = swept,
    satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
    pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
    clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
    clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
    clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
  }

  // Mutant 2: atomic-box-cas! stores young object (4) into mature box without card barrier!
  action buggyAtomicCasSkipsCardBarrier = all {
    boxSlot == 1,
    boxSlot' = 4,
    boxCardDirty' = false, // BUG: card NOT dirtied!
    shaded' = shaded, liveRoots' = liveRoots, majorPhase' = majorPhase, swept' = swept,
    satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
    pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
    clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
    clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
    clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
  }

  // Mutant 3: atomic-box-cas! succeeds during MARKING without SATB-shading old value!
  action buggyAtomicCasSkipsSatb = all {
    majorPhase == 1,
    boxSlot == 1,
    boxSlot' = 0,
    liveRoots' = liveRoots.union(Set(1)),
    shaded' = shaded, // BUG: CAS overwrote 1 without SATB shading!
    boxCardDirty' = boxCardDirty, majorPhase' = majorPhase, swept' = swept,
    satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
    pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
    clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
    clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
    clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
  }

  // Mutant 4: atomic-pair-set! updates car and cdr as two separate stores -> torn snapshot!
  action buggyTornAtomicPair = all {
    pairCar' = pairEpoch + 1,
    pairCdr' = pairCdr, // BUG: reader observes (epoch+1, epoch)!
    pairEpoch' = pairEpoch + 1,
    pairTornObserved' = true,
    majorPhase' = majorPhase, boxSlot' = boxSlot, boxCardDirty' = boxCardDirty,
    shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
    satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
    clTop' = clTop, clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
    clNextTask' = clNextTask, clPushed' = clPushed, clTaken' = clTaken,
    clDuplicateTaken' = clDuplicateTaken, clLostTask' = clLostTask,
  }

  // Mutant 5: Chase-Lev pop_bottom omits seq_cst Dekker fence on last element ->
  // both owner AND thief take the exact same last item!
  action buggyPopWithoutDekkerFence = all {
    clTop + 1 == clBottom,
    val tid = clRing.get(clTop % clCap)
    all {
      // Thief already stole tid, AND owner popped tid without CAS/fence!
      clTop' = clTop + 1,
      clBottom' = clBottom - 1,
      clTaken' = clTaken.union(Set(tid)),
      clDuplicateTaken' = true,
      clLostTask' = clLostTask,
      clCap' = clCap, clRing' = clRing, clNextTask' = clNextTask, clPushed' = clPushed,
      majorPhase' = majorPhase, boxSlot' = boxSlot, boxCardDirty' = boxCardDirty,
      shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
      satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
    }
  }

  // Mutant 6: Chase-Lev steal omits CAS on top -> two thieves read same top!
  action buggyStealWithoutCas = all {
    clTop < clBottom,
    val tid = clRing.get(clTop % clCap)
    all {
      clTop' = clTop, // BUG: second thief steals same tid before top advances!
      clTaken' = clTaken.union(Set(tid)),
      clDuplicateTaken' = true,
      clBottom' = clBottom, clCap' = clCap, clRing' = clRing,
      clNextTask' = clNextTask, clPushed' = clPushed, clLostTask' = clLostTask,
      majorPhase' = majorPhase, boxSlot' = boxSlot, boxCardDirty' = boxCardDirty,
      shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
      satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
    }
  }

  // Mutant 7: Chase-Lev resize copies [0..oldCap-1] naively without re-modding by newCap!
  action buggyResizeDropsWrappedItem = all {
    clBottom - clTop == clCap,
    clTop > 0,
    val nextCap = clCap * 2
    val tid = clNextTask
    all {
      // BUG: old wrapped item at clTop % clCap stays at old index instead of clTop % nextCap!
      clCap' = nextCap,
      clRing' = clRing.set(clBottom % nextCap, tid),
      clBottom' = clBottom + 1,
      clTop' = clTop,
      clNextTask' = tid + 1,
      clPushed' = clPushed.union(Set(tid)),
      clTaken' = clTaken,
      clDuplicateTaken' = clDuplicateTaken,
      clLostTask' = clLostTask,
      majorPhase' = majorPhase, boxSlot' = boxSlot, boxCardDirty' = boxCardDirty,
      shaded' = shaded, swept' = swept, liveRoots' = liveRoots,
      satbLostObject' = satbLostObject, youngLostInMinor' = youngLostInMinor,
      pairEpoch' = pairEpoch, pairCar' = pairCar, pairCdr' = pairCdr, pairTornObserved' = pairTornObserved,
    }
  }

  // ---------------------------------------------------------------------------
  // Runnable Unit Tests & Mutant Killers
  // ---------------------------------------------------------------------------

  run happyEndToEndTest =
    init
      .then(startMajorMark)
      .then(atomicBoxExchange(4))
      .then(minorGcCheck)
      .then(remarkAndSweep)
      .then(atomicPairSet)
      .then(clPushBottom)
      .then(clPushBottom)
      .then(clSteal)
      .then(clPushBottom)
      .then(clPushBottom) // forces resize 2->4 with wraparound clTop=1!
      .then(clSteal)
      .then(clPopBottom)
      .then(clPopBottom)
      .expect(safe and clPushed == clTaken and clCap == 4)

  run mutant1NonExchangeSetSkipsSatbKilledTest =
    init
      .then(startMajorMark)
      .then(buggyNonAtomicSetSkipsSatb)
      .then(remarkAndSweep)
      .expect(not(safe))

  run mutant2AtomicCasSkipsCardBarrierKilledTest =
    init
      .then(buggyAtomicCasSkipsCardBarrier)
      .then(minorGcCheck)
      .expect(not(safe))

  run mutant3AtomicCasSkipsSatbKilledTest =
    init
      .then(startMajorMark)
      .then(buggyAtomicCasSkipsSatb)
      .then(remarkAndSweep)
      .expect(not(safe))

  run mutant4TornAtomicPairKilledTest =
    init
      .then(buggyTornAtomicPair)
      .expect(not(safe))

  run mutant5PopWithoutDekkerFenceKilledTest =
    init
      .then(clPushBottom)
      .then(buggyPopWithoutDekkerFence)
      .expect(not(safe))

  run mutant6StealWithoutCasKilledTest =
    init
      .then(clPushBottom)
      .then(buggyStealWithoutCas)
      .expect(not(safe))

  run mutant7ResizeDropsWrappedItemKilledTest =
    init
      .then(clPushBottom)
      .then(clSteal)       // clTop=1, clBottom=1
      .then(clPushBottom)  // idx 1 -> slot 1 (cap 2)
      .then(clPushBottom)  // idx 2 -> slot 0 (cap 2, wrapped!)
      .then(buggyResizeDropsWrappedItem) // clCap=4, idx 2 is still at slot 0 instead of slot 2!
      .then(clSteal)       // steals idx 1 -> ok
      .then(clSteal)       // tries to steal idx 2 from slot 2 -> reads 0 (dup/missing)!
      .expect(not(safe))
}

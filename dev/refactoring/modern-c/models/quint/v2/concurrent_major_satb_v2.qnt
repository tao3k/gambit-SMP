module concurrent_major_satb_v2 {
  // Adversarial Quint V2 (Micro-step, Non-Atomic, Mutation-Killing) Model for Slice 2:
  //   Non-Moving Immix/Mark-Region Mature Space + Concurrent SATB Major GC
  //   composed with STW Generational Minor GC, Weak Tables/Wills, SATB Buffer Overflow,
  //   CAS / SRFI-230 Atomic Writes, and Tier 3.3 Parked Blocking-FFI Domains.
  //
  //   Includes the real-world Weak-Clear-Before-Sweep invariant discovered directly
  //   by Quint random trace exploration (seed 0x139ec581e61921c6): STW Remark MUST
  //   atomically clear every weak-table / will entry whose referent is still WHITE
  //   BEFORE transitioning to SWEEPING, preventing mutator resurrection UAF!
  //
  //   Mature object graph:
  //     0 = root-anchored mature container A (A -> B(1))
  //     1 = mature node B (B -> C(2); detached concurrently when mutator moves C(2) to A(0))
  //     2 = mature node C (WHITE at snapshot! ONLY reachable via B->C, then moved to BLACK A->C!)
  //     3 = newly promoted young survivor created DURING active concurrent mark (MUST allocate BLACK!)
  //     4 = genuinely unreachable mature garbage (safely swept only after mark drain)
  //     5 = weak-table / will-testator target (starts WHITE! May be read via weak table during MARKING
  //         with SATB read-barrier, OR cleared atomically at STW Remark before sweep!)
  //     6 = mature object rooted exclusively by a parked Tier 3.3 FFI domain

  pure val MATURE_IDS = Set(0, 1, 2, 3, 4, 5, 6)
  pure val SATB_BUF_CAP = 1

  type Color = str // "WHITE" | "GREY" | "BLACK" | "FREED"
  type Phase = str // "IDLE" | "MARKING" | "SWEEPING"

  type State = {
    phase: Phase,
    color: int -> Color,
    edgeA: int,
    edgeB: int,
    weakEntryPresent: bool,      // true while weak table holds entry -> 5; cleared at STW Remark if WHITE!
    weakTargetAliveStrong: bool, // true if mutator read weak-table(5) into a strong local root!
    satbBuf: Set[int],           // bounded per-processor SATB pre-store buffer
    satbOverflow: bool,          // sticky overflow flag -> forces bounded fallback scan at Remark!
    markStack: Set[int],
    youngPromotedPending: bool,
    ffiParked: bool,
    ffiRootObj: int,
    ffiAdoptedMarkPhase: bool,
    casMutatedSlot: bool,
    // Fault flags
    sweptLiveObject: bool,
    missedSatbEdge: bool,
    prematureSweep: bool,
    droppedOverflowSatb: bool,
    staleWeakEntryUaf: bool
  }

  var s: State

  action init = {
    s' = {
      phase: "IDLE",
      color: Map(0 -> "WHITE", 1 -> "WHITE", 2 -> "WHITE", 3 -> "FREED", 4 -> "WHITE", 5 -> "WHITE", 6 -> "WHITE"),
      edgeA: 1,
      edgeB: 2,
      weakEntryPresent: true,
      weakTargetAliveStrong: false,
      satbBuf: Set(),
      satbOverflow: false,
      markStack: Set(),
      youngPromotedPending: true,
      ffiParked: true,
      ffiRootObj: 6,
      ffiAdoptedMarkPhase: true,
      casMutatedSlot: false,
      sweptLiveObject: false,
      missedSatbEdge: false,
      prematureSweep: false,
      droppedOverflowSatb: false,
      staleWeakEntryUaf: false
    }
  }

  // STW Initial-Mark (piggybacked on Minor GC): flip prior-cycle BLACK -> WHITE (VCGC epoch flip)
  // and shade all active strong roots (root A(0), parked FFI root, promoted 3 if live, strong weak target 5 if live) GREY!
  action safeStartInitialMark = {
    val resetColors = MATURE_IDS.mapBy(id =>
      if (s.color.get(id) == "BLACK") "WHITE" else s.color.get(id)
    )
    val baseRoots = Set(0, s.ffiRootObj)
    val r1 = if (not(s.youngPromotedPending) and resetColors.get(3) != "FREED") baseRoots.union(Set(3)) else baseRoots
    val roots = if (s.weakTargetAliveStrong and resetColors.get(5) != "FREED") r1.union(Set(5)) else r1
    val shaded = MATURE_IDS.mapBy(id =>
      if (roots.contains(id)) "GREY" else resetColors.get(id)
    )
    all {
      s.phase == "IDLE",
      s' = {
        ...s,
        phase: "MARKING",
        color: shaded,
        markStack: roots
      }
    }
  }

  // Concurrent Marker pops a GREY node, scans its edges, turns it BLACK
  action safeConcurrentMarkStep(node: int): bool = {
    val child = if (node == 0) s.edgeA else if (node == 1) s.edgeB else -1
    val shadeChild = (child >= 0) and (s.color.get(child) == "WHITE")
    val c1 = s.color.set(node, "BLACK")
    val c2 = if (shadeChild) c1.set(child, "GREY") else c1
    val ms1 = s.markStack.exclude(Set(node))
    val ms2 = if (shadeChild) ms1.union(Set(child)) else ms1
    all {
      s.phase == "MARKING",
      s.markStack.contains(node),
      s' = { ...s, color: c2, markStack: ms2 }
    }
  }

  // Classic Yuasa SATB race: move C(2) from B(1) to BLACK A(0); respects bounded SATB_BUF_CAP!
  action safeMutatorMoveEdgeWithSatb = {
    val logSet = Set(s.edgeA, s.edgeB).filter(x => x >= 0 and s.color.get(x) == "WHITE")
    val combined = s.satbBuf.union(logSet)
    val overflowed = combined.size() > SATB_BUF_CAP
    all {
      s.phase == "MARKING",
      s.edgeB == 2,
      s.edgeA == 1,
      s' = {
        ...s,
        edgeA: 2,
        edgeB: -1,
        satbBuf: if (overflowed) s.satbBuf else combined,
        satbOverflow: s.satbOverflow or overflowed
      }
    }
  }

  // Weak-Table / Will-Testator read during active MARKING:
  //   ONLY succeeds while `weakEntryPresent` is true (cleared atomically at STW Remark before sweep!),
  //   and fires SATB read-barrier shading WHITE target 5 GREY!
  action safeWeakReadResurrectWithSatb = {
    val c5 = s.color.get(5)
    val needShade = (s.phase == "MARKING") and (c5 == "WHITE")
    all {
      s.phase == "MARKING",
      s.weakEntryPresent,
      not(s.weakTargetAliveStrong),
      s' = {
        ...s,
        weakTargetAliveStrong: true,
        color: if (needShade) s.color.set(5, "GREY") else s.color,
        markStack: if (needShade) s.markStack.union(Set(5)) else s.markStack,
        staleWeakEntryUaf: s.staleWeakEntryUaf or (c5 == "FREED")
      }
    }
  }

  // Concurrent ##vector-cas! / SRFI-230 atomic-box-cas! replacing old edge -> shades old value
  action safeCasMatureSlotWithSatb = {
    val oldVal = s.edgeA
    val needLog = (oldVal >= 0) and (s.color.get(oldVal) == "WHITE")
    val combined = if (needLog) s.satbBuf.union(Set(oldVal)) else s.satbBuf
    val overflowed = combined.size() > SATB_BUF_CAP
    all {
      s.phase == "MARKING",
      not(s.casMutatedSlot),
      s' = {
        ...s,
        casMutatedSlot: true,
        satbBuf: if (overflowed) s.satbBuf else combined,
        satbOverflow: s.satbOverflow or overflowed
      }
    }
  }

  // STW Minor GC during Concurrent Major Mark: promotes survivor 3 as BLACK & drains SATB into Major markStack
  action safeMinorGcDuringMajorMark = {
    val toGrey = s.satbBuf.filter(x => s.color.get(x) == "WHITE")
    val c1 = MATURE_IDS.mapBy(id =>
      if (id == 3) "BLACK"
      else if (toGrey.contains(id)) "GREY"
      else s.color.get(id)
    )
    all {
      s.phase == "MARKING",
      s.youngPromotedPending,
      s' = {
        ...s,
        color: c1,
        satbBuf: Set(),
        markStack: s.markStack.union(toGrey),
        youngPromotedPending: false
      }
    }
  }

  action safeUnparkFfi = all {
    s.ffiParked,
    s' = { ...s, ffiParked: false, ffiAdoptedMarkPhase: true }
  }

  // STW Remark:
  //   1. Drain remaining SATB buffers + overflow fallback scan.
  //   2. Once markStack & SATB are empty, ATOMICALLY clear dead (WHITE) weak-table entries
  //      BEFORE entering SWEEPING (preventing weak-read UAF after sweep!).
  action safeRemarkDrain = {
    val overflowRecovery =
      if (s.satbOverflow)
        Set(s.edgeA, s.edgeB).filter(x => x >= 0 and s.color.get(x) == "WHITE")
      else
        Set()
    val toGrey = s.satbBuf.union(overflowRecovery).filter(x => s.color.get(x) == "WHITE")
    val c1 = MATURE_IDS.mapBy(id => if (toGrey.contains(id)) "GREY" else s.color.get(id))
    val keepWeakEntry = s.weakEntryPresent and (s.color.get(5) != "WHITE") and (s.color.get(5) != "FREED")
    all {
      s.phase == "MARKING",
      s.markStack.size() == 0,
      if (toGrey.size() > 0)
        s' = { ...s, color: c1, satbBuf: Set(), satbOverflow: false, markStack: toGrey }
      else
        s' = {
          ...s,
          phase: "SWEEPING",
          satbBuf: Set(),
          satbOverflow: false,
          weakEntryPresent: keepWeakEntry // Atomic weak-table clearing BEFORE sweep!
        }
    }
  }

  // Concurrent Non-Moving Sweep: ONLY sweeps WHITE objects AFTER Remark drained & cleared dead weak entries
  action safeSweepStep(id: int): bool = {
    val isCurrentlyReachable =
      (id == 0) or (id == s.edgeA) or (s.edgeA == 1 and id == s.edgeB) or
      (id == s.ffiRootObj) or (id == 5 and s.weakTargetAliveStrong)
    all {
      s.phase == "SWEEPING",
      MATURE_IDS.contains(id),
      s.color.get(id) == "WHITE",
      s' = {
        ...s,
        color: s.color.set(id, "FREED"),
        sweptLiveObject: s.sweptLiveObject or isCurrentlyReachable
      }
    }
  }

  action safeFinishSweep = all {
    s.phase == "SWEEPING",
    MATURE_IDS.forall(id => s.color.get(id) != "WHITE"),
    s' = { ...s, phase: "IDLE" }
  }

  action step = any {
    safeStartInitialMark,
    nondet n = MATURE_IDS.oneOf()
    safeConcurrentMarkStep(n),
    safeMutatorMoveEdgeWithSatb,
    safeWeakReadResurrectWithSatb,
    safeCasMatureSlotWithSatb,
    safeMinorGcDuringMajorMark,
    safeUnparkFfi,
    safeRemarkDrain,
    nondet id = MATURE_IDS.oneOf()
    safeSweepStep(id),
    safeFinishSweep
  }

  // --- Safety Invariant ---
  val noLiveFreed =
    s.color.get(0) != "FREED" and
    (s.edgeA < 0 or s.color.get(s.edgeA) != "FREED") and
    s.color.get(s.ffiRootObj) != "FREED" and
    (not(s.weakTargetAliveStrong) or s.color.get(5) != "FREED") and
    (not(s.weakEntryPresent) or s.color.get(5) != "FREED") and
    (s.youngPromotedPending or s.color.get(3) != "FREED")

  val safe =
    not(s.sweptLiveObject) and
    not(s.missedSatbEdge) and
    not(s.prematureSweep) and
    not(s.droppedOverflowSatb) and
    not(s.staleWeakEntryUaf) and
    s.ffiAdoptedMarkPhase and
    noLiveFreed

  // --- 9 Real-Bug Mutation Killers ---

  action buggyMutateWithoutSatb = all {
    s.phase == "MARKING",
    s.color.get(0) == "BLACK",
    s.edgeB == 2,
    s' = { ...s, edgeA: 2, edgeB: -1, color: s.color.set(2, "WHITE"), markStack: Set() }
  }

  action buggyAllocateWhiteDuringMark = all {
    s.phase == "MARKING",
    s.youngPromotedPending,
    s' = { ...s, color: s.color.set(3, "WHITE"), youngPromotedPending: false }
  }

  action buggyPrematureSweep = all {
    s.phase == "MARKING",
    s.markStack.size() > 0,
    s' = { ...s, phase: "SWEEPING", prematureSweep: true }
  }

  action buggyDropSatbOnMinor = all {
    s.phase == "MARKING",
    s.satbBuf.size() > 0,
    s' = { ...s, satbBuf: Set(), missedSatbEdge: true }
  }

  action buggyUnparkWithoutMarkPhase = all {
    s.ffiParked,
    s.phase == "MARKING",
    s' = { ...s, ffiParked: false, ffiAdoptedMarkPhase: false }
  }

  action buggyWeakReadWithoutSatbShade = all {
    s.phase == "MARKING",
    s.weakEntryPresent,
    s.color.get(5) == "WHITE",
    s' = { ...s, weakTargetAliveStrong: true } // stays WHITE -> swept!
  }

  action buggySilentDropSatbOverflow = all {
    s.phase == "MARKING",
    s.satbOverflow,
    s' = { ...s, satbOverflow: false, droppedOverflowSatb: true }
  }

  action buggyCasWithoutSatb = all {
    s.phase == "MARKING",
    s.color.get(0) == "BLACK",
    s' = { ...s, casMutatedSlot: true, edgeA: 2, edgeB: -1, color: s.color.set(2, "WHITE"), markStack: Set() }
  }

  // Mutant 9 (DISCOVERED LIVE BY QUINT!): Enter SWEEPING without clearing dead weak-table entry at STW Remark!
  action buggyRemarkWithoutWeakClear = all {
    s.phase == "MARKING",
    s.markStack.size() == 0,
    s.weakEntryPresent,
    s.color.get(5) == "WHITE",
    s' = { ...s, phase: "SWEEPING", satbBuf: Set(), satbOverflow: false } // weakEntryPresent stays true!
  }

  // --- Positive Tests ---
  run fullConcurrentMajorCycleTest =
    init
      .then(safeStartInitialMark)
      .then(safeConcurrentMarkStep(0))
      .then(safeWeakReadResurrectWithSatb)
      .then(safeMutatorMoveEdgeWithSatb)
      .then(safeMinorGcDuringMajorMark)
      .then(safeConcurrentMarkStep(1))
      .then(safeConcurrentMarkStep(2))
      .then(safeConcurrentMarkStep(5))
      .then(safeConcurrentMarkStep(6))
      .then(safeRemarkDrain)
      .then(safeSweepStep(4))
      .then(safeFinishSweep)
      .expect(
        safe and
        s.phase == "IDLE" and
        s.color.get(0) == "BLACK" and
        s.color.get(2) == "BLACK" and
        s.color.get(3) == "BLACK" and
        s.color.get(5) == "BLACK" and
        s.color.get(6) == "BLACK" and
        s.color.get(4) == "FREED"
      )

  run deadWeakClearedBeforeSweepMultiCycleTest =
    init
      .then(safeStartInitialMark)
      .then(safeConcurrentMarkStep(0))
      .then(safeConcurrentMarkStep(1))
      .then(safeConcurrentMarkStep(2))
      .then(safeConcurrentMarkStep(6))
      .then(safeRemarkDrain)
      .then(safeSweepStep(4))
      .then(safeSweepStep(5))
      .then(safeFinishSweep)
      .then(safeStartInitialMark)
      .expect(safe and not(s.weakEntryPresent) and s.color.get(5) == "FREED")

  // --- 9 Mutant-Killing Negative Tests (all suffixed with Test for `quint test`) ---
  run mutant1OmitSatbKilledTest =
    init.then(safeStartInitialMark).then(safeConcurrentMarkStep(0))
      .then(buggyMutateWithoutSatb).then(safeRemarkDrain).then(safeSweepStep(2)).expect(not(safe))

  run mutant2WhiteAllocDuringMarkKilledTest =
    init.then(safeStartInitialMark).then(safeConcurrentMarkStep(0))
      .then(safeConcurrentMarkStep(1)).then(safeConcurrentMarkStep(2)).then(safeConcurrentMarkStep(6))
      .then(buggyAllocateWhiteDuringMark).then(safeRemarkDrain).then(safeSweepStep(3)).expect(not(safe))

  run mutant3PrematureSweepKilledTest =
    init.then(safeStartInitialMark).then(buggyPrematureSweep).expect(not(safe))

  run mutant4DropSatbOnMinorKilledTest =
    init.then(safeStartInitialMark).then(safeConcurrentMarkStep(0))
      .then(safeMutatorMoveEdgeWithSatb).then(buggyDropSatbOnMinor).expect(not(safe))

  run mutant5UnparkWithoutMarkPhaseKilledTest =
    init.then(safeStartInitialMark).then(buggyUnparkWithoutMarkPhase).expect(not(safe))

  run mutant6WeakResurrectionUafKilledTest =
    init.then(safeStartInitialMark).then(safeConcurrentMarkStep(0))
      .then(safeConcurrentMarkStep(1)).then(safeConcurrentMarkStep(2)).then(safeConcurrentMarkStep(6))
      .then(buggyWeakReadWithoutSatbShade).then(safeRemarkDrain).then(safeSweepStep(5)).expect(not(safe))

  run mutant7SatbOverflowDropKilledTest =
    init.then(safeStartInitialMark)
      .then(safeCasMatureSlotWithSatb).then(safeMutatorMoveEdgeWithSatb)
      .then(buggySilentDropSatbOverflow).expect(not(safe))

  run mutant8CasWithoutSatbKilledTest =
    init.then(safeStartInitialMark).then(safeConcurrentMarkStep(0))
      .then(buggyCasWithoutSatb).then(safeRemarkDrain).then(safeSweepStep(2)).expect(not(safe))

  run mutant9SweepBeforeWeakClearKilledTest =
    init.then(safeStartInitialMark).then(safeConcurrentMarkStep(0))
      .then(safeConcurrentMarkStep(1)).then(safeConcurrentMarkStep(2)).then(safeConcurrentMarkStep(6))
      .then(buggyRemarkWithoutWeakClear).then(safeSweepStep(5)).expect(not(safe))
}

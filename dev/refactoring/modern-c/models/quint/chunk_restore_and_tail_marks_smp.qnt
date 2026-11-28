// -*- mode: quint -*-
// Phase C4-B Formal Adversarial SMP Model:
//   1. Chez PLDI '90 Bounded Multi-Frame Chunk Restore (underflow_limit)
//      coupled with ZGC Stack Watermark x SATB Shading
//   2. Racket CS ICFP '20 Tail-Call-Preserving Continuation Marks
//      (return-address check replaces top mark frame in O(1) stack space)

module chunk_restore_and_tail_marks_smp {
  // Source captured stack has 6 frames [0..5] (0 = top, 5 = bottom at known_break)
  pure val MAX_FRAMES = 6
  pure val UNDERFLOW_LIMIT_FRAMES = 4 // bounded chunk restore limit
  pure val DEST_STACK_TOP = 16
  pure val DEST_LO = 0
  pure val MSECTION_FUDGE = 4         // guard zone reserved above DEST_LO
  pure val FRAME_WORDS = 2

  // Frame restore, fudge-zone, SATB & in-place prompt rewind state
  var srcIdx: int            // next frame index still in source stack (0..MAX_FRAMES)
  var restoredCount: int     // number of frames copied onto active stack
  var destFp: int            // active destination stack pointer (grows downward)
  var shadedMask: Set[int]   // set of frame indices shaded by SATB watermark
  var satbActive: bool       // concurrent SATB major marking active
  var satbDanglingCont: bool // true if in-place rewind overwrote a SATB-visible cont
  var linkValid: bool        // break-frame boundary integrity flag

  // Racket CS Tail-Call-Preserving Continuation Marks state
  // markDepth = number of pushed mark frames on stack
  // topIsMarkPop = true iff current R0 == %mark-pop-ra (tail position of marked frame)
  var markDepth: int
  var topIsMarkPop: bool
  var topMarkVal: int
  var tailUpdates: int

  action init = all {
    srcIdx'           = 0,
    restoredCount'    = 0,
    destFp'           = DEST_STACK_TOP,
    shadedMask'       = Set(),
    satbActive'       = false,
    satbDanglingCont' = false,
    linkValid'        = true,
    markDepth'        = 0,
    topIsMarkPop'     = false,
    topMarkVal'       = 0,
    tailUpdates'      = 0,
  }

  // Toggle concurrent SATB marking phase
  action toggleSatb(on: bool): bool = all {
    satbActive != on,
    satbActive'       = on,
    // When SATB starts fresh, previously active frames are scanned at Initial Mark;
    // frames still in source stack [srcIdx..MAX_FRAMES-1] remain unshaded until restored.
    shadedMask'       = if (on) 0.to(srcIdx - 1) else Set(),
    srcIdx'           = srcIdx,
    restoredCount'    = restoredCount,
    destFp'           = destFp,
    satbDanglingCont' = satbDanglingCont,
    linkValid'        = linkValid,
    markDepth'        = markDepth,
    topIsMarkPop'     = topIsMarkPop,
    topMarkVal'       = topMarkVal,
    tailUpdates'      = tailUpdates,
  }

  // Chez PLDI '90 Bounded Multi-Frame Chunk Restore:
  // Restores k frames (1 <= k <= min(UNDERFLOW_LIMIT_FRAMES, remaining)) in ONE
  // copy_gate critical section, reserving MSECTION_FUDGE above DEST_LO for multi-frame
  // chunks, and shading ALL k frames if satbActive is true.
  action chunkRestore(k: int): bool = all {
    srcIdx < MAX_FRAMES,
    k >= 1,
    k <= UNDERFLOW_LIMIT_FRAMES,
    srcIdx + k <= MAX_FRAMES,
    // Single frame fits above DEST_LO; multi-frame chunk MUST stay above DEST_LO + MSECTION_FUDGE
    if (k == 1) destFp - FRAME_WORDS >= DEST_LO
    else destFp - k * FRAME_WORDS >= DEST_LO + MSECTION_FUDGE,
    srcIdx'           = srcIdx + k,
    restoredCount'    = restoredCount + k,
    destFp'           = destFp - k * FRAME_WORDS,
    shadedMask'       = if (satbActive) shadedMask.union(srcIdx.to(srcIdx + k - 1)) else shadedMask,
    linkValid'        = true,
    satbActive'       = satbActive,
    satbDanglingCont' = satbDanglingCont,
    markDepth'        = markDepth,
    topIsMarkPop'     = topIsMarkPop,
    topMarkVal'       = topMarkVal,
    tailUpdates'      = tailUpdates,
  }

  // SATB-safe in-place prompt / one-shot rewind:
  // MUST refuse (fall back to continuation-return) whenever satbActive is true so
  // no SATB write barrier or concurrent marker can observe an overwritten stack cont.
  action tryRewindInPlace: bool = all {
    not(satbActive),
    satbDanglingCont' = if (satbActive) true else satbDanglingCont,
    destFp'           = DEST_STACK_TOP,
    srcIdx'           = srcIdx,
    restoredCount'    = restoredCount,
    shadedMask'       = shadedMask,
    satbActive'       = satbActive,
    linkValid'        = linkValid,
    markDepth'        = markDepth,
    topIsMarkPop'     = topIsMarkPop,
    topMarkVal'       = topMarkVal,
    tailUpdates'      = tailUpdates,
  }

  // Non-tail with-continuation-mark: pushes 1 mark frame, sets R0 = %mark-pop-ra
  action pushMarkNonTail(v: int): bool = all {
    not(topIsMarkPop),
    markDepth < 8,
    markDepth'        = markDepth + 1,
    topIsMarkPop'     = true,
    topMarkVal'       = v,
    tailUpdates'      = tailUpdates,
    srcIdx'           = srcIdx,
    restoredCount'    = restoredCount,
    destFp'           = destFp,
    shadedMask'       = shadedMask,
    satbActive'       = satbActive,
    satbDanglingCont' = satbDanglingCont,
    linkValid'        = linkValid,
  }

  // Tail with-continuation-mark (R0 == %mark-pop-ra): replaces top frame in O(1)!
  action replaceMarkTail(v: int): bool = all {
    topIsMarkPop,
    markDepth > 0,
    markDepth'        = markDepth,  // ZERO stack growth!
    topIsMarkPop'     = true,
    topMarkVal'       = v,
    tailUpdates'      = tailUpdates + 1,
    srcIdx'           = srcIdx,
    restoredCount'    = restoredCount,
    destFp'           = destFp,
    shadedMask'       = shadedMask,
    satbActive'       = satbActive,
    satbDanglingCont' = satbDanglingCont,
    linkValid'        = linkValid,
  }

  // Non-tail subcall inside marked body clears topIsMarkPop (R0 becomes body's RA)
  action enterNonTailSubcall: bool = all {
    topIsMarkPop,
    topIsMarkPop'     = false,
    markDepth'        = markDepth,
    topMarkVal'       = topMarkVal,
    tailUpdates'      = tailUpdates,
    srcIdx'           = srcIdx,
    restoredCount'    = restoredCount,
    destFp'           = destFp,
    shadedMask'       = shadedMask,
    satbActive'       = satbActive,
    satbDanglingCont' = satbDanglingCont,
    linkValid'        = linkValid,
  }

  // Return through %mark-pop-ra pops top mark frame
  action returnPopMark: bool = all {
    markDepth > 0,
    markDepth'        = markDepth - 1,
    topIsMarkPop'     = false,
    topMarkVal'       = topMarkVal,
    tailUpdates'      = tailUpdates,
    srcIdx'           = srcIdx,
    restoredCount'    = restoredCount,
    destFp'           = destFp,
    shadedMask'       = shadedMask,
    satbActive'       = satbActive,
    satbDanglingCont' = satbDanglingCont,
    linkValid'        = linkValid,
  }

  action step = any {
    toggleSatb(true),
    toggleSatb(false),
    nondet k = oneOf(Set(1, 2, 3, 4))
    chunkRestore(k),
    tryRewindInPlace,
    nondet v = oneOf(Set(1, 2, 3))
    pushMarkNonTail(v),
    nondet v = oneOf(Set(1, 2, 3))
    replaceMarkTail(v),
    enterNonTailSubcall,
    returnPopMark,
  }

  // --- SAFETY INVARIANTS ---

  // 1. Chunk restore conservation & stack hard-edge safety
  val invChunkConservation: bool =
    srcIdx >= 0 and srcIdx <= MAX_FRAMES and restoredCount == srcIdx and
    destFp >= DEST_LO and linkValid

  // 2. ZGC Watermark x SATB completeness: while satbActive, EVERY restored frame
  //    [0 .. srcIdx - 1] MUST be in shadedMask before mutator executes, and NO
  //    in-place rewind may expose a dangling stack continuation to SATB!
  val invSatbChunkShaded: bool =
    not(satbDanglingCont) and
    (satbActive implies 0.to(srcIdx - 1).forall(i => shadedMask.contains(i)))

  // 3. Racket CS Tail-Mark O(1) Stack Bound: markDepth never exceeds 8 even after
  //    unbounded tailUpdates, and topIsMarkPop implies markDepth >= 1.
  val invTailMarkBounded: bool =
    markDepth >= 0 and markDepth <= 8 and (topIsMarkPop implies markDepth >= 1)

  val allInvariants: bool =
    invChunkConservation and invSatbChunkShaded and invTailMarkBounded
}

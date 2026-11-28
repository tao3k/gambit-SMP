// Stage-2 Big Old-Gen Architecture Formal Model:
//   1. Chez-Style Creator-Owned Segment Routing & Remote Mark Queues
//   2. Zero-Contention Marking (anyMarked flag + Deferred Phase R-C liveWords)
//   3. Multi-Hole Immix Line Recycling (disjoint from all live objects)
//   4. Parallel Initial-Mark & Parallel Remark Quiescence
module big_oldgen_chez_immix {
  pure val WORKERS: Set[int] = Set(0, 1)
  pure val SECS: Set[int] = Set(0, 1, 2, 3)
  pure val LINES: Set[int] = Set(0, 1, 2, 3)
  pure val OBJS: Set[int] = Set(0, 1, 2, 3, 4, 5)

  // Static section ownership (Chez creator-owned partition: owner(s) = s % 2)
  pure def secOwner(s: int): int = s % 2

  // Static placement of objects into (section, line) pairs:
  //   sec 0 (w0): obj 0 @ line 0, obj 1 @ line 2  (lines 1, 3 are dead holes!)
  //   sec 1 (w1): obj 2 @ line 0, obj 3 @ line 1
  //   sec 2 (w0): obj 4 @ line 1                  (lines 0, 2, 3 are dead holes!)
  //   sec 3 (w1): obj 5 @ line 0                  (100% dead if obj 5 unreachable)
  pure def objSec(o: int): int =
    if (o == 0 or o == 1) 0
    else if (o == 2 or o == 3) 1
    else if (o == 4) 2
    else 3

  pure def objLine(o: int): int =
    if (o == 0) 0
    else if (o == 1) 2
    else if (o == 2) 0
    else if (o == 3) 1
    else if (o == 4) 1
    else 0

  // Cross-section cyclic object graph:
  //   0 (w0) -> 2 (w1) -> 4 (w0) -> 1 (w0) -> 0 (w0)  [cyclic across owners!]
  //   2 (w1) -> 3 (w1)
  //   5 (w1) is unreachable (section 3 becomes 100% dead!)
  pure def edges(o: int): Set[int] =
    if (o == 0) Set(2)
    else if (o == 1) Set(0)
    else if (o == 2) Set(3, 4)
    else if (o == 3) Set()
    else if (o == 4) Set(1)
    else Set()

  pure val ROOTS: Set[int] = Set(0)

  // Phase: "INIT_CLEAR" -> "MARKING" -> "SWEEP" -> "RECYCLE"
  var phase: str

  // Parallel init-mark cleared flags per section
  var secCleared: int -> bool

  // Mark bitmap (written ONLY by secOwner(objSec(o))!)
  var marked: int -> bool

  // Monotonic 0->1 flag per section (replaces per-object atomic FETCH_ADD live_words)
  var anyMarked: int -> bool

  // Per-worker local mark stack and per-target remote mark queue
  var localQ: int -> Set[int]
  var remoteQ: int -> Set[int]

  // Deferred Phase R-C exact live word count per section
  var liveWords: int -> int

  // Multi-hole Immix free-line bitmap per section (computed in Phase R-C)
  var freeLines: int -> Set[int]

  // Promoted objects placed into recycled Immix lines: sec -> set of recycled lines used
  var promotedLines: int -> Set[int]

  // Tracks whether a section was unlinked as 100%-dead in Phase R-D
  var unlinkedSec: int -> bool

  // Audit flag: did any worker ever violate owner-only mark writes?
  var ownerViolation: bool

  action init = all {
    phase' = "INIT_CLEAR",
    secCleared' = SECS.mapBy(_ => false),
    marked' = OBJS.mapBy(_ => false),
    anyMarked' = SECS.mapBy(_ => false),
    localQ' = WORKERS.mapBy(_ => Set()),
    remoteQ' = WORKERS.mapBy(_ => Set()),
    liveWords' = SECS.mapBy(_ => 0),
    freeLines' = SECS.mapBy(_ => Set()),
    promotedLines' = SECS.mapBy(_ => Set()),
    unlinkedSec' = SECS.mapBy(_ => false),
    ownerViolation' = false,
  }

  // Parallel Initial-Mark: worker w clears a section s it owns
  action parallelInitClear(w: int, s: int): bool = all {
    phase == "INIT_CLEAR",
    secOwner(s) == w,
    not(secCleared.get(s)),
    secCleared' = secCleared.set(s, true),
    phase' = phase,
    marked' = marked,
    anyMarked' = anyMarked,
    localQ' = localQ,
    remoteQ' = remoteQ,
    liveWords' = liveWords,
    freeLines' = freeLines,
    promotedLines' = promotedLines,
    unlinkedSec' = unlinkedSec,
    ownerViolation' = ownerViolation,
  }

  // Barrier after INIT_CLEAR: seed ROOTS into their owners' remoteQ and enter MARKING
  action beginMarking: bool = all {
    phase == "INIT_CLEAR",
    SECS.forall(s => secCleared.get(s)),
    phase' = "MARKING",
    remoteQ' = WORKERS.mapBy(w => ROOTS.filter(o => secOwner(objSec(o)) == w)),
    secCleared' = secCleared,
    marked' = marked,
    anyMarked' = anyMarked,
    localQ' = localQ,
    liveWords' = liveWords,
    freeLines' = freeLines,
    promotedLines' = promotedLines,
    unlinkedSec' = unlinkedSec,
    ownerViolation' = ownerViolation,
  }

  // Worker w drains one object o from its own remoteQ[w]:
  // Since o is owned by w, w marks o with ZERO cross-core contention and pushes to localQ[w].
  action drainRemote(w: int, o: int): bool = all {
    phase == "MARKING",
    remoteQ.get(w).contains(o),
    remoteQ' = remoteQ.set(w, remoteQ.get(w).exclude(Set(o))),
    ownerViolation' = (ownerViolation or (secOwner(objSec(o)) != w)),
    marked' = marked.set(o, true),
    anyMarked' = anyMarked.set(objSec(o), true),
    localQ' = if (not(marked.get(o))) localQ.set(w, localQ.get(w).union(Set(o))) else localQ,
    phase' = phase,
    secCleared' = secCleared,
    liveWords' = liveWords,
    freeLines' = freeLines,
    promotedLines' = promotedLines,
    unlinkedSec' = unlinkedSec,
  }

  // Worker w pops o from localQ[w] and scans its outgoing edges:
  //   - Same-owner targets are marked immediately and pushed to localQ[w]
  //   - Remote-owner targets are routed to remoteQ[owner] (Chez send_remote_sweep_stack)
  action scanLocal(w: int, o: int): bool =
    val outs = edges(o)
    val localUnmarked = outs.filter(t => secOwner(objSec(t)) == w and not(marked.get(t)))
    val remoteTargets = outs.filter(t => secOwner(objSec(t)) != w)
    val newLocalSecs = localUnmarked.map(t => objSec(t))
    all {
      phase == "MARKING",
      localQ.get(w).contains(o),
      localQ' = localQ.set(w, localQ.get(w).exclude(Set(o)).union(localUnmarked)),
      marked' = OBJS.mapBy(x => if (localUnmarked.contains(x)) true else marked.get(x)),
      anyMarked' = SECS.mapBy(s => if (newLocalSecs.contains(s)) true else anyMarked.get(s)),
      remoteQ' = WORKERS.mapBy(dst =>
        if (dst == w) remoteQ.get(dst)
        else remoteQ.get(dst).union(remoteTargets.filter(t => secOwner(objSec(t)) == dst))
      ),
      phase' = phase,
      secCleared' = secCleared,
      liveWords' = liveWords,
      freeLines' = freeLines,
      promotedLines' = promotedLines,
      unlinkedSec' = unlinkedSec,
      ownerViolation' = ownerViolation,
    }

  // Remark Quiescence Barrier: all localQ and remoteQ are empty -> enter SWEEP (Phase R-C)
  action finishMarkingToSweep: bool = all {
    phase == "MARKING",
    WORKERS.forall(w => localQ.get(w) == Set() and remoteQ.get(w) == Set()),
    phase' = "SWEEP",
    // Compute deferred liveWords, multi-hole freeLines, and O(1) 100%-dead unlink per section
    liveWords' = SECS.mapBy(s =>
      if (not(anyMarked.get(s))) 0
      else OBJS.filter(o => objSec(o) == s and marked.get(o)).size()
    ),
    unlinkedSec' = SECS.mapBy(s => not(anyMarked.get(s))),
    freeLines' = SECS.mapBy(s =>
      if (not(anyMarked.get(s))) Set()
      else LINES.filter(l =>
        OBJS.forall(o => (objSec(o) == s and objLine(o) == l) implies not(marked.get(o)))
      )
    ),
    secCleared' = secCleared,
    marked' = marked,
    anyMarked' = anyMarked,
    localQ' = localQ,
    remoteQ' = remoteQ,
    promotedLines' = promotedLines,
    ownerViolation' = ownerViolation,
  }

  // Multi-Hole Immix Recycling: claim ANY available free line l in section s for promotion
  action recycleImmixLine(s: int, l: int): bool = all {
    phase == "SWEEP",
    not(unlinkedSec.get(s)),
    freeLines.get(s).contains(l),
    freeLines' = freeLines.set(s, freeLines.get(s).exclude(Set(l))),
    promotedLines' = promotedLines.set(s, promotedLines.get(s).union(Set(l))),
    phase' = phase,
    secCleared' = secCleared,
    marked' = marked,
    anyMarked' = anyMarked,
    localQ' = localQ,
    remoteQ' = remoteQ,
    liveWords' = liveWords,
    unlinkedSec' = unlinkedSec,
    ownerViolation' = ownerViolation,
  }

  action step = any {
    beginMarking,
    finishMarkingToSweep,
    nondet w = WORKERS.oneOf()
    nondet s = SECS.oneOf()
    nondet o = OBJS.oneOf()
    nondet l = LINES.oneOf()
    any {
      parallelInitClear(w, s),
      drainRemote(w, o),
      scanLocal(w, o),
      recycleImmixLine(s, l),
    }
  }

  // Invariant 1: Zero cross-owner bitmap write violations
  val inv_owner_mark_disjoint: bool = not(ownerViolation)

  // Invariant 2: anyMarked[s] == false implies ZERO marked objects in s
  val inv_any_marked_sound: bool = SECS.forall(s =>
    not(anyMarked.get(s)) implies OBJS.forall(o => objSec(o) == s implies not(marked.get(o)))
  )

  // Invariant 3: At SWEEP (post-quiescence), every reachable object (0,1,2,3,4) is marked
  // and unreachable section 3 is cleanly unlinked with liveWords == 0
  val inv_quiescence_complete: bool =
    (phase == "SWEEP") implies all {
      Set(0, 1, 2, 3, 4).forall(o => marked.get(o)),
      not(marked.get(5)),
      unlinkedSec.get(3),
      liveWords.get(3) == 0,
      liveWords.get(0) == 2,
      liveWords.get(1) == 2,
      liveWords.get(2) == 1,
    }

  // Invariant 4: Multi-hole Immix freeLines and promotedLines NEVER overlap any marked object
  val inv_immix_multi_hole_disjoint: bool =
    (phase == "SWEEP") implies OBJS.forall(o =>
      marked.get(o) implies (
        not(freeLines.get(objSec(o)).contains(objLine(o))) and
        not(promotedLines.get(objSec(o)).contains(objLine(o)))
      )
    )

  val inv_all: bool = all {
    inv_owner_mark_disjoint,
    inv_any_marked_sound,
    inv_quiescence_complete,
    inv_immix_multi_hole_disjoint,
  }
}

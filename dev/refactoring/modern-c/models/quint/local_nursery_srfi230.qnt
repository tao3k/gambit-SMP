// Phase A: Processor-Local Independent Minor GC + SRFI-230 Promote-on-Share Protocol
// Models disjoint per-processor nurseries N_p, shared old generation S,
// transitive promote-on-share before SRFI-230 release publication,
// acquire loads by sibling processors, and independent local minor GC without global STW.
module local_nursery_srfi230 {
  pure val PROCS: Set[int] = Set(0, 1)
  pure val OBJS: Set[int] = Set(1, 2, 3, 4)

  // Object placement:
  //   0  -> unallocated / reclaimed
  //   1  -> in processor 0 local nursery N_0
  //   2  -> in processor 1 local nursery N_1
  //   3  -> in shared old generation S
  var loc: int -> int

  // Object reference edge (0 means immediate / null)
  var edge: int -> int

  // Per-processor root pointer (0 means null)
  var root: int -> int

  // SRFI-230 atomic box stored in shared old generation S (0 means null)
  var atomicBox: int

  // Last object observed by each processor via SRFI-230 acquire load (0 means none)
  var acquired: int -> int

  // Processor execution mode: "RUN" or "LOCAL_GC" (notice: no global STW barrier)
  var mode: int -> str

  pure def nurseryLoc(p: int): int = if (p == 0) 1 else 2

  action init = all {
    loc' = OBJS.mapBy(_ => 0),
    edge' = OBJS.mapBy(_ => 0),
    root' = PROCS.mapBy(_ => 0),
    atomicBox' = 0,
    acquired' = PROCS.mapBy(_ => 0),
    mode' = PROCS.mapBy(_ => "RUN"),
  }

  // Allocate a fresh object in processor p's private local nursery N_p
  action allocLocal(p: int, o: int): bool = all {
    mode.get(p) == "RUN",
    loc.get(o) == 0,
    loc' = loc.set(o, nurseryLoc(p)),
    // Optionally link to p's current root (either in N_p or S, never in sibling nursery)
    edge' = edge.set(o, root.get(p)),
    root' = root.set(p, o),
    atomicBox' = atomicBox,
    acquired' = acquired,
    mode' = mode,
  }

  // SRFI-230 atomic-box-set! / CAS release publication of p's root o.
  // Promote-on-share barrier: if o (or its child in N_p) is in N_p, promote its
  // transitive closure inside N_p to shared old gen S BEFORE publishing to atomicBox.
  action srfi230Publish(p: int): bool = {
    val o = root.get(p)
    val c1 = if (o != 0) edge.get(o) else 0
    val c2 = if (c1 != 0) edge.get(c1) else 0
    val c3 = if (c2 != 0) edge.get(c2) else 0
    val nloc = nurseryLoc(p)
    val promotedLoc = OBJS.mapBy(x =>
      if ((x == o or x == c1 or x == c2 or x == c3) and loc.get(x) == nloc) 3
      else loc.get(x)
    )
    all {
      mode.get(p) == "RUN",
      o != 0,
      loc.get(o) != 0,
      loc' = promotedLoc,
      edge' = edge,
      root' = root,
      atomicBox' = o,
      acquired' = acquired,
      mode' = mode,
    }
  }

  // SRFI-230 atomic-box-ref with memory_order_acquire on processor q
  action srfi230Acquire(q: int): bool = all {
    mode.get(q) == "RUN",
    atomicBox != 0,
    acquired' = acquired.set(q, atomicBox),
    root' = root.set(q, atomicBox),
    loc' = loc,
    edge' = edge,
    atomicBox' = atomicBox,
    mode' = mode,
  }

  // Processor p enters independent local minor GC (sibling q may remain in RUN)
  action startLocalGC(p: int): bool = all {
    mode.get(p) == "RUN",
    mode' = mode.set(p, "LOCAL_GC"),
    loc' = loc,
    edge' = edge,
    root' = root,
    atomicBox' = atomicBox,
    acquired' = acquired,
  }

  // Processor p completes independent local minor GC:
  // - promotes live objects reachable from root[p] in N_p to S
  // - reclaims all dead objects in N_p (sets loc to 0)
  // - never touches sibling nursery N_q or blocks sibling q
  action finishLocalGC(p: int): bool = {
    val nloc = nurseryLoc(p)
    val r = root.get(p)
    val c1 = if (r != 0) edge.get(r) else 0
    val c2 = if (c1 != 0) edge.get(c1) else 0
    val c3 = if (c2 != 0) edge.get(c2) else 0
    val liveInNp = Set(r, c1, c2, c3)
    val newLoc = OBJS.mapBy(x =>
      if (loc.get(x) == nloc) (
        if (liveInNp.contains(x)) 3 else 0
      ) else loc.get(x)
    )
    val newEdge = OBJS.mapBy(x =>
      if (loc.get(x) == nloc and not(liveInNp.contains(x))) 0 else edge.get(x)
    )
    all {
      mode.get(p) == "LOCAL_GC",
      loc' = newLoc,
      edge' = newEdge,
      root' = root,
      atomicBox' = atomicBox,
      acquired' = acquired,
      mode' = mode.set(p, "RUN"),
    }
  }

  // Drop processor p's local root (creates nursery garbage)
  action dropRoot(p: int): bool = all {
    mode.get(p) == "RUN",
    root' = root.set(p, 0),
    loc' = loc,
    edge' = edge,
    atomicBox' = atomicBox,
    acquired' = acquired,
    mode' = mode,
  }

  action step = any {
    nondet p = PROCS.oneOf()
    nondet o = OBJS.oneOf()
    any {
      allocLocal(p, o),
      srfi230Publish(p),
      srfi230Acquire(p),
      startLocalGC(p),
      finishLocalGC(p),
      dropRoot(p),
    }
  }

  // Invariant 1: No processor root or nursery object ever points into a sibling's nursery
  val inv_no_cross_nursery: bool = PROCS.forall(p => {
    val otherN = if (p == 0) 2 else 1
    val r = root.get(p)
    val rootOk = r == 0 or loc.get(r) != otherN
    val edgesOk = OBJS.forall(o =>
      (loc.get(o) == nurseryLoc(p) and edge.get(o) != 0) implies loc.get(edge.get(o)) != otherN
    )
    rootOk and edgesOk
  })

  // Invariant 2: Shared old generation S and atomicBox are closed (never point into any nursery)
  val inv_shared_closed: bool = all {
    atomicBox == 0 or loc.get(atomicBox) == 3,
    OBJS.forall(o =>
      (loc.get(o) == 3 and edge.get(o) != 0) implies loc.get(edge.get(o)) == 3
    ),
  }

  // Invariant 3: Any SRFI-230 acquire load observes a live object in S (never dangling or in nursery)
  val inv_srfi230_acquire_valid: bool = PROCS.forall(q => {
    val a = acquired.get(q)
    a == 0 or loc.get(a) == 3
  })

  // Invariant 4: No dangling roots on any processor (even during/after sibling local GC)
  val inv_no_dangling_roots: bool = PROCS.forall(p => {
    val r = root.get(p)
    r == 0 or loc.get(r) != 0
  })

  val inv_all: bool = all {
    inv_no_cross_nursery,
    inv_shared_closed,
    inv_srfi230_acquire_valid,
    inv_no_dangling_roots,
  }
}

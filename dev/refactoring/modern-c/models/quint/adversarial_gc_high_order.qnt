// High-Order Adversarial Model (Aligned with vendor/chez & vendor/ocaml):
// - 3 processors (P0, P1, P2) x 6 objects (1..6) with ARBITRARY CYCLIC GRAPHS
// - Shared Weak/Will Box registration (must promote-on-share like SRFI-230 atomicBox)
// - OCaml 5 3-state CAS forwarding protocol: ORIG -> IN_PROGRESS -> FORWARDED + field0 payload
// - Chez Scheme creator-owned remote-sweep queue conservation
module adversarial_gc_high_order {
  pure val PROCS: Set[int] = Set(0, 1, 2)
  pure val OBJS: Set[int] = Set(1, 2, 3, 4, 5, 6)

  // Placement: 0 = unalloc, 1 = N_0, 2 = N_1, 3 = N_2, 4 = SHARED
  var loc: int -> int

  // Arbitrary directed graph edges (cycles allowed! 0 = null)
  var edge: int -> int

  // Per-processor root
  var root: int -> int

  // SRFI-230 atomic box and shared weak/will box in SHARED
  var atomicBox: int
  var weakBox: int

  // OCaml 5 3-state forwarding header for objects in SHARED:
  //   0 = ORIG (normal header)
  //   1 = IN_PROGRESS (winner claimed header via CAS, writing fwdAddr)
  //   2 = FORWARDED (winner published header=0/FWD with release; fwdAddr valid)
  var fwdState: int -> int
  var fwdAddr: int -> int
  var fwdOwner: int -> int

  // Chez-style creator-owned remote sweep pending count (must remain >= 0 and conserved)
  var remoteSweepQueued: int -> int

  pure def nloc(p: int): int = p + 1

  // Compute full transitive closure inside processor p's nursery (handles cycles up to length 6!)
  pure def closure6(start: int, p: int, curLoc: int -> int, curEdge: int -> int): Set[int] = {
    val nl = nloc(p)
    val s0 = if (start != 0 and curLoc.get(start) == nl) Set(start) else Set()
    val s1 = s0.union(OBJS.filter(x => s0.exists(u => curEdge.get(u) == x) and curLoc.get(x) == nl))
    val s2 = s1.union(OBJS.filter(x => s1.exists(u => curEdge.get(u) == x) and curLoc.get(x) == nl))
    val s3 = s2.union(OBJS.filter(x => s2.exists(u => curEdge.get(u) == x) and curLoc.get(x) == nl))
    val s4 = s3.union(OBJS.filter(x => s3.exists(u => curEdge.get(u) == x) and curLoc.get(x) == nl))
    val s5 = s4.union(OBJS.filter(x => s4.exists(u => curEdge.get(u) == x) and curLoc.get(x) == nl))
    s5
  }

  action init = all {
    loc' = OBJS.mapBy(_ => 0),
    edge' = OBJS.mapBy(_ => 0),
    root' = PROCS.mapBy(_ => 0),
    atomicBox' = 0,
    weakBox' = 0,
    fwdState' = OBJS.mapBy(_ => 0),
    fwdAddr' = OBJS.mapBy(_ => 0),
    fwdOwner' = OBJS.mapBy(_ => -1),
    remoteSweepQueued' = PROCS.mapBy(_ => 0),
  }

  // Allocate fresh object in N_p
  action allocLocal(p: int, o: int): bool = all {
    loc.get(o) == 0,
    loc' = loc.set(o, nloc(p)),
    edge' = edge.set(o, root.get(p)),
    root' = root.set(p, o),
    atomicBox' = atomicBox,
    weakBox' = weakBox,
    fwdState' = fwdState,
    fwdAddr' = fwdAddr,
    fwdOwner' = fwdOwner,
    remoteSweepQueued' = remoteSweepQueued,
  }

  // Adversarial cyclic mutation inside N_p: create an arbitrary edge u -> v (including cycles u -> ... -> u!)
  action mutateLocalCycle(p: int, u: int, v: int): bool = all {
    loc.get(u) == nloc(p),
    loc.get(v) == nloc(p) or loc.get(v) == 4,
    edge' = edge.set(u, v),
    loc' = loc,
    root' = root,
    atomicBox' = atomicBox,
    weakBox' = weakBox,
    fwdState' = fwdState,
    fwdAddr' = fwdAddr,
    fwdOwner' = fwdOwner,
    remoteSweepQueued' = remoteSweepQueued,
  }

  // SRFI-230 atomic-box-set! release publication with full cyclic promote-on-share
  action srfi230Publish(p: int): bool = {
    val o = root.get(p)
    val cl = closure6(o, p, loc, edge)
    all {
      o != 0,
      loc.get(o) != 0,
      loc' = OBJS.mapBy(x => if (cl.contains(x)) 4 else loc.get(x)),
      atomicBox' = o,
      edge' = edge,
      root' = root,
      weakBox' = weakBox,
      fwdState' = fwdState,
      fwdAddr' = fwdAddr,
      fwdOwner' = fwdOwner,
      remoteSweepQueued' = remoteSweepQueued,
    }
  }

  // Shared weak/will box registration: MUST promote cyclic closure to SHARED
  action registerWeakBox(p: int): bool = {
    val o = root.get(p)
    val cl = closure6(o, p, loc, edge)
    all {
      o != 0,
      loc.get(o) != 0,
      loc' = OBJS.mapBy(x => if (cl.contains(x)) 4 else loc.get(x)),
      weakBox' = o,
      edge' = edge,
      root' = root,
      atomicBox' = atomicBox,
      fwdState' = fwdState,
      fwdAddr' = fwdAddr,
      fwdOwner' = fwdOwner,
      remoteSweepQueued' = remoteSweepQueued,
    }
  }

  // SRFI-230 acquire load by any sibling processor q
  action srfi230Acquire(q: int): bool = all {
    atomicBox != 0,
    root' = root.set(q, atomicBox),
    loc' = loc,
    edge' = edge,
    atomicBox' = atomicBox,
    weakBox' = weakBox,
    fwdState' = fwdState,
    fwdAddr' = fwdAddr,
    fwdOwner' = fwdOwner,
    remoteSweepQueued' = remoteSweepQueued,
  }

  // Independent local minor GC on processor p (reclaims dead cycles in N_p, never touches q != p)
  action localMinorGC(p: int): bool = {
    val nl = nloc(p)
    val liveCl = closure6(root.get(p), p, loc, edge)
    all {
      loc' = OBJS.mapBy(x =>
        if (loc.get(x) == nl) (if (liveCl.contains(x)) 4 else 0) else loc.get(x)
      ),
      edge' = OBJS.mapBy(x =>
        if (loc.get(x) == nl and not(liveCl.contains(x))) 0 else edge.get(x)
      ),
      root' = root,
      atomicBox' = atomicBox,
      weakBox' = weakBox,
      fwdState' = fwdState,
      fwdAddr' = fwdAddr,
      fwdOwner' = fwdOwner,
      remoteSweepQueued' = remoteSweepQueued,
    }
  }

  // Drop local root
  action dropRoot(p: int): bool = all {
    root' = root.set(p, 0),
    loc' = loc,
    edge' = edge,
    atomicBox' = atomicBox,
    weakBox' = weakBox,
    fwdState' = fwdState,
    fwdAddr' = fwdAddr,
    fwdOwner' = fwdOwner,
    remoteSweepQueued' = remoteSweepQueued,
  }

  // OCaml 5 3-state CAS forwarding Step 1: winner CAS ORIG(0) -> IN_PROGRESS(1)
  action ocamlFwdClaim(p: int, o: int): bool = all {
    loc.get(o) == 4,
    fwdState.get(o) == 0,
    fwdState' = fwdState.set(o, 1),
    fwdOwner' = fwdOwner.set(o, p),
    fwdAddr' = fwdAddr,
    loc' = loc,
    edge' = edge,
    root' = root,
    atomicBox' = atomicBox,
    weakBox' = weakBox,
    remoteSweepQueued' = remoteSweepQueued,
  }

  // OCaml 5 3-state CAS forwarding Step 2+3: owner writes fwdAddr and release-publishes FORWARDED(2)
  action ocamlFwdPublish(p: int, o: int): bool = all {
    loc.get(o) == 4,
    fwdState.get(o) == 1,
    fwdOwner.get(o) == p,
    fwdAddr' = fwdAddr.set(o, 100 + p * 10 + o),
    fwdState' = fwdState.set(o, 2),
    fwdOwner' = fwdOwner,
    loc' = loc,
    edge' = edge,
    root' = root,
    atomicBox' = atomicBox,
    weakBox' = weakBox,
    remoteSweepQueued' = remoteSweepQueued,
  }

  // Chez creator-owned remote sweep push & drain
  action chezPushRemote(target: int): bool = all {
    remoteSweepQueued.get(target) < 8,
    remoteSweepQueued' = remoteSweepQueued.set(target, remoteSweepQueued.get(target) + 1),
    loc' = loc,
    edge' = edge,
    root' = root,
    atomicBox' = atomicBox,
    weakBox' = weakBox,
    fwdState' = fwdState,
    fwdAddr' = fwdAddr,
    fwdOwner' = fwdOwner,
  }

  action chezDrainRemote(owner: int): bool = all {
    remoteSweepQueued.get(owner) > 0,
    remoteSweepQueued' = remoteSweepQueued.set(owner, remoteSweepQueued.get(owner) - 1),
    loc' = loc,
    edge' = edge,
    root' = root,
    atomicBox' = atomicBox,
    weakBox' = weakBox,
    fwdState' = fwdState,
    fwdAddr' = fwdAddr,
    fwdOwner' = fwdOwner,
  }

  action step = {
    nondet p = PROCS.oneOf()
    nondet o = OBJS.oneOf()
    nondet v = OBJS.oneOf()
    any {
      allocLocal(p, o),
      mutateLocalCycle(p, o, v),
      srfi230Publish(p),
      registerWeakBox(p),
      srfi230Acquire(p),
      localMinorGC(p),
      dropRoot(p),
      ocamlFwdClaim(p, o),
      ocamlFwdPublish(p, o),
      chezPushRemote(p),
      chezDrainRemote(p),
    }
  }

  // High-order Invariant 1: Strict 3-proc nursery disjointness (even with cyclic graphs)
  val inv_no_cross_nursery: bool = PROCS.forall(p => {
    val nl = nloc(p)
    val r = root.get(p)
    val rootOk = r == 0 or loc.get(r) == nl or loc.get(r) == 4
    val edgesOk = OBJS.forall(o =>
      (loc.get(o) == nl and edge.get(o) != 0) implies (loc.get(edge.get(o)) == nl or loc.get(edge.get(o)) == 4)
    )
    rootOk and edgesOk
  })

  // High-order Invariant 2: Shared old gen, atomicBox, and weakBox are completely closed (no dangling/nursery pointers)
  val inv_shared_and_weak_closed: bool = all {
    atomicBox == 0 or loc.get(atomicBox) == 4,
    weakBox == 0 or loc.get(weakBox) == 4,
    OBJS.forall(o =>
      (loc.get(o) == 4 and edge.get(o) != 0) implies loc.get(edge.get(o)) == 4
    ),
  }

  // High-order Invariant 3: OCaml 5 3-state CAS forwarding visibility
  // A FORWARDED(2) object ALWAYS has a valid non-zero fwdAddr and valid owner;
  // an ORIG(0) object NEVER has a stale fwdAddr.
  val inv_ocaml_3state_fwd: bool = OBJS.forall(o => all {
    fwdState.get(o) == 0 implies fwdAddr.get(o) == 0,
    fwdState.get(o) == 1 implies fwdOwner.get(o) != -1,
    fwdState.get(o) == 2 implies (fwdAddr.get(o) >= 100 and fwdOwner.get(o) != -1),
  })

  // High-order Invariant 4: Chez remote-sweep queue non-negative
  val inv_chez_remote_nonneg: bool = PROCS.forall(p => remoteSweepQueued.get(p) >= 0)

  val inv_all: bool = all {
    inv_no_cross_nursery,
    inv_shared_and_weak_closed,
    inv_ocaml_3state_fwd,
    inv_chez_remote_nonneg,
  }
}

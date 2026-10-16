module btq_copy_epochs {
  import btq_operations as B from "./btq_operations"

  // Field projection, not a full thread layout or C weak-memory proof.
  // Permanent queue/type references are 9/17; false/true are -4/-12.
  pure val nodes = Set(1, 2)
  pure val actors = Set(0, 1)
  pure val payloadFields = Set(0, 4, 5, 6, 7, 17)
  pure val copyOrder = List(0, 4, 5, 6, 7, 17)
  // Offsets are below 32, so this injectively encodes (address, offset).
  pure def at(address: int, offset: int): int = address * 32 + offset
  pure val roots = Set(0, 1)
  pure val addresses = Set(0, 32768).fold(Set(), (out, base) =>
    out.union(actors.fold(Set(), (found, actor) =>
      found.union(nodes.map(slot => base + actor * 1024 + slot * 256 + 1)))))
  pure val cells = addresses.fold(roots, (out, address) =>
    out.union(payloadFields.map(offset => at(address, offset))))
  pure val permanent = Set(9, 17, -4, -12)
  pure val tree = B::insertBelow(B::color(B::insertBelow(B::initial(0).t, 1, false), 1, false), 2, false)

  type State = { fault: int, phase: str, epoch: int, fromBase: int, toBase: int,
    heap: int -> int, heads: int -> int, identity: int -> int,
    locations: int -> int, known: Set[int], ready: Set[int],
    pending: Set[int], completed: Set[int],
    worker: int -> str, job: int -> int, origin: int -> int,
    destination: int -> int, cursor: int -> int, copied: int -> int,
    duplicateUsed: bool, badInput: bool, badAlias: bool }
  var g: State

  pure def refOf(node: int, locations: int -> int): int =
    if (node == -1) -4 else if (node == 0) 9 else locations.get(node)
  pure def word(t: B::Tree, node: int, offset: int, locations: int -> int): int =
    if (offset == 0) 17 else if (offset == 4) (if (t.red.get(node)) -12 else -4)
    else refOf(if (offset == 5) t.p.get(node) else if (offset == 6) t.l.get(node)
      else if (offset == 7) t.r.get(node) else t.container.get(node), locations)
  pure def withTree(st: State, t: B::Tree): State = {
    val payload = st.known.union(t.members).fold(st.heap, (heap, node) =>
      payloadFields.fold(heap, (data, offset) =>
        data.set(at(st.locations.get(node), offset), word(t, node, offset, st.locations))))
    { ...st, heap: payload.set(0, refOf(t.l.get(0), st.locations))
      .set(1, refOf(t.r.get(0), st.locations)), known: t.members }
  }
  pure def initial(fault: int): State = withTree({
    fault: fault, phase: "collect", epoch: 1, fromBase: 0, toBase: 32768,
    heap: cells.mapBy(_ => -44),
    heads: addresses.mapBy(a => if (Set(257, 513).contains(a)) 0 else -1),
    identity: addresses.mapBy(a => if (a == 257) 1 else if (a == 513) 2 else -1),
    locations: Map(1 -> 257, 2 -> 513), known: nodes, ready: Set(257, 513),
    pending: roots, completed: Set(), worker: actors.mapBy(_ => "idle"),
    job: actors.mapBy(_ => -1), origin: actors.mapBy(_ => -1),
    destination: actors.mapBy(_ => -1), cursor: actors.mapBy(_ => 0),
    copied: actors.mapBy(_ => 0), duplicateUsed: false, badInput: false, badAlias: false,
  }, tree)
  action init = all {
    B::s' = { ...B::initial(0), t: tree, remaining: Set(), draining: true },
    g' = initial(0),
  }
  action initDuplicate = all {
    B::s' = { ...B::initial(0), t: tree, remaining: Set(), draining: true },
    g' = initial(1),
  }
  action initEarlyPublish = all {
    B::s' = { ...B::initial(0), t: tree, remaining: Set(), draining: true },
    g' = initial(2),
  }
  action initMissingRight = all {
    B::s' = { ...B::initial(0), t: tree, remaining: Set(), draining: true },
    g' = initial(3),
  }
  action initEarlyResume = all {
    B::s' = { ...B::initial(0), t: tree, remaining: Set(), draining: true },
    g' = initial(4),
  }
  action initAliasedArena = all {
    B::s' = { ...B::initial(0), t: tree, remaining: Set(), draining: true },
    g' = initial(5),
  }

  pure def scanCells(address: int, fault: int): Set[int] =
    payloadFields.exclude(if (fault == 3) Set(0, 7) else Set(0)).map(offset => at(address, offset))
  action mark = {
    nondet actor = actors.oneOf()
    nondet cell = g.pending.oneOf()
    val value = g.heap.get(cell)
    val base = { ...g, pending: g.pending.exclude(Set(cell)) }
    all { g.phase == "collect", g.worker.get(actor) == "idle", B::s' = B::s,
      if (permanent.contains(value))
        g' = { ...base, completed: g.completed.union(Set(cell)) }
      else if (not(addresses.contains(value)))
        g' = { ...base, badInput: true }
      else if (value < g.fromBase or value >= g.fromBase + 32768 or g.heads.get(value) < 0)
        // Record the old-space input-contract violation; do not silently skip
        // a duplicate to-space input and claim that the source was repaired.
        g' = { ...base, badInput: true }
      else if (g.heads.get(value) > 0)
        g' = { ...base, heap: g.heap.set(cell, g.heads.get(value)),
          completed: g.completed.union(Set(cell)) }
      else {
        val nextSlot = g.cursor.get(actor) + 1
        val destination = g.toBase + (if (g.fault == 5) 0 else actor * 1024) + nextSlot * 256 + 1
        all { nextSlot <= 2,
          g' = { ...base, worker: g.worker.set(actor, "reserved"),
            job: g.job.set(actor, cell), origin: g.origin.set(actor, value),
            destination: g.destination.set(actor, destination), cursor: g.cursor.set(actor, nextSlot),
            heads: g.heads.set(destination, 0), identity: g.identity.set(destination, g.identity.get(value)),
            copied: g.copied.set(actor, 0), badAlias: g.badAlias or g.heads.get(destination) != -1 }
        }
      }
    }
  }
  action forwardCAS = {
    nondet actor = actors.oneOf()
    val old = g.origin.get(actor)
    val destination = g.destination.get(actor)
    val cell = g.job.get(actor)
    all { g.phase == "collect", g.worker.get(actor) == "reserved", B::s' = B::s,
      if (g.heads.get(old) == 0)
        g' = { ...g, heads: g.heads.set(old, destination), heap: g.heap.set(cell, destination),
          completed: g.completed.union(Set(cell)), worker: g.worker.set(actor, "copying"),
          pending: if (g.fault == 2) g.pending.union(scanCells(destination, g.fault)) else g.pending }
      else
        // The losing reservation is private and is rolled back, not queued.
        g' = { ...g, heap: g.heap.set(cell, g.heads.get(old)),
          completed: g.completed.union(Set(cell)), worker: g.worker.set(actor, "idle"),
          cursor: g.cursor.set(actor, g.cursor.get(actor) - 1),
          heads: g.heads.set(destination, -1), identity: g.identity.set(destination, -1) }
    }
  }
  action copyWord = {
    nondet actor = actors.oneOf()
    val index = g.copied.get(actor)
    all { g.phase == "collect", g.worker.get(actor) == "copying", index < 6,
      g' = { ...g, heap: g.heap.set(at(g.destination.get(actor), copyOrder[index]),
        g.heap.get(at(g.origin.get(actor), copyOrder[index]))), copied: g.copied.set(actor, index + 1) },
      B::s' = B::s }
  }
  action publish = {
    nondet actor = actors.oneOf()
    val destination = g.destination.get(actor)
    all { g.phase == "collect", g.worker.get(actor) == "copying", g.copied.get(actor) == 6,
      g' = { ...g, ready: g.ready.union(Set(destination)), worker: g.worker.set(actor, "idle"),
        pending: if (g.fault == 2) g.pending else g.pending.union(scanCells(destination, g.fault)) },
      B::s' = B::s }
  }
  action duplicateScan = {
    nondet cell = g.completed.oneOf()
    all { g.phase == "collect", g.fault == 1, not(g.duplicateUsed),
      g' = { ...g, pending: g.pending.union(Set(cell)), duplicateUsed: true }, B::s' = B::s }
  }
  action finishCollection = all {
    g.phase == "collect",
    (g.pending == Set() and actors.forall(actor => g.worker.get(actor) == "idle")) or
      (g.fault == 4 and roots.subseteq(g.completed)),
    g' = { ...g, phase: "mutate", locations: nodes.mapBy(node =>
      if (B::s.t.members.contains(node)) {
        val forwarded = g.heads.get(g.locations.get(node))
        if (forwarded > 0) forwarded else -44
      } else g.locations.get(node)) }, B::s' = B::s,
  }
  pure def nextCollection(st: State): State = {
    val destinationBase = if (st.toBase == 32768) 0 else 32768
    val cleared = addresses.filter(address => address >= destinationBase and address < destinationBase + 32768)
    { ...st, phase: "collect", epoch: 2, fromBase: st.toBase, toBase: destinationBase,
      heap: cleared.fold(st.heap, (heap, address) => payloadFields.fold(heap, (data, offset) => data.set(at(address, offset), -44))),
      heads: cleared.fold(st.heads, (heads, address) => heads.set(address, -1)),
      identity: cleared.fold(st.identity, (ids, address) => ids.set(address, -1)),
      ready: st.ready.exclude(cleared), pending: roots, completed: Set(),
      worker: actors.mapBy(_ => "idle"), cursor: actors.mapBy(_ => 0) }
  }
  action remove = all {
    g.phase == "mutate", B::beginRemove, g' = { ...g, phase: "mirror" },
  }
  action fix = all {
    g.phase == "mutate", B::removeFix, g' = { ...g, phase: "mirror" },
  }
  action removeDone = all {
    g.phase == "mutate", B::removeDone, g' = { ...g, phase: "mirror" },
  }
  action release = all {
    g.phase == "mutate", B::release, g' = { ...g, phase: "mirror-release" },
  }
  // Projection bookkeeping is unobservable: no collection or tree action may
  // run until the imported transition's physical field mirror is complete.
  action mirror = all {
    g.phase == "mirror", B::s' = B::s,
    g' = { ...withTree(g, B::s.t), phase: "mutate" },
  }
  action mirrorRelease = all {
    g.phase == "mirror-release", B::s' = B::s,
    {
      val updated = { ...withTree(g, B::s.t), phase: "mutate" }
      g' = if (g.epoch == 1) nextCollection(updated)
        else if (B::s.t.members == Set()) { ...updated, phase: "done" } else updated
    },
  }
  action advance = any { mark, forwardCAS, copyWord, publish, duplicateScan,
    finishCollection, remove, fix, removeDone, release, mirror, mirrorRelease }
  action step = any { advance, all { g.phase == "done", g' = g, B::s' = B::s } }

  pure def copiedNodeSafe(st: State, t: B::Tree, node: int): bool = {
    val address = st.locations.get(node)
    if (not(addresses.contains(address))) false
    else st.ready.contains(address) and st.identity.get(address) == node
      and address >= st.toBase and address < st.toBase + 32768
      and payloadFields.forall(offset => st.heap.get(at(address, offset)) == word(t, node, offset, st.locations))
  }
  val stableCopy = g.phase != "mutate" and g.phase != "done" or
    (B::s.t.members.forall(node => copiedNodeSafe(g, B::s.t, node))
      and g.heap.get(0) == refOf(B::s.t.l.get(0), g.locations)
      and g.heap.get(1) == refOf(B::s.t.r.get(0), g.locations))
  val safe = B::safe and not(g.badInput) and not(g.badAlias) and stableCopy
  temporal completion = weakFair(advance, (B::s, g)).implies(eventually(g.phase == "done"))
}

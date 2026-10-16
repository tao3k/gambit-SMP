module btq_operations {
  // Bounded operational translation of define-rbtree, not a collector model.
  // 0 is the sentinel; its left is the root and its right is the minimum.
  // -1 represents the #f links cleared on removal, never a valid tree node.
  pure val nodes = Set(1, 2, 3, 4)
  pure val slots = Set(-1, 0, 1, 2, 3, 4)
  type Tree = { l: int -> int, r: int -> int, p: int -> int,
    red: int -> bool, members: Set[int], container: int -> int }
  type State = { t: Tree, phase: str, x: int, parent: int, owner: int,
    remaining: Set[int], draining: bool, fault: int, badRead: bool,
    otherQueueWrites: int, round: int, tied: bool }
  var s: State
  pure def initial(fault: int): State = {
    t: { l: slots.mapBy(n => if (n == 0) 0 else -1),
      r: slots.mapBy(n => if (n == 0) 0 else -1),
      p: slots.mapBy(n => if (n == 0) 0 else -1),
      red: slots.mapBy(_ => false), members: Set(),
      container: slots.mapBy(_ => -1) },
    phase: "idle", x: 0, parent: 0, owner: 0, remaining: nodes,
    draining: false, fault: fault, badRead: false, otherQueueWrites: 0, round: 0, tied: false,
  }
  action init = {
    nondet tied = Set(false, true).oneOf()
    s' = { ...initial(0), tied: tied }
  }
  action initMissingRotationParent = s' = initial(1)
  action initMissingTransplant = s' = initial(2)

  pure def child(t: Tree, n: int, left: bool): int =
    if (left) t.l.get(n) else t.r.get(n)
  pure def writeChild(t: Tree, n: int, left: bool, v: int): Tree =
    if (left) { ...t, l: t.l.set(n, v) } else { ...t, r: t.r.set(n, v) }
  pure def replace(t: Tree, p: int, old: int, v: int): Tree =
    writeChild(t, p, t.l.get(p) == old, v)
  pure def color(t: Tree, n: int, red: bool): Tree =
    { ...t, red: t.red.set(n, red) }
  pure def minimum(t: Tree, n: int): int =
    1.to(4).fold(n, (x, _) => if (t.l.get(x) == 0) x else t.l.get(x))
  pure def finish(t: Tree): Tree = { ...t, p: t.p.set(0, 0) }
  // rotate! writes the nil child's parent too, matching the source exactly.
  pure def rotate(t: Tree, n: int, left: bool, fault: int): Tree = {
    val y = child(t, n, not(left))
    val beta = child(t, y, left)
    val p = t.p.get(n)
    val a = writeChild(t, n, not(left), beta)
    val b = { ...a, p: a.p.set(beta, n) }
    val c = writeChild(b, y, left, n)
    val d = { ...c, p: c.p.set(n, y).set(y, p) }
    if (fault == 1) d else replace(d, p, n, y)
  }
  pure def insertBelow(t: Tree, n: int, tied: bool): Tree = {
    val p = 1.to(4).fold(0, (p, _) => {
      val nextNode = if (p == 0) t.l.get(0) else child(t, p, not(tied) and n < p)
      if (nextNode == 0) p else nextNode
    })
    val a = { ...t, l: t.l.set(n, 0), r: t.r.set(n, 0),
      p: t.p.set(n, p), red: t.red.set(n, true),
      container: t.container.set(n, 0), members: t.members.union(Set(n)) }
    val goesLeft = p == 0 or (not(tied) and n < p)
    val b = writeChild(a, p, goesLeft, n)
    // insert-left! updates the alias only when inserting below the minimum.
    if (goesLeft and p == t.r.get(0))
      { ...b, r: b.r.set(0, n) } else b
  }
  action beginInsert = {
    nondet n = s.remaining.oneOf()
    nondet actor = Set(1, 2).oneOf()
    all { s.phase == "idle", not(s.draining), s.remaining != Set(),
      s' = { ...s, t: insertBelow(s.t, n, s.tied), phase: "insert-fix", x: n,
        owner: actor, remaining: s.remaining.exclude(Set(n)) } }
  }
  action insertFix = all {
    s.phase == "insert-fix",
    {
      val p = s.t.p.get(s.x)
      val g = s.t.p.get(p)
      val left = s.t.l.get(g) == p
      val uncle = child(s.t, g, not(left))
      if (not(s.t.red.get(p)))
        s' = { ...s, t: finish(color(s.t, s.t.l.get(0), false)), phase: "release" }
      else if (s.t.red.get(uncle))
        s' = { ...s, t: color(color(color(s.t, p, false), uncle, false), g, true), x: g }
      else {
        val inner = s.x == child(s.t, p, not(left))
        val a = if (inner) rotate(s.t, p, left, s.fault) else s.t
        val y = if (inner) a.p.get(p) else a.p.get(s.x)
        val b = color(a, y, false)
        val gy = b.p.get(y)
        val c = rotate(color(b, gy, true), gy, not(left), s.fault)
        s' = { ...s, t: finish(color(c, c.l.get(0), false)), phase: "release" }
      }
    },
  }
  action startDrain = all { s.phase == "idle", s.remaining == Set(), not(s.draining),
    s' = { ...s, draining: true } }
  // Includes successor search, exchange-color and both successor placements.
  action beginRemove = {
    nondet n = s.t.members.oneOf()
    nondet actor = Set(1, 2).oneOf()
    all { s.phase == "idle", s.draining,
      {
        val p = s.t.p.get(n)
        val l = s.t.l.get(n)
        val r = s.t.r.get(n)
        val a = { ...s.t, p: s.t.p.set(n, -1), l: s.t.l.set(n, -1),
          r: s.t.r.set(n, -1).set(0,
            if (l == 0 and n == s.t.r.get(0)) (if (r == 0) p else r)
            else s.t.r.get(0)), container: s.t.container.set(n, -1),
          members: s.t.members.exclude(Set(n)) }
        val y = if (l == 0 or r == 0) n else minimum(s.t, r)
        val py = s.t.p.get(y)
        val x = if (y == n) (if (l == 0) r else l) else s.t.r.get(y)
        val fixParent = if (y == n) p else if (py == n) y else py
        val b = if (y == n) {
          val b0 = { ...a, p: a.p.set(x, p) }
          if (s.fault == 2) b0 else replace(b0, p, n, x)
        } else {
          val b0 = { ...a, red: a.red.set(y, s.t.red.get(n)),
            p: a.p.set(l, y).set(y, p), l: a.l.set(y, l) }
          val b1 = replace(b0, p, n, y)
          if (py == n) b1 else {
            val b2 = { ...b1, p: b1.p.set(x, py).set(r, y),
              l: b1.l.set(py, x), r: b1.r.set(y, r) }
            b2
          }
        }
        s' = { ...s, t: color(b, n, true), x: x, parent: fixParent,
          phase: if (s.t.red.get(y)) "remove-done" else "remove-fix", owner: actor }
      } }
  }
  action removeFix = all {
    s.phase == "remove-fix",
    if (s.parent == 0 or s.t.red.get(s.x))
      s' = { ...s, t: color(s.t, s.x, false), phase: "remove-done" }
    else {
      val left = s.x == s.t.l.get(s.parent)
      val sibling = child(s.t, s.parent, not(left))
      val a = if (s.t.red.get(sibling))
        rotate(color(color(s.t, sibling, false), s.parent, true), s.parent, left, s.fault)
        else s.t
      val w = child(a, s.parent, not(left))
      val far = child(a, w, not(left))
      val near = child(a, w, left)
      val invalid = w == 0 or not(a.members.contains(w))
        or not(a.members.union(Set(0)).contains(far))
        or not(a.members.union(Set(0)).contains(near))
      if (not(a.red.get(far)) and not(a.red.get(near)))
        s' = { ...s, t: color(a, w, true), x: s.parent,
          parent: a.p.get(s.parent), badRead: s.badRead or invalid }
      else {
        val b = if (a.red.get(far)) a else
          rotate(color(color(a, near, false), w, true), w, not(left), s.fault)
        val y = child(b, s.parent, not(left))
        val c = color(color(color(b, y, b.red.get(s.parent)), s.parent, false),
          child(b, y, not(left)), false)
        val d = rotate(c, s.parent, left, s.fault)
        s' = { ...s, t: color(d, d.l.get(0), false), phase: "remove-done",
          badRead: s.badRead or invalid }
      }
    },
  }
  action removeDone = all { s.phase == "remove-done",
    s' = { ...s, t: finish(s.t), phase: "release" } }
  action release = all { s.phase == "release", s' = { ...s, owner: 0, phase: "idle" } }
  action otherQueueWrite = all { s.otherQueueWrites == 0,
    s' = { ...s, otherQueueWrites: 1 } }
  // Reuse cleared nodes without resetting their fields or rebuilding the tree.
  action reuseNodes = all { s.phase == "idle", s.draining,
    s.t.members == Set(), s.round == 0,
    s' = { ...s, round: 1, remaining: nodes, draining: false } }
  action advance = any { beginInsert, insertFix, startDrain, beginRemove, removeFix, removeDone, release, reuseNodes }
  action step = any { advance, otherQueueWrite, s' = s }

  pure def reached(t: Tree): Set[int] = {
    val descendants = 1.to(4).fold(Set(t.l.get(0)),
      (seen, _) => seen.union(seen.exclude(Set(0, -1)).fold(Set(),
        (out, n) => out.union(Set(t.l.get(n), t.r.get(n))))))
    descendants.exclude(Set(0))
  }
  // All sixteen bounded direction paths. Stop at nil: its left is NOT a child.
  pure def blackHeights(t: Tree): Set[int] = 0.to(15).map(bits => {
    val path = List(0, 1, 2, 3).foldl({ n: t.l.get(0), count: 0 }, (a, bit) =>
      if (a.n == 0 or a.n == -1) a else {
        n: child(t, a.n, ((bits / (2 ^ bit)) % 2) == 0),
        count: a.count + (if (t.red.get(a.n)) 0 else 1),
      })
    path.count
  })
  val stable = s.phase == "idle" or s.phase == "release"
  val topology = reached(s.t) == s.t.members and s.t.p.get(0) == 0
    and s.t.members.forall(n => s.t.container.get(n) == 0
      and Set(s.t.l.get(n), s.t.r.get(n)).subseteq(s.t.members.union(Set(0)))
      and (s.t.l.get(n) == 0 or ((s.tied or s.t.l.get(n) < n) and s.t.p.get(s.t.l.get(n)) == n))
      and (s.t.r.get(n) == 0 or ((s.tied or s.t.r.get(n) > n) and s.t.p.get(s.t.r.get(n)) == n)))
    and (s.t.l.get(0) == 0 or s.t.p.get(s.t.l.get(0)) == 0)
    and s.t.r.get(0) == (if (s.t.members == Set()) 0 else minimum(s.t, s.t.l.get(0)))
    and (s.tied or s.t.members.forall(n => 1.to(4).fold(s.t.l.get(0), (x, _) =>
      if (x == n or x == 0 or x == -1) x else child(s.t, x, n < x)) == n))
  val balanced = not(s.t.red.get(0)) and not(s.t.red.get(s.t.l.get(0)))
    and blackHeights(s.t).size() == 1
    and s.t.members.forall(n => not(s.t.red.get(n))
      or (not(s.t.red.get(s.t.l.get(n))) and not(s.t.red.get(s.t.r.get(n)))))
  val safe = not(s.badRead) and (not(stable) or (topology and balanced))
    and ((s.owner == 0) == (s.phase == "idle"))
  temporal completion = weakFair(advance, s).and(weakFair(otherQueueWrite, s))
    .implies(eventually(s.round == 1 and s.draining and s.t.members == Set()
      and s.phase == "idle" and s.otherQueueWrites == 1))
}

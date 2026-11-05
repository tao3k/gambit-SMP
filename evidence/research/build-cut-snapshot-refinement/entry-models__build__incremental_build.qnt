module incremental_build {
  // Mathematical protocol, not a build implementation. Two selected units stand
  // for a frozen gsc cohort; untouched module/wrapper objects are fixed inputs.
  // Real compiler processes, dynamic dependency discovery, hashes, filesystem
  // atomicity and source-to-model refinement are NOT modeled by these integers.
  val Nodes = 0.to(9)
  type Output = { bytes: int, meta: int }
  type State = { leaf: int, macroInput: int, fault: int,
    out: int -> Output, saved: int -> List[int], phase: int -> int,
    staged: int -> Output, snapshot: int -> List[int],
    used: int, executed: Set[int], cancelled: bool, stable: bool,
    badReuse: bool, badOrder: bool, stalePublish: bool }
  var s: State
  pure def deps(n: int): Set[int] =
    if (n <= 1) Set() else if (n == 2) Set(0) else if (n == 3) Set(1)
    else if (n == 4) Set(0, 1) else if (n == 5) Set(4)
    else if (n == 6) Set(2, 3, 5) else if (n == 7) Set(4)
    else if (n == 8) Set(7) else Set(6, 8)
  pure def signature(n: int, leaf: int, macroInput: int, out: int -> Output): List[int] =
    if (n == 0) List(n, leaf, macroInput)
    else if (n == 1) List(n, macroInput)
    else if (n == 2) List(n, out.get(0).bytes)
    else if (n == 3) List(n, out.get(1).bytes)
    else if (n == 4) List(n, out.get(0).meta, out.get(1).meta)
    else if (n == 5) List(n, out.get(4).bytes)
    else if (n == 6) List(n, out.get(2).bytes, out.get(3).bytes, out.get(5).bytes)
    else if (n == 7) List(n, out.get(4).meta)
    else if (n == 8) List(n, out.get(7).bytes)
    else List(n, out.get(6).bytes, out.get(8).bytes)
  pure def calculate(n: int, leaf: int, macroInput: int, out: int -> Output): Output =
    if (n == 0) { bytes: leaf + macroInput, meta: macroInput }
    else if (n == 1) { bytes: macroInput, meta: macroInput }
    else if (n == 2) { bytes: out.get(0).bytes, meta: 0 }
    else if (n == 3) { bytes: out.get(1).bytes, meta: 0 }
    else if (n == 4) { bytes: out.get(0).meta + out.get(1).meta, meta: out.get(0).meta + out.get(1).meta }
    else if (n == 5) { bytes: out.get(4).bytes, meta: 0 }
    else if (n == 6) { bytes: out.get(2).bytes + out.get(3).bytes + out.get(5).bytes, meta: 0 }
    else if (n == 7) { bytes: out.get(4).meta, meta: 0 }
    else if (n == 8) { bytes: out.get(7).bytes, meta: 0 }
    else { bytes: out.get(6).bytes + out.get(8).bytes, meta: 0 }
  pure def initial(leaf: int, macroInput: int, fault: int): State = {
    leaf: leaf, macroInput: macroInput, fault: fault,
    out: Nodes.mapBy(_ => { bytes: 0, meta: 0 }),
    saved: Nodes.mapBy(n => signature(n, 0, 0, Nodes.mapBy(_ => { bytes: 0, meta: 0 }))),
    phase: Nodes.mapBy(_ => 0), staged: Nodes.mapBy(_ => { bytes: 0, meta: 0 }),
    snapshot: Nodes.mapBy(_ => List()), used: 0, executed: Set(),
    cancelled: false, stable: true, badReuse: false, badOrder: false, stalePublish: false,
  }
  action initNoChange = s' = initial(0, 0, 0)
  action initLeaf = s' = initial(1, 0, 0)
  action initMacro = s' = initial(0, 1, 0)
  action initBadReuse = s' = initial(1, 0, 1)
  action initStalePublish = s' = initial(1, 0, 2)
  action initOverBudget = s' = initial(0, 1, 3)
  action initMissingDependency = s' = initial(1, 0, 4)
  action initRedundant = s' = initial(0, 0, 5)
  def ready(n: int): bool = deps(n).forall(d => s.phase.get(d) == 2)
  action reuse(n: int): bool = all {
    s.stable, not(s.cancelled), s.phase.get(n) == 0, ready(n),
    s.fault == 1 or s.saved.get(n) == signature(n, s.leaf, s.macroInput, s.out),
    s' = { ...s, phase: s.phase.set(n, 2),
      badReuse: s.badReuse or s.out.get(n) != calculate(n, s.leaf, s.macroInput, s.out) },
  }
  action start(n: int): bool = all {
    s.stable, not(s.cancelled), s.phase.get(n) == 0,
    ready(n) or s.fault == 4, s.used < 2 or s.fault == 3,
    s.saved.get(n) != signature(n, s.leaf, s.macroInput, s.out) or s.fault == 5,
    s' = { ...s, phase: s.phase.set(n, 1), used: s.used + 1,
      executed: s.executed.union(Set(n)),
      staged: s.staged.set(n, calculate(n, s.leaf, s.macroInput, s.out)),
      snapshot: s.snapshot.set(n, signature(n, s.leaf, s.macroInput, s.out)),
      badOrder: s.badOrder or not(ready(n)) },
  }
  action finish(n: int): bool = all {
    s.phase.get(n) == 1,
    s' = { ...s, used: s.used - 1, phase: s.phase.set(n, 3) },
  }
  action publish(n: int): bool = all {
    s.phase.get(n) == 3,
    (s.stable and not(s.cancelled)) or s.fault == 2,
    s.snapshot.get(n) == signature(n, s.leaf, s.macroInput, s.out),
    s' = { ...s, phase: s.phase.set(n, 2), out: s.out.set(n, s.staged.get(n)),
      saved: s.saved.set(n, s.snapshot.get(n)),
      stalePublish: s.stalePublish or not(s.stable) or s.cancelled },
  }
  action invalidate = all { s.stable, s' = { ...s, stable: false } }
  action cancel = all { not(s.cancelled), s' = { ...s, cancelled: true } }
  action discard(n: int): bool = all {
    (not(s.stable) or s.cancelled), s.phase.get(n) == 3,
    s' = { ...s, phase: s.phase.set(n, 4) },
  }
  action stutter = s' = s
  action step = any {
    nondet n = Nodes.oneOf()
    any { reuse(n), start(n), finish(n), publish(n), discard(n) },
    invalidate, cancel, stutter,
  }
  val reuseSafe = not(s.badReuse)
  val dependencySafe = not(s.badOrder)
  val publicationSafe = not(s.stalePublish)
  val budgetSafe = s.used >= 0 and s.used <= 2
  val accountingSafe = s.used == Nodes.filter(n => s.phase.get(n) == 1).size()
  val safe = reuseSafe and dependencySafe and publicationSafe and budgetSafe and accountingSafe
  val complete = s.stable and not(s.cancelled) and Nodes.forall(n => s.phase.get(n) == 2)
  val noChangeWork = (s.leaf == 0 and s.macroInput == 0) implies s.executed.size() == 0
}

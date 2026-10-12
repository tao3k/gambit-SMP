module resize_local_resource_transfer {
  // A reachable still object and a registered RC block, not thread counts.
  type State = { policy: str, phase: int, admission: bool,
    owner: int -> int, alive: Set[int], counts: int -> int,
    scanner: bool, scanIssued: bool, joined: bool }
  var s: State
  val resources = Set(0, 1)
  pure def initial(policy: str): State = {
    policy: policy, phase: 0, admission: true,
    owner: resources.mapBy(_ => 1), alive: resources,
    counts: Map(0 -> 0, 1 -> 2), scanner: false, scanIssued: false,
    joined: false,
  }
  action initFixed = s' = initial("transfer")
  action initFreeReachable = s' = initial("free-local")
  action initLoseAccounting = s' = initial("omit-accounting")
  action initIgnoreScanner = s' = initial("ignore-scanner")
  action scanEnter = all { s.admission, not(s.scanIssued),
    s' = { ...s, scanner: true, scanIssued: true } }
  action scanLeave = all { s.scanner, s' = { ...s, scanner: false } }
  action closeAdmission = all { s.phase == 0,
    s' = { ...s, admission: false, phase: 1 } }
  // Thread/OS drain and successful join are premises from the other contracts.
  action join = all { s.phase == 1,
    s' = { ...s, joined: true, phase: 2 } }
  action transfer = all { s.phase == 2, s.policy != "free-local",
    not(s.scanner) or s.policy == "ignore-scanner",
    s' = { ...s, owner: resources.mapBy(_ => 0), phase: 3,
      counts: if (s.policy == "omit-accounting") s.counts else Map(0 -> 2, 1 -> 0) } }
  action cleanup = all { s.phase == 3 or (s.phase == 2 and s.policy == "free-local"),
    s' = { ...s, phase: 4,
      alive: s.alive.filter(r => s.owner.get(r) != 1),
      counts: s.counts.set(1, 0) } }
  val terminal = s.phase == 4 and not(s.scanner)
  action finished = all { terminal, s' = s }
  action step = any { scanEnter, scanLeave, closeAdmission, join, transfer, cleanup, finished }
  val resourceSafe = resources.subseteq(s.alive)
  val accountingSafe = Set(0, 1).forall(p => s.counts.get(p) ==
    s.alive.filter(r => s.owner.get(r) == p).size())
  val scannerSafe = s.scanner.implies(resources.forall(r => s.owner.get(r) == 1 and s.alive.contains(r)))
  val safe = resourceSafe and accountingSafe and scannerSafe
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}

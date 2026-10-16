// Abstract compatible-VM transfer, NOT an existing Gambit cross-VM API.
// Two requests, source/destination roots and generation-bound retirement.
module ContinuationVMTransfer {
  type State = { policy: str, owner: int, target: int, generation: int,
    roots: Set[int], pending: bool, published: bool, lease: bool,
    retired: Set[int], wrong: bool }
  var s: State
  pure def initial(policy: str): State = { policy: policy, owner: 0,
    target: 1, generation: 0, roots: Set(0), pending: false,
    published: false, lease: true, retired: Set(), wrong: false }
  action init = s' = initial("checked")
  action initNoRoot = s' = initial("no-destination-root")
  action initStaleAck = s' = initial("stale-generation-ack")
  action initNoDrain = s' = initial("no-foreign-drain")
  action request = all { not(s.pending), s.generation < 2,
    not(s.retired.contains(1 - s.owner)),
    s' = { ...s, target: 1 - s.owner, generation: s.generation + 1,
      pending: true, published: false } }
  action registerTarget = all { s.pending, not(s.published),
    s' = { ...s, roots: s.roots.union(Set(s.target)) } }
  action publish = all { s.pending, not(s.published),
    s.roots.contains(s.target) or s.policy == "no-destination-root",
    s' = { ...s, owner: s.target, published: true } }
  action acknowledge(token: int): bool = all { s.pending,
    (s.published and token == s.generation) or
      (s.policy == "stale-generation-ack" and token < s.generation),
    s' = { ...s, pending: false, roots: Set(s.target),
      wrong: s.wrong or not(s.published) or token != s.generation } }
  action foreignReturn = all { s.lease, s' = { ...s, lease: false } }
  action retireSource = all { s.owner == 1, not(s.pending),
    not(s.roots.contains(0)), not(s.retired.contains(0)),
    not(s.lease) or s.policy == "no-foreign-drain",
    s' = { ...s, retired: s.retired.union(Set(0)) } }
  action step = any { request, registerTarget, publish, acknowledge(0),
    acknowledge(1), acknowledge(2), foreignReturn, retireSource }
  val Safe = not(s.wrong) and s.roots.contains(s.owner) and
    not(s.retired.contains(s.owner)) and
    (s.lease implies not(s.retired.contains(0)))
}

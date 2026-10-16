// Two relocation rounds, wrapping colors and distinct logical generations.
// The unbounded stamp in the checked policy is a ghost design obligation,
// not a claim that Gambit has spare pointer bits or a ZGC implementation.
module RelocationEpochRoots {
  type State = { policy: str, epoch: int, metadata: Set[int], reused: Set[int],
    continuation: int, still: int, lease: bool, foreignDone: bool,
    resumed: bool, scanned: bool, wrongObject: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, epoch: 0, metadata: Set(), reused: Set(),
    continuation: 0, still: 0, lease: true, foreignDone: false,
    resumed: false, scanned: false, wrongObject: false }
  action init = s' = initial("checked")
  action initColorOnly = s' = initial("color-only")
  action initNoContinuation = s' = initial("ignore-continuation")
  action initNoStill = s' = initial("ignore-still")
  action initNoLease = s' = initial("ignore-lease")
  action move = all { s.epoch < 2,
    s' = { ...s, epoch: s.epoch + 1,
      metadata: s.metadata.union(Set(s.epoch)), reused: s.reused.union(Set(s.epoch)) } }
  def resolves(ref: int): bool =
    if (s.policy == "color-only" and ref % 2 == s.epoch % 2) ref == s.epoch
    else ref == s.epoch or s.metadata.contains(ref)
  action resume = all { not(s.resumed),
    s' = { ...s, resumed: true, continuation: s.epoch,
      wrongObject: s.wrongObject or not(resolves(s.continuation)) } }
  action scanStill = all { not(s.scanned),
    s' = { ...s, scanned: true, still: s.epoch,
      wrongObject: s.wrongObject or not(resolves(s.still)) } }
  action healContinuation = all { s.continuation != s.epoch,
    resolves(s.continuation), s' = { ...s, continuation: s.epoch } }
  action healStill = all { s.still != s.epoch,
    resolves(s.still), s' = { ...s, still: s.epoch } }
  action releaseLease = all { s.lease,
    s' = { ...s, lease: false, foreignDone: true } }
  // Moving a logical object does not reclaim the physical page leased by C.
  action retire(origin: int): bool = all { s.metadata.contains(origin),
    s.continuation != origin or s.policy == "ignore-continuation",
    s.still != origin or s.policy == "ignore-still",
    origin != 0 or not(s.lease) or s.policy == "ignore-lease",
    s' = { ...s, metadata: s.metadata.exclude(Set(origin)) } }
  action step = any { move, resume, scanStill, healContinuation, healStill,
    releaseLease, retire(0), retire(1) }
  val Safe = not(s.wrongObject) and
    (s.epoch > 0 and s.lease implies s.metadata.contains(0))
}

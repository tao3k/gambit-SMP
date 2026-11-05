// Interface-observation model, not a new collector or C transition refinement.
// One work token and two epochs are finite roles, not runtime CPU limits.
module runtime_transfer_boundary {
  import WorkObligations as Work from "../library/gc/WorkObligations"

  type State = { fault: int, family: int, phase: int,
    announced: bool, acknowledged: bool, roots: bool, mutating: bool,
    privateWork: Set[int], outbound: Set[int], inbound: Set[int], scanning: Set[int],
    epoch: int, observedEpoch: int, ownsEntry: bool, acquired: int,
    released: int, error: int, delivered: int, admitted: bool }
  var s: State
  pure def initial(fault: int, family: int): State = {
    fault: fault, family: family, phase: 0,
    announced: true, acknowledged: true, roots: true, mutating: false,
    privateWork: Set(), outbound: Set(), inbound: Set(), scanning: Set(),
    epoch: 1, observedEpoch: 1, ownsEntry: true, acquired: 1,
    released: 0, error: 7, delivered: 0, admitted: false,
  }
  action initialize(fault: int): bool = {
    nondet family = Set(1, 2, 3, 4, 5).oneOf()
    s' = initial(fault, family)
  }
  action init = initialize(0)
  action initAnnouncedOnly = s' = initial(1, 1)
  action initRootsOnly = s' = initial(2, 2)
  action initCachedReady = s' = initial(3, 3)
  action initAddressOnly = s' = initial(4, 4)
  action initUnbalancedExit = s' = initial(5, 5)

  // A previously ready boundary can be invalidated before use/commit.
  // These are adversarial observations, not claims of native reachability.
  action observe = {
    nondet changed = Set(false, true).oneOf()
    nondet secondary = Set(false, true).oneOf()
    nondet location = Set(0, 1, 2, 3).oneOf()
    all {
      s.phase == 0,
      s' = if (s.family == 1) { ...s, phase: 1, acknowledged: not(changed) }
        else if (s.family == 2) { ...s, phase: 1, roots: not(changed), mutating: secondary }
        else if (s.family == 3) { ...s, phase: 1,
          privateWork: if (changed and location == 0) Set(0) else Set(),
          outbound: if (changed and location == 1) Set(0) else Set(),
          inbound: if (changed and location == 2) Set(0) else Set(),
          scanning: if (changed and location == 3) Set(0) else Set() }
        else if (s.family == 4) { ...s, phase: 1, epoch: if (changed) 2 else 1 }
        else { ...s, phase: 1, ownsEntry: changed,
          acquired: if (changed) 1 else 0, error: if (secondary) 7 else 0 },
    }
  }
  pure def serviceReady(st: State): bool = st.announced and st.acknowledged
  pure def rootReady(st: State): bool = st.roots and not(st.mutating)
  pure def workReady(st: State): bool = Work::noOutstanding(
    st.privateWork, st.outbound, st.inbound, st.scanning)
  pure def identityReady(st: State): bool = st.observedEpoch == st.epoch
  pure def exitBalanced(st: State): bool = st.released == st.acquired and
    st.delivered == st.error
  action commit = all {
    s.phase == 1,
    s' = if (s.family == 1) { ...s, phase: 2,
      admitted: if (s.fault == 1) s.announced else serviceReady(s) }
    else if (s.family == 2) { ...s, phase: 2,
      admitted: if (s.fault == 2) s.roots else rootReady(s) }
    else if (s.family == 3) { ...s, phase: 2,
      admitted: s.fault == 3 or workReady(s) }
    else if (s.family == 4) { ...s, phase: 2,
      admitted: s.fault == 4 or identityReady(s) }
    else { ...s, phase: 2, admitted: true,
      released: if (s.fault == 5) 1 else s.acquired,
      delivered: s.error },
  }
  action finished = all { s.phase == 2, s' = s }
  action step = any { observe, commit, finished }
  val safe = not(s.admitted) or
    (if (s.family == 1) serviceReady(s)
     else if (s.family == 2) rootReady(s)
     else if (s.family == 3) workReady(s)
     else if (s.family == 4) identityReady(s)
     else exitBalanced(s))
  // Observation/commit completion is not mutator or GC termination.
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.phase == 2))
}

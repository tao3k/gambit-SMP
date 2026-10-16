module public_vm_retirement_composition {
  // Owner exclusion and joined direct users are premises; registry readers
  // and active/retired cohort members are independently represented.
  type State = { policy: str, phase: str, active: bool, pending: bool,
    foreign: bool, foreignGate: bool, registryGate: bool, reader: str,
    lease: bool, memory: bool, resource: bool, releases: int }
  var s: State
  pure def initial(policy: str, active: bool, pending: bool, foreign: bool): State = {
    policy: policy, phase: "request", active: active, pending: pending,
    foreign: foreign, foreignGate: true, registryGate: true,
    reader: "new", lease: false, memory: true, resource: true, releases: 0 }
  action init = {
    nondet active = Set(false, true).oneOf()
    nondet pending = Set(false, true).oneOf()
    nondet foreign = Set(false, true).oneOf()
    s' = initial("owned", active, pending, foreign)
  }
  action initActiveControl = s' = initial("foreign-only", true, false, false)
  action initPendingControl = s' = initial("foreign-only", false, true, false)
  action readerEnter = all { s.reader == "new", s.registryGate,
    s' = { ...s, reader: "use", lease: true } }
  action readerLeave = all { s.reader == "use",
    s' = { ...s, reader: "done", lease: false } }
  action readerCancel = all { s.reader == "new", not(s.registryGate),
    s' = { ...s, reader: "done" } }
  action request = all { s.phase == "request",
    s' = if (s.foreign or (s.policy == "owned" and (s.active or s.pending)))
      { ...s, phase: "retained" }
    else { ...s, foreignGate: false, phase: "close" } }
  action close = all { s.phase == "close",
    s' = { ...s, registryGate: false, phase: "drain" } }
  action drain = all { s.phase == "drain", not(s.lease),
    s' = { ...s, phase: "release" } }
  action release = all { s.phase == "release", not(s.lease),
    s' = { ...s, resource: false, releases: s.releases + 1, phase: "memory" } }
  action reclaim = all { s.phase == "memory", not(s.lease),
    s' = { ...s, memory: false, phase: "done" } }
  val terminal = s.phase == "done" or s.phase == "retained"
  action finished = all { terminal, s' = s }
  action step = any { readerEnter, readerLeave, readerCancel, request, close,
    drain, release, reclaim, finished }
  val cohortOwned = (not(s.memory) or not(s.resource)).implies(
    not(s.active) and not(s.pending))
  val safe = cohortOwned and s.releases <= 1 and
    (not(s.memory).implies(not(s.foreign) and not(s.foreignGate) and
      not(s.registryGate) and not(s.lease) and not(s.resource))) and
    (s.phase == "retained").implies(s.memory and s.resource and s.releases == 0)
  val noStall = terminal or enabled(step)
  // Rejection is not successful cleanup. It retains all storage for its owner.
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}

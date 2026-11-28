module root_registry_callback {
  import vm_list_reader_retirement as R from "../gambit/vm_list_reader_retirement"

  // Trusted scanner callbacks only: no arbitrary Scheme re-entry permission.
  // Deletion changes registry topology, not the last-use ownership of a slot.
  // A separate phase projection: two domains may each own their entry lock.
  // Neither that ownership nor one local scan completion releases global roots.
  type Payload = { phase: int, parked: Set[int], updated: Set[int],
    earlyResume: bool, overlap: bool, lateWrite: bool }
  pure def payloadInitial(early: bool): Payload = {
    phase: 0, parked: Set(), updated: Set(), earlyResume: early,
    overlap: false, lateWrite: false }
  type Registry = { policy: int, external: bool, phase: int,
    locked: bool, depth: int, deferred: bool, badAuthority: bool,
    phaseStudy: bool, payload: Payload }
  var r: Registry
  pure def initial(policy: int, external: bool): Registry = {
    policy: policy, external: external, phase: 0, locked: false,
    depth: 0, deferred: false, badAuthority: false,
    phaseStudy: false, payload: payloadInitial(false) }
  action initFixed = {
    nondet external = Set(false, true).oneOf()
    all { r' = initial(0, external), R::s' = R::initial("drain-admitted") }
  }
  action initRelockInsideScan = all { r' = initial(1, false),
    R::s' = R::initial("drain-admitted") }
  action initForeignDepthBypass = all { r' = initial(2, true),
    R::s' = R::initial("drain-admitted") }
  action initUnlinkAsLastUse = all { r' = initial(3, false),
    R::s' = R::initial("drain-admitted") }
  action initScanPhaseFixed = all {
    r' = { ...initial(0, false), phaseStudy: true },
    R::s' = R::initial("drain-admitted") }
  action initLocalScanAsGlobalCompletion = all {
    r' = { ...initial(0, false), phaseStudy: true, payload: payloadInitial(true) },
    R::s' = R::initial("drain-admitted") }
  action keepR = R::s' = R::s

  action acquireRecord = all { r.phase == 0,
    any { R::enter, R::load, R::register }, r' = r }
  action enterScanner = all { r.phase == 0, R::s.reader == "use",
    r' = { ...r, phase: 1, locked: true, depth: 1 }, keepR }
  // Same scanner owner marks a deletion without acquiring its own lock again.
  // The existing R protocol retains admitted readers through their last use.
  action ownerDelete = all { r.phase == 1, not(r.external), r.policy != 1,
    R::stop, r' = { ...r, phase: 2, deferred: true } }
  action recursiveRelock = all { r.phase == 1, not(r.external), r.policy == 1,
    r' = { ...r, phase: 5 }, keepR }
  // A different OS thread's local depth is zero. A global depth shortcut
  // would incorrectly grant that thread the scanner's mutation authority.
  action foreignDepthBypass = all { r.phase == 1, r.external, r.policy == 2,
    R::stop, r' = { ...r, phase: 2, deferred: true, badAuthority: true } }
  action ordinaryCallbackReturn = all { r.phase == 1, r.external,
    r' = { ...r, phase: 2 }, keepR }
  action callbackTail = all { r.phase == 2,
    r' = { ...r, phase: 3 }, keepR }
  action lastSlotUse = all { r.phase == 3, R::dereference,
    r' = { ...r, phase: 4, locked: false, depth: 0 } }
  action prematureSlotFree = all { r.policy == 3, r.phase == 2, R::s.alive,
    R::s' = { ...R::s, alive: false }, r' = r }
  action externalDelete = all { r.phase == 4, r.external,
    R::stop, r' = r }
  action finishDeletion = all { r.phase == 4,
    any { R::drain, R::unlink, R::reclaim }, r' = r }

  val scannerTerminal = r.phase == 4 and R::terminal
  action finished = all { scannerTerminal, r' = r, keepR }
  action scannerStep = any { acquireRecord, enterScanner, ownerDelete,
    recursiveRelock, foreignDepthBypass, ordinaryCallbackReturn, callbackTail,
    lastSlotUse, prematureSlotFree, externalDelete, finishDeletion, finished }

  pure val domains = Set(0, 1)
  action parkDomain(id: int): bool = all { r.payload.phase == 0,
    not(r.payload.parked.contains(id)),
    r' = { ...r, payload: { ...r.payload, parked: r.payload.parked.union(Set(id)) } }, keepR }
  action startGlobalScan = all { r.payload.phase == 0, r.payload.parked == domains,
    r' = { ...r, payload: { ...r.payload, phase: 1 } }, keepR }
  action finishGlobalScan = all { r.payload.phase == 1,
    r' = { ...r, payload: { ...r.payload, phase: 2 } }, keepR }
  action resumeDomain(id: int): bool = all { r.payload.parked.contains(id),
    r.payload.phase == 2 or (r.payload.phase == 1 and r.payload.earlyResume),
    r' = { ...r, payload: { ...r.payload, parked: r.payload.parked.exclude(Set(id)) } }, keepR }
  action writePayload(id: int): bool = all {
    not(r.payload.parked.contains(id)), not(r.payload.updated.contains(id)),
    r' = { ...r, payload: { ...r.payload,
      updated: r.payload.updated.union(Set(id)),
      overlap: r.payload.overlap or r.payload.phase == 1,
      lateWrite: r.payload.lateWrite or r.payload.phase == 2 } }, keepR }
  val payloadTerminal = r.payload.phase == 2 and r.payload.parked == Set()
    and r.payload.updated == domains
  action payloadFinished = all { payloadTerminal, r' = r, keepR }
  action payloadStep = any { parkDomain(0), parkDomain(1), startGlobalScan,
    finishGlobalScan, resumeDomain(0), resumeDomain(1), writePayload(0),
    writePayload(1), payloadFinished }
  val terminal = if (r.phaseStudy) payloadTerminal else scannerTerminal
  action step = any { all { not(r.phaseStudy), scannerStep },
    all { r.phaseStudy, payloadStep } }
  val safe = R::safe and not(r.badAuthority) and not(r.payload.overlap)
  val noStall = terminal or enabled(step)
  val noOwnerCompletion = not(terminal and not(r.external) and r.deferred)
  val noExternalCompletion = not(terminal and r.external and not(r.deferred))
  val noPostScanMutation = not(r.phaseStudy and payloadTerminal and r.payload.lateWrite)
  // Finite callbacks/critical sections, explicit slot last-use premise and
  // SC actions. The payload projection checks mutator/scan exclusion only,
  // not same-slot writer serialization, a write barrier, or physical moving GC.
  temporal completion = always(noStall) and
    weakFair(step, Set((r, R::s))).implies(eventually(terminal))
}

module saved_stack_last_access {
  import saved_stack_root_closure.* from "./saved_stack_root_closure"

  // Refine the supplied root census with one potentially omitted in-flight
  // old-frame consumer. This is a source-correspondence obligation, not an
  // assertion that such an unaccounted reader exists in the native candidate.
  type Reader = { requireDrain: bool, started: bool, active: bool,
    returned: bool, recycled: bool, badRead: bool }
  var reader: Reader
  var rank: int
  pure def readerInitial(required: bool): Reader = { requireDrain: required,
    started: false, active: false, returned: false, recycled: false, badRead: false }
  action initAccess = {
    nondet required = Set(false, true).oneOf()
    all { initClosure, reader' = readerInitial(required), rank' = 0 }
  }
  action keepRoots = all { keepA, g' = g }
  action rootProtocol = all {
    any { retirePrefix, establishRoot, restoreHead, consumeHead,
      collect, forwardHead, retargetOrigin, drainTargetWork,
      closeCycle, resumeHead }, reader' = reader }
  action beginRead = all { g.collection, g.workPending,
    not(reader.recycled), g.rawOrigins != Set(), not(reader.started), keepRoots,
    reader' = { ...reader, started: true, active: true } }
  // Resolving a registered root does not itself complete this captured read.
  action lastAccess = all { reader.active, keepRoots,
    reader' = { ...reader, active: false, returned: true,
      badRead: reader.recycled } }
  action reuse = all { not(reader.requireDrain) or not(reader.active),
    nextCycleReuse, reader' = { ...reader, recycled: true } }
  val accessTerminal = closureTerminal and not(reader.active)
  action accessStep = any {
    all { g.fault == 0, not(accessTerminal),
      any { rootProtocol, beginRead, lastAccess, reuse }, rank' = rank + 1 },
    all { g.fault != 0 or accessTerminal, keepRoots, reader' = reader, rank' = rank } }
  val declaredRootSafe = closureSafe
  val lastAccessSafe = not(reader.badRead) and
    (not(reader.recycled) or not(reader.active))
  val completeCensusSafe = not(reader.requireDrain) or lastAccessSafe
  val noClosedConsumerReuse = not(reader.requireDrain and reader.returned
    and reader.recycled and closureTerminal)
  temporal accessCompletion = always(g.fault != 0) or
    weakFair(accessStep, Set(rank)).implies(eventually(accessTerminal))
}

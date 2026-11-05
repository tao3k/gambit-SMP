module ebnf_reader_custody {
  import ebnf_reader_parameters.* from "./ebnf_reader_parameters"
  val Readers = 0.to(ConsumerCount - 1)
  type State = { admitted: bool, ports: int -> int, depth: int -> int,
    open: int -> bool, cursor: int -> int, buf: int -> List[int],
    captured: Set[int], suspended: Set[int], errorRoots: Set[int],
    done: Set[int], reclaimed: Set[int], savedCursor: int -> int,
    epoch: int, inputEpoch: int, frozen: bool, cached: bool,
    lost: bool, replayed: bool, wrongIdentity: bool, rawUseClosed: bool, badReuse: bool }
  var s: State
  pure def initial(admitted: bool, alias: bool): State = {
    admitted: admitted, ports: Readers.mapBy(c => if (alias) 0 else c),
    depth: Readers.mapBy(_ => 0), open: Readers.mapBy(_ => true),
    cursor: Readers.mapBy(_ => 0), buf: Readers.mapBy(_ => List()),
    captured: Set(), suspended: Set(), errorRoots: Set(), done: Set(), reclaimed: Set(),
    savedCursor: Readers.mapBy(_ => 0), epoch: 0, inputEpoch: 0,
    frozen: false, cached: false, lost: false, replayed: false,
    wrongIdentity: false, rawUseClosed: false, badReuse: false }
  action init = s' = initial(true, false)
  action initActual = s' = initial(ActualAdmitted, false)
  action initAliased = s' = initial(true, true)
  def active(c: int): bool = s.depth.get(c) > 0
  def ownsLease(c: int): bool = active(c) or s.captured.contains(c) or s.errorRoots.contains(c)
  def available(c: int): bool = Readers.forall(other => other == c or
    s.ports.get(other) != s.ports.get(c) or not(ownsLease(other)))
  action enter(c: int): bool = all { s.open.get(s.ports.get(c)), available(c), s.depth.get(c) < DepthLimit,
    not(s.suspended.contains(c)), not(s.reclaimed.contains(c)),
    s' = { ...s, depth: s.depth.set(c, s.depth.get(c) + 1) } }
  action read(c: int): bool = all { active(c), s.open.get(s.ports.get(c)), not(s.suspended.contains(c)),
    s' = if (s.buf.get(c).length() == 0)
      { ...s, cursor: s.cursor.set(s.ports.get(c), s.cursor.get(s.ports.get(c)) + 1) }
      else { ...s, buf: s.buf.set(c, s.buf.get(c).tail()) } }
  action unread(c: int): bool = all { active(c), not(s.suspended.contains(c)),
    s' = { ...s, buf: s.buf.set(c, List(17).concat(s.buf.get(c))) } }
  // Empty buffer is sufficient, not necessary, for a transparent direct-port handoff.
  action directRead(c: int): bool = all { active(c), s.open.get(s.ports.get(c)),
    not(s.suspended.contains(c)), s.buf.get(c).length() == 0,
    s' = { ...s, cursor: s.cursor.set(s.ports.get(c), s.cursor.get(s.ports.get(c)) + 1) } }
  action capture(c: int): bool = all { active(c), not(s.suspended.contains(c)),
    s' = { ...s, captured: s.captured.union(Set(c)), savedCursor: s.savedCursor.set(c, s.cursor.get(s.ports.get(c))) } }
  action suspend(c: int): bool = all { active(c), s.captured.contains(c),
    s' = { ...s, suspended: s.suspended.union(Set(c)) } }
  action resume(c: int): bool = all { s.suspended.contains(c), s.open.get(s.ports.get(c)),
    // Preserve current cursor/heap; Scheme continuation return does not roll back mutation.
    s' = { ...s, suspended: s.suspended.exclude(Set(c)) } }
  action leaveNested(c: int): bool = all { s.depth.get(c) > 1, not(s.suspended.contains(c)),
    s' = { ...s, depth: s.depth.set(c, s.depth.get(c) - 1) } }
  action abortReader(c: int): bool = all { active(c), not(s.suspended.contains(c)),
    // Conservative custody: source call-with-input-file shown has no dynamic-wind cleanup.
    s' = { ...s, depth: s.depth.set(c, 0), errorRoots: s.errorRoots.union(Set(c)) } }
  action finish(c: int): bool = all { s.depth.get(c) == 1, not(s.suspended.contains(c)),
    s' = { ...s, depth: s.depth.set(c, 0), open: s.open.set(s.ports.get(c), false), done: s.done.union(Set(c)) } }
  action observeClosedResume(c: int): bool = all { s.captured.contains(c), not(s.open.get(s.ports.get(c))),
    s' = { ...s, errorRoots: s.errorRoots.union(Set(c)) } }
  action dropRoots(c: int): bool = all { not(active(c)), not(s.suspended.contains(c)),
    s' = { ...s, captured: s.captured.exclude(Set(c)), errorRoots: s.errorRoots.exclude(Set(c)) } }
  action reclaim(c: int): bool = all { not(active(c)), not(s.captured.contains(c)),
    not(s.errorRoots.contains(c)), not(s.suspended.contains(c)),
    s' = { ...s, reclaimed: s.reclaimed.union(Set(c)) } }
  action changeReadtable = s' = { ...s, epoch: s.epoch + 1 }
  action freezeOutput = all { s.admitted, s' = { ...s, frozen: true } }
  def canCache = s.admitted and s.done == Readers and s.frozen
    and s.inputEpoch == s.epoch and Readers.forall(c => s.buf.get(c).length() == 0)
  action cacheResult = all { canCache, s' = { ...s, cached: true } }
  action reuseCached = all { s.cached, s.inputEpoch == s.epoch, s' = s }
  def safe = not(s.lost) and not(s.replayed) and not(s.wrongIdentity) and not(s.rawUseClosed)
    and Readers.forall(c => Readers.forall(other => c == other or
      not(ownsLease(c) and ownsLease(other)) or s.ports.get(c) != s.ports.get(other)))
    and s.reclaimed.forall(c => not(active(c)) and not(s.captured.contains(c)) and not(s.errorRoots.contains(c)))
    and (not(s.cached) or (s.admitted and s.frozen)) and not(s.badReuse)
  action step = any {
    nondet c = Readers.oneOf()
    any { enter(c), read(c), unread(c), directRead(c), capture(c), suspend(c), resume(c),
      leaveNested(c), abortReader(c), finish(c), observeClosedResume(c), dropRoots(c), reclaim(c) },
    changeReadtable, freezeOutput, cacheResult, reuseCached, s' = s }
  action unsafeAliasEnter = s' = { ...s, depth: s.depth.set(1, 1) }
  action unsafeHandoff(c: int): bool = s' = { ...s, lost: s.buf.get(c).length() > 0, buf: s.buf.set(c, List()) }
  action unsafeRollback(c: int): bool = s' = { ...s, replayed: s.cursor.get(s.ports.get(c)) != s.savedCursor.get(c), cursor: s.cursor.set(s.ports.get(c), s.savedCursor.get(c)) }
  action unsafeIdentity = s' = { ...s, wrongIdentity: true }
  action unsafeReclaim(c: int): bool = s' = { ...s, reclaimed: s.reclaimed.union(Set(c)) }
  action unsafeClosedRead = s' = { ...s, rawUseClosed: true }
  action unsafeCache = s' = { ...s, cached: true }
  action unsafeReuse = s' = { ...s, badReuse: s.inputEpoch != s.epoch }
  run independentPortsTest = init.then(enter(0)).then(enter(1)).expect(safe and active(0) and active(1))
  run nestedSameInvocationTest = init.then(enter(0)).then(enter(0)).then(leaveNested(0)).expect(safe and s.depth.get(0) == 1)
  run bufferedReadTest = init.then(enter(0)).then(unread(0)).then(read(0)).expect(safe and s.cursor.get(0) == 0 and s.buf.get(0) == List())
  run directPortEmptyBufferTest = init.then(enter(0)).then(directRead(0)).expect(safe and s.cursor.get(0) == 1)
  run nonemptyBufferDeniesHandoffTest = init.then(enter(0)).then(unread(0)).expect(safe and s.buf.get(0).length() > 0)
  run resumeKeepsMutationTest = init.then(enter(0)).then(capture(0)).then(read(0)).then(suspend(0)).then(resume(0)).expect(safe and s.cursor.get(0) == 1)
  run repeatResumeKeepsIdentityTest = init.then(enter(0)).then(capture(0)).then(suspend(0)).then(resume(0)).then(suspend(0)).then(resume(0)).expect(safe and s.captured.contains(0))
  run failureRootsAndPortRetainedTest = init.then(enter(0)).then(abortReader(0)).expect(safe and s.open.get(0) and s.errorRoots.contains(0))
  run closedResumeObservedTest = init.then(enter(0)).then(capture(0)).then(finish(0)).then(observeClosedResume(0)).expect(safe and s.errorRoots.contains(0) and not(s.open.get(0)))
  run rootsDrainBeforeReclaimTest = init.then(enter(0)).then(abortReader(0)).then(dropRoots(0)).then(reclaim(0)).expect(safe and s.reclaimed.contains(0))
  run actualCacheDeniedTest = initActual.then(enter(0)).then(finish(0)).then(enter(1)).then(finish(1)).expect(safe and not(canCache))
  run qualifiedCacheTest = init.then(enter(0)).then(finish(0)).then(enter(1)).then(finish(1)).then(freezeOutput).then(cacheResult).expect(safe and s.cached)
  run changedReadtableDeniedTest = init.then(enter(0)).then(finish(0)).then(enter(1)).then(finish(1)).then(freezeOutput).then(changeReadtable).expect(safe and not(canCache))
  run aliasedPortControlTest = initAliased.then(enter(0)).then(unsafeAliasEnter).expect(not(safe))
  run lostLookaheadControlTest = init.then(enter(0)).then(unread(0)).then(unsafeHandoff(0)).expect(not(safe))
  run continuationRollbackControlTest = init.then(enter(0)).then(capture(0)).then(read(0)).then(unsafeRollback(0)).expect(not(safe))
  run replacementIdentityControlTest = init.then(enter(0)).then(unsafeIdentity).expect(not(safe))
  run activeReclaimControlTest = init.then(enter(0)).then(unsafeReclaim(0)).expect(not(safe))
  run errorRootReclaimControlTest = init.then(enter(0)).then(abortReader(0)).then(unsafeReclaim(0)).expect(not(safe))
  run closedPortUseControlTest = init.then(enter(0)).then(capture(0)).then(finish(0)).then(unsafeClosedRead).expect(not(safe))
  run unqualifiedCacheControlTest = initActual.then(unsafeCache).expect(not(safe))
  run staleReadtableReuseControlTest = init.then(enter(0)).then(finish(0)).then(enter(1)).then(finish(1)).then(freezeOutput).then(cacheResult).then(changeReadtable).then(unsafeReuse).expect(not(safe))
}

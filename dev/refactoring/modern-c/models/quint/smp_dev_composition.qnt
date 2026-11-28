module smp_dev_composition {
  // One finite abstract epoch. Numbers summarize obligations, not real addresses
  // or a complete census. No fairness, memory model or timing claim is made.
  type S = { closed: bool, readers: int, work: int, scan: int, weak: bool, grant: bool,
    retired: bool, published: bool, loaded: bool, loadedGrant: int, allocated: bool,
    request: int, woke: bool, registry: int, ffi: int, freed: bool }
  var s: S
  action init = s' = { closed: false, readers: 0, work: 0, scan: 0, weak: false,
    grant: false, retired: false, published: false, loaded: false, loadedGrant: 0,
    allocated: false, request: 0, woke: false, registry: 0, ffi: 0, freed: false }
  action readerEnter = all { not(s.closed), s.readers == 0, s' = {...s, readers: 1} }
  action readerExit = all { s.readers == 1, s' = {...s, readers: 0} }
  action publishWork = all { not(s.closed), s.work == 0, s' = {...s, work: 1} }
  action finishWork = all { s.work == 1, s' = {...s, work: 0} }
  action weakEnter = all { not(s.closed), not(s.weak), s' = {...s, weak: true} }
  action weakExit = all { s.weak, s' = {...s, weak: false} }
  action close = all { not(s.closed), s' = {...s, closed: true} }
  // One frozen root task: pending, claimed, uncertain, then completed.
  action claimScan = all { s.closed, s.scan == 0, s' = {...s, scan: 1} }
  action loseScanReply = all { s.scan == 1, s' = {...s, scan: 2} }
  action finishScan = all { s.scan == 1, s' = {...s, scan: 3} }
  // Query settles the existing claim; it cannot create another claim.
  action reconcileScan = all { s.scan == 2, s' = {...s, scan: 3} }
  action handoff = all { s.closed, s.scan == 3, s.work == 0, not(s.weak), not(s.grant), s' = {...s, grant: true} }
  action retire = all { s.grant, s.readers == 0, not(s.retired), s' = {...s, retired: true} }
  action publishCursor = all { s.retired, not(s.published), s' = {...s, published: true} }
  action reload = all { s.published, not(s.loaded), s' = {...s, loaded: true, loadedGrant: 1} }
  action allocate = all { s.loaded, s.loadedGrant == 1, s.grant, not(s.freed), not(s.allocated), s' = {...s, allocated: true} }
  // 0 absent; 1 accepted; 2 claimed; 3 settled. A wake is not a settlement.
  action acceptRequest = all { not(s.freed), s.request == 0, s' = {...s, request: 1} }
  action claimRequest = all { s.request == 1, s' = {...s, request: 2} }
  action settleRequest = all { s.request == 2, s' = {...s, request: 3} }
  action wakeWaiter = all { s.request == 3, not(s.woke), s' = {...s, woke: true} }
  // Registry and FFI borrowers may outlive round closure; 2 is uncertain.
  action borrowRegistry = all { not(s.freed), s.registry == 0, s' = {...s, registry: 1} }
  action releaseRegistry = all { s.registry == 1, s' = {...s, registry: 0} }
  action borrowFfi = all { not(s.freed), s.ffi == 0, s' = {...s, ffi: 1} }
  action unknownFfi = all { s.ffi == 1, s' = {...s, ffi: 2} }
  action reconcileFfi = all { s.ffi == 2, s' = {...s, ffi: 0} }
  action releaseFfi = all { s.ffi == 1, s' = {...s, ffi: 0} }
  action free = all { s.retired, s.registry == 0, s.ffi == 0, (s.request == 0 or (s.request == 3 and s.woke)),
    not(s.freed), s' = {...s, freed: true} }
  action step = any { readerEnter, readerExit, publishWork, finishWork, weakEnter,
    weakExit, close, claimScan, loseScanReply, finishScan, reconcileScan, handoff, retire, publishCursor, reload, allocate,
    acceptRequest, claimRequest, settleRequest, wakeWaiter, borrowRegistry, releaseRegistry, borrowFfi,
    unknownFfi, reconcileFfi, releaseFfi, free, s' = s }
  val safe = all { s.retired implies (s.closed and s.grant and s.readers == 0),
    s.grant implies (s.closed and s.scan == 3 and s.work == 0 and not(s.weak)),
    s.allocated implies (s.loaded and s.loadedGrant == 1 and s.published and s.retired and s.grant),
    s.woke implies (s.request == 3),
    s.freed implies (s.retired and s.registry == 0 and s.ffi == 0 and (s.request == 0 or (s.request == 3 and s.woke))) }
  run delayedCompositionTest = init.then(readerEnter).then(publishWork).then(weakEnter)
    .then(acceptRequest).then(borrowRegistry).then(borrowFfi).then(close)
    .then(finishWork).then(weakExit).then(claimScan).then(finishScan).then(handoff).expect(s.readers == 1 and not(s.retired))
    .then(readerExit).then(retire).then(publishCursor).then(reload).then(allocate)
    .then(unknownFfi).expect(not(s.freed) and safe).then(reconcileFfi)
    .then(releaseRegistry).then(claimRequest).then(settleRequest).then(wakeWaiter).then(free).expect(s.freed and safe)
  run earlyRetireControlTest = init.then(readerEnter).then(close).then(claimScan).then(finishScan).then(handoff)
    .then(all { s' = {...s, retired: true} }).expect(not(safe))
  run hiddenWorkControlTest = init.then(publishWork).then(close)
    .then(all { s' = {...s, grant: true} }).expect(not(safe))
  run staleCursorControlTest = init.then(close).then(claimScan).then(finishScan).then(handoff).then(retire).then(publishCursor)
    .then(all { s' = {...s, loaded: true, loadedGrant: 2, allocated: true} }).expect(not(safe))
  run unknownReleaseControlTest = init.then(borrowFfi).then(unknownFfi).then(close)
    .then(claimScan).then(finishScan).then(handoff).then(retire).then(all { s' = {...s, freed: true} }).expect(not(safe))
  run pendingRequestControlTest = init.then(acceptRequest).then(close).then(claimScan).then(finishScan).then(handoff)
    .then(retire).then(all { s' = {...s, freed: true} }).expect(not(safe))
  run lostScanReplyTest = init.then(close).then(claimScan).then(loseScanReply)
    .expect(safe and not(s.grant)).then(reconcileScan).then(handoff).expect(safe)
  run unknownScanReleaseControlTest = init.then(close).then(claimScan).then(loseScanReply)
    .then(all { s' = {...s, grant: true} }).expect(not(safe))
  run prematureWakeControlTest = init.then(acceptRequest).then(claimRequest)
    .then(all { s' = {...s, woke: true} }).expect(not(safe))
}

// Composition seam only: reuse the existing native-root protocol unchanged.
// Pending work and other-producer closure are abstract acknowledgements, not
// a second collector, allocator, queue or proof of the concrete C adapters.
module shared_heap_cut {
  import rc_freeze_publication as Host from "../../../../../../models/gambit/rc_freeze_publication"
  type Cycle = { phase: int, epoch: int, permitEpoch: int, pending: int,
    producersClosed: bool, rewritten: bool, loaded: int, restores: int,
    deferred: bool, effectRoot: bool, waitsOwnerEffect: bool }
  var cycle: Cycle
  action init = all { Host::init,
    cycle' = { phase: 0, epoch: 1, permitEpoch: 0, pending: 0,
      producersClosed: false, rewritten: false, loaded: 0, restores: 0,
      deferred: false, effectRoot: false, waitsOwnerEffect: false } }
  action prepare = all { cycle.phase == 0, Host::prepare, cycle' = cycle }
  action publish = all { cycle.phase == 0, Host::publish, cycle' = cycle }
  action enter = all { cycle.phase == 0, Host::enter, cycle' = cycle }
  action close = all { cycle.phase == 0, Host::close, cycle' = cycle }
  action park = all { cycle.phase == 0, Host::park, cycle' = cycle }
  action issue = all { cycle.phase == 0, Host::issue, cycle' = cycle }
  action pin = all { cycle.phase == 0, Host::pin, cycle' = cycle }
  // Discovery before scan pin invalidates any issued, unclaimed root receipt.
  // Discovery after pin is an adversarial source-contract breach, not a safe
  // moving-GC transition that a Boolean can magically repair.
  action unknownWriter = all { cycle.phase == 0, not(Host::s.pin),
    Host::s' = { ...Host::s, known: false, receipt: false }, cycle' = cycle }
  action begin = all { cycle.phase == 0, Host::s.pin, Host::frozen, Host::current,
    Host::s' = Host::s, cycle' = { ...cycle, phase: 1, pending: 1,
      permitEpoch: cycle.epoch } }
  action settleCopy = all { cycle.phase == 1, cycle.pending == 1, Host::s.pin,
    Host::s' = Host::s, cycle' = { ...cycle, pending: 0 } }
  action rewriteRoots = all { cycle.phase == 1, not(cycle.rewritten),
    Host::relocate, cycle' = { ...cycle, rewritten: true } }
  action closeProducers = all { cycle.phase == 1, cycle.pending == 0,
    Host::s' = Host::s, cycle' = { ...cycle, producersClosed: true } }
  action finish = all { cycle.phase == 1, cycle.pending == 0,
    cycle.rewritten, cycle.producersClosed, cycle.permitEpoch == cycle.epoch,
    Host::endGC, cycle' = { ...cycle, phase: 2 } }
  action reopen = all { cycle.phase == 2, Host::reopen,
    cycle' = { ...cycle, phase: 3 } }
  action restore = all { cycle.phase == 3, cycle.restores < 2,
    Host::reload, cycle' = { ...cycle, loaded: Host::s.rootVersion,
      restores: cycle.restores + 1 } }
  // Owner-affine effects remain in custody but are not prerequisites for
  // resuming the owner. They may not add unregistered moving roots here.
  action deferOwnerEffect = all { cycle.phase == 1, not(cycle.deferred),
    Host::enqueueCleanup, cycle' = { ...cycle, deferred: true, effectRoot: true } }
  action ownerReturn = all { cycle.phase == 3, cycle.restores > 0,
    Host::leave, cycle' = cycle }
  action deliverEffect = all { cycle.phase == 3, cycle.deferred,
    Host::finishCleanup, cycle' = { ...cycle, deferred: false, effectRoot: false } }
  action idle = all { Host::s' = Host::s, cycle' = cycle }
  action step = any { prepare, publish, enter, close, park, issue, pin, unknownWriter, begin,
    settleCopy, rewriteRoots, closeProducers, finish, reopen, restore,
    deferOwnerEffect, ownerReturn, deliverEffect, idle }
  val safe = Host::safe and all {
    cycle.deferred implies all { cycle.effectRoot, Host::s.queued },
    not(cycle.waitsOwnerEffect and cycle.phase == 1),
    cycle.phase == 1 implies all { Host::frozen, Host::s.pin,
      cycle.permitEpoch == cycle.epoch },
    cycle.phase >= 2 implies all { cycle.pending == 0, cycle.rewritten,
      cycle.producersClosed, cycle.permitEpoch == cycle.epoch },
    cycle.restores > 0 implies all { cycle.phase == 3,
      not(Host::s.closed), not(Host::s.pin), cycle.loaded == Host::s.rootVersion }
  }
  // Adversarial omissions are controls, never admitted step alternatives.
  action badLateDiscovery = all { Host::escape, cycle' = cycle }
  action badEarlyEnd = all { Host::endGC, cycle' = { ...cycle, phase: 2 } }
  action badReopen = all { Host::reopen, cycle' = { ...cycle, phase: 3 } }
  action badStaleEpoch = all { Host::s' = Host::s,
    cycle' = { ...cycle, epoch: cycle.epoch + 1 } }
  action badDropSourcePin = all { Host::s' = { ...Host::s, pin: false }, cycle' = cycle }
  action badUseOldAddress = all { Host::reload,
    cycle' = { ...cycle, loaded: Host::s.rootVersion - 1, restores: 1 } }
  action badLoseEffectCustody = all { Host::s' = Host::s,
    cycle' = { ...cycle, effectRoot: false } }
  action badWaitOwnerEffect = all { Host::s' = Host::s,
    cycle' = { ...cycle, waitsOwnerEffect: true } }
  action pinnedStart = init.then(prepare).then(publish).then(enter)
    .then(close).then(park).then(issue).then(pin).then(begin)
  action drained = pinnedStart.then(settleCopy).then(rewriteRoots)
    .then(closeProducers).then(finish)
  action deferredDrained = pinnedStart.then(deferOwnerEffect).then(settleCopy)
    .then(rewriteRoots).then(closeProducers).then(finish)
  run deferredEffectDoesNotBlockResumeTest = deferredDrained.then(reopen).then(restore)
    .expect(safe and cycle.deferred and cycle.effectRoot)
  run deliverAfterOwnerReturnTest = deferredDrained.then(reopen).then(restore)
    .then(ownerReturn).then(deliverEffect).expect(safe and not(cycle.deferred))
  run droppedEffectCustodyControlTest = pinnedStart.then(deferOwnerEffect)
    .then(badLoseEffectCustody).expect(Host::safe and not(safe))
  run ownerEffectWaitCycleControlTest = pinnedStart.then(deferOwnerEffect)
    .then(badWaitOwnerEffect).expect(Host::safe and not(safe))
  run unknownRevokesUnclaimedReceiptTest = init.then(prepare).then(publish)
    .then(close).then(issue).then(unknownWriter)
    .expect(safe and not(Host::s.receipt) and not(Host::s.pin))
  run lateUnknownDiscoveryControlTest = init.then(prepare).then(publish)
    .then(close).then(issue).then(pin).then(badLateDiscovery).expect(not(safe))
  run unknownWriterBlocksCutTest = init.then(prepare).then(publish).then(enter)
    .then(close).then(park).then(unknownWriter).then(idle)
    .expect(safe and not(Host::frozen) and not(Host::s.receipt) and cycle.phase == 0)
  run repeatedRestoreTest = drained.then(reopen).then(restore).then(restore)
    .expect(safe and cycle.restores == 2 and Host::s.callbacks == Set(0))
  run copyBeforeRewriteTest = pinnedStart.then(settleCopy).then(rewriteRoots)
    .then(closeProducers).then(finish).expect(safe)
  run rewriteBeforeCopyTest = pinnedStart.then(rewriteRoots).then(settleCopy)
    .then(closeProducers).then(finish).expect(safe)
  run pendingDebtRetainsPinTest = pinnedStart.then(idle)
    .expect(safe and Host::s.pin and cycle.pending == 1)
  // Concrete source seam: root_round_finish_scan sets DRAINING before weak
  // work and restore. Even a rewritten root view cannot settle that debt.
  run localCompletionIsNotGlobalControlTest = pinnedStart.then(rewriteRoots).then(badEarlyEnd)
    .expect(Host::safe and not(safe))
  run localReopenIsNotGlobalControlTest = pinnedStart.then(badEarlyEnd)
    .then(badReopen).expect(Host::safe and not(safe))
  run omittedProducerClosureControlTest = pinnedStart.then(settleCopy)
    .then(rewriteRoots).then(badEarlyEnd).expect(Host::safe and not(safe))
  run staleEpochControlTest = pinnedStart.then(badStaleEpoch).expect(not(safe))
  run droppedPinControlTest = pinnedStart.then(badDropSourcePin).expect(not(safe))
  run staleReloadControlTest = drained.then(reopen).then(badUseOldAddress)
    .expect(Host::safe and not(safe))
}

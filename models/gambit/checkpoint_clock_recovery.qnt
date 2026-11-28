module checkpoint_clock_recovery {
  import checkpoint_dependency_recovery as D from "./checkpoint_dependency_recovery"
  // A checked cross-boot mapping is an external premise, not a wall-clock guess.
  type Clock = { epoch: int, bound: bool, bypass: bool }
  var clock: Clock
  action init = all {
    clock' = { epoch: 0, bound: true, bypass: false },
    D::dependency' = D::initial(true, true, false, false),
    D::resetProducer,
  }
  action initBypass = all {
    clock' = { epoch: 0, bound: true, bypass: true },
    D::dependency' = D::initial(true, true, false, false),
    D::resetProducer,
  }
  action producerStep = all {
    any { D::leafStep, D::invalidateParent }, clock' = clock,
  }
  action reboot = all {
    Set(3, 4).contains(D::producer.phase), clock.epoch == 0,
    clock' = { ...clock, epoch: 1, bound: false },
    D::producerElapsed, D::dependency' = D::dependency,
  }
  action loseClock = all {
    Set(3, 4).contains(D::producer.phase), clock.bound,
    clock' = { ...clock, bound: false },
    D::keepProducer, D::dependency' = D::dependency,
  }
  // The environment supplies a verified mapping including downtime. No reset.
  action mapClock = all {
    clock.epoch == 1, not(clock.bound), D::producer.quiescent,
    clock' = { ...clock, bound: true },
    D::keepProducer, D::dependency' = D::dependency,
  }
  action recover = all {
    clock.bound or clock.bypass, D::recover, clock' = clock,
  }
  action launch = all {
    clock.bound or clock.bypass, D::launch, clock' = clock,
  }
  action step = any { producerStep, reboot, loseClock, mapClock, recover, launch }
  val safe = D::safe and D::producer.launched.implies(clock.bound)
  action completedCheckpoint = all {
    D::producerStart, D::dependency' = D::dependency, clock' = clock,
  }
  action finishedCheckpoint = all {
    D::producerFinish, D::dependency' = D::dependency, clock' = clock,
  }
  action committedCheckpoint = all {
    D::producerCommit, D::dependency' = D::dependency, clock' = clock,
  }
  action interruptedCheckpoint = all {
    D::producerInterrupt, D::dependency' = D::dependency, clock' = clock,
  }
  run rebootWithoutMappingTest = init.then(completedCheckpoint).then(finishedCheckpoint)
    .then(committedCheckpoint).then(interruptedCheckpoint).then(reboot)
    .then(all { assert(not(clock.bound)), assert(not(D::producer.launched)), assert(safe),
                D::keepProducer, D::dependency' = D::dependency, clock' = clock })
  run verifiedMappingTest = init.then(completedCheckpoint).then(finishedCheckpoint)
    .then(committedCheckpoint).then(interruptedCheckpoint).then(reboot).then(mapClock)
    .then(recover).then(launch)
    .then(all { assert(D::producer.launched), assert(D::producer.actualSpent == 3), assert(safe),
                D::keepProducer, D::dependency' = D::dependency, clock' = clock })
  run expiredMappingTest = init.then(completedCheckpoint).then(finishedCheckpoint)
    .then(committedCheckpoint).then(interruptedCheckpoint).then(reboot)
    .then(all { D::producerElapsed, D::dependency' = D::dependency, clock' = clock })
    .then(mapClock)
    .then(all { assert(not(D::producerAdmissible)), assert(safe),
                D::keepProducer, D::dependency' = D::dependency, clock' = clock })
  run clockBypassControlTest = initBypass.then(completedCheckpoint).then(finishedCheckpoint)
    .then(committedCheckpoint).then(interruptedCheckpoint).then(reboot).then(recover).then(launch)
    .then(all { assert(not(safe)), D::keepProducer,
                D::dependency' = D::dependency, clock' = clock })
  run postReviewClockLossTest = init.then(completedCheckpoint).then(finishedCheckpoint)
    .then(committedCheckpoint).then(interruptedCheckpoint).then(recover).then(loseClock)
    .then(all { assert(not(clock.bound)), assert(not(D::producer.launched)), assert(safe),
                D::keepProducer, D::dependency' = D::dependency, clock' = clock })
}

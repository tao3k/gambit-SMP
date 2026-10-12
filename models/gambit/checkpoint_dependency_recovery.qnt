module checkpoint_dependency_recovery {
  import interrupted_producer_recovery as R from "./interrupted_producer_recovery"
  // Two dependent checkpoints are protocol actors, not a CPU allocation.
  type Dependency = { present: bool, valid: bool, cycle: bool, bypass: bool }
  var dependency: Dependency
  pure def initial(present: bool, valid: bool, cycle: bool, bypass: bool): Dependency = {
    present: present, valid: valid, cycle: cycle, bypass: bypass,
  }
  action init = all {
    dependency' = initial(true, true, false, false), R::s' = R::initial(false, false, false, false),
  }
  action initStale = all {
    dependency' = initial(true, false, false, true), R::s' = R::initial(false, false, false, false),
  }
  action initMissing = all {
    dependency' = initial(false, false, false, true), R::s' = R::initial(false, false, false, false),
  }
  action initCycle = all {
    dependency' = initial(true, true, true, true), R::s' = R::initial(false, false, false, false),
  }
  val dependencyReady = dependency.present and dependency.valid and not(dependency.cycle)
  action leafStep = all {
    any { R::start, R::finish, R::commit, R::interrupt, R::elapsed, R::drift, R::hold },
    dependency' = dependency,
  }
  action invalidateParent = all {
    Set(3, 4).contains(R::s.phase), dependency.valid,
    dependency' = { ...dependency, valid: false }, R::s' = R::s,
  }
  action recover = all {
    dependencyReady or dependency.bypass, R::recover, dependency' = dependency,
  }
  action launch = all {
    dependencyReady or dependency.bypass, R::launch, dependency' = dependency,
  }
  action step = any { leafStep, invalidateParent, recover, launch }
  val safe = R::safe and R::s.launched.implies(dependencyReady)
  run dependencyClosedTest = init
    .then(all { R::start, dependency' = dependency })
    .then(all { R::finish, dependency' = dependency })
    .then(all { R::commit, dependency' = dependency })
    .then(all { R::interrupt, dependency' = dependency }).then(recover).then(launch)
    .then(all { assert(R::s.launched), assert(safe), R::s' = R::s, dependency' = dependency })
  run staleParentControlTest = initStale
    .then(all { R::start, dependency' = dependency })
    .then(all { R::finish, dependency' = dependency })
    .then(all { R::commit, dependency' = dependency })
    .then(all { R::interrupt, dependency' = dependency }).then(recover).then(launch)
    .then(all { assert(not(safe)), R::s' = R::s, dependency' = dependency })
  run missingParentControlTest = initMissing
    .then(all { R::start, dependency' = dependency })
    .then(all { R::finish, dependency' = dependency })
    .then(all { R::commit, dependency' = dependency })
    .then(all { R::interrupt, dependency' = dependency }).then(recover).then(launch)
    .then(all { assert(not(safe)), R::s' = R::s, dependency' = dependency })
  run cycleControlTest = initCycle
    .then(all { R::start, dependency' = dependency })
    .then(all { R::finish, dependency' = dependency })
    .then(all { R::commit, dependency' = dependency })
    .then(all { R::interrupt, dependency' = dependency }).then(recover).then(launch)
    .then(all { assert(not(safe)), R::s' = R::s, dependency' = dependency })
  run postRecoveryParentDriftTest = init
    .then(all { R::start, dependency' = dependency })
    .then(all { R::finish, dependency' = dependency })
    .then(all { R::commit, dependency' = dependency })
    .then(all { R::interrupt, dependency' = dependency }).then(recover).then(invalidateParent)
    .then(all { assert(not(dependencyReady)), assert(safe), R::s' = R::s, dependency' = dependency })
}

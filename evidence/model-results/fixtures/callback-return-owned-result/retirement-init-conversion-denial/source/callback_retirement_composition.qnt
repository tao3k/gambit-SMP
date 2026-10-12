module callback_retirement_composition {
  import callback_return_owned_result as C from "./callback_return_owned_result"
  import resize_saved_stack_retirement_isolated as R from "./resize_saved_stack_retirement_isolated"
  // Origin 1 is the removable worker, 0 survives. These are semantic roles.
  type Life = { policy: int, marker: bool, cFrame: bool, converted: bool,
    originGeneration: int, slotGeneration: int, quiesced: bool, reused: bool }
  var life: Life
  pure def initial(policy: int): Life = {
    policy: policy, marker: true, cFrame: true, converted: false,
    originGeneration: 0, slotGeneration: 0, quiesced: false, reused: false
  }
  action initialize(policy: int): bool = {
    nondet value = Set(0, 1, 2).oneOf()
    all {
      life' = initial(policy), R::retirementState' = R::initial("copy-before-retire"),
      C::s' = { policy: 0, origin: 1, current: 1, phase: 0, value: value,
        result: value, saved: -1, rooted: false, epoch: 0, savedEpoch: 0,
        migration: true },
    }
  }
  action initFixed = initialize(0)
  action initHeapOnly = initialize(1)
  action initEarlyMarkerKill = initialize(2)
  action initIdOnlyReuse = initialize(3)
  action initWaitInsideCollective = initialize(4)

  // Explicit abstraction interface: migration captures and detaches execution.
  // Native macro/queue ordering still needs refinement; this is not an atomic
  // claim about the implementation's THREAD_SAVE and queue publication.
  action migrateBody = all {
    not(life.quiesced), C::bodyReturn, R::capture, life' = life,
  }
  action route = all {
    not(life.quiesced), C::routeToOrigin, R::detachExecution, life' = life,
  }
  action callbackStep = all {
    not(life.quiesced),
    any { C::collect, C::resume, C::restore }, R::retirementState' = R::retirementState, life' = life,
  }
  action savedFrameStep = all {
    any { R::publish, R::beginScan, R::copyFrames },
    C::s' = C::s, life' = life,
  }
  action convertResult = all {
    C::terminal, not(life.converted), not(life.quiesced),
    life' = { ...life, converted: true }, C::s' = C::s, R::retirementState' = R::retirementState,
  }
  // Normal SFUN exit kills the marker after conversion, not on migration.
  action killMarker = all {
    life.marker, life.converted or life.policy == 2,
    life' = { ...life, marker: false, cFrame: false }, C::s' = C::s, R::retirementState' = R::retirementState,
  }
  // Closing before the collective is a design hypothesis. The real runtime
  // has no equivalent proven C-frame admission/drain witness yet.
  action enterCollective = all {
    not(life.quiesced), R::retirementState.published,
    not(life.cFrame) or Set(1, 3, 4).contains(life.policy),
    life' = { ...life, quiesced: true }, C::s' = C::s, R::retirementState' = R::retirementState,
  }
  action retire = all {
    life.quiesced, not(life.cFrame) or Set(1, 3).contains(life.policy),
    R::retire, C::s' = C::s, life' = life,
  }
  action releaseStorage = all { R::releaseStorage, C::s' = C::s, life' = life }
  action resizeReturn = all { R::returnCaller, C::s' = C::s, life' = life }
  action reuseId = all {
    life.policy == 3, R::retirementState.released, not(life.reused),
    life' = { ...life, reused: true, slotGeneration: 1, quiesced: false },
    C::s' = C::s, R::retirementState' = R::retirementState,
  }
  val terminal = R::retirementState.returned and life.converted and not(life.marker)
  action finished = all { terminal, C::s' = C::s, R::retirementState' = R::retirementState, life' = life }
  action step = any { migrateBody, route, callbackStep, savedFrameStep,
    convertResult, killMarker, enterCollective, retire, releaseStorage,
    resizeReturn, reuseId, finished }

  val ownerAlive = not(life.cFrame) or not(R::retirementState.retired)
  val markerLifetime = not(life.marker).implies(life.converted)
  val ownerGeneration = (C::s.phase >= 4 and life.cFrame)
    .implies(life.originGeneration == life.slotGeneration)
  val progressEnabled = terminal or enabled(step)
  val safe = C::safe and R::safe and ownerAlive and markerLifetime
    and ownerGeneration and progressEnabled
  temporal completion = weakFair(step, Set((C::s, R::retirementState, life)))
    .implies(eventually(terminal))
}

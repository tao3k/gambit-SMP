module vm_constructor_same_storage_retry {
  import pstate_setup_transaction as P from "./pstate_setup_transaction"
  // A private non-root VM. Memory/OS constructor callees unwind their own
  // incomplete prefixes; destructors return and direct users are quiescent.
  // The real EMFILE experiment covers only processor failure at OS stage 2.
  // Publication failure means catch-up allocation, not terminal registry seal.
  type Retry = { policy: int, failure: str, phase: str, owned: Set[int],
    slot: int, attempt: int, restored: bool, linked: bool, count: int,
    invalidRetry: bool, setupCalls: int, setupVisits: Set[int], interruptRetained: bool }
  var r: Retry
  pure def initial(policy: int, failure: str): Retry = {
    policy: policy, failure: failure, phase: "prepare", owned: Set(),
    slot: 0, attempt: 0, restored: false, linked: false, count: 0,
    invalidRetry: false, setupCalls: 0, setupVisits: Set(),
    interruptRetained: false,
  }
  action init = {
    nondet failure = Set("memory", "processor", "publication-allocation", "none").oneOf()
    nondet stage = Set(1, 2, 3, 4, 5).oneOf()
    all { r' = initial(0, failure),
      P::s' = P::initialState(0, false, if (failure == "processor") stage else 0) }
  }
  action initLeakedOuter = all {
    r' = initial(1, "processor"), P::s' = P::initialState(0, false, 2),
  }
  action initWrongStorage = all {
    r' = initial(2, "processor"), P::s' = P::initialState(0, false, 2),
  }
  action initPrematureRetry = all {
    r' = initial(3, "processor"), P::s' = P::initialState(0, false, 2),
  }
  action initRepeatedWork = all {
    r' = initial(4, "processor"), P::s' = P::initialState(0, false, 2),
  }
  action prepareVM = all {
    r.phase == "prepare", P::s' = P::s,
    // VM memory failure already removed its own resources and VM OS prefix.
    r' = { ...r, owned: if (r.failure == "memory") Set(0) else Set(0, 1, 2),
      phase: if (r.failure == "memory") "outer-rollback" else "processor" },
  }
  action processorStep = all {
    r.phase == "processor", not(P::terminal), P::step,
    r' = if (P::s.phase < 5) { ...r,
      setupCalls: r.setupCalls + (if (r.policy == 4) 2 else 1),
      setupVisits: r.setupVisits.union(Set(r.attempt * 5 + P::s.phase)),
      interruptRetained: r.interruptRetained or P::s.intr }
      else { ...r, interruptRetained: r.interruptRetained or P::s.intr },
  }
  action receiveProcessor = all {
    r.phase == "processor", P::terminal, P::s' = P::s,
    r' = { ...r, phase: if (P::s.phase == 7) "outer-rollback" else "publish" },
  }
  action publish = all {
    r.phase == "publish",
    P::s' = if (r.failure == "publication-allocation") { ...P::s, phase: 6 } else P::s,
    r' = if (r.failure == "publication-allocation") { ...r, phase: "processor-abort" }
      else { ...r, phase: "running", count: 1, linked: true },
  }
  action abortProcessor = all {
    r.phase == "processor-abort", not(P::terminal),
    any { P::planRollback, P::releaseOne, P::rollbackDone },
    r' = { ...r, interruptRetained: r.interruptRetained or P::s.intr },
  }
  action processorAborted = all {
    r.phase == "processor-abort", P::s.phase == 7, P::s' = P::s,
    r' = { ...r, phase: "outer-rollback" },
  }
  action releaseOuter = {
    nondet resource = r.owned.oneOf()
    all {
      r.phase == "outer-rollback", r.policy != 1,
      r.owned.forall(other => other <= resource), P::s' = P::s,
      r' = { ...r, owned: r.owned.exclude(Set(resource)) },
    }
  }
  action returnFailure = all {
    r.phase == "outer-rollback",
    (r.owned == Set() and not(r.interruptRetained)) or r.policy == 1,
    P::s' = P::s, r' = { ...r, phase: "error" },
  }
  // cleanup_interrupts_pstate drains queued work; only the final outer
  // cleanup_interrupt_resources_pstate destroys the retained mutex.
  action releaseInterrupt = all {
    r.phase == "outer-rollback", r.owned == Set(), r.interruptRetained,
    P::s' = P::s, r' = { ...r, interruptRetained: false },
  }
  // Restoring the external resource is a caller observation, not a property
  // manufactured by setup. It does not reset or reallocate the VM object.
  action restoreResource = all {
    r.phase == "error", not(r.restored), P::s' = P::s,
    r' = { ...r, restored: true },
  }
  action retry = all {
    r.attempt == 0, r.restored or r.policy == 3,
    r.phase == "error" or (r.policy == 3 and r.phase == "outer-rollback"),
    P::s' = P::initialState(0, false, 0),
    r' = { ...r, phase: "prepare", failure: "none", attempt: 1,
      slot: if (r.policy == 2) 1 else r.slot,
      invalidRetry: r.invalidRetry or r.owned != Set() or r.linked or
        r.count != 0 or r.interruptRetained or not(r.restored),
      owned: Set(), interruptRetained: false },
  }
  val terminal = r.phase == "running"
  action finished = all { terminal, r' = r, P::s' = P::s }
  action step = any { prepareVM, processorStep, receiveProcessor, publish,
    abortProcessor, processorAborted, releaseOuter, releaseInterrupt, returnFailure,
    restoreResource, retry, finished }
  val noProcessorResources = not(P::s.intr) and not(P::s.os) and
    not(P::s.mem) and not(P::s.mut) and not(P::s.cv)
  val errorUnpublished = r.phase != "error" or
    (r.count == 0 and not(r.linked) and r.owned == Set() and noProcessorResources and
      not(r.interruptRetained))
  val sameStorage = r.slot == 0 and not(r.invalidRetry)
  val retryOwnershipSafe = not(r.invalidRetry)
  val publicationSafe = not(r.linked) or
    (r.phase == "running" and r.count == 1 and P::s.phase == 8 and P::safe and
      r.owned == Set(0, 1, 2))
  // Cumulative setup visits across attempts, never reset at retry. The five
  // semantic setup stages are not a machine processor/concurrency limit.
  val workBound = r.setupCalls == r.setupVisits.size() and
    r.setupCalls <= 5 * (r.attempt + 1)
  val contract = errorUnpublished and sameStorage and publicationSafe and
    P::safe and workBound
  temporal progress = weakFair(step, Set((r, P::s))).implies(eventually(terminal))
  action initNativeOSFailure = all {
    r' = initial(0, "processor"), P::s' = P::initialState(0, false, 2),
  }
  run nativeOSFailureSameStorageRetryTest = initNativeOSFailure.then(prepareVM)
    .then(processorStep).then(processorStep).then(processorStep)
    .then(processorStep).then(processorStep).then(receiveProcessor)
    .then(releaseOuter).then(releaseOuter).then(releaseOuter)
    .then(releaseInterrupt).then(returnFailure)
    .then(all { assert(contract), assert(noProcessorResources), r' = r, P::s' = P::s })
    .then(restoreResource).then(retry).then(prepareVM)
    .then(processorStep).then(processorStep).then(processorStep)
    .then(processorStep).then(processorStep).then(processorStep)
    .then(receiveProcessor).then(publish)
    .then(all { assert(contract), assert(terminal), assert(r.attempt == 1),
      assert(r.slot == 0), assert(r.setupCalls == 7), r' = r, P::s' = P::s })
  run redundantSetupControlTest = initRepeatedWork.then(prepareVM).then(processorStep)
    .then(all { assert(not(workBound)), r' = r, P::s' = P::s })
}

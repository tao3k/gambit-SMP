module resize_saved_stack_retirement_isolated {
  // One saved continuation and its donor storage: a design refinement bound.
  type State = { policy: str, saved: bool, executing: bool,
    published: bool, heapFrame: bool, donorStorage: bool,
    scanning: bool, retired: bool, released: bool, returned: bool }
  var retirementState: State
  pure def initial(policy: str): State = {
    policy: policy, saved: false, executing: true, published: false,
    heapFrame: false, donorStorage: true, scanning: false,
    retired: false, released: false, returned: false,
  }
  action initFixed = retirementState' = initial("copy-before-retire")
  action initQueueOnly = retirementState' = initial("queue-only")
  action initPublishFirst = retirementState' = initial("publish-first")
  // THREAD_SAVE can leave a raw stack-frame address in the continuation.
  action capture = all { not(retirementState.saved), retirementState' = { ...retirementState, saved: true } }
  action detachExecution = all { retirementState.saved, retirementState.executing,
    retirementState' = { ...retirementState, executing: false } }
  action publish = all { retirementState.saved, not(retirementState.published),
    not(retirementState.executing) or retirementState.policy == "publish-first",
    retirementState' = { ...retirementState, published: true } }
  // Root reachability and exclusive backing-storage ownership are assumptions
  // requiring native/source refinement; collection itself is not an atomic
  // publish-and-retire operation.
  action beginScan = all { retirementState.saved, not(retirementState.heapFrame), not(retirementState.scanning),
    retirementState.donorStorage, retirementState' = { ...retirementState, scanning: true } }
  action copyFrames = all { retirementState.scanning, retirementState.donorStorage,
    retirementState' = { ...retirementState, scanning: false, heapFrame: true } }
  action retire = all { retirementState.published, not(retirementState.executing), not(retirementState.retired),
    retirementState.heapFrame or retirementState.policy == "queue-only",
    retirementState' = { ...retirementState, retired: true } }
  action releaseStorage = all { retirementState.retired, not(retirementState.scanning), not(retirementState.released),
    retirementState' = { ...retirementState, donorStorage: false, released: true } }
  action returnCaller = all { retirementState.released, retirementState.heapFrame, not(retirementState.returned),
    retirementState' = { ...retirementState, returned: true } }
  val continuationStorageSafe = not(retirementState.saved) or retirementState.heapFrame or retirementState.donorStorage
  val exclusiveExecution = not(retirementState.published) or not(retirementState.executing)
  val scannerStorageSafe = not(retirementState.scanning) or retirementState.donorStorage
  val safe = continuationStorageSafe and exclusiveExecution and scannerStorageSafe
  action finished = all { retirementState.returned, retirementState' = retirementState }
  action step = any { capture, detachExecution, publish, beginScan,
    copyFrames, retire, releaseStorage, returnCaller, finished }
  temporal completion = weakFair(step, Set(retirementState)).implies(eventually(retirementState.returned))
}

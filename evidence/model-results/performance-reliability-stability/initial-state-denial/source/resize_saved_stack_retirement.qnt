module resize_saved_stack_retirement {
  // One saved continuation and its donor storage: a design refinement bound.
  type State = { policy: str, saved: bool, executing: bool,
    published: bool, heapFrame: bool, donorStorage: bool,
    scanning: bool, retired: bool, released: bool, returned: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, saved: false, executing: true, published: false,
    heapFrame: false, donorStorage: true, scanning: false,
    retired: false, released: false, returned: false,
  }
  action initFixed = s' = initial("copy-before-retire")
  action initQueueOnly = s' = initial("queue-only")
  action initPublishFirst = s' = initial("publish-first")
  // THREAD_SAVE can leave a raw stack-frame address in the continuation.
  action capture = all { not(s.saved), s' = { ...s, saved: true } }
  action detachExecution = all { s.saved, s.executing,
    s' = { ...s, executing: false } }
  action publish = all { s.saved, not(s.published),
    not(s.executing) or s.policy == "publish-first",
    s' = { ...s, published: true } }
  // Root reachability and exclusive backing-storage ownership are assumptions
  // requiring native/source refinement; collection itself is not an atomic
  // publish-and-retire operation.
  action beginScan = all { s.saved, not(s.heapFrame), not(s.scanning),
    s.donorStorage, s' = { ...s, scanning: true } }
  action copyFrames = all { s.scanning, s.donorStorage,
    s' = { ...s, scanning: false, heapFrame: true } }
  action retire = all { s.published, not(s.executing), not(s.retired),
    s.heapFrame or s.policy == "queue-only",
    s' = { ...s, retired: true } }
  action releaseStorage = all { s.retired, not(s.scanning), not(s.released),
    s' = { ...s, donorStorage: false, released: true } }
  action returnCaller = all { s.released, s.heapFrame, not(s.returned),
    s' = { ...s, returned: true } }
  val continuationStorageSafe = not(s.saved) or s.heapFrame or s.donorStorage
  val exclusiveExecution = not(s.published) or not(s.executing)
  val scannerStorageSafe = not(s.scanning) or s.donorStorage
  val safe = continuationStorageSafe and exclusiveExecution and scannerStorageSafe
  action finished = all { s.returned, s' = s }
  action step = any { capture, detachExecution, publish, beginScan,
    copyFrames, retire, releaseStorage, returnCaller, finished }
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.returned))
}

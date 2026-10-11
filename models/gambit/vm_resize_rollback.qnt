module vm_resize_rollback {
  // Grow 1 -> 4 under the VM-wide synchronization operation. Setup may fail.
  // Counts abstract consecutive prepared processor IDs; failed setup is not
  // eligible for the outer cleanup loop. GC resumes only after the operation.
  var cleanupRepair: bool
  var targetRepair: bool
  var initialized: int
  var active: int
  var target: int
  var phase: int
  var failed: int
  var rollback: int
  var invalidCleanup: bool
  action initOld = all {
    cleanupRepair' = false, targetRepair' = false, initialized' = 1,
    active' = 1, target' = 4, phase' = 0, failed' = 0, rollback' = 0,
    invalidCleanup' = false,
  }
  action initStaleTarget = all {
    cleanupRepair' = true, targetRepair' = false, initialized' = 1,
    active' = 1, target' = 4, phase' = 0, failed' = 0, rollback' = 0,
    invalidCleanup' = false,
  }
  action initFixed = all {
    cleanupRepair' = true, targetRepair' = true, initialized' = 1,
    active' = 1, target' = 4, phase' = 0, failed' = 0, rollback' = 0,
    invalidCleanup' = false,
  }
  action setup(success: bool): bool = all {
    phase == 0, initialized < 4,
    initialized' = if (success) initialized + 1 else initialized,
    phase' = if (success) 0 else 1,
    failed' = if (success) failed else initialized,
    rollback' = if (success) rollback else initialized - 1,
    cleanupRepair' = cleanupRepair, targetRepair' = targetRepair,
    active' = active, target' = target, invalidCleanup' = invalidCleanup,
  }
  action cleanup = {
    val pointer = if (cleanupRepair) rollback else failed
    all {
      phase == 1, rollback >= 1,
      invalidCleanup' = (invalidCleanup or pointer != initialized - 1),
      initialized' = if (pointer == initialized - 1) initialized - 1 else initialized,
      rollback' = rollback - 1,
      cleanupRepair' = cleanupRepair, targetRepair' = targetRepair,
      active' = active, target' = target, phase' = phase, failed' = failed,
    }
  }
  action returnFailure = all {
    phase == 1, rollback == 0, phase' = 2,
    target' = if (targetRepair) active else target,
    cleanupRepair' = cleanupRepair, targetRepair' = targetRepair,
    initialized' = initialized, active' = active, failed' = failed,
    rollback' = rollback, invalidCleanup' = invalidCleanup,
  }
  action publish = all {
    phase == 0, initialized == 4, active' = 4, phase' = 2,
    cleanupRepair' = cleanupRepair, targetRepair' = targetRepair,
    initialized' = initialized, target' = target, failed' = failed,
    rollback' = rollback, invalidCleanup' = invalidCleanup,
  }
  action idle = all {
    phase == 2, cleanupRepair' = cleanupRepair, targetRepair' = targetRepair,
    initialized' = initialized, active' = active, target' = target,
    phase' = phase, failed' = failed, rollback' = rollback,
    invalidCleanup' = invalidCleanup,
  }
  action step = any { setup(true), setup(false), cleanup, returnFailure, publish, idle }
  val cleanupSafe = not(invalidCleanup)
  val targetSafe = phase != 2 or target == active
  val gcPopulationSafe = phase != 2 or initialized == active
  val safe = cleanupSafe and targetSafe and gcPopulationSafe
}

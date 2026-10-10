module gc_stack_lifecycle {
  var repair: bool
  var phase: int
  var scenario: int
  var marker: int
  var invalidWrite: bool
  var currentTouched: bool
  var restored: int
  action initOld = all {
    repair' = false, phase' = 0, scenario' = -1, marker' = 9,
    invalidWrite' = false, currentTouched' = false, restored' = 0,
  }
  action initFixed = all {
    repair' = true, phase' = 0, scenario' = -1, marker' = 9,
    invalidWrite' = false, currentTouched' = false, restored' = 0,
  }
  action choose(which: int): bool = all {
    phase == 0, phase' = 1, scenario' = which, repair' = repair,
    marker' = marker, invalidWrite' = invalidWrite,
    currentTouched' = currentTouched, restored' = restored,
  }
  // 0: processor setup before stack_break assignment; 1: nonempty copy;
  // 2: fresh break frame. Old includes the locally observed wrong-target edit.
  action writeMarker = all {
    phase == 1, phase' = 2, scenario' = scenario, repair' = repair,
    marker' = if (repair) 0 else marker,
    invalidWrite' = (scenario == 0 and not(repair)),
    currentTouched' = (scenario == 1 and not(repair)), restored' = restored,
  }
  action restore = all {
    phase == 2, phase' = 3, scenario' = scenario, repair' = repair,
    restored' = marker, marker' = marker, invalidWrite' = invalidWrite,
    currentTouched' = currentTouched,
  }
  action idle = all {
    phase == 3, phase' = phase, scenario' = scenario, repair' = repair,
    restored' = restored, marker' = marker, invalidWrite' = invalidWrite,
    currentTouched' = currentTouched,
  }
  action step = any { choose(0), choose(1), choose(2), writeMarker, restore, idle }
  val safe = not(invalidWrite) and not(currentTouched) and (phase < 3 or restored == 0)
}

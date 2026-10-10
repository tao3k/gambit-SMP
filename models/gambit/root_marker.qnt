module root_marker {
  var repair: bool
  var phase: int
  var localAddress: int
  var objectAddress: int
  var protected: bool
  var markerAddress: int

  action initOld = all {
    repair' = false, phase' = 0, localAddress' = 1,
    objectAddress' = 1, protected' = false, markerAddress' = 0,
  }
  action initFixed = all {
    repair' = true, phase' = 0, localAddress' = 1,
    objectAddress' = 1, protected' = false, markerAddress' = 0,
  }
  // PR 1010 saves the C argument before ___make_vector may collect.
  action save = all {
    phase == 0, phase' = 1, protected' = repair,
    repair' = repair, localAddress' = localAddress,
    objectAddress' = objectAddress, markerAddress' = markerAddress,
  }
  action allocate(collect: bool): bool = all {
    phase == 1, phase' = 2,
    objectAddress' = if (collect) 2 else objectAddress,
    repair' = repair, protected' = protected,
    localAddress' = localAddress, markerAddress' = markerAddress,
  }
  // Restore reads the relocated root, not the stale C local.
  action restore = all {
    phase == 2, phase' = 3,
    localAddress' = if (protected) objectAddress else localAddress,
    protected' = false, repair' = repair,
    objectAddress' = objectAddress, markerAddress' = markerAddress,
  }
  action install = all {
    phase == 3, phase' = 4, markerAddress' = localAddress,
    repair' = repair, localAddress' = localAddress,
    objectAddress' = objectAddress, protected' = protected,
  }
  action idle = all {
    phase == 4, phase' = phase, markerAddress' = markerAddress,
    repair' = repair, localAddress' = localAddress,
    objectAddress' = objectAddress, protected' = protected,
  }
  action step = any { save, allocate(false), allocate(true), restore, install, idle }
  val safe = (phase < 4) or (markerAddress == objectAddress)
}

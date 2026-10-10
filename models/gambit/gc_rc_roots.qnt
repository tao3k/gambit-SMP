module gc_rc_roots {
  var repair: bool
  var phase: int
  var marked0: bool
  var marked1: bool
  var retained0: bool
  var retained1: bool
  action initOld = all {
    repair' = false, phase' = 0, marked0' = false, marked1' = false,
    retained0' = true, retained1' = true,
  }
  action initFixed = all {
    repair' = true, phase' = 0, marked0' = false, marked1' = false,
    retained0' = true, retained1' = true,
  }
  // rc_head is per processor, not a VM-global list.
  action markRoots = all {
    phase == 0, phase' = 1, marked0' = true, marked1' = repair,
    retained0' = retained0, retained1' = retained1, repair' = repair,
  }
  action collect = all {
    phase == 1, phase' = 2, retained0' = marked0, retained1' = marked1,
    marked0' = marked0, marked1' = marked1, repair' = repair,
  }
  action idle = all {
    phase == 2, phase' = phase, retained0' = retained0, retained1' = retained1,
    marked0' = marked0, marked1' = marked1, repair' = repair,
  }
  action step = any { markRoots, collect, idle }
  val safe = retained0 and retained1
}

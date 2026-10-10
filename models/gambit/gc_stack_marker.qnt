module gc_stack_marker {
  var repair: bool
  var phase: int
  var breakMarker: int
  var currentMarker: int
  var restoredSection: int
  action initOld = all {
    repair' = false, phase' = 0, breakMarker' = 9,
    currentMarker' = 9, restoredSection' = 0,
  }
  action initFixed = all {
    repair' = true, phase' = 0, breakMarker' = 9,
    currentMarker' = 9, restoredSection' = 0,
  }
  // Non-empty copied stack: current frame and first break frame differ.
  action copyStack = all {
    phase == 0, phase' = 1,
    breakMarker' = if (repair) 0 else breakMarker,
    currentMarker' = if (repair) currentMarker else 0,
    repair' = repair, restoredSection' = restoredSection,
  }
  action undo = all {
    phase == 1, phase' = 2, restoredSection' = breakMarker,
    repair' = repair, breakMarker' = breakMarker, currentMarker' = currentMarker,
  }
  action idle = all {
    phase == 2, phase' = phase, restoredSection' = restoredSection,
    repair' = repair, breakMarker' = breakMarker, currentMarker' = currentMarker,
  }
  action step = any { copyStack, undo, idle }
  val safe = restoredSection == 0
}

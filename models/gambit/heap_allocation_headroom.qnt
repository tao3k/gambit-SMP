module heap_allocation_headroom {
  // Exact section/word units from mem.c, not a claim about every GC failure.
  // A small live heap still assigns one stack and one local heap per processor.
  val sectionWords = 131072
  val reserveWords = 204808
  var repair: bool
  var processors: int
  var sections: int
  var assigned: int
  var phase: int

  action initOld = all {
    repair' = false, processors' = 1, sections' = 9, assigned' = 0, phase' = 0,
  }
  action initFixed = all {
    repair' = true, processors' = 1, sections' = 9, assigned' = 0, phase' = 0,
  }
  action collect(p: int): bool = {
    val base = 2 * p
    val headroom = (reserveWords + sectionWords - 1) / sectionWords + 1
    val minimum = base + (if (repair) headroom else 0)
    all {
      phase == 0, processors' = p, assigned' = base, phase' = 1,
      sections' = if (minimum > 9) minimum else 9, repair' = repair,
    }
  }
  action idle = all {
    phase == 1, phase' = phase, processors' = processors, assigned' = assigned,
    sections' = sections, repair' = repair,
  }
  action step = any { collect(1), collect(2), collect(4), idle }
  val sectionFloor = sections >= 2 * processors
  val allocationFree = (sections - assigned) * sectionWords - reserveWords
  val safe = sectionFloor and (phase != 1 or allocationFree >= sectionWords)
}

module heap_floor {
  var repair: bool
  var processors: int
  var sections: int
  var phase: int

  action initOld = all {
    repair' = false, processors' = 1, sections' = 2, phase' = 0,
  }
  action initFixed = all {
    repair' = true, processors' = 1, sections' = 2, phase' = 0,
  }
  // Two sections per processor is a scale abstraction, not a byte budget.
  // The old unlimited-max-heap path omitted the processor-count floor.
  action resize(p: int): bool = all {
    phase == 0, processors' = p, phase' = 1,
    sections' = if (repair) 2 * p else 2, repair' = repair,
  }
  action idle = all {
    phase == 1, phase' = phase, processors' = processors,
    sections' = sections, repair' = repair,
  }
  action step = any { resize(1), resize(2), resize(4), idle }
  val safe = sections >= 2 * processors
}

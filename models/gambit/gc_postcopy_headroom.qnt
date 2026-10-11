module gc_postcopy_headroom {
  // Admission floor after copying, not a full collector or timing proof.
  // Copying may assign another section beyond the initial two per processor.
  val sectionWords = 131072
  val reserveWords = 204808
  val headroom = (reserveWords + sectionWords - 1) / sectionWords + 1
  var repair: bool
  var processors: int
  var assigned: int
  var sections: int
  var cap: int
  var phase: int

  action initOld = all {
    repair' = false, processors' = 1, assigned' = 0,
    sections' = 9, cap' = 0, phase' = 0,
  }
  action initFixed = all {
    repair' = true, processors' = 1, assigned' = 0,
    sections' = 9, cap' = 0, phase' = 0,
  }
  action collect(p: int, extra: int, limited: bool): bool = {
    val copied = 2 * p + extra
    val initialFloor = 2 * p + headroom
    val floor = if (repair and copied + headroom > initialFloor)
                copied + headroom else initialFloor
    val target = if (floor > 9) floor else 9
    val limit = if (limited) 2 * p + headroom else 0
    all {
      phase == 0, repair' = repair, processors' = p, assigned' = copied,
      sections' = if (limit > 0 and target > limit) limit else target,
      cap' = limit, phase' = 1,
    }
  }
  action idle = all {
    phase == 1, repair' = repair, processors' = processors,
    assigned' = assigned, sections' = sections, cap' = cap, phase' = phase,
  }
  action step = {
    nondet p = Set(1, 2, 4, 12).oneOf()
    nondet extra = Set(0, 1, 2).oneOf()
    nondet limited = Set(false, true).oneOf()
    any { collect(p, extra, limited), idle }
  }
  val free = (sections - assigned) * sectionWords - reserveWords
  val safe = phase == 0 or all {
    sections >= assigned,
    cap == 0 implies free >= sectionWords,
    cap > 0 implies sections <= cap,
  }
}

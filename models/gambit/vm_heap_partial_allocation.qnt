module vm_heap_partial_allocation {
  // Fresh constructor only: one descriptor and at most two heap sections.
  // adjust_msections deliberately returns partial ownership, not an error code.
  type State = { policy: str, failAt: int, phase: str, table: bool,
    sections: Set[int], nbSections: int, badOrder: bool }
  var s: State
  pure def initial(policy: str, failAt: int): State = {
    policy: policy, failAt: failAt, phase: "table", table: false,
    sections: Set(), nbSections: 0, badOrder: false,
  }
  action initOld = s' = initial("legacy", 1)
  action initPartial = s' = initial("legacy", 2)
  action initSkipZero = s' = initial("skip-zero", 1)
  action initTableFirst = s' = initial("table-first", 2)
  action initFixed = {
    // 0: descriptor failure; 1/2: first/second section failure; 3: success.
    nondet failAt = Set(0, 1, 2, 3).oneOf()
    s' = initial("fixed", failAt)
  }
  action allocateTable = all {
    s.phase == "table",
    s' = if (s.failAt == 0) { ...s, phase: "helper-return" }
      else { ...s, phase: "grow", table: true },
  }
  action allocateSection = all {
    s.phase == "grow", s.nbSections < 2,
    s' = if (s.failAt == s.nbSections + 1) { ...s, phase: "helper-return" }
      else { ...s, nbSections: s.nbSections + 1,
        sections: s.sections.union(Set(s.nbSections)),
        phase: if (s.nbSections + 1 == 2) "helper-return" else "grow" },
  }
  action callerCheck = all {
    s.phase == "helper-return",
    s' = if (s.table and s.nbSections == 2) { ...s, phase: "success" }
      else if (s.policy == "legacy" or
               (s.policy == "skip-zero" and s.nbSections == 0))
        { ...s, phase: "error" }
      else { ...s, phase: "rollback" },
  }
  action releaseSection = all {
    s.phase == "rollback", s.sections.size() > 0,
    s.policy != "table-first" or not(s.table),
    // free_msections visits every live section before freeing its descriptor.
    nondet section = s.sections.oneOf()
    s' = { ...s, sections: s.sections.exclude(Set(section)),
      badOrder: s.badOrder or not(s.table) },
  }
  action releaseTable = all {
    s.phase == "rollback", s.table,
    s.sections.size() == 0 or s.policy == "table-first",
    s' = { ...s, table: false,
      badOrder: s.badOrder or s.sections.size() > 0 },
  }
  action errorReturn = all {
    s.phase == "rollback", not(s.table), s.sections.size() == 0,
    s' = { ...s, phase: "error" },
  }
  val terminal = Set("success", "error").contains(s.phase)
  action finished = all { terminal, s' = s }
  action step = any { allocateTable, allocateSection, callerCheck,
    releaseSection, releaseTable, errorReturn, finished }
  val helperShapeSafe = s.phase != "helper-return" or
    (s.nbSections == s.sections.size() and
      (s.sections.size() == 0 or s.table))
  val failureSafe = s.phase != "error" or
    (not(s.table) and s.sections.size() == 0)
  val zeroDescriptorSafe = s.phase != "error" or s.nbSections != 0 or not(s.table)
  val descriptorLifetimeSafe = not(s.badOrder)
  val successSafe = s.phase != "success" or
    (s.table and s.sections == Set(0, 1) and s.nbSections == 2)
  val safe = helperShapeSafe and failureSafe and zeroDescriptorSafe and descriptorLifetimeSafe and successSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

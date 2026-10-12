module vm_mem_setup_transaction {
  // Descriptor ownership is separate from empty, partial or complete sections.
  // P0 memory setup happens later; its destructor is not a VM rollback primitive.
  // Integer resource identities follow the shared counterexample format.
  pure val rMutex = 0
  pure val rCond = 1
  pure val rRoots = 2
  pure val rSection0 = 3
  pure val rSection1 = 4
  pure val rTable = 5
  pure val rSpinMisc = 6
  pure val rSpinAlloc = 7
  pure val spinResources = Set(rSpinMisc, rSpinAlloc)
  pure val heapResources = Set(rTable, rSection0, rSection1)
  type State = { policy: str, failAt: str, threaded: bool, multi: bool,
    spinBackend: str, spinReady: bool,
    phase: str, owned: Set[int], linked: bool, listLock: bool,
    p0Ready: bool, badP0: bool, badList: bool, badDestroy: bool }
  var s: State
  pure def initial(policy: str, failAt: str, threaded: bool, multi: bool, spinBackend: str): State = {
    policy: policy, failAt: failAt, threaded: threaded, multi: multi,
    spinBackend: spinBackend, spinReady: false,
    phase: "spin", owned: Set(), linked: false, listLock: false,
    p0Ready: false, badP0: false, badList: false, badDestroy: false,
  }
  action initOld = s' = initial("legacy", "scanMutex", true, true, "ticket")
  action initRoots = s' = initial("legacy", "roots", true, true, "ticket")
  action initSections = s' = initial("legacy", "sections-partial", true, true, "ticket")
  action initBlanket = s' = initial("blanket", "sections-partial", true, true, "ticket")
  action initUnlocked = s' = initial("unlocked", "sections-partial", true, true, "ticket")
  action initInvalid = s' = initial("blind-destroy", "scanCond", true, true, "ticket")
  action initFixed = {
    nondet threaded = Set(false, true).oneOf()
    nondet multi = Set(false, true).oneOf()
    nondet spinBackend = Set("ticket", "posix-mutex", "void-mutex").oneOf()
    nondet failAt = Set("none", "spin", "scanMutex", "scanCond", "roots",
      "sections-table", "sections-empty", "sections-partial").oneOf()
    s' = initial("fixed", failAt, threaded, multi, spinBackend)
  }
  action spin = all {
    s.phase == "spin",
    // Proposed checked prefix contract: a failed prefix has already unwound itself.
    s' = if (s.threaded and s.spinBackend == "posix-mutex" and s.failAt == "spin")
      { ...s, phase: "rollback" }
      else { ...s, phase: "mutex", spinReady: s.threaded,
        owned: if (s.threaded and s.spinBackend != "ticket") spinResources else Set() },
  }
  action mutex = all {
    s.phase == "mutex",
    s' = if (not(s.threaded)) { ...s, phase: "roots" }
      else if (s.failAt == "scanMutex") { ...s,
        phase: if (s.policy == "legacy") "cond" else "rollback" }
      else { ...s, phase: "cond", owned: s.owned.union(Set(rMutex)) },
  }
  action cond = all {
    s.phase == "cond",
    s' = if (s.failAt == "scanCond") { ...s,
        phase: if (s.policy == "legacy") "roots" else "rollback" }
      else { ...s, phase: "roots", owned: s.owned.union(Set(rCond)) },
  }
  action roots = all {
    s.phase == "roots",
    // ensure_glo_segment failure already frees the partial root tables.
    s' = if (not(s.multi)) { ...s, phase: "table" }
      else if (s.failAt == "roots") { ...s,
        phase: if (s.policy == "legacy") "error" else "rollback" }
      else { ...s, phase: "link", owned: s.owned.union(Set(rRoots)), listLock: true },
  }
  action link = all {
    s.phase == "link", s.listLock,
    s' = { ...s, phase: "table", linked: true, listLock: false },
  }
  action table = all {
    s.phase == "table",
    s' = if (s.failAt == "sections-table") { ...s,
        phase: if (s.policy == "legacy") "error" else "rollback" }
      else { ...s, phase: "section0", owned: s.owned.union(Set(rTable)) },
  }
  action section0 = all {
    s.phase == "section0",
    s' = if (s.failAt == "sections-empty") { ...s,
        phase: if (s.policy == "legacy") "error" else "rollback" }
      else { ...s, phase: "section1", owned: s.owned.union(Set(rSection0)) },
  }
  action section1 = all {
    s.phase == "section1",
    s' = if (s.failAt == "sections-partial") { ...s,
        phase: if (s.policy == "legacy") "error" else "rollback" }
      else { ...s, phase: "success", owned: s.owned.union(Set(rSection1)) },
  }
  action blanketCleanup = all {
    s.phase == "rollback", s.policy == "blanket",
    // Existing full cleanup also cleans P0 and assumes vm_list_mut is locked.
    s' = { ...s, phase: "error", owned: Set(), linked: false,
      badP0: not(s.p0Ready), badList: s.linked and not(s.listLock),
      badDestroy: s.threaded and not(Set(rMutex, rCond).subseteq(s.owned)) },
  }
  action blindDestroy = all {
    s.phase == "rollback", s.policy == "blind-destroy",
    s' = { ...s, phase: "error", owned: Set(),
      badDestroy: not(Set(rMutex, rCond).subseteq(s.owned)) },
  }
  action freeSections = all {
    s.phase == "rollback", Set("fixed", "unlocked").contains(s.policy),
    s.owned.intersect(heapResources).size() > 0,
    // Abstract the separately checked free_msections lifetime contract.
    s' = { ...s, owned: s.owned.exclude(heapResources) },
  }
  action prepareUnlink = all {
    s.phase == "rollback", Set("fixed", "unlocked").contains(s.policy),
    s.owned.intersect(heapResources).size() == 0, s.linked,
    s' = { ...s, phase: "unlink", listLock: s.policy == "fixed" },
  }
  action unlink = all {
    s.phase == "unlink",
    s' = { ...s, phase: "rollback", linked: false, listLock: false,
      badList: s.badList or not(s.listLock) },
  }
  action freeOwned = all {
    s.phase == "rollback", Set("fixed", "unlocked").contains(s.policy),
    not(s.linked), s.owned.intersect(heapResources).size() == 0,
    s.owned.size() > 0,
    // Dependency order: roots, then condition variable, then its mutex.
    val resource = if (s.owned.contains(rRoots)) rRoots
      else if (s.owned.contains(rCond)) rCond else if (s.owned.contains(rMutex)) rMutex
      else if (s.owned.contains(rSpinAlloc)) rSpinAlloc else rSpinMisc
    s' = { ...s, owned: s.owned.exclude(Set(resource)),
      badDestroy: s.badDestroy or not(s.owned.contains(resource)) },
  }
  action errorReturn = all {
    s.phase == "rollback", Set("fixed", "unlocked").contains(s.policy),
    not(s.linked), s.owned.size() == 0,
    s' = { ...s, phase: "error" },
  }
  val terminal = Set("success", "error").contains(s.phase)
  action finished = all { terminal, s' = s }
  action step = any { spin, mutex, cond, roots, link, table, section0, section1,
    blanketCleanup, blindDestroy, freeSections, prepareUnlink, unlink,
    freeOwned, errorReturn, finished }
  val initializationSafe = s.phase != "success" or
    (heapResources.subseteq(s.owned) and
      (not(s.threaded) or Set(rMutex, rCond).subseteq(s.owned)) and
      (not(s.threaded) or (s.spinReady and
        (s.spinBackend == "ticket" or spinResources.subseteq(s.owned)))) and
      (not(s.multi) or (s.linked and s.owned.contains(rRoots))))
  val failureSafe = s.phase != "error" or (s.owned.size() == 0 and not(s.linked))
  val pstateCleanupSafe = not(s.badP0)
  val listMutationSafe = not(s.badList)
  val destroySafe = not(s.badDestroy)
  val heapLifetimeSafe = s.owned.intersect(Set(rSection0, rSection1)).size() == 0 or
    s.owned.contains(rTable)
  val safe = initializationSafe and failureSafe and pstateCleanupSafe and
    listMutationSafe and destroySafe and heapLifetimeSafe and not(s.p0Ready)
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

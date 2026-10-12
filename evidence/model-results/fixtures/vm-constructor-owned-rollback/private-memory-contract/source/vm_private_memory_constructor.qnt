module vm_private_memory_constructor {
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
  var vmMemory: State
  pure def initial(policy: str, failAt: str, threaded: bool, multi: bool, spinBackend: str): State = {
    policy: policy, failAt: failAt, threaded: threaded, multi: multi,
    spinBackend: spinBackend, spinReady: false,
    phase: "spinMisc", owned: Set(), linked: false, listLock: false,
    p0Ready: false, badP0: false, badList: false, badDestroy: false,
  }
  action initOld = vmMemory' = initial("legacy", "scanMutex", true, true, "ticket")
  action initRoots = vmMemory' = initial("legacy", "roots", true, true, "ticket")
  action initSections = vmMemory' = initial("legacy", "sections-partial", true, true, "ticket")
  action initBlanket = vmMemory' = initial("blanket", "sections-partial", true, true, "ticket")
  action initUnlocked = vmMemory' = initial("unlocked", "sections-partial", true, true, "ticket")
  action initInvalid = vmMemory' = initial("blind-destroy", "scanCond", true, true, "ticket")
  action initFixed = {
    nondet threaded = Set(false, true).oneOf()
    nondet multi = Set(false, true).oneOf()
    nondet spinBackend = Set("ticket", "posix-mutex", "void-mutex").oneOf()
    nondet failAt = Set("none", "spinMisc", "spinAlloc", "scanMutex", "scanCond", "roots",
      "sections-table", "sections-empty", "sections-partial").oneOf()
    vmMemory' = initial("fixed", failAt, threaded, multi, spinBackend)
  }
  action spin = all {
    vmMemory.phase == "spinMisc",
    vmMemory' = if (vmMemory.threaded and vmMemory.spinBackend == "posix-mutex" and vmMemory.failAt == "spinMisc")
      { ...vmMemory, phase: "rollback" }
      else { ...vmMemory, phase: "spinAlloc",
        owned: if (vmMemory.threaded and vmMemory.spinBackend != "ticket") Set(rSpinMisc) else Set() },
  }
  action spinAlloc = all {
    vmMemory.phase == "spinAlloc",
    vmMemory' = if (vmMemory.threaded and vmMemory.spinBackend == "posix-mutex" and vmMemory.failAt == "spinAlloc")
      { ...vmMemory, phase: "rollback" }
      else { ...vmMemory, phase: "mutex", spinReady: vmMemory.threaded,
        owned: if (vmMemory.threaded and vmMemory.spinBackend != "ticket")
          vmMemory.owned.union(Set(rSpinAlloc)) else vmMemory.owned },
  }
  action mutex = all {
    vmMemory.phase == "mutex",
    vmMemory' = if (not(vmMemory.threaded)) { ...vmMemory, phase: "roots" }
      else if (vmMemory.failAt == "scanMutex") { ...vmMemory,
        phase: if (vmMemory.policy == "legacy") "cond" else "rollback" }
      else { ...vmMemory, phase: "cond", owned: vmMemory.owned.union(Set(rMutex)) },
  }
  action cond = all {
    vmMemory.phase == "cond",
    vmMemory' = if (vmMemory.failAt == "scanCond") { ...vmMemory,
        phase: if (vmMemory.policy == "legacy") "roots" else "rollback" }
      else { ...vmMemory, phase: "roots", owned: vmMemory.owned.union(Set(rCond)) },
  }
  action roots = all {
    vmMemory.phase == "roots",
    // ensure_glo_segment failure already frees the partial root tables.
    vmMemory' = if (not(vmMemory.multi)) { ...vmMemory, phase: "table" }
      else if (vmMemory.failAt == "roots") { ...vmMemory,
        phase: if (vmMemory.policy == "legacy") "error" else "rollback" }
      else { ...vmMemory, phase: if (vmMemory.policy == "fixed") "table" else "link",
        owned: vmMemory.owned.union(Set(rRoots)), listLock: vmMemory.policy != "fixed" },
  }
  action link = all {
    vmMemory.phase == "link", vmMemory.listLock,
    vmMemory' = { ...vmMemory, phase: "table", linked: true, listLock: false },
  }
  action table = all {
    vmMemory.phase == "table",
    vmMemory' = if (vmMemory.failAt == "sections-table") { ...vmMemory,
        phase: if (vmMemory.policy == "legacy") "error" else "rollback" }
      else { ...vmMemory, phase: "section0", owned: vmMemory.owned.union(Set(rTable)) },
  }
  action section0 = all {
    vmMemory.phase == "section0",
    vmMemory' = if (vmMemory.failAt == "sections-empty") { ...vmMemory,
        phase: if (vmMemory.policy == "legacy") "error" else "rollback" }
      else { ...vmMemory, phase: "section1", owned: vmMemory.owned.union(Set(rSection0)) },
  }
  action section1 = all {
    vmMemory.phase == "section1",
    vmMemory' = if (vmMemory.failAt == "sections-partial") { ...vmMemory,
        phase: if (vmMemory.policy == "legacy") "error" else "rollback" }
      else { ...vmMemory, phase: "success", owned: vmMemory.owned.union(Set(rSection1)) },
  }
  action blanketCleanup = all {
    vmMemory.phase == "rollback", vmMemory.policy == "blanket",
    // Existing full cleanup also cleans P0 and assumes vm_list_mut is locked.
    vmMemory' = { ...vmMemory, phase: "error", owned: Set(), linked: false,
      badP0: not(vmMemory.p0Ready), badList: vmMemory.linked and not(vmMemory.listLock),
      badDestroy: vmMemory.threaded and not(Set(rMutex, rCond).subseteq(vmMemory.owned)) },
  }
  action blindDestroy = all {
    vmMemory.phase == "rollback", vmMemory.policy == "blind-destroy",
    vmMemory' = { ...vmMemory, phase: "error", owned: Set(),
      badDestroy: not(Set(rMutex, rCond).subseteq(vmMemory.owned)) },
  }
  action freeSections = all {
    vmMemory.phase == "rollback", Set("fixed", "unlocked").contains(vmMemory.policy),
    vmMemory.owned.intersect(heapResources).size() > 0,
    // Abstract the separately checked free_msections lifetime contract.
    vmMemory' = { ...vmMemory, owned: vmMemory.owned.exclude(heapResources) },
  }
  action prepareUnlink = all {
    vmMemory.phase == "rollback", Set("fixed", "unlocked").contains(vmMemory.policy),
    vmMemory.owned.intersect(heapResources).size() == 0, vmMemory.linked,
    vmMemory' = { ...vmMemory, phase: "unlink", listLock: vmMemory.policy == "fixed" },
  }
  action unlink = all {
    vmMemory.phase == "unlink",
    vmMemory' = { ...vmMemory, phase: "rollback", linked: false, listLock: false,
      badList: vmMemory.badList or not(vmMemory.listLock) },
  }
  action freeOwned = all {
    vmMemory.phase == "rollback", Set("fixed", "unlocked").contains(vmMemory.policy),
    not(vmMemory.linked), vmMemory.owned.intersect(heapResources).size() == 0,
    vmMemory.owned.size() > 0,
    // Dependency order: roots, then condition variable, then its mutex.
    val resource = if (vmMemory.owned.contains(rRoots)) rRoots
      else if (vmMemory.owned.contains(rCond)) rCond else if (vmMemory.owned.contains(rMutex)) rMutex
      else if (vmMemory.owned.contains(rSpinAlloc)) rSpinAlloc else rSpinMisc
    vmMemory' = { ...vmMemory, owned: vmMemory.owned.exclude(Set(resource)),
      badDestroy: vmMemory.badDestroy or not(vmMemory.owned.contains(resource)) },
  }
  action errorReturn = all {
    vmMemory.phase == "rollback", Set("fixed", "unlocked").contains(vmMemory.policy),
    not(vmMemory.linked), vmMemory.owned.size() == 0,
    vmMemory' = { ...vmMemory, phase: "error" },
  }
  val terminal = Set("success", "error").contains(vmMemory.phase)
  action finished = all { terminal, vmMemory' = vmMemory }
  action step = any { spin, spinAlloc, mutex, cond, roots, link, table, section0, section1,
    blanketCleanup, blindDestroy, freeSections, prepareUnlink, unlink,
    freeOwned, errorReturn, finished }
  val initializationSafe = vmMemory.phase != "success" or
    (heapResources.subseteq(vmMemory.owned) and
      (not(vmMemory.threaded) or Set(rMutex, rCond).subseteq(vmMemory.owned)) and
      (not(vmMemory.threaded) or (vmMemory.spinReady and
        (vmMemory.spinBackend == "ticket" or spinResources.subseteq(vmMemory.owned)))) and
      (not(vmMemory.multi) or (vmMemory.owned.contains(rRoots) and
        (if (vmMemory.policy == "fixed") not(vmMemory.linked) else vmMemory.linked))))
  val failureSafe = vmMemory.phase != "error" or (vmMemory.owned.size() == 0 and not(vmMemory.linked))
  val pstateCleanupSafe = not(vmMemory.badP0)
  val listMutationSafe = not(vmMemory.badList)
  val destroySafe = not(vmMemory.badDestroy)
  val heapLifetimeSafe = vmMemory.owned.intersect(Set(rSection0, rSection1)).size() == 0 or
    vmMemory.owned.contains(rTable)
  val safe = initializationSafe and failureSafe and pstateCleanupSafe and
    listMutationSafe and destroySafe and heapLifetimeSafe and not(vmMemory.p0Ready)
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(vmMemory)).implies(eventually(terminal))
}

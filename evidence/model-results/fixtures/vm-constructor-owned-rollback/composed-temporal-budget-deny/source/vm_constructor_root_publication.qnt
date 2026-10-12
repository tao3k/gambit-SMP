module vm_constructor_root_publication {
  type State = { policy: str, phase: str, globals: Set[int], roots: Set[int],
    count: int, linked: bool, ready: bool, failed: bool, catchupFailed: bool,
    badRead: bool, badPublish: bool }
  var publication: State

  pure def initial(policy: str): State = {
    policy: policy, phase: "roots", globals: Set(0), roots: Set(),
    count: 0, linked: false, ready: false, failed: false,
    catchupFailed: false, badRead: false, badPublish: false,
  }
  action initEarly = publication' = initial("early-count")
  action initDeferred = publication' = initial("deferred-count")
  action initUnchecked = publication' = initial("unchecked-catchup")
  action initSplit = publication' = initial("split-lock")
  action initFixed = publication' = initial("fixed")

  // Roots are sampled under vm_list_mut. There is no running P0 yet.
  action prepareRoots = all {
    publication.phase == "roots",
    publication' = { ...publication, roots: publication.globals, phase: "processor",
      linked: publication.policy != "fixed",
      count: if (publication.policy == "early-count") 1 else 0 },
  }
  // A second VM can register globals at any constructor transition boundary.
  // The existing writer skips VMs whose processor_count is zero.
  action registerGlobal = all {
    publication.globals.size() < 3,
    val slot = publication.globals.size()
    publication' = { ...publication, globals: publication.globals.union(Set(slot)),
      roots: if (publication.linked and publication.count > 0)
        publication.roots.union(Set(slot)) else publication.roots },
  }
  action setupProcessor = all {
    publication.phase == "processor",
    nondet succeeds = Set(false, true).oneOf()
    publication' = { ...publication, phase: if (succeeds) "publish" else "abort",
      ready: succeeds, failed: not(succeeds) },
  }
  action publish = all {
    publication.phase == "publish",
    nondet allocates = Set(false, true).oneOf()
    val catchup = publication.policy != "deferred-count"
    val needsAllocation = not(publication.globals.subseteq(publication.roots))
    val failure = catchup and needsAllocation and not(allocates)
    val rejects = failure and publication.policy != "unchecked-catchup"
    val split = publication.policy == "split-lock" and not(rejects)
    // Fixed models catchup/link/count as one vm_list_mut critical section.
    publication' = { ...publication,
      phase: if (rejects) "abort" else if (split) "enable" else "running",
      roots: if (catchup and not(failure)) publication.globals else publication.roots,
      count: if (rejects or split) 0 else 1,
      linked: not(rejects), catchupFailed: failure, failed: rejects,
      badPublish: publication.badPublish or (failure and not(rejects)) },
  }
  action enable = all {
    publication.phase == "enable",
    publication' = { ...publication, phase: "running", count: 1 },
  }
  // Ordinary interrupt dispatch trusts a nonzero processor count.
  action interrupt = all {
    publication.count > 0,
    publication' = { ...publication, badRead: publication.badRead or not(publication.ready) },
  }
  // Fresh constructor only: rollback removes unpublished resources exactly once.
  action abort = all {
    publication.phase == "abort",
    publication' = { ...publication, phase: "error", roots: Set(), linked: false,
      count: 0, ready: false },
  }
  val terminal = Set("running", "error").contains(publication.phase)
  action finished = all { terminal, publication' = publication }
  action step = any { prepareRoots, registerGlobal, setupProcessor, publish,
    enable, interrupt, abort, finished }
  val processorReadySafe = not(publication.badRead) and
    (publication.count == 0 or publication.ready)
  val rootCoverageSafe = publication.phase != "running" or
    publication.globals.subseteq(publication.roots)
  val allocationSafe = not(publication.badPublish)
  val rollbackSafe = publication.phase != "error" or
    (publication.roots == Set() and not(publication.linked) and publication.count == 0)
  val safe = processorReadySafe and rootCoverageSafe and allocationSafe and rollbackSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(prepareRoots, Set(publication)).and(weakFair(setupProcessor, Set(publication)))
      .and(weakFair(publish, Set(publication))).and(weakFair(enable, Set(publication)))
      .and(weakFair(abort, Set(publication))).implies(eventually(terminal))
}

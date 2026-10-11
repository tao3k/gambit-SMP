module vm_configuration_contract {
  // All eight configure flag combinations, at most two VMs and two processors.
  // SMP selects the Scheme scheduler; threaded VMs select per-VM processor
  // capacity and runtime GC synchronization. These are independent inputs.
  type State = { fault: int, multiple: bool, threaded: bool, smp: bool,
    configured: bool, vmCount: int, processorCount: int,
    phase: int -> int, parked: int -> Set[int], rootOwner: int -> int }
  var s: State
  pure def initialState(fault: int, m: bool, t: bool, p: bool): State = {
    fault: fault, multiple: m, threaded: t, smp: p, configured: false,
    vmCount: 1, processorCount: 1, phase: Map(1 -> 0, 2 -> 0),
    parked: Map(1 -> Set(), 2 -> Set()), rootOwner: Map(1 -> 0, 2 -> 0),
  }
  action initFixed = {
    nondet m = Set(false, true).oneOf()
    nondet t = Set(false, true).oneOf()
    nondet p = Set(false, true).oneOf()
    s' = initialState(0, m, t, p)
  }
  action initSchedulerGate = {
    nondet m = Set(false, true).oneOf()
    nondet t = Set(false, true).oneOf()
    nondet p = Set(false, true).oneOf()
    s' = initialState(1, m, t, p)
  }
  action initVmCountConfusion = {
    nondet m = Set(false, true).oneOf()
    nondet t = Set(false, true).oneOf()
    nondet p = Set(false, true).oneOf()
    s' = initialState(2, m, t, p)
  }
  action initGlobalRoots = {
    nondet m = Set(false, true).oneOf()
    nondet t = Set(false, true).oneOf()
    nondet p = Set(false, true).oneOf()
    s' = initialState(3, m, t, p)
  }
  val vms = if (s.vmCount == 2) Set(1, 2) else Set(1)
  val processors = if (s.processorCount == 2) Set(1, 2) else Set(1)
  action configure = all {
    not(s.configured),
    s' = { ...s, configured: true, vmCount: if (s.multiple) 2 else 1,
      processorCount: if (s.threaded or (s.fault == 2 and s.multiple)) 2 else 1 },
  }
  action request(v: int): bool = all {
    s.configured, vms.contains(v), s.phase.get(v) == 0,
    s' = { ...s, phase: s.phase.set(v, 1) },
  }
  action park(v: int, p: int): bool = all {
    s.phase.get(v) == 1, processors.contains(p), not(s.parked.get(v).contains(p)),
    s' = { ...s, parked: s.parked.set(v, s.parked.get(v).union(Set(p))) },
  }
  action enterRoots(v: int): bool = all {
    s.phase.get(v) == 1,
    s.parked.get(v) == processors or
      (s.fault == 1 and not(s.smp) and s.parked.get(v).size() > 0),
    s' = { ...s, phase: s.phase.set(v, 2),
      rootOwner: s.rootOwner.set(v, if (s.fault == 3) 1 else v) },
  }
  // Collection body delegates to epoch/work, scan transfer and lifetime models.
  action complete(v: int): bool = all {
    s.phase.get(v) == 2, s' = { ...s, phase: s.phase.set(v, 3) },
  }
  val terminal = s.configured and vms.forall(v => s.phase.get(v) == 3)
  action finished = all { terminal, s' = s }
  action step = any { configure, request(1), request(2),
    park(1, 1), park(1, 2), park(2, 1), park(2, 2),
    enterRoots(1), enterRoots(2), complete(1), complete(2), finished }
  val capacitySafe = not(s.configured) or s.threaded or s.processorCount == 1
  val gcSafe = vms.forall(v => s.phase.get(v) < 2 or s.parked.get(v) == processors)
  val isolationSafe = vms.forall(v => s.phase.get(v) < 2 or s.rootOwner.get(v) == v)
  val safe = capacitySafe and gcSafe and isolationSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}

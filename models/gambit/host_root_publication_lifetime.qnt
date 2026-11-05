module host_root_publication_instance {
  const role: str
  import vm_list_c_memory_order.* from "./vm_list_c_memory_order"
  export vm_list_c_memory_order.*
}

module host_root_publication_lifetime {
  import host_root_publication_instance(role = "publication") as V
  import vm_list_reader_retirement as L from "./vm_list_reader_retirement"

  // One already-owned host entry and one collector reader, not new attachment
  // semantics or a CPU count. Two logical root roles are a declared census,
  // not an enumeration of Gambit's physical registers, frames and descriptors.
  val roots = Set("activation", "foreign-result")
  type Host = { fault: int, phase: int, saved: Set[str], scanned: bool,
    lastUse: bool, badCensus: bool, badHostUse: bool }
  var h: Host
  pure def initial(fault: int): Host = {
    fault: fault, phase: 0, saved: Set(), scanned: false,
    lastUse: false, badCensus: false, badHostUse: false }
  action initFixed = all { h' = initial(0),
    V::s' = V::initial("release-acquire"), L::s' = L::initial("drain-admitted") }
  action initMissingRoot = all { h' = initial(1),
    V::s' = V::initial("release-acquire"), L::s' = L::initial("drain-admitted") }
  action initCollectorDoneAsHostDone = all { h' = initial(2),
    V::s' = V::initial("release-acquire"), L::s' = L::initial("drain-admitted") }
  action initReleaseOnly = all { h' = initial(0),
    V::s' = V::initial("release-only"), L::s' = L::initial("drain-admitted") }
  action keepV = V::s' = V::s
  action keepL = L::s' = L::s

  action saveRoot = {
    nondet root = roots.oneOf()
    all { h.phase == 0, V::s.writer == "initialize",
      not(h.saved.contains(root)),
      h.fault != 1 or root == "foreign-result",
      h' = { ...h, saved: h.saved.union(Set(root)) }, keepV, keepL }
  }
  action initializeRecord = all { h.phase == 0,
    h.saved == roots or (h.fault == 1 and h.saved == Set("foreign-result")),
    V::initialize, h' = h, keepL }
  // Ordered descriptor publication precedes relinquishing execution. The
  // C mutex/atomic/collective implementation of that history remains unbound.
  action publishAndBlock = all { h.phase == 0, V::publish,
    h' = { ...h, phase: 1, badCensus: h.saved != roots }, keepL }

  action admitScanner = all { h.phase == 1, L::enter, h' = h, keepV }
  action loadRecord = all { L::load, V::load, h' = h }
  action registerScanner = all { L::register, h' = h, keepV }
  action scanRoots = all { L::dereference, V::use,
    h' = { ...h, scanned: true } }
  // Assume the existing generated-code/GC root reload contract here. This
  // projection adds neither physical relocation nor another callback unwinder.
  action resumeHost = all { h.phase == 1, h.scanned,
    h' = { ...h, phase: 2 }, keepV, keepL }
  action lastHostUse = all { h.phase == 2,
    h' = { ...h, phase: 3, lastUse: true,
      badHostUse: h.badHostUse or not(L::s.alive) }, keepV, keepL }
  // Draining only L's scanner would omit the still-returning host consumer.
  action close = all { h.phase == 3 or (h.fault == 2 and h.scanned),
    L::stop, h' = h, keepV }
  action retireRecord = all { any { L::drain, L::unlink, L::reclaim },
    h' = h, keepV }

  val rootCensusSafe = not(h.badCensus)
  val hostTailSafe = not(h.badHostUse) and (h.phase < 3 implies L::s.alive)
  val publicationSafe = V::safe
  val safe = rootCensusSafe and hostTailSafe and V::safe and L::safe
  val terminal = h.phase == 3 and h.lastUse and V::terminal and L::terminal
  val noInactiveScan = not(h.phase == 1 and h.scanned and L::s.alive)
  val noCompleteCleanup = not(terminal)
  action finished = all { terminal, h' = h, keepV, keepL }
  action step = any { saveRoot, initializeRecord, publishAndBlock, admitScanner,
    loadRecord, registerScanner, scanRoots, resumeHost, lastHostUse, close,
    retireRecord, finished }
  // Finite returning host/scanner and no new admissions beyond this cohort.
  // V supplies an abstract visibility relation, not complete C weak memory.
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set((h, V::s, L::s))).implies(eventually(terminal))
}

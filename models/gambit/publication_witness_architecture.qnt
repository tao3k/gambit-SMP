module publication_witness_architecture {
  // One publication rule for the four open gates. A downstream count is not
  // the producer witness: pending_join_count == 0 is not handler quiet, a
  // finished numerical file is not the GC/FFI inventory, a TYPEID fault is
  // not a cause, and a correctness timing is not a latency population.
  // Only the lifecycle witness is payable here, and only while pending is
  // still held. The other three gates have no earn action, so a lifecycle
  // resize does not close them. This is not 9/12 and not a source patch.
  // control 0 pays quiet while pending, then joins, transfers, and resizes.
  // controls 1-4 are the bugs TLC already found in the separate models.
  type State = {
    control: int, pending: bool, quietEarned: bool, joined: bool, count: int,
    resized: bool, numericDone: bool, inventory: bool, gcClosed: bool,
    fault: bool, causeKnown: bool, repaired: bool, timing: bool,
    population: bool, latencyPublished: bool
  }
  var s: State
  pure def initial(control: int): State = {
    control: control, pending: true, quietEarned: false, joined: false,
    count: 1, resized: false, numericDone: false, inventory: false,
    gcClosed: false, fault: false, causeKnown: false, repaired: false,
    timing: false, population: false, latencyPublished: false
  }
  action initArchitecture = s' = initial(0)
  action initCountBug = s' = initial(1)
  action initPhiBug = s' = initial(2)
  action initFaultBug = s' = initial(3)
  action initTimingBug = s' = initial(4)
  action quietWhilePending = all {
    s.control == 0, s.pending, not(s.quietEarned),
    s' = { ...s, quietEarned: true }
  }
  action joinOk = all {
    s.control == 0, s.pending, not(s.joined),
    s' = { ...s, joined: true }
  }
  action transferAfterQuiet = all {
    s.control == 0, s.joined, s.quietEarned, s.pending, s.count == 1,
    s' = { ...s, pending: false, count: 0 }
  }
  action resizeAfterQuiet = all {
    s.control == 0, s.count == 0, s.quietEarned, s.joined, not(s.resized),
    not(s.gcClosed), not(s.repaired), not(s.latencyPublished),
    s' = { ...s, resized: true }
  }
  action joinBug = all {
    s.control == 1, s.pending, not(s.joined),
    s' = { ...s, joined: true }
  }
  action clearCountWithoutQuiet = all {
    s.control == 1, s.joined, not(s.quietEarned), s.count == 1,
    s' = { ...s, pending: false, count: 0 }
  }
  action resizeOnCount = all {
    s.control == 1, s.count == 0, not(s.quietEarned), not(s.resized),
    s' = { ...s, resized: true }
  }
  action closeFromNumeric = all {
    s.control == 2, not(s.inventory), not(s.gcClosed),
    s' = { ...s, numericDone: true, gcClosed: true }
  }
  action blameFault = all {
    s.control == 3, not(s.causeKnown),
    s' = { ...s, fault: true, causeKnown: true, repaired: true }
  }
  action publishTiming = all {
    s.control == 4, not(s.population), not(s.latencyPublished),
    s' = { ...s, timing: true, latencyPublished: true }
  }
  val terminal =
    s.control == 0 and s.resized and s.quietEarned and s.joined and
    s.count == 0 and not(s.pending) and not(s.gcClosed) and
    not(s.repaired) and not(s.latencyPublished)
  action done = all { terminal, s' = s }
  action step = any {
    quietWhilePending, joinOk, transferAfterQuiet, resizeAfterQuiet,
    joinBug, clearCountWithoutQuiet, resizeOnCount, closeFromNumeric,
    blameFault, publishTiming, done
  }
  val safe =
    (not(s.resized) or s.quietEarned) and
    (not(s.gcClosed) or s.inventory) and
    (not(s.repaired) or s.causeKnown) and
    (not(s.causeKnown) or s.fault) and
    (not(s.latencyPublished) or s.population) and
    (s.control != 0 or (not(s.gcClosed) and not(s.repaired) and not(s.latencyPublished)))
  val countIsNotQuiet = not(s.resized) or s.quietEarned
  val fileIsNotInventory = not(s.gcClosed) or s.inventory
  val faultIsNotCause = not(s.repaired) or (s.causeKnown and s.fault and s.control != 3)
  val timingIsNotPopulation = not(s.latencyPublished) or s.population
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}

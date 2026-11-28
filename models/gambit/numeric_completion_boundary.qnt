module numeric_completion_boundary {
  // The original numerical file keeps its 90-second cap. A new host grouping
  // finishes inside that cap, and the official GC/FFI inventory is a separate
  // record. A raised cap, a rejected grouping, a smaller PHI count, or the
  // numeric file alone does not close the gate. Not an observed native pass.
  type State = {
    control: int, cap: int, grouping: int, launched: bool, phiSmaller: bool,
    numericDone: bool, inventoryDone: bool, closed: bool, release: bool
  }
  var s: State
  pure def initial(control: int, cap: int, grouping: int): State = {
    control: control, cap: cap, grouping: grouping, launched: false,
    phiSmaller: false, numericDone: false, inventoryDone: false,
    closed: false, release: false
  }
  action initBounded = s' = initial(0, 90, 1)
  action initRejected = s' = initial(1, 90, 0)
  action initRaised = s' = initial(2, 180, 1)
  action initPhiOnly = s' = initial(3, 90, 1)
  action initSmallerPhi = s' = initial(4, 90, 1)
  action launch = all {
    s.control == 0, s.grouping == 1, s.cap == 90, not(s.launched),
    s' = { ...s, launched: true }
  }
  action finishWithinCap = all {
    s.control == 0, s.launched, s.cap == 90, s.grouping == 1, not(s.numericDone),
    s' = { ...s, numericDone: true }
  }
  action recordInventory = all {
    s.control == 0, s.numericDone, not(s.inventoryDone),
    s' = { ...s, inventoryDone: true }
  }
  action closeBoth = all {
    s.control == 0, s.numericDone, s.inventoryDone, s.cap == 90,
    s.grouping == 1, not(s.phiSmaller), not(s.release), not(s.closed),
    s' = { ...s, closed: true }
  }
  action forceRejected = all {
    s.control == 1, s.grouping == 0, not(s.launched),
    s' = { ...s, launched: true }
  }
  action finishRaised = all {
    s.control == 2, s.cap > 90, not(s.closed),
    s' = { ...s, launched: true, numericDone: true, inventoryDone: true, closed: true }
  }
  action closeFromFile = all {
    s.control == 3, not(s.inventoryDone), not(s.closed),
    s' = { ...s, numericDone: true, closed: true }
  }
  action markSmallerPhi = all {
    s.control == 4, not(s.phiSmaller),
    s' = { ...s, phiSmaller: true }
  }
  action closeFromSmallerPhi = all {
    s.control == 4, s.phiSmaller, not(s.closed),
    s' = { ...s, closed: true }
  }
  val terminal =
    s.control == 0 and s.closed and s.numericDone and s.inventoryDone and
    s.cap == 90 and s.grouping == 1 and not(s.phiSmaller) and not(s.release)
  action done = all { terminal, s' = s }
  action step = any {
    launch, finishWithinCap, recordInventory, closeBoth, forceRejected,
    finishRaised, closeFromFile, markSmallerPhi, closeFromSmallerPhi, done
  }
  val safe =
    not(s.release) and
    (not(s.closed) or
      (s.cap == 90 and s.numericDone and s.inventoryDone and
       s.grouping == 1 and not(s.phiSmaller))) and
    (not(s.launched) or s.grouping == 1 or s.control == 1)
  val capHeld = not(s.closed) or s.cap == 90
  val newGrouping = not(s.launched) or s.grouping == 1
  val inventoryHeld = not(s.closed) or s.inventoryDone
  val phiHeld = not(s.closed) or not(s.phiSmaller)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}

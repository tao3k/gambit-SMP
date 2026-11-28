module smp_interpreter_fast_path_guard {
  // Equivalence guard for a proposed transient non-escaping interpreter
  // region. This is not an implementation, a census, or a measured speedup.
  // A fast transition is admitted only when every listed observer is absent.
  // Any escape, capture, debug hook, interrupt, exception, or reentry
  // requires the existing materialization. Delays stay in the full count.
  pure def observers(escape: bool, capture: bool, debug: bool,
                     interrupt: bool, exception: bool, reentry: bool): bool =
    escape or capture or debug or interrupt or exception or reentry
  pure def fast(escape: bool, capture: bool, debug: bool,
                interrupt: bool, exception: bool, reentry: bool): bool =
    not(observers(escape, capture, debug, interrupt, exception, reentry))
  pure def perDelayCalls(delay: int): int = delay + 2
  pure def conditionalRte(nodes: int, roots: int, delay: int): int =
    nodes * roots * perDelayCalls(delay)

  run quietFastPathTest = assert(fast(false, false, false, false, false, false))
  run escapeRefusesFastPathTest = assert(not(fast(true, false, false, false, false, false)))
  run captureRefusesFastPathTest = assert(not(fast(false, true, false, false, false, false)))
  run debugRefusesFastPathTest = assert(not(fast(false, false, true, false, false, false)))
  run interruptRefusesFastPathTest = assert(not(fast(false, false, false, true, false, false)))
  run exceptionRefusesFastPathTest = assert(not(fast(false, false, false, false, true, false)))
  run reentryRefusesFastPathTest = assert(not(fast(false, false, false, false, false, true)))
  run fullCountRetainsDelaysTest = assert(
    conditionalRte(1973, 5000, 6000) == 59209730000)
  run reducedIsNotFullGuardTest = assert(
    not(1000 * perDelayCalls(6000) == conditionalRte(1973, 5000, 6000)))
  run erasedDelayRefusedTest = assert(
    not(conditionalRte(1973, 5000, 0) == conditionalRte(1973, 5000, 6000)))
}

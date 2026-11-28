// Quint model for generator lifecycle coherency across non-local control escapes:
//   - abort-current-continuation
//   - non-composable continuation & raw call/1cc
//   - outer suspending effect perform & resume
//   - transactional dynamic-wind after-thunk rollback
//
// Core invariant:
//   (gen_state == GEN_RUNNING) <=> on_mc_stack
// Whenever a generator's prompt frame is popped off st.mc (by exception, abort,
// call/1cc, or outer effect perform), %mc-run-unwind-hooks!('unwind) transitions
// gen_state -> GEN_DONE. Whenever a captured prefix containing the generator's
// frame is re-installed by resume/composable replay, %mc-run-unwind-hooks!('restore)
// transitions GEN_DONE -> GEN_RUNNING. On a throwing dynamic-wind after-thunk,
// commit is skipped so the generator stays RUNNING and on_mc_stack.

module generator_nonlocal_escape_unwind_hooks_smp {

  pure val GEN_INIT      = 0
  pure val GEN_RUNNING   = 1
  pure val GEN_SUSPENDED = 2
  pure val GEN_DONE      = 3

  var gen_state: int
  var on_mc_stack: bool
  var k_captured: bool       // outer effect / composable cont captured prefix with pf_gen
  var stuck_running: bool
  var premature_done: bool

  action init = all {
    gen_state' = GEN_INIT,
    on_mc_stack' = false,
    k_captured' = false,
    stuck_running' = false,
    premature_done' = false,
  }

  // Start or resume generator normally: INIT/SUSPENDED -> RUNNING, push pf_gen on st.mc
  action enterGenerator = all {
    (gen_state == GEN_INIT or gen_state == GEN_SUSPENDED),
    not(on_mc_stack),
    gen_state' = GEN_RUNNING,
    on_mc_stack' = true,
    k_captured' = k_captured,
    stuck_running' = stuck_running,
    premature_done' = premature_done,
  }

  // Normal yield: RUNNING -> SUSPENDED, pop pf_gen from st.mc
  action yieldGenerator = all {
    gen_state == GEN_RUNNING,
    on_mc_stack,
    gen_state' = GEN_SUSPENDED,
    on_mc_stack' = false,
    k_captured' = k_captured,
    stuck_running' = stuck_running,
    premature_done' = premature_done,
  }

  // Normal finish: RUNNING -> DONE, pop pf_gen from st.mc
  action finishGenerator = all {
    gen_state == GEN_RUNNING,
    on_mc_stack,
    gen_state' = GEN_DONE,
    on_mc_stack' = false,
    k_captured' = k_captured,
    stuck_running' = stuck_running,
    premature_done' = premature_done,
  }

  // Non-local escape via abort-current-continuation or call/1cc (normal commit):
  // pops pf_gen and runs %mc-run-unwind-hooks!('unwind) -> GEN_DONE.
  action escapeAbortOrCall1ccCommit = all {
    gen_state == GEN_RUNNING,
    on_mc_stack,
    gen_state' = GEN_DONE,
    on_mc_stack' = false,
    k_captured' = false,
    stuck_running' = stuck_running,
    premature_done' = premature_done,
  }

  // Non-local escape across dynamic-wind whose after-thunk throws (rollback):
  // landing thunk never runs -> pf_gen remains on st.mc and gen_state stays RUNNING!
  action escapeAcrossDynwindAfterThrows = all {
    gen_state == GEN_RUNNING,
    on_mc_stack,
    gen_state' = GEN_RUNNING,
    on_mc_stack' = true,
    k_captured' = k_captured,
    stuck_running' = stuck_running,
    premature_done' = premature_done,
  }

  // Outer suspending effect perform pops prefix containing pf_gen:
  // runs %mc-run-unwind-hooks!('unwind) -> GEN_DONE, sets k_captured = true.
  action outerEffectPerformSuspend = all {
    gen_state == GEN_RUNNING,
    on_mc_stack,
    not(k_captured),
    gen_state' = GEN_DONE,
    on_mc_stack' = false,
    k_captured' = true,
    stuck_running' = stuck_running,
    premature_done' = premature_done,
  }

  // Outer effect handler resumes k:
  // re-installs prefix containing pf_gen and runs %mc-run-unwind-hooks!('restore) -> GEN_RUNNING.
  action outerEffectResume = all {
    k_captured,
    gen_state == GEN_DONE,
    not(on_mc_stack),
    gen_state' = GEN_RUNNING,
    on_mc_stack' = true,
    k_captured' = false,
    stuck_running' = stuck_running,
    premature_done' = premature_done,
  }

  // Outer effect handler abandons k without resuming
  action outerEffectAbandon = all {
    k_captured,
    not(on_mc_stack),
    k_captured' = false,
    gen_state' = gen_state,
    on_mc_stack' = on_mc_stack,
    stuck_running' = stuck_running,
    premature_done' = premature_done,
  }

  // External caller invokes (g) while generator is not on st.mc:
  // must see DONE (returns #!eof) or SUSPENDED, NEVER stuck in RUNNING!
  action probeCallWhenOffStack = all {
    not(on_mc_stack),
    stuck_running' = (stuck_running or (gen_state == GEN_RUNNING)),
    gen_state' = gen_state,
    on_mc_stack' = on_mc_stack,
    k_captured' = k_captured,
    premature_done' = premature_done,
  }

  // Buggy pre-C40 action: abort/call1cc/perform pops pf_gen without calling unwind hook
  action buggyEscapeSkipsUnwindHook = all {
    gen_state == GEN_RUNNING,
    on_mc_stack,
    on_mc_stack' = false,
    gen_state' = GEN_RUNNING, // BUG: stuck in RUNNING while off stack!
    k_captured' = k_captured,
    stuck_running' = stuck_running,
    premature_done' = premature_done,
  }

  action step = any {
    enterGenerator,
    yieldGenerator,
    finishGenerator,
    escapeAbortOrCall1ccCommit,
    escapeAcrossDynwindAfterThrows,
    outerEffectPerformSuspend,
    outerEffectResume,
    outerEffectAbandon,
    probeCallWhenOffStack,
  }

  // Safety invariants
  val inv_running_iff_on_mc = (gen_state == GEN_RUNNING) == on_mc_stack
  val inv_no_stuck_running = not(stuck_running)
  val inv_no_premature_done = not(premature_done)

  val safety = and {
    inv_running_iff_on_mc,
    inv_no_stuck_running,
    inv_no_premature_done,
  }

  // Unit tests
  run abortEscapeSetsDoneAndAllowsEofTest = {
    init
      .then(enterGenerator)
      .then(yieldGenerator)
      .then(enterGenerator)
      .then(escapeAbortOrCall1ccCommit)
      .then(probeCallWhenOffStack)
      .expect(safety and gen_state == GEN_DONE and not(stuck_running))
  }

  run outerEffectSuspendAndResumeTest = {
    init
      .then(enterGenerator)
      .then(outerEffectPerformSuspend)
      .then(probeCallWhenOffStack)
      .then(outerEffectResume)
      .then(yieldGenerator)
      .then(enterGenerator)
      .then(finishGenerator)
      .expect(safety and gen_state == GEN_DONE)
  }

  run outerEffectAbandonLeavesCleanDoneTest = {
    init
      .then(enterGenerator)
      .then(outerEffectPerformSuspend)
      .then(outerEffectAbandon)
      .then(probeCallWhenOffStack)
      .expect(safety and gen_state == GEN_DONE)
  }

  run dynwindAfterThrowRollbackPreservesRunningTest = {
    init
      .then(enterGenerator)
      .then(escapeAcrossDynwindAfterThrows)
      .then(yieldGenerator)
      .expect(safety and gen_state == GEN_SUSPENDED)
  }

  run buggyAbortSkipsUnwindHookDetectedTest = {
    init
      .then(enterGenerator)
      .then(buggyEscapeSkipsUnwindHook)
      .then(probeCallWhenOffStack)
      .expect(not(inv_running_iff_on_mc) and stuck_running)
  }
}

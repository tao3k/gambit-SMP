module compiled_phase_loader_contract {
  // Public compiler/loader protocol, not compiler equivalence or GC correctness.
  type State = { phase: int, cArtifact: bool, moduleArtifact: bool,
    linker: str, expectedLinker: str, assertionsFail: bool,
    stopped: bool, accepted: bool, completed: int, policy: str }
  var s: State
  pure def initial(policy: str, failedTest: bool): State = {
    phase: 0, cArtifact: false, moduleArtifact: false,
    linker: "", expectedLinker: "_test.o1", assertionsFail: failedTest,
    stopped: false, accepted: false, completed: 0, policy: policy,
  }
  action init = {
    nondet failedTest = Set(false, true).oneOf()
    s' = initial("original-loader", failedTest)
  }
  action initDiagnostic = s' = initial("diagnostic-entry", false)
  action initMissing = s' = initial("missing-artifact", false)
  action initIgnoreExit = s' = initial("ignore-assertion-exit", true)
  action emitC = all {
    not(s.stopped), s.phase == 0,
    s' = { ...s, phase: 1, completed: 1,
      cArtifact: s.policy != "missing-artifact",
      linker: if (s.policy == "diagnostic-entry") "probe" else s.expectedLinker },
  }
  action compileC = all {
    not(s.stopped), s.phase == 1,
    s' = { ...s, phase: 2, completed: 2, moduleArtifact: true },
  }
  action loadOriginal = all {
    not(s.stopped), s.phase == 2,
    s' = { ...s, phase: 3, completed: 3, stopped: true,
      accepted: s.policy == "ignore-assertion-exit" or
        (s.cArtifact and s.moduleArtifact and s.linker == s.expectedLinker
          and not(s.assertionsFail)) },
  }
  action failPhase = all { not(s.stopped), s' = { ...s, stopped: true } }
  action advance = any { emitC, compileC, loadOriginal, failPhase }
  action step = any { advance, s' = s }
  val sourceArtifact = s.phase < 1 or s.cArtifact
  val originalEntry = s.phase < 1 or s.linker == s.expectedLinker
  val originalAssertions = not(s.accepted) or not(s.assertionsFail)
  val safe = sourceArtifact and originalEntry and originalAssertions
    and s.completed == s.phase
    and (not(s.accepted) or (s.phase == 3 and s.moduleArtifact))
  temporal completion = weakFair(advance, s).implies(eventually(s.stopped))
}

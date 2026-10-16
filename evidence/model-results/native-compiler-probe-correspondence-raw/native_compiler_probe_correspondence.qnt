module native_compiler_probe_correspondence {
  // The three phase names and single-file deadline map to the typed probe.
  // A partial diagnostic denial is never promoted to a whole-suite result.
  type State = { diagnostic: bool, stable: bool, gsc: bool, prefixPassed: bool,
    phaseFailed: bool, phase: int, last: int, originalFile: int,
    currentFiles: Set[int], probeRegime: bool, nestedFileCap: bool,
    oldCap: int, newCap: int, spent: int, admitted: bool, bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    diagnostic: true, stable: true, gsc: true, prefixPassed: true,
    phaseFailed: true, phase: 1, last: 1, originalFile: 1,
    currentFiles: Set(1, 2), probeRegime: true, nestedFileCap: true,
    oldCap: 3, newCap: 3, spent: 0, admitted: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  val bound = s.diagnostic and s.stable and s.gsc and s.prefixPassed and
    s.phaseFailed and s.phase >= 0 and s.phase <= 2 and s.phase == s.last and
    s.currentFiles.contains(s.originalFile) and s.probeRegime and s.nestedFileCap and
    s.newCap <= s.oldCap and s.spent <= s.newCap
  action unknownPhase = all { not(s.admitted), s.phase != 3, s' = { ...s, phase: 3 } }
  action nonterminalPhase = all { not(s.admitted), s.last == 1, s' = { ...s, last: 2 } }
  action omittedFixture = all { not(s.admitted), s.currentFiles.contains(1),
    s' = { ...s, currentFiles: Set(2) } }
  action failedPrefix = all { not(s.admitted), s.prefixPassed,
    s' = { ...s, prefixPassed: false } }
  action sourceDrift = all { not(s.admitted), s.stable, s' = { ...s, stable: false } }
  action changeMode = all { not(s.admitted), s.gsc, s' = { ...s, gsc: false } }
  action relabel = all { not(s.admitted), s.probeRegime, s' = { ...s, probeRegime: false } }
  action wholeCapOnly = all { not(s.admitted), s.nestedFileCap,
    s' = { ...s, nestedFileCap: false } }
  action expand = all { not(s.admitted), s.newCap == 3, s' = { ...s, newCap: 4 } }
  action tick = all { not(s.admitted), s.spent < 5, s' = { ...s, spent: s.spent + 1 } }
  action admit = all { not(s.admitted), bound or s.bypass, s' = { ...s, admitted: true } }
  action hold = s' = s
  action step = any { unknownPhase, nonterminalPhase, omittedFixture, failedPrefix,
    sourceDrift, changeMode, relabel, wholeCapOnly, expand, tick, admit, hold }
  val safe = s.admitted implies bound
  run originalProbeTest = init.then(admit)
    .then(all { assert(s.admitted), assert(safe), s' = s })
  run relabelControlTest = initBypass.then(relabel).then(admit)
    .then(all { assert(not(safe)), s' = s })
  run wholeOnlyControlTest = initBypass.then(wholeCapOnly).then(admit)
    .then(all { assert(not(safe)), s' = s })
  run unknownPhaseControlTest = initBypass.then(unknownPhase).then(admit)
    .then(all { assert(not(safe)), s' = s })
}

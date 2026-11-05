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
  type PassSample = { exit: int, warnings: bool, functions: int, requested: str,
    dumps: Set[str], source: int, dumpSource: int, compiler: int, dumpCompiler: int,
    timeout: bool }
  pure val passSample: PassSample = { exit: 0, warnings: false, functions: 1,
    requested: "alias", dumps: Set("alias"), source: 1, dumpSource: 1,
    compiler: 1, dumpCompiler: 1, timeout: false }
  pure def passExercised(p: PassSample): bool = p.exit == 0 and not(p.warnings) and
    p.functions > 0 and p.dumps.contains(p.requested) and p.source == p.dumpSource and
    p.compiler == p.dumpCompiler and not(p.timeout)
  // Unit labels are distinct: a class count is not a universe element count,
  // and neither determines a measured compiler work/time quantity.
  pure def classUnits(groups: Set[Set[a]]): int = groups.size()
  pure def universeUnits(groups: Set[Set[a]]): int =
    groups.fold(Set(), (allNodes, group) => allNodes.union(group)).size()
  pure def projectedUnits(group: Set[a]): int = group.size()
  pure val passControls = Set(passSample, { ...passSample, dumps: Set() },
    { ...passSample, functions: 0 }, { ...passSample, warnings: true },
    { ...passSample, dumpSource: 2 }, { ...passSample, dumpCompiler: 2 },
    { ...passSample, dumps: Set("different-pass") }, { ...passSample, timeout: true },
    { ...passSample, exit: 3 })
  run mechanismRequestedPassTest = init.then(all {
    assert(passExercised(passSample)),
    assert(passControls.forall(p => passExercised(p) == (p == passSample))), s' = s })
  run mechanismCostUnitsTest = init.then(all {
    assert(classUnits(Set(Set(1, 2), Set(3, 4))) == 2),
    assert(universeUnits(Set(Set(1, 2), Set(3, 4))) == 4),
    assert(projectedUnits(Set(1, 2)) == 2),
    assert(universeUnits(Set(Set(("value", 1), ("location", 1)))) == 2),
    assert(universeUnits(Set(Set(1, 2), Set(2, 3))) == 3), s' = s })

  // Candidate finite relation saturation. The test oracle uses independent
  // per-start queue traversal, never this composition or class projection.
  pure def aliasClosure(nodes: Set[a], edges: Set[(a, a)]): Set[(a, a)] =
    nodes.fold(edges.union(nodes.map(n => (n, n))), (reach, _) =>
      reach.union(reach.fold(Set(), (result, a) => result.union(
        reach.filter(b => a._2 == b._1).map(b => (a._1, b._2))))))

}

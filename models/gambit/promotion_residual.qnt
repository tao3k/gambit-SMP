module promotion_residual {
  // Target handoff kernel, not today's mem.c. Two unique objects cost 3+4 words.
  // Old-edge cards are retained conservatively across a staged epoch handoff.
  type State = { phase: int, epoch: int, activeEpoch: int, ingress: bool,
    writers: int, settled: bool, closed: bool, used: int, free: int,
    claims: Set[int], forwarded: Set[int], ready: Set[int], sourceAlive: bool,
    edges: Set[int], oldDirty: Set[int], staged: Set[int], hints: Set[int],
    overflow: bool, seedReady: bool, installed: bool, quarantined: bool,
    aliasesDone: bool, weakDone: bool }
  var s: State
  pure def cost(i: int): int = if (i == 0) 3 else 4
  pure def spent(xs: Set[int]): int = (if (xs.contains(0)) 3 else 0) + (if (xs.contains(1)) 4 else 0)
  action init = s' = { phase: 0, epoch: 1, activeEpoch: 1, ingress: true,
    writers: 0, settled: false, closed: false, used: 0, free: 7,
    claims: Set(), forwarded: Set(), ready: Set(), sourceAlive: true,
    edges: Set(0,1), oldDirty: Set(0,1), staged: Set(), hints: Set(),
    overflow: false, seedReady: false, installed: false, quarantined: false,
    aliasesDone: false, weakDone: false }
  val safe = s.used >= 0 and s.free >= 0 and s.used + s.free == 7 and
    s.used == spent(s.claims) and s.forwarded.subseteq(s.claims) and
    s.ready.subseteq(s.forwarded) and
    (not(s.closed) or ((not(s.ingress) or s.installed) and s.writers == 0 and s.settled)) and
    (not(s.installed) or (s.seedReady and s.closed and s.aliasesDone and s.weakDone and
      s.edges.subseteq(s.staged) and (s.overflow or s.staged.subseteq(s.hints)) and
      s.activeEpoch == s.epoch + 1)) and
    (s.sourceAlive or (s.installed and s.forwarded == s.ready and s.edges.size() == 0)) and
    (not(s.quarantined) or (s.sourceAlive and not(s.ingress))) and
    (s.ingress or s.installed or s.edges.subseteq(s.oldDirty))
  action beginWriter = all { s.phase == 0, s.ingress, s.writers == 0,
    s' = { ...s, writers: 1 } }
  action close = all { s.phase == 0, s' = { ...s, phase: 1, ingress: false } }
  action settleWriter = all { s.writers == 1, not(s.closed), s' = { ...s, writers: 0 } }
  action seal = all { s.phase == 1, s.writers == 0,
    s' = { ...s, phase: 2, settled: true, closed: true } }
  action claim = all { s.phase == 2, Set(0,1).exclude(s.claims).size() > 0,
    nondet i = Set(0,1).exclude(s.claims).filter(j => cost(j) <= s.free).oneOf()
    s' = { ...s, claims: s.claims.union(Set(i)),
      used: s.used + cost(i), free: s.free - cost(i) } }
  action forward = all { s.phase == 2, s.claims.exclude(s.forwarded).size() > 0,
    nondet i = s.claims.exclude(s.forwarded).oneOf()
    s' = { ...s, forwarded: s.forwarded.union(Set(i)) } }
  action initialize = all { s.phase == 2, s.forwarded.exclude(s.ready).size() > 0,
    nondet i = s.forwarded.exclude(s.ready).oneOf()
    s' = { ...s, ready: s.ready.union(Set(i)) } }
  action refundUnpublished = all { s.phase == 2, s.claims.exclude(s.forwarded).size() > 0,
    nondet i = s.claims.exclude(s.forwarded).oneOf()
    s' = { ...s, claims: s.claims.exclude(Set(i)), used: s.used-cost(i), free: s.free+cost(i) } }
  // Conservative residuals remain. Zero residual needs the stronger full-promotion branch.
  action settleConservative = all { s.phase == 2, s.forwarded == s.ready,
    s' = { ...s, phase: 3, aliasesDone: true, weakDone: true } }
  action settleDirectPromotion = all { s.phase == 2, s.ready == Set(0,1),
    s' = { ...s, phase: 3, aliasesDone: true, weakDone: true, edges: Set() } }
  action stageFallback = all { s.phase == 3,
    s' = { ...s, staged: s.edges, hints: Set(), overflow: true, seedReady: true } }
  action stageHints = all { s.phase == 3, s.edges.size() <= 1,
    s' = { ...s, staged: s.edges, hints: s.edges, overflow: false, seedReady: true } }
  action install = all { s.phase == 3, s.seedReady, s.aliasesDone, s.weakDone,
    s' = { ...s, phase: 4, installed: true, activeEpoch: s.epoch+1, oldDirty: Set() } }
  action reopen = all { s.phase == 4, s.installed,
    s' = { ...s, phase: 5, ingress: true, sourceAlive: s.edges.size() > 0 } }
  action quarantine = all { s.phase == 2, s.forwarded.size() > 0,
    s' = { ...s, phase: 6, quarantined: true } }
  action rejectPreflight = all { s.phase == 2, s.forwarded.size() == 0,
    s' = { ...s, phase: 7 } }
  action abandonStaging = all { s.phase == 3, not(s.installed),
    s' = { ...s, staged: Set(), hints: Set(), overflow: false, seedReady: false } }
  action stutter = s' = s
  action step = any { beginWriter, close, settleWriter, seal, claim, forward, initialize,
    refundUnpublished, settleConservative, settleDirectPromotion, stageFallback,
    stageHints, install, reopen, quarantine, rejectPreflight, abandonStaging, stutter }
  // Omission controls, deliberately excluded from step.
  action badEarlySeal = s' = { ...s, closed: true, settled: true }
  action badDoubleClaim = s' = { ...s, used: s.used+3, free: s.free-3 }
  action badRefundForward = s' = { ...s, claims: Set(), used: 0, free: 7 }
  action badSeedOrphan = s' = { ...s, staged: s.edges, hints: Set(), overflow: false, seedReady: true }
  action badInstallUnknown = s' = { ...s, installed: true, activeEpoch: s.epoch+1, oldDirty: Set() }
  action badClearBeforeInstall = s' = { ...s, oldDirty: Set() }
  action badEarlyFree = s' = { ...s, sourceAlive: false }
  action badStaleEpoch = s' = { ...s, activeEpoch: s.epoch }
  action badReopenQuarantine = s' = { ...s, ingress: true }
  action cut = close.then(seal)
  action copyBoth = claim.then(claim).then(forward).then(forward).then(initialize).then(initialize)
  run exactBudgetTest = init.then(cut).then(copyBoth).expect(safe and s.used == 7 and s.free == 0)
  run duplicateClaimControlTest = init.then(cut).then(claim).then(badDoubleClaim).expect(not(safe))
  run refundBeforeForwardTest = init.then(cut).then(claim).then(refundUnpublished).expect(safe and s.free == 7)
  run forwardRefundControlTest = init.then(cut).then(claim).then(forward).then(badRefundForward).expect(not(safe))
  run partialFailureTest = init.then(cut).then(claim).then(forward).then(quarantine).expect(safe and s.sourceAlive)
  run preflightRetainsTest = init.then(cut).then(rejectPreflight).expect(safe and s.oldDirty == Set(0,1))
  run pendingWriterTest = init.then(beginWriter).then(close).then(settleWriter).then(seal).expect(safe)
  run earlySealControlTest = init.then(beginWriter).then(close).then(badEarlySeal).expect(not(safe))
  run residualFallbackTest = init.then(cut).then(settleConservative).then(stageFallback).then(install).then(reopen).expect(safe and s.staged == Set(0,1))
  run zeroResidualTest = init.then(cut).then(copyBoth).then(settleDirectPromotion).then(stageHints).then(install).then(reopen).expect(safe and s.staged == Set())
  run orphanSeedControlTest = init.then(cut).then(settleConservative).then(badSeedOrphan).then(install).expect(not(safe))
  run unknownInstallControlTest = init.then(cut).then(settleConservative).then(badInstallUnknown).expect(not(safe))
  run clearBeforeInstallControlTest = init.then(cut).then(settleConservative).then(badClearBeforeInstall).expect(not(safe))
  run staleEpochControlTest = init.then(cut).then(settleConservative).then(stageFallback).then(install).then(badStaleEpoch).expect(not(safe))
  run earlyFreeControlTest = init.then(cut).then(claim).then(forward).then(badEarlyFree).expect(not(safe))
  run failedStagingTest = init.then(cut).then(settleConservative).then(stageFallback).then(abandonStaging).expect(safe and s.oldDirty == Set(0,1))
  run quarantineReopenControlTest = init.then(cut).then(claim).then(forward).then(quarantine).then(badReopenQuarantine).expect(not(safe))
}

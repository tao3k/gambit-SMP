module release_cohort_admission {
  // Family 12 (12/12: release) whole-runtime conjunction and paired-cohort model.
  // Enforces:
  // 1. Same-source conjunction across all 12 equal-weight SMP acceptance families.
  // 2. Strict refusal of cross-source splicing (e.g., 1-5 on tree A + 6-12 on tree B).
  // 3. Matched baseline/candidate cohort pairing with mandatory censoring retention.
  // 4. Hard < 8 GiB (8192 MiB) peak RSS ceiling across build and execution.
  // 5. Same-source unresolved-failure veto precedence.

  pure val MAX_RSS_MIB = 8192

  type State = {
    targetSourceTree: int,
    targetProfile: int,
    // Family 1..12 recorded source tree (0 = unverified)
    familyTree: int -> int,
    familyVeto: int -> bool,
    // Paired release cohort
    baselineMeasured: bool,
    candidateMeasured: bool,
    baselineProfile: int,
    candidateProfile: int,
    rawCensoredEvents: int,
    retainedCensoredEvents: int,
    peakRssMiB: int,
    wholeReleaseAdmitted: bool,
    // Violation flags
    crossSourceSpliced: bool,
    censorDropped: bool,
    rssCapViolated: bool,
    vetoBypassed: bool
  }

  var s: State

  action init = {
    s' = {
      targetSourceTree: 11,
      targetProfile: 884,
      familyTree: Map(
        1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 0, 6 -> 0,
        7 -> 0, 8 -> 0, 9 -> 0, 10 -> 0, 11 -> 0, 12 -> 0
      ),
      familyVeto: Map(
        1 -> false, 2 -> false, 3 -> false, 4 -> false, 5 -> false, 6 -> false,
        7 -> false, 8 -> false, 9 -> false, 10 -> false, 11 -> false, 12 -> false
      ),
      baselineMeasured: false,
      candidateMeasured: false,
      baselineProfile: 884,
      candidateProfile: 884,
      rawCensoredEvents: 0,
      retainedCensoredEvents: 0,
      peakRssMiB: 0,
      wholeReleaseAdmitted: false,
      crossSourceSpliced: false,
      censorDropped: false,
      rssCapViolated: false,
      vetoBypassed: false
    }
  }

  action recordFamilyPass(f: int, tree: int, rssMiB: int): bool = all {
    f >= 1 and f <= 12,
    tree > 0,
    rssMiB >= 0 and rssMiB < MAX_RSS_MIB,
    not(s.familyVeto.get(f)),
    val nextRss = if (rssMiB > s.peakRssMiB) rssMiB else s.peakRssMiB
    s' = {
      ...s,
      familyTree: s.familyTree.set(f, tree),
      peakRssMiB: nextRss,
      wholeReleaseAdmitted: false
    }
  }

  action recordSameSourceVeto(f: int): bool = all {
    f >= 1 and f <= 12,
    s' = {
      ...s,
      familyVeto: s.familyVeto.set(f, true),
      wholeReleaseAdmitted: false
    }
  }

  action runMatchedPairedCohort(censors: int, rssMiB: int): bool = all {
    censors >= 0,
    rssMiB >= 0 and rssMiB < MAX_RSS_MIB,
    val nextRss = if (rssMiB > s.peakRssMiB) rssMiB else s.peakRssMiB
    s' = {
      ...s,
      baselineMeasured: true,
      candidateMeasured: true,
      baselineProfile: s.targetProfile,
      candidateProfile: s.targetProfile,
      rawCensoredEvents: s.rawCensoredEvents + censors,
      retainedCensoredEvents: s.retainedCensoredEvents + censors,
      peakRssMiB: nextRss
    }
  }

  action admitWholeRelease = all {
    1.to(12).forall(f => s.familyTree.get(f) == s.targetSourceTree and not(s.familyVeto.get(f))),
    s.baselineMeasured and s.candidateMeasured,
    s.baselineProfile == s.targetProfile and s.candidateProfile == s.targetProfile,
    s.retainedCensoredEvents == s.rawCensoredEvents,
    s.peakRssMiB < MAX_RSS_MIB,
    s' = { ...s, wholeReleaseAdmitted: true }
  }

  // Negative fault: promote 12/12 while some family was verified on a different source tree
  action faultCrossSourceSplice = all {
    1.to(12).exists(f => s.familyTree.get(f) != s.targetSourceTree),
    s' = { ...s, wholeReleaseAdmitted: true, crossSourceSpliced: true }
  }

  // Negative fault: omit a censored/timed-out event from the paired release receipt
  action faultDropCensoredEvent = all {
    s' = {
      ...s,
      rawCensoredEvents: s.rawCensoredEvents + 1,
      censorDropped: true
    }
  }

  // Negative fault: admit a run whose peak RSS hits or exceeds 8 GiB
  action faultAdmitOverRssCap(rssMiB: int): bool = all {
    rssMiB >= MAX_RSS_MIB,
    s' = { ...s, peakRssMiB: rssMiB, wholeReleaseAdmitted: true, rssCapViolated: true }
  }

  // Negative fault: admit whole release despite an active same-source failure veto
  action faultBypassSameSourceVeto = all {
    1.to(12).exists(f => s.familyVeto.get(f)),
    s' = { ...s, wholeReleaseAdmitted: true, vetoBypassed: true }
  }

  action step = any {
    nondet f = oneOf(Set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12))
    recordFamilyPass(f, s.targetSourceTree, 7420),
    runMatchedPairedCohort(0, 150),
    admitWholeRelease
  }

  val safe = and {
    not(s.crossSourceSpliced),
    not(s.censorDropped),
    not(s.rssCapViolated),
    not(s.vetoBypassed),
    s.retainedCensoredEvents == s.rawCensoredEvents,
    s.wholeReleaseAdmitted implies and {
      1.to(12).forall(f => s.familyTree.get(f) == s.targetSourceTree and not(s.familyVeto.get(f))),
      s.baselineMeasured and s.candidateMeasured,
      s.baselineProfile == s.targetProfile and s.candidateProfile == s.targetProfile,
      s.peakRssMiB < MAX_RSS_MIB
    }
  }

  run unifiedTwelveOfTwelveSameSourceTest =
    init
      .then(recordFamilyPass(1, 11, 7420))
      .then(recordFamilyPass(2, 11, 512))
      .then(recordFamilyPass(3, 11, 1024))
      .then(recordFamilyPass(4, 11, 512))
      .then(recordFamilyPass(5, 11, 1024))
      .then(recordFamilyPass(6, 11, 512))
      .then(recordFamilyPass(7, 11, 1024))
      .then(recordFamilyPass(8, 11, 256))
      .then(recordFamilyPass(9, 11, 256))
      .then(recordFamilyPass(10, 11, 512))
      .then(recordFamilyPass(11, 11, 2048))
      .then(recordFamilyPass(12, 11, 256))
      .then(runMatchedPairedCohort(0, 256))
      .then(admitWholeRelease)
      .expect(s.wholeReleaseAdmitted and s.peakRssMiB < MAX_RSS_MIB and safe)

  run crossSourceSpliceRefusedTest =
    init
      .then(recordFamilyPass(1, 9, 7400))
      .then(recordFamilyPass(7, 10, 150))
      .then(recordFamilyPass(8, 11, 150))
      .then(faultCrossSourceSplice)
      .expect(not(safe) and s.crossSourceSpliced)

  run droppedCensorRefusedTest =
    init
      .then(runMatchedPairedCohort(1, 256))
      .then(faultDropCensoredEvent)
      .expect(not(safe) and s.censorDropped)

  run rssOverEightGiBVetoTest =
    init
      .then(faultAdmitOverRssCap(9216))
      .expect(not(safe) and s.rssCapViolated)

  run sameSourceFailureVetoPreservedTest =
    init
      .then(recordSameSourceVeto(2))
      .then(faultBypassSameSourceVeto)
      .expect(not(safe) and s.vetoBypassed)
}

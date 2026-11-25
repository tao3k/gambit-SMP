module runtime_import_deferred_provider {
  // The selected path and its cheap stamp stay fixed in every mutation.
  // The qualified transition needs the installed content and a stable generation.
  type State = {
    stage: int,
    policy: str,
    sealed: bool,
    corrupt: bool,
    deferred: bool,
    receipt: bool,
    failure: str,
  }
  var s: State
  pure val unsealed: State = {
    stage: 0, policy: "sealed", sealed: false, corrupt: false,
    deferred: false, receipt: false, failure: "",
  }

  action initMutable = s' = unsealed
  action initSealed = s' = { ...unsealed, sealed: true }
  action init = any { initMutable, initSealed }
  action initOldStamp = s' = { ...unsealed, policy: "stamp" }
  action initOldSnapshot = s' = { ...unsealed, policy: "snapshot" }

  action mutate = all {
    s.stage <= 1, not(s.sealed), not(s.corrupt),
    s' = { ...s, corrupt: true },
  }

  action admit = all {
    s.stage == 0,
    val selected = if (s.policy == "stamp") true
      else if (s.policy == "snapshot") not(s.corrupt)
      else s.sealed and not(s.corrupt)
    s' = { ...s, stage: 1, deferred: selected },
  }

  action importReader = all {
    s.stage == 1,
    val failsNow = s.corrupt and not(s.deferred)
    s' = { ...s, stage: 2,
      receipt: not(failsNow), failure: if (failsNow) "import" else "",
    },
  }

  action demandLater = all {
    s.stage == 2, s.receipt,
    s' = { ...s, stage: 3, failure: if (s.corrupt) "late" else "" },
  }

  val sameFailureBoundary = (s.stage >= 2 and s.corrupt).implies(
    not(s.receipt) and s.failure == "import")
  val safe = sameFailureBoundary and (s.deferred.implies(s.sealed and not(s.corrupt)))
  val oldStampSafe = sameFailureBoundary
  val oldSnapshotSafe = sameFailureBoundary

  action step = any { mutate, admit, importReader, demandLater, s' = s }

  run mutableFallbackTest = initMutable.then(mutate).then(admit).then(importReader).then(all {
    assert(safe and not(s.receipt) and s.failure == "import"), s' = s,
  })

  run sealedReaderTest = initSealed.then(admit).then(importReader).then(demandLater).then(all {
    assert(safe and s.deferred and s.receipt and s.failure == ""), s' = s,
  })

  run stampControlTest = initOldStamp.then(mutate).then(admit)
    .then(importReader).then(demandLater).then(all {
      assert(not(sameFailureBoundary) and s.receipt and s.failure == "late"), s' = s,
    })

  run snapshotControlTest = initOldSnapshot.then(admit).then(mutate)
    .then(importReader).then(demandLater).then(all {
      assert(not(sameFailureBoundary) and s.receipt and s.failure == "late"), s' = s,
    })
}

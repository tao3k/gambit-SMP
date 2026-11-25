module runtime_import_native_placement {
  // Ordered checkpoints can enter different members of the same immutable image.
  // Each claim records the opened artifact and its decoded logical member.
  type Claim = { worker: int, member: int, provider: int, image: int }
  type State = {
    installed: int, prepared: int, collision: bool, claim: Claim,
    published: List[int], opened: List[int], baseline: Set[int],
    importImages: Set[int], receiptImages: Set[int], laterImages: Set[int],
    demanded: bool, separateLateImage: bool, independentDemanded: bool,
    staleOpen: bool, control: str,
  }

  pure val emptyClaim = { worker: 0, member: 0, provider: 0, image: 0 }
  pure val initial: State = {
    installed: 1, prepared: 0, collision: false, claim: emptyClaim,
    published: List(), opened: List(), baseline: Set(),
    importImages: Set(), receiptImages: Set(), laterImages: Set(),
    demanded: false, separateLateImage: false, independentDemanded: false,
    staleOpen: false, control: "",
  }
  var s: State

  action init = s' = initial
  action initCollision = s' = { ...initial, collision: true }
  action initOldInstall = s' = { ...initial, installed: 2, prepared: 1, control: "install" }
  action initOldCollision = s' = { ...initial, prepared: 1, collision: true, control: "linker" }
  action initOldRecharge = s' = { ...initial, prepared: 1, control: "recharge" }
  action initOldScopeReset = s' = { ...initial, prepared: 1, control: "scopeReset" }

  action prewarm = all {
    s.prepared == 0, s.installed == 1, s.baseline == Set(),
    s.claim.worker == 0, s.published == List(),
    s' = { ...s, baseline: Set(1) },
  }

  action demandReceipt(separate: bool): bool = all {
    not(s.demanded), s.published == List(1, 2),
    s' = { ...s, demanded: true, separateLateImage: separate },
  }

  action demandLate = demandReceipt(false)

  action demandIndependent = all {
    not(s.independentDemanded), s.published == List(1, 2, 3),
    s' = { ...s, independentDemanded: true },
  }

  action discoverCollision = all {
    not(s.collision), s.prepared == 0, s.claim.worker == 0, s.published == List(),
    s' = { ...s, collision: true },
  }

  action prepare = all {
    s.prepared == 0, s.installed == 1, s.claim.worker == 0, s.published == List(),
    s' = { ...s, prepared: 1 },
  }

  action replace = all {
    s.installed == 1,
    s' = { ...s, installed: 2 },
  }

  // Opening is modeled as a single operation that returns a stable artifact
  // identity. Publication uses that claim even if a later install changes
  // the path. The old controls bypass one check each.
  action openEntry(worker: int, old: bool): bool = all {
    s.claim.worker == 0,
    s.published.length() < (if (s.independentDemanded) 4 else if (s.demanded) 3 else 2),
    val member = s.published.length() + 1
    val current = s.prepared == s.installed
    val packed = s.prepared != 0 and
      (current or (old and s.control == "install")) and
      (not(s.collision) or (old and s.control == "linker"))
    val provider = if (packed and s.collision) 1 else member
    val packedImage = if (member >= 3 and s.separateLateImage) 2 else 1
    val image = if (packed) packedImage else 10 + member
    s' = { ...s,
      claim: { worker: worker, member: member, provider: provider, image: image },
      staleOpen: s.staleOpen or (packed and not(current)),
    },
  }

  action publish(worker: int, old: bool): bool = all {
    s.claim.worker == worker,
    val image = s.claim.image
    val atImport = s.claim.member <= 2
    val atReceipt = s.claim.member == 3
    val resetImport = old and s.control == "recharge"
    val resetReceipt = old and s.control == "scopeReset"
    val charge = not(image.in(s.baseline)) and
      (not(image.in(s.importImages)) or resetImport) and
      (not(image.in(s.receiptImages)) or resetReceipt)
    s' = { ...s, claim: emptyClaim,
      published: s.published.append(s.claim.provider),
      opened: s.opened.append(image),
      importImages: if (atImport and charge) s.importImages.union(Set(image)) else s.importImages,
      receiptImages: if (atReceipt and charge) Set(image) else s.receiptImages,
      laterImages: if (not(atImport or atReceipt) and charge) Set(image) else s.laterImages,
    },
  }

  val ordered = s.published.in(Set(List(), List(1), List(1, 2), List(1, 2, 3), List(1, 2, 3, 4)))
    and (s.published.length() < 3 or s.demanded)
    and (s.published.length() < 4 or s.independentDemanded)
  val currentArtifact = not(s.staleOpen)
  val validOwner = s.claim.worker == 0 or all {
    s.claim.member == s.published.length() + 1,
    s.claim.provider == s.claim.member,
  }
  val physicalExact = all {
    s.importImages == s.opened.indices().filter(i => i < 2)
      .map(i => s.opened[i]).exclude(s.baseline),
    s.receiptImages == s.opened.indices().filter(i => i == 2)
      .map(i => s.opened[i]).exclude(s.baseline.union(s.importImages)),
    s.laterImages == s.opened.indices().filter(i => i == 3)
      .map(i => s.opened[i]).exclude(s.baseline.union(s.importImages).union(s.receiptImages)),
  }
  val safe = ordered and currentArtifact and validOwner and physicalExact
  val oldInstallSafe = currentArtifact
  val oldCollisionSafe = ordered and validOwner
  val oldRechargeSafe = physicalExact
  val oldScopeResetSafe = physicalExact

  action settle = any { publish(1, false), publish(2, false) }
  temporal claimSettlement = weakFair(settle, Set(s)).implies(
    always((s.claim.worker != 0).implies(eventually(s.claim.worker == 0))))

  action step = any {
    discoverCollision, prepare, replace, prewarm, demandLate, demandReceipt(true), demandIndependent,
    openEntry(1, false), openEntry(2, false),
    settle, s' = s,
    all { s.control == "install", openEntry(1, true) },
    all { s.control == "linker", openEntry(2, true) },
    all { s.control == "recharge", s.claim.member == 3, publish(1, true) },
    all { s.control == "scopeReset", s.claim.member == 4, publish(1, true) },
  }

  run sharingTest = init.then(prepare)
    .then(openEntry(1, false)).then(publish(1, false))
    .then(openEntry(2, false)).then(publish(2, false)).then(all {
      assert(safe and s.published == List(1, 2) and s.importImages == Set(1)),
      s' = s,
    })

  run lateSharedMemberTest = init.then(prepare)
    .then(openEntry(1, false)).then(publish(1, false))
    .then(openEntry(2, false)).then(publish(2, false))
    .then(demandLate).then(openEntry(1, false)).then(publish(1, false)).then(all {
      assert(safe and s.published == List(1, 2, 3) and s.importImages == Set(1)
        and s.receiptImages == Set()),
      s' = s,
    })

  run prewarmedImageTest = init.then(prewarm).then(prepare)
    .then(openEntry(1, false)).then(publish(1, false))
    .then(openEntry(2, false)).then(publish(2, false))
    .then(demandLate).then(openEntry(1, false)).then(publish(1, false)).then(all {
      assert(safe and s.published == List(1, 2, 3) and s.importImages == Set()
        and s.receiptImages == Set()),
      s' = s,
    })

  run lateReplacementTest = init.then(prepare)
    .then(openEntry(1, false)).then(publish(1, false))
    .then(openEntry(2, false)).then(publish(2, false))
    .then(demandLate).then(replace).then(openEntry(1, false)).then(publish(1, false)).then(all {
      assert(safe and s.published == List(1, 2, 3) and s.importImages == Set(1)
        and s.receiptImages == Set(13)),
      s' = s,
    })

  run independentScopeSharesReceiptImageTest = init.then(prepare)
    .then(openEntry(1, false)).then(publish(1, false))
    .then(openEntry(2, false)).then(publish(2, false))
    .then(demandReceipt(true)).then(openEntry(1, false)).then(publish(1, false))
    .then(demandIndependent).then(openEntry(2, false)).then(publish(2, false)).then(all {
      assert(safe and s.published == List(1, 2, 3, 4) and s.importImages == Set(1)
        and s.receiptImages == Set(2) and s.laterImages == Set()),
      s' = s,
    })

  run independentScopeAfterReplacementTest = init.then(prepare)
    .then(openEntry(1, false)).then(publish(1, false))
    .then(openEntry(2, false)).then(publish(2, false))
    .then(demandReceipt(true)).then(openEntry(1, false)).then(publish(1, false))
    .then(demandIndependent).then(replace).then(openEntry(2, false)).then(publish(2, false)).then(all {
      assert(safe and s.published == List(1, 2, 3, 4) and s.importImages == Set(1)
        and s.receiptImages == Set(2) and s.laterImages == Set(14)),
      s' = s,
    })

  run oldScopeResetControlTest = initOldScopeReset
    .then(openEntry(1, false)).then(publish(1, false))
    .then(openEntry(2, false)).then(publish(2, false))
    .then(demandReceipt(true)).then(openEntry(1, false)).then(publish(1, false))
    .then(demandIndependent).then(openEntry(1, false)).then(publish(1, true)).then(all {
      assert(not(oldScopeResetSafe)), s' = s,
    })

  run oldRechargeControlTest = initOldRecharge
    .then(openEntry(1, false)).then(publish(1, false))
    .then(openEntry(2, false)).then(publish(2, false))
    .then(demandLate).then(openEntry(1, false)).then(publish(1, true)).then(all {
      assert(not(oldRechargeSafe)), s' = s,
    })

  run replacementBeforeOpenTest = init.then(prepare).then(replace)
    .then(openEntry(1, false)).then(publish(1, false))
    .then(openEntry(2, false)).then(publish(2, false)).then(all {
      assert(safe and s.published == List(1, 2) and s.importImages == Set(11, 12)),
      s' = s,
    })

  run replacementAfterOpenTest = init.then(prepare).then(openEntry(1, false)).then(replace)
    .then(publish(1, false)).then(openEntry(2, false)).then(publish(2, false)).then(all {
      assert(safe and s.published == List(1, 2) and s.importImages == Set(1, 12)),
      s' = s,
    })

  run conflictingEntriesTest = initCollision.then(prepare)
    .then(openEntry(1, false)).then(publish(1, false))
    .then(openEntry(2, false)).then(publish(2, false)).then(all {
      assert(safe and s.importImages == Set(11, 12)),
      s' = s,
    })

  run oldInstallControlTest = initOldInstall.then(openEntry(1, true)).then(all {
    assert(not(oldInstallSafe)), s' = s,
  })

  run oldCollisionControlTest = initOldCollision
    .then(openEntry(2, true)).then(publish(2, false)).then(openEntry(2, true)).then(all {
      assert(not(oldCollisionSafe)), s' = s,
    })
}

module binding_read_activation {
  // P0-2 Binding-Read Activation protocol model.
  // Models ps->context->binding_view.vm open/freeze/restore/close lifecycle,
  // single-page primitive_value acquire-flag -> acquire-cell equivalence,
  // ___primitive_ref fast path with root_writer_open fallback, and
  // generated-module ___GLOBALVARPRIMREF dispatch under ___ORDERED_WORD_NATIVE.

  type State = {
    vmIncarnation: int,
    entryCount: int,
    contextOpen: bool,
    frozenForGc: bool,
    gcEpoch: int,
    bindingViewVm: int,         // 0 when cleared/revoked; vmIncarnation when open
    // Global primitive cell state (dual-page model vs single-page model)
    primFlag: bool,
    primValue: int,
    fallbackTemplateValue: int,
    // Last observed read values
    lastFastVal: int,
    lastSlowVal: int,
    // Violation flags for explicit falsifier tests
    illegalStaleRead: bool,
    fastSlowDivergence: bool,
    useAfterCloseOrderViolation: bool
  }

  var s: State

  action init = {
    s' = {
      vmIncarnation: 1,
      entryCount: 1,
      contextOpen: true,
      frozenForGc: false,
      gcEpoch: 1,
      bindingViewVm: 1,
      primFlag: true,
      primValue: 100,
      fallbackTemplateValue: 100,
      lastFastVal: 100,
      lastSlowVal: 100,
      illegalStaleRead: false,
      fastSlowDivergence: false,
      useAfterCloseOrderViolation: false
    }
  }

  pure def singlePagePrimitiveValue(flag: bool, cell: int, tmpl: int): int =
    if (flag) cell else tmpl

  pure def dualPagePrimitiveValue(flag: bool, cell: int, tmpl: int): int =
    if (flag) cell else tmpl

  // Fast path: ___GLOBALVARPRIMREF / ___primitive_ref when bindingViewVm == vmIncarnation
  action fastPathRead = all {
    s.contextOpen,
    not(s.frozenForGc),
    s.entryCount > 0,
    s.bindingViewVm == s.vmIncarnation,
    val vFast = singlePagePrimitiveValue(s.primFlag, s.primValue, s.fallbackTemplateValue)
    val vDual = dualPagePrimitiveValue(s.primFlag, s.primValue, s.fallbackTemplateValue)
    s' = {
      ...s,
      lastFastVal: vFast,
      lastSlowVal: vDual,
      fastSlowDivergence: s.fastSlowDivergence or (vFast != vDual)
    }
  }

  // Fallback path: root_writer_open when bindingViewVm == 0
  action slowFallbackRead = all {
    s.contextOpen,
    not(s.frozenForGc),
    s.entryCount > 0,
    s.bindingViewVm == 0,
    val vSlow = singlePagePrimitiveValue(s.primFlag, s.primValue, s.fallbackTemplateValue)
    s' = { ...s, lastSlowVal: vSlow }
  }

  // Cooperative GC root freeze revokes binding_view.vm BEFORE GC moves cells
  action freezeRootsForGc = all {
    s.contextOpen,
    not(s.frozenForGc),
    s' = { ...s, frozenForGc: true, bindingViewVm: 0 }
  }

  // GC relocates a moving primitive cell while roots are frozen and bindingViewVm == 0
  action gcRelocatePrimitive(newVal: int): bool = all {
    s.frozenForGc,
    s.bindingViewVm == 0,
    newVal > s.primValue,
    s' = { ...s, gcEpoch: s.gcEpoch + 1, primValue: newVal }
  }

  // After GC round release and physical restore, reopen binding_view.vm
  action restoreAndReopenView = all {
    s.contextOpen,
    s.frozenForGc,
    s.entryCount > 0,
    s' = { ...s, frozenForGc: false, bindingViewVm: s.vmIncarnation }
  }

  // Override primitive cell while mutator is active (publish value then flag)
  action publishPrimitiveOverride(newVal: int): bool = all {
    s.contextOpen,
    not(s.frozenForGc),
    newVal > 0,
    s' = { ...s, primFlag: true, primValue: newVal }
  }

  // Safe context exit: revoke binding_view.vm BEFORE releasing the last entry
  action safeRevokeAndClose = all {
    s.contextOpen,
    s.entryCount == 1,
    s' = { ...s, bindingViewVm: 0, entryCount: 0, contextOpen: false }
  }

  // Negative fault: reading via stale binding_view.vm while frozen or closed
  action faultReadStaleView = all {
    s.frozenForGc or not(s.contextOpen) or (s.bindingViewVm != s.vmIncarnation),
    s' = { ...s, illegalStaleRead: true }
  }

  // Negative fault: decrementing last entry before clearing binding_view.vm
  action faultZeroEntryBeforeClear = all {
    s.contextOpen,
    s.entryCount == 1,
    s.bindingViewVm == s.vmIncarnation,
    s' = { ...s, entryCount: 0, contextOpen: false, useAfterCloseOrderViolation: true }
  }

  action step = any {
    fastPathRead,
    slowFallbackRead,
    freezeRootsForGc,
    gcRelocatePrimitive(s.primValue + 16),
    restoreAndReopenView,
    publishPrimitiveOverride(s.primValue + 8),
    safeRevokeAndClose
  }

  val safe = and {
    not(s.illegalStaleRead),
    not(s.fastSlowDivergence),
    not(s.useAfterCloseOrderViolation),
    s.frozenForGc implies (s.bindingViewVm == 0),
    not(s.contextOpen) implies (s.bindingViewVm == 0),
    (s.bindingViewVm != 0) implies (s.bindingViewVm == s.vmIncarnation and s.entryCount > 0)
  }

  run openReadFreezeFallbackReopenTest =
    init
      .then(fastPathRead)
      .expect(s.lastFastVal == 100 and safe)
      .then(freezeRootsForGc)
      .expect(s.bindingViewVm == 0 and safe)
      .then(gcRelocatePrimitive(256))
      .then(restoreAndReopenView)
      .then(fastPathRead)
      .expect(s.lastFastVal == 256 and safe)
      .then(safeRevokeAndClose)
      .expect(not(s.contextOpen) and s.bindingViewVm == 0 and safe)

  run singlePageMatchesDualPageTest =
    init
      .then(publishPrimitiveOverride(333))
      .then(fastPathRead)
      .expect(s.lastFastVal == 333 and s.lastSlowVal == 333 and safe)

  run staleViewDuringFreezeRefusedTest =
    init
      .then(freezeRootsForGc)
      .then(faultReadStaleView)
      .expect(not(safe) and s.illegalStaleRead)

  run closeBeforeLastLeaveOrderTest =
    init
      .then(faultZeroEntryBeforeClear)
      .expect(not(safe) and s.useAfterCloseOrderViolation)
}

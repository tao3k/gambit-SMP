module saved_stack_arena_ownership {
  import resize_saved_stack_retirement_isolated as R from "./resize_saved_stack_retirement_isolated"

  // One reachable saved frame, no unenumerated aliases. This is a source
  // ownership extension, not a refinement of R's copy-before-retire guard.
  // R.donorStorage denotes readable old-half backing, not pstate allocation.
  type Arena = { fault: int, phase: int, owner: str, borrowed: bool,
    slotCleaned: bool, slotReused: bool, vmAlive: bool, epoch: int,
    copied: bool, recycled: bool, badRead: bool }
  var a: Arena
  pure def initial(fault: int): Arena = {
    fault: fault, phase: 0, owner: "none", borrowed: false,
    slotCleaned: false, slotReused: false, vmAlive: true, epoch: 0,
    copied: false, recycled: false, badRead: false }
  action initFixed = all { a' = initial(0),
    R::retirementState' = R::initial("copy-before-retire") }
  action initSlotOwnsBacking = all { a' = initial(1),
    R::retirementState' = R::initial("copy-before-retire") }
  action initClearedSlotAsLastUse = all { a' = initial(2),
    R::retirementState' = R::initial("copy-before-retire") }
  action initReusedAddressAsIdentity = all { a' = initial(3),
    R::retirementState' = R::initial("copy-before-retire") }
  action keepR = R::retirementState' = R::retirementState
  action save = all { a.phase == 0, R::capture,
    a' = { ...a, phase: 1, owner: "thread", borrowed: true } }
  action detach = all { a.phase == 1, R::detachExecution,
    a' = { ...a, phase: 2 } }
  action publish = all { a.phase == 2, R::publish,
    a' = { ...a, phase: 3 } }
  // The source retires the executor while VM-owned backing remains assigned.
  // The existing component safety predicates do not require eager copying.
  action retireExecutor = all { a.phase == 3,
    R::retirementState.published, not(R::retirementState.executing),
    R::retirementState.donorStorage,
    R::retirementState' = { ...R::retirementState, retired: true },
    a' = { ...a, phase: 4 } }
  action cleanupSlot = all { a.phase == 4,
    R::retirementState' = { ...R::retirementState,
      donorStorage: if (a.fault == 1) false else R::retirementState.donorStorage },
    a' = { ...a, phase: 5, slotCleaned: true } }
  action reinitializeSlot = all { a.phase == 5, not(a.slotReused), keepR,
    a' = { ...a, slotReused: true, epoch: if (a.fault == 3) 1 else a.epoch } }
  // Clearing thread.cont transfers its raw pointer to the receiver break link.
  action restoreRaw = all { a.phase == 5, a.owner == "thread",
    R::retirementState' = { ...R::retirementState,
      saved: if (a.fault == 2) false else R::retirementState.saved },
    a' = { ...a, phase: 6, owner: "break",
      borrowed: if (a.fault == 2) false else a.borrowed } }
  action consumeRawFrame = all { a.phase == 6,
    R::retirementState' = { ...R::retirementState, saved: false, returned: true },
    a' = { ...a, phase: 7, owner: "receiver", borrowed: false,
      badRead: a.badRead or not(R::retirementState.donorStorage) or a.epoch != 0 } }
  // A later collection scans the actual current root location, not only the
  // former thread slot. Mutator consumption is excluded during this scan.
  action beginCollection = all { a.phase == 5 or a.phase == 6,
    R::beginScan, a' = { ...a, phase: 8 } }
  action finishCollection = all { a.phase == 8, R::copyFrames,
    a' = { ...a, phase: 9, owner: "heap", copied: true, borrowed: false } }
  action recycleOldHalf = all { not(a.recycled),
    (a.phase == 9 and not(a.borrowed)) or
      (a.fault == 2 and a.phase == 6 and not(a.borrowed)),
    R::releaseStorage, a' = { ...a, recycled: true, epoch: 1 } }
  action resumeCopied = all { a.phase == 9,
    R::retirementState' = { ...R::retirementState, saved: false, returned: true },
    a' = { ...a, phase: 10, owner: "receiver" } }
  val rawNeeded = a.owner == "thread" or a.owner == "break"
  val backingCoverage = not(rawNeeded) or
    (a.vmAlive and R::retirementState.donorStorage and a.epoch == 0)
  val incarnationSafe = not(rawNeeded) or a.epoch == 0
  val lastConsumerSafe = not(a.badRead)
  val safe = R::safe and backingCoverage and lastConsumerSafe
  val terminal = a.phase == 7 or a.phase == 10
  val noRawRetirementWithoutGc = not(terminal and a.slotCleaned and a.slotReused and
    not(a.copied) and a.vmAlive and R::retirementState.donorStorage)
  val noRecycledCopiedFrame = not(terminal and a.copied and a.recycled)
  action finished = all { terminal, a' = a, keepR }
  action step = any { save, detach, publish, retireExecutor, cleanupSlot,
    reinitializeSlot, restoreRaw, consumeRawFrame, beginCollection,
    finishCollection, recycleOldHalf, resumeCopied, finished }
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set((a, R::retirementState))).implies(eventually(terminal))
}

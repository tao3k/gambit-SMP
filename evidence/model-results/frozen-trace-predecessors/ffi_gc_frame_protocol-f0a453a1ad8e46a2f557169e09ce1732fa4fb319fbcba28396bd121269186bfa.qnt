module ffi_gc_frame_protocol {
  // A generated-code processor waits while a second requests up to two GCs.
  // Root publication, rendezvous and cached-state reload are distinct steps.
  // GC relocation is atomic here; no C weak-memory or collector proof is made.
  type State = { fault: int, phase: int, gc: int, epoch: int,
    cachedFrame: int, processorFrame: int, cachedRoot: int, processorRoot: int,
    savedRA: int, returnedRA: int, badRoots: bool }
  var s: State

  pure def initial(fault: int): State = {
    fault: fault, phase: 0, gc: 0, epoch: 0, cachedFrame: 0,
    processorFrame: 0, cachedRoot: 7, processorRoot: 3,
    savedRA: 0, returnedRA: 0, badRoots: false,
  }
  action initOld = s' = initial(1)
  action initNoReload = s' = initial(2)
  action initNoReturnRoot = s' = initial(3)
  action initFixed = s' = initial(0)

  action saveReturnAddress = all {
    s.phase == 0,
    s' = { ...s, phase: 1, savedRA: if (s.fault == 3) 0 else 9 },
  }
  action publishRegisters = all {
    s.phase == 1,
    s' = { ...s, phase: 2, processorFrame: s.cachedFrame,
      processorRoot: if (s.fault == 1) s.processorRoot else s.cachedRoot },
  }
  action enterForeignCall = all { s.phase == 2, s' = { ...s, phase: 3 } }
  // The second processor requests a synchronous operation. The waiting
  // processor must join before roots are relocated; no timeout grants safety.
  action requestGC = all {
    s.phase == 3, s.gc == 0, s.epoch < 2,
    s' = { ...s, gc: 1 },
  }
  action waitingProcessorJoins = all {
    s.phase == 3, s.gc == 1, s' = { ...s, gc: 2 },
  }
  action relocateRoots = all {
    s.phase == 3, s.gc == 2,
    s' = { ...s, gc: 0, epoch: s.epoch + 1,
      processorFrame: s.epoch + 1, processorRoot: s.processorRoot + 1,
      badRoots: s.badRoots or s.processorRoot != 7 + s.epoch },
  }
  action foreignCallReturns = all {
    s.phase == 3, s.gc == 0, s' = { ...s, phase: 4 },
  }
  action reloadRegisters = all {
    s.phase == 4,
    s' = { ...s, phase: 5,
      cachedFrame: if (s.fault == 2) s.cachedFrame else s.processorFrame,
      cachedRoot: if (s.fault == 2) s.cachedRoot else s.processorRoot },
  }
  action restoreReturnAddress = all {
    s.phase == 5,
    s' = { ...s, phase: 6,
      returnedRA: if (s.fault == 3 and s.epoch == 0) 9 else
        if (s.cachedFrame == s.processorFrame) s.savedRA else 0 },
  }
  // Host-function writeback must not overwrite relocated processor state
  // with stale cached frame/register identities.
  action hostFunctionReturns = all {
    s.phase == 6,
    s' = { ...s, phase: 7, processorFrame: s.cachedFrame,
      processorRoot: s.cachedRoot },
  }
  action finished = all { s.phase == 7, s' = s }
  action step = any { saveReturnAddress, publishRegisters, enterForeignCall,
    requestGC, waitingProcessorJoins, relocateRoots, foreignCallReturns,
    reloadRegisters, restoreReturnAddress, hostFunctionReturns, finished }

  val rootsSafe = not(s.badRoots) and
    (s.phase != 7 or s.processorRoot == 7 + s.epoch)
  val reloadSafe = s.phase != 7 or (s.processorFrame == s.epoch and
    s.processorRoot == 7 + s.epoch)
  val returnSafe = s.phase < 6 or s.returnedRA == 9
  val rendezvousSafe = s.phase <= 3 or s.gc == 0
  val safe = rootsSafe and reloadSafe and returnSafe and rendezvousSafe
}

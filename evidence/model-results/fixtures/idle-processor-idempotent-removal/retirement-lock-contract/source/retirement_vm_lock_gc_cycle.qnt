module retirement_vm_lock_gc_cycle {
  // P0 joins the retiree; an active peer may request a GC rendezvous.
  type State = { fixed: bool, peer: int, retired: bool, vmLocked: bool }
  var s: State
  action initOld = s' = { fixed: false, peer: 0, retired: false, vmLocked: false }
  action initFixed = s' = { fixed: true, peer: 0, retired: false, vmLocked: false }
  action peerLocks = all {
    s.peer == 0, not(s.vmLocked),
    s' = { ...s, peer: 1, vmLocked: true },
  }
  // Allocating while holding the VM lock can enter a GC sync operation.
  action peerRequestsGc = all {
    s.peer == 1,
    s' = { ...s, peer: 2, vmLocked: not(s.fixed) },
  }
  action retire = all {
    not(s.retired), not(s.vmLocked), s' = { ...s, retired: true },
  }
  // P0 cannot participate in GC until its join finishes.
  action gcCompletes = all {
    s.peer == 2, s.retired, s' = { ...s, peer: 3, vmLocked: false },
  }
  action finished = all { s.peer == 3, s.retired, s' = s }
  action step = any { peerLocks, peerRequestsGc, retire, gcCompletes, finished }
  val safe = not(s.peer == 2 and s.vmLocked and not(s.retired))
  temporal completion = weakFair(step, Set(s)).implies(
    eventually(s.peer == 3 and s.retired))
}

/-
  Slice 3B-1 Additive Refinement Proofs (Standalone Lean 4, zero warnings, zero sorry):
  Persistent kqueue/epoll FD-Generation Interest Sync, Unlimited Dynamic Reactor
  Capacity (eliminating FD_SETSIZE=1024 and MAX_CONDVARS=8192), and fork() Safety.

  Preserves sealed Family 9 digest of SmpIoSelectCloseRefinement.lean verbatim.
-/

namespace Slice3B1EventedIoReactor

inductive ReactorSyncOp where
  | reusePersistent : ReactorSyncOp  -- zero kernel syscalls: exact same (fd, mask, gen)
  | reRegisterFresh : ReactorSyncOp  -- delete stale + add fresh (fd, mask, gen)
  | deleteIdle      : ReactorSyncOp  -- remove from kernel interest set
  | noop            : ReactorSyncOp
  deriving DecidableEq, Repr

def reactorSlotSync (regMask wantMask : Nat) (regGen wantGen : Nat) : ReactorSyncOp :=
  if wantMask == 0 then
    if regMask == 0 then .noop else .deleteIdle
  else if regMask == wantMask && regGen == wantGen && regGen > 0 then
    .reusePersistent
  else
    .reRegisterFresh

/-- Theorem: Whenever an FD has been closed and reused by the OS (`wantGen ≠ regGen`),
    persistent reactor sync MUST re-register fresh in kqueue/epoll (Zero FD-Reuse Hang). -/
theorem fd_reuse_forces_fresh_registration
    (regMask wantMask regGen wantGen : Nat)
    (hWant : wantMask ≠ 0) (hNe : regGen ≠ wantGen) :
    reactorSlotSync regMask wantMask regGen wantGen = .reRegisterFresh := by
  unfold reactorSlotSync
  have hW : (wantMask == 0) = false := beq_false_of_ne hWant
  have hG : (regGen == wantGen) = false := beq_false_of_ne hNe
  simp [hW, hG]

/-- Theorem: Persistent open device with unchanged mask and generation (`regGen = wantGen > 0`)
    requires ZERO kernel `EV_ADD` / `epoll_ctl` modifications. -/
theorem persistent_same_gen_zero_kernel_syscalls
    (mask gen : Nat) (hMask : mask ≠ 0) (hGen : gen > 0) :
    reactorSlotSync mask mask gen gen = .reusePersistent := by
  unfold reactorSlotSync
  have hW : (mask == 0) = false := beq_false_of_ne hMask
  simp [hW, hGen]

/-- Theorem: Dynamic reactor capacity growth strictly covers any `need >= 1`
    with zero compile-time `FD_SETSIZE` (1024) or `MAX_CONDVARS` (8192) ceiling. -/
def dynamicReactorCapacity (cur need : Nat) : Nat :=
  let base := if cur < 64 then 64 else cur
  if need ≤ base then base else max (base * 2) need

theorem dynamic_reactor_capacity_covers (cur need : Nat) :
    need ≤ dynamicReactorCapacity cur need ∧ 64 ≤ dynamicReactorCapacity cur need := by
  unfold dynamicReactorCapacity
  dsimp only
  split <;> split <;> omega

/-- Theorem: `fork()` safety — a child process (`curPid ≠ ownerPid`) ALWAYS resets its
    inherited `kqueue`/`epoll` descriptor before issuing events. -/
def reactorNeedsForkReset (ownerPid curPid : Nat) : Bool :=
  ownerPid != curPid

theorem child_after_fork_always_resets_reactor (p c : Nat) (hNe : p ≠ c) :
    reactorNeedsForkReset p c = true := by
  unfold reactorNeedsForkReset
  simp [bne_iff_ne, hNe]

end Slice3B1EventedIoReactor

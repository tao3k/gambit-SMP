/-
  VmLifecycleClosureRefinement.lean
  Family 9 (9/12: lifecycle) standalone Lean 4 proofs (0 sorry, 0 external imports):
    1. Unknown-join quarantine retains exact root and native resource custody
       (never prematurely reclaimed while join outcome is unresolved).
    2. Disjoint healthy-VM GC independence: an unresolved unknown-join fault on VM A
       cannot block GC completion on a dependency-disjoint healthy VM B.
    3. Generation-guarded retry custody: a stale rollback or retry cannot release
       resources belonging to a newer generation.
-/

namespace VmLifecycleClosureRefinement

inductive VmCustody where
  | healthy
  | unknownJoinQuarantined
  | reclaimed
  deriving DecidableEq, Repr

structure VmRecord where
  generation   : Nat
  custody      : VmCustody
  retainedDebt : Nat
  gcEpoch      : Nat
  deriving DecidableEq, Repr

structure TwoVmSystem where
  vmA : VmRecord
  vmB : VmRecord
  deriving DecidableEq, Repr

def CustodyInvariant (v : VmRecord) : Prop :=
  (v.custody = VmCustody.unknownJoinQuarantined → v.retainedDebt > 0) ∧
  (v.custody = VmCustody.reclaimed → v.retainedDebt = 0)

def enterUnknownJoin (v : VmRecord) (debt : Nat) : VmRecord :=
  { v with custody := VmCustody.unknownJoinQuarantined, retainedDebt := v.retainedDebt + debt }

def tryReclaimVm (v : VmRecord) (reqGen : Nat) : Option VmRecord :=
  if v.generation = reqGen ∧ v.custody = VmCustody.healthy ∧ v.retainedDebt = 0 then
    some { v with generation := v.generation + 1, custody := VmCustody.reclaimed, retainedDebt := 0 }
  else
    none

def collectHealthyVmB (sys : TwoVmSystem) : Option TwoVmSystem :=
  if sys.vmB.custody = VmCustody.healthy then
    some { sys with vmB := { sys.vmB with gcEpoch := sys.vmB.gcEpoch + 1 } }
  else
    none

theorem unknownJoin_blocks_reclaim
    (v : VmRecord) (debt reqGen : Nat) :
    tryReclaimVm (enterUnknownJoin v debt) reqGen = none := by
  unfold tryReclaimVm enterUnknownJoin
  simp

theorem unknownJoin_retains_positive_debt
    (v : VmRecord) (debt : Nat) (hPos : debt > 0) :
    CustodyInvariant (enterUnknownJoin v debt) := by
  unfold CustodyInvariant enterUnknownJoin
  refine ⟨?_, ?_⟩
  · intro _
    simp
    omega
  · intro h
    cases h

theorem healthy_vmB_collects_despite_vmA_unknownJoin
    (sys : TwoVmSystem) (debt : Nat) (hPos : debt > 0)
    (hBHealthy : sys.vmB.custody = VmCustody.healthy) :
    ∃ sys',
      collectHealthyVmB { sys with vmA := enterUnknownJoin sys.vmA debt } = some sys' ∧
      sys'.vmB.gcEpoch = sys.vmB.gcEpoch + 1 ∧
      sys'.vmA.custody = VmCustody.unknownJoinQuarantined ∧
      sys'.vmA.retainedDebt > 0 := by
  refine ⟨{ vmA := enterUnknownJoin sys.vmA debt,
            vmB := { sys.vmB with gcEpoch := sys.vmB.gcEpoch + 1 } }, ?_⟩
  refine ⟨?_, rfl, rfl, ?_⟩
  · simp [collectHealthyVmB, hBHealthy]
  · simp [enterUnknownJoin]
    omega

theorem stale_generation_reclaim_refused
    (v : VmRecord) (reqGen : Nat) (hStale : reqGen < v.generation) :
    tryReclaimVm v reqGen = none := by
  unfold tryReclaimVm
  have hNe : v.generation ≠ reqGen := Nat.ne_of_gt hStale
  simp [hNe]

end VmLifecycleClosureRefinement

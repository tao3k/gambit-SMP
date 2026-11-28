import Std.Tactic
namespace VMRootRegistry
def admissible (source target : Nat) := source=target
theorem vmMatch (source target : Nat) (h : source≠target) : ¬admissible source target := h
def finishAllowed (phase : Nat) (accepted : Bool) := accepted=true ∧ phase≤1
theorem acceptedUpdateMayDrain : finishAllowed 1 true := by simp [finishAllowed]
def newWriterAllowed (phase : Nat) := phase=0
theorem noNewWriter : ¬newWriterAllowed 1 := by simp [newWriterAllowed]
def covered (snapshot worker0 worker1 : Nat → Prop) := ∀ slot, snapshot slot ↔ worker0 slot ∨ worker1 slot
theorem coverageUnion (snapshot worker0 worker1 : Nat → Prop) (h : covered snapshot worker0 worker1)
 (slot : Nat) (s : snapshot slot) : worker0 slot ∨ worker1 slot := (h slot).mp s
def mayReclaim (phase : Nat) (lease unknown : Bool) := phase=0 ∧ lease=false ∧ unknown=false
theorem scanBlocksReclaim (lease unknown : Bool) : ¬mayReclaim 2 lease unknown := by simp [mayReclaim]
theorem leaseBlocksReclaim (phase : Nat) (unknown : Bool) : ¬mayReclaim phase true unknown := by simp [mayReclaim]
theorem unknownBlocksReclaim (phase : Nat) (lease : Bool) : ¬mayReclaim phase lease true := by simp [mayReclaim]
structure Registry where
 slots : List Nat
 processors : List Nat
def departOne (r : Registry) : Registry := {r with processors:=r.processors.filter (fun p => p != 1)}
theorem creatorExitPreservesSlot (r : Registry) : (departOne r).slots=r.slots := rfl
def mayDepart (live storage : Nat → Prop) := ∀ slot, live slot → storage slot
theorem storageBlocksExit (live storage : Nat → Prop) (slot : Nat) (l : live slot) (n : ¬storage slot) : ¬mayDepart live storage := by
 intro h; exact n (h slot l)
def scanSlot (old : Nat) := old+10
theorem slotAfterScan (old : Nat) : scanSlot old=old+10 := rfl
theorem costPositive (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end VMRootRegistry

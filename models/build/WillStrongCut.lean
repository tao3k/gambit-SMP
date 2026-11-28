import Std.Tactic
namespace WillStrongCut
def eligible (allocated observedMarked : Bool) := allocated && !observedMarked
theorem movableObservationChanges : eligible true false=true ∧ eligible true true=false := by decide
theorem stillObservationChanges : eligible true false≠eligible true true := by decide
theorem immediateNever (marked : Bool) : eligible false marked=false := rfl
theorem strongNever : eligible true true=false := rfl
def cut (members decided : Nat → Prop) := ∀ p, members p → decided p
theorem outstandingBlocksCut (members decided : Nat → Prop) (p : Nat) (m : members p) (d : ¬decided p) : ¬cut members decided := by
 intro h; exact d (h p m)
theorem validCutIncludes (members decided : Nat → Prop) (h : cut members decided) (p : Nat) (m : members p) : decided p := h p m
def selected (decision : Nat → Bool) (order : List Nat) := order.filter decision
theorem selectedMembership (decision : Nat → Bool) (order : List Nat) (p : Nat) :
 p∈selected decision order ↔ p∈order ∧ decision p=true := by simp [selected]
theorem orderIndependent (decision : Nat → Bool) (left right : List Nat) (same : ∀ p, p∈left ↔ p∈right) (p : Nat) :
 p∈selected decision left ↔ p∈selected decision right := by simp [selected,same p]
theorem preWeakStable (allocated snapshot current : Bool) (unchanged : current=snapshot) : eligible allocated current=eligible allocated snapshot := by rw [unchanged]
def epochValid (receipt epoch : Nat) := receipt=epoch
theorem staleRejected (receipt epoch : Nat) (h : receipt≠epoch) : ¬epochValid receipt epoch := h
def finishAllowed (copyDebt weakDebt : Nat) := copyDebt=0 ∧ weakDebt=0
theorem copyDebtBlocks (c w : Nat) (h : 0<c) : ¬finishAllowed c w := by simp [finishAllowed]; omega
theorem netBenefit (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end WillStrongCut

import Std.Tactic
namespace GambitSMP.StillInitSafepoint
structure Gate where
  owned : Bool
  initialized : Bool
  resultRooted : Bool
  rootsReady : Bool
  unknown : Bool
  request : Nat
  acknowledgement : Nat

def mayAck (g : Gate) : Prop :=
  g.rootsReady=true ∧ g.unknown=false ∧
    (g.owned=false ∨ (g.initialized=true ∧ g.resultRooted=true))
theorem noUninitializedAck (g : Gate) (ack : mayAck g) (owns : g.owned=true) :
    g.initialized=true := by
  rcases ack with ⟨_, _, h⟩
  cases h with
  | inl h => simp [owns] at h
  | inr h => exact h.1
theorem noUnrootedAck (g : Gate) (ack : mayAck g) (owns : g.owned=true) :
    g.resultRooted=true := by
  rcases ack with ⟨_, _, h⟩
  cases h with
  | inl h => simp [owns] at h
  | inr h => exact h.2
theorem requestIsNotAck (ack req : Nat) (current : ack≤req) : ack<req+1 := by omega
theorem freshRequestInvalidates (ack req : Nat) (old : ack=req) : ack≠req+1 := by omega
theorem initializedPublication (written count : Nat) (complete : written=count) :
    ∀ i, i<count → i<written := by omega
-- Every token has its own updateable root cell; nested frames never use one slot.
def releaseOwn (roots : Nat→Option Nat) (token : Nat) : Nat→Option Nat :=
  fun k => if k=token then none else roots k
theorem childReleasePreservesParent (roots : Nat→Option Nat) (parent child : Nat)
    (distinct : parent≠child) : releaseOwn roots child parent=roots parent := by
  simp [releaseOwn, distinct]
theorem releasedChildAbsent (roots : Nat→Option Nat) (child : Nat) :
    releaseOwn roots child child=none := by simp [releaseOwn]
theorem unknownCannotAck (g : Gate) (unknown : g.unknown=true) : ¬mayAck g := by
  intro h
  simp [mayAck, unknown] at h
structure Custody where
  allocated : Nat
  heldUnknown : Nat
  pendingCharge : Nat
  rootRecords : Nat
def charge (c : Custody) : Nat := c.allocated+c.heldUnknown
theorem unknownChargeRetained (c : Custody) : c.heldUnknown≤charge c := by
  simp [charge]
theorem accountingSettlementNotFree (c : Custody) :
    charge {c with pendingCharge:=0}=charge c := rfl
theorem sourceRefcountIsNotReadiness (initialized : Bool) :
    initialized=false → ¬initialized=true := by intro h; simp [h]
theorem boundedRootSlots (frames slots limit : Nat) (bound : frames≤limit) :
    slots*frames≤slots*limit := Nat.mul_le_mul_left _ bound
theorem wholePeakNeedsAllPhases (base oldOther omitted extra : Nat)
    (unchanged : oldOther=base) : ¬max oldOther (base-omitted+extra)<base := by omega
end GambitSMP.StillInitSafepoint

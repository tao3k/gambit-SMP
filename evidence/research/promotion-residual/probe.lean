import Std.Tactic
namespace GambitSMP.PromotionResidual
-- Current no-handle frame layout, in words. Stack alignment >= unrounded size.
theorem frameFitsStack (fs stackWords : Nat) (h : fs + 3 ≤ stackWords) :
    fs + 2 ≤ stackWords := by omega
-- No survivor forecast: enumerate unique source extents and destination layout costs.
theorem payloadBound (heapDest stackDest heapAllocated stackAllocated : Nat)
    (heap : heapDest ≤ heapAllocated) (stack : stackDest ≤ stackAllocated) :
    heapDest + stackDest ≤ heapAllocated + stackAllocated := by omega
-- Overhead charged separately: never use payload bound as physical reservation.
theorem fullBound (actual payload overhead bound : Nat)
    (h : actual ≤ payload + overhead) (b : payload + overhead ≤ bound) : actual ≤ bound := by omega
structure Credit where
  free : Nat
  used : Nat
  total : Nat
def Conserved (s : Credit) := s.free + s.used = s.total
def claim (s : Credit) (n : Nat) : Credit := { s with free := s.free-n, used := s.used+n }
theorem claimConserves (s : Credit) (n : Nat) (h : Conserved s) (fits : n ≤ s.free) :
    Conserved (claim s n) := by simp_all [Conserved, claim]; omega
theorem refundConserves (free used total n : Nat) (h : free+used=total) (owned : n ≤ used) :
    (free+n)+(used-n)=total := by omega
-- This proves arithmetic only. A forwarding-free claim token is a separate premise.
structure Seed (Card : Type) where
  dirty : Card → Prop
  hints : Card → Prop
  overflow : Bool
def Complete {Card} (s : Seed Card) : Prop := ∀ c, s.dirty c → s.hints c ∨ s.overflow=true
def stage {Card} (residual : Card → Prop) (fits : Bool) : Seed Card :=
  { dirty := residual, hints := fun c => fits=true ∧ residual c, overflow := !fits }
theorem seedComplete {Card} (r : Card → Prop) (fits : Bool) : Complete (stage r fits) := by
  intro c hc
  cases fits with
  | false => exact Or.inr rfl
  | true => exact Or.inl ⟨rfl,hc⟩
theorem residualCovered {Card} (r edges : Card → Prop) (covers : ∀ c, edges c → r c) :
    ∀ c, edges c → (stage r true).hints c := by
  intro c hc; exact ⟨rfl,covers c hc⟩
theorem zeroResidual {Card} (edges : Card → Prop) (closed : ∀ c, ¬edges c) :
    ∀ c, edges c → False := by intro c hc; exact closed c hc
-- Peak is *simultaneous physical committed extents*, not two sums of overlapping roles.
theorem disjointPeak (base dest resume metadata : Nat) :
    base + dest + resume + metadata = base + (dest + resume + metadata) := by omega
theorem positiveWork (k mature added : Nat) (kpos : 1 ≤ k)
    (benefit : added < (k-1)*mature) : mature+added < k*mature := by
  have eq : k*mature = mature+(k-1)*mature := by
    have hk : k = 1+(k-1) := by omega
    calc
      k*mature = (1+(k-1))*mature := congrArg (fun n => n*mature) hk
      _ = mature+(k-1)*mature := by rw [Nat.add_mul, Nat.one_mul]
  omega
end GambitSMP.PromotionResidual
#check GambitSMP.PromotionResidual.frameFitsStack
#print axioms GambitSMP.PromotionResidual.frameFitsStack
#check GambitSMP.PromotionResidual.payloadBound
#print axioms GambitSMP.PromotionResidual.payloadBound
#check GambitSMP.PromotionResidual.fullBound
#print axioms GambitSMP.PromotionResidual.fullBound
#check GambitSMP.PromotionResidual.claimConserves
#print axioms GambitSMP.PromotionResidual.claimConserves
#check GambitSMP.PromotionResidual.refundConserves
#print axioms GambitSMP.PromotionResidual.refundConserves
#check GambitSMP.PromotionResidual.seedComplete
#print axioms GambitSMP.PromotionResidual.seedComplete
#check GambitSMP.PromotionResidual.residualCovered
#print axioms GambitSMP.PromotionResidual.residualCovered
#check GambitSMP.PromotionResidual.zeroResidual
#print axioms GambitSMP.PromotionResidual.zeroResidual
#check GambitSMP.PromotionResidual.disjointPeak
#print axioms GambitSMP.PromotionResidual.disjointPeak
#check GambitSMP.PromotionResidual.positiveWork
#print axioms GambitSMP.PromotionResidual.positiveWork

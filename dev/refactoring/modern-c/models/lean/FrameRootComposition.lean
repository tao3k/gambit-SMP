import FrameSealRoot
import ProducerCapacity
namespace FrameRootComposition
open FrameSealRootAst
-- Bridge uses the earlier physical SourceCover theorem; slots never count as objects.
theorem sourceBudgetFromReceipt (q : State) (h : Safe q) (issued : q.receipt=true)
 (pieces : List ProducerCapacity.SourcePiece) (lo hi : Int)
 (cover : ProducerCapacity.SourceCover lo hi pieces) (extent : hi-lo≤q.Q) :
 ProducerCapacity.destinationSum pieces+q.A+q.T≤q.B := by
 have scope := FrameSealRoot.receiptScope q h issued
 exact ProducerCapacity.sourceCoverBudget pieces lo hi q.Q q.A q.T q.B cover extent scope.2.2.2.2
-- A delta is a disjoint extension of canonical object/source identity, not the sum of roots.
theorem unionDelta (base extra total : Int) (disjointCharge : total=base+extra)
 (extraNonnegative : 0≤extra) : base≤total ∧ total-base=extra := by omega
theorem duplicateHasNoCharge (base total : Int) (sameUnion : total=base) : total-base=0 := by omega
-- Relational graph union handles aliasing without summing root-slot charges.
def reachable (reach : Nat → Nat → Prop) (roots : List Nat) (object : Nat) : Prop :=
 ∃ root, root∈roots ∧ reach root object
theorem duplicateRootSameReach (reach : Nat → Nat → Prop) (roots : List Nat) (r o : Nat) :
 reachable reach (r::r::roots) o ↔ reachable reach (r::roots) o := by
 simp [reachable]
theorem addedRootPreservesReach (reach : Nat → Nat → Prop) (roots : List Nat) (r o : Nat)
 (h : reachable reach roots o) : reachable reach (r::roots) o := by
 rcases h with ⟨x,member,hx⟩
 exact ⟨x,List.mem_cons_of_mem r member,hx⟩
theorem sourceAckPreservesSuccessor (reach : Nat → Nat → Prop) (roots : List Nat)
 (source downstream o : Nat) (sameGraph : ∀ x, reach source x ↔ reach downstream x) :
 reachable reach (source::downstream::roots) o ↔ reachable reach (downstream::roots) o := by
 simp only [reachable,List.mem_cons]
 constructor
 · rintro ⟨r,hr,ho⟩
   rcases hr with hs | hd | rest
   · subst r; exact ⟨downstream,Or.inl rfl,(sameGraph o).mp ho⟩
   · exact ⟨r,Or.inl hd,ho⟩
   · exact ⟨r,Or.inr rest,ho⟩
 · rintro ⟨r,hr,ho⟩
   exact ⟨r,Or.inr hr,ho⟩
end FrameRootComposition

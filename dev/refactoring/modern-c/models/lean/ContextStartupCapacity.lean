import Std
namespace Gambit.ContextStartupCapacity
-- All quantities count actual physical sections. The source must separately
-- prove correspondence, checked arithmetic, root custody and allocation success.
def Covered (capacity assigned pending resume : Nat) : Prop :=
  assigned + 2 * pending + resume ≤ capacity

theorem floorCovers (assigned pending resume : Nat) :
    Covered (assigned + 2 * pending + resume) assigned pending resume := by
  exact Nat.le_refl _

theorem initializePreserves (capacity assigned pending resume : Nat)
    (enough : Covered capacity assigned (pending+1) resume) :
    Covered capacity (assigned+2) pending resume := by
  unfold Covered at *
  omega

theorem grantsAtLeastTwo (capacity assigned pending resume : Nat)
    (enough : Covered capacity assigned (pending+1) resume) :
    assigned + 2 ≤ capacity := by
  unfold Covered at enough
  omega

theorem oldDenseFloorInsufficient : ¬ Covered 24 10 11 0 := by
  unfold Covered
  omega
end Gambit.ContextStartupCapacity

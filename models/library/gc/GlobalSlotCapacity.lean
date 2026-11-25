import Std.Tactic

-- Value arithmetic only. QNT owns publication/scan interleavings. Relating
-- native glo->val and count to this monotone interval remains a source premise.
namespace Gambit.GlobalSlotCapacity

def Covers (capacity base count : Nat) : Prop :=
  ∀ offset, offset < count → base + offset < capacity

theorem count_bound (capacity base count : Nat)
    (covers : Covers capacity base count) : count ≤ capacity := by
  by_cases bound : count ≤ capacity
  · exact bound
  · have outside : capacity < count := by omega
    have h := covers capacity outside
    omega

theorem fixed_table_cannot_cover_control (base : Nat) :
    ¬ Covers 20000 base 32768 := by
  intro covers
  have h := count_bound 20000 base 32768 covers
  omega

theorem first_outside_when_base_fits (capacity base count : Nat)
    (fits : base ≤ capacity) (reaches : capacity - base < count) :
    ∃ offset, offset < count ∧ base + offset = capacity := by
  exact ⟨capacity - base, reaches, by omega⟩

end Gambit.GlobalSlotCapacity

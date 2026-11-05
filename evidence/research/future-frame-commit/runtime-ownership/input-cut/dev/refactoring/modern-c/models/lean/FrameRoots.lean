import Std

namespace Gambit.FrameRoots

-- One-based physical slots; the tail excludes the first bitmap word.
theorem tailIndex (slot width : Nat) (hw : 0 < width) (hs : width < slot) :
    ((slot-1)/width-1)+1 = (slot-1)/width := by
  have h : 1 ≤ (slot-1)/width := (Nat.le_div_iff_mul_le hw).2 (by omega)
  omega

theorem bitOffset (slot width : Nat) (hw : 0 < width) :
    (slot-1)%width < width := Nat.mod_lt _ hw

theorem coordinate (slot width : Nat) (hs : 0 < slot) :
    ((slot-1)%width) + width*((slot-1)/width) + 1 = slot := by
  have h := Nat.mod_add_div (slot-1) width
  omega

def Prefix (root seen : Nat → Bool) (pos : Nat) : Prop :=
  ∀ i, seen i = true ↔ 0 < i ∧ i < pos ∧ root i = true

def visit (root seen : Nat → Bool) (pos : Nat) : Nat → Bool :=
  fun i => if i = pos then root pos else seen i

theorem initial (root : Nat → Bool) : Prefix root (fun _ => false) 1 := by
  intro i
  simp only [Bool.false_eq_true, false_iff]
  omega

theorem step (root seen : Nat → Bool) (pos : Nat) (hp : 0 < pos)
    (h : Prefix root seen pos) : Prefix root (visit root seen pos) (pos+1) := by
  intro i
  by_cases hi : i = pos
  · subst i
    simp [visit, hp]
  · simp only [visit, if_neg hi]
    rw [h i]
    constructor <;> intro x
    · exact ⟨x.1, by omega, x.2.2⟩
    · exact ⟨x.1, by omega, x.2.2⟩

theorem noDuplicate (root seen : Nat → Bool) (pos : Nat)
    (h : Prefix root seen pos) : seen pos ≠ true := by
  intro hx
  have hh := (h pos).1 hx
  omega

theorem complete (root seen : Nat → Bool) (fs : Nat)
    (h : Prefix root seen (fs+1)) :
    ∀ i, seen i = true ↔ 0 < i ∧ i ≤ fs ∧ root i = true := by
  intro i
  rw [h i]
  constructor <;> intro x
  · exact ⟨x.1, by omega, x.2.2⟩
  · exact ⟨x.1, by omega, x.2.2⟩

end Gambit.FrameRoots

import Std.Tactic
namespace IncrementalCompilerArchitecture
def netWorkPositive (avoided overhead : Nat) : Prop := overhead < avoided
theorem workPositive (r h : Nat) (p : h < r) : netWorkPositive r h := p
-- Work/span is an assumed scheduling lower bound, not a speedup prediction.
theorem spanLowerBound (time span : Nat) (p : span ≤ time) : span ≤ time := p
structure Projection where
  interface : Nat
  transformer : Nat
  deriving DecidableEq
def old : Projection := ⟨0,0⟩
def changed : Projection := ⟨0,1⟩
theorem interfaceNotSupport : old.interface = changed.interface ∧ old ≠ changed := by decide
structure Evidence where
  cohort : Bool
  tracked : Bool
  isolated : Bool
  interfaceSame : Bool
  supportSame : Bool
  success : Bool
  groupComplete : Bool
def reusable (e : Evidence) : Prop := e.cohort = true ∧ e.tracked = true ∧ e.isolated = true ∧
  e.interfaceSame = true ∧ e.supportSame = true ∧ e.success = true ∧ e.groupComplete = true
theorem cohortNeeded (e : Evidence) (h : reusable e) : e.cohort = true := h.1
theorem opaqueRejects (e : Evidence) (h : e.tracked = false) : ¬ reusable e := by
  intro v
  have t := v.2.1
  simp [h] at t
theorem projectionNeedsSupport (e : Evidence) (h : reusable e) : e.supportSame = true := h.2.2.2.2.1
theorem publicationNeedsSuccess (e : Evidence) (h : reusable e) : e.success = true ∧ e.groupComplete = true := h.2.2.2.2.2
-- The conditional protocol proof cannot produce the missing source simulation.
theorem sourceProofSeparate (modelChecked sourceRefines : Prop) (_m : modelChecked)
    (s : sourceRefines) : modelChecked ∧ sourceRefines := ⟨_m,s⟩
end IncrementalCompilerArchitecture

import Std.Tactic
namespace IterCompilerService
-- The source refinement must establish the bounded stage range and prefix premise.
theorem orderedPrefix (stage : Nat) (h : 3 ≤ stage) : 2 ≤ stage := by omega
theorem freshGeneration (old : Nat) : old < old + 1 := by omega
structure Custody where
  callbackActive : Bool
  rootsLive : Bool
  closed : Bool
def released (c : Custody) : Prop := c.callbackActive = false ∧ c.rootsLive = false ∧ c.closed = true
theorem releaseNotifies (c : Custody) (h : released c) : c.callbackActive = false ∧ c.rootsLive = false := ⟨h.1,h.2.1⟩
structure Projection where
  binding : Nat
  support : Nat
  deriving DecidableEq
theorem projectionNeedsSupport : (Projection.mk 0 0).binding = (Projection.mk 0 1).binding ∧ (Projection.mk 0 0) ≠ (Projection.mk 0 1) := by decide
theorem workPositive (oldWork newWork avoided overhead : Nat)
    (h : newWork + avoided = oldWork + overhead) (p : overhead < avoided) : newWork < oldWork := by omega
theorem spanImproves (oldSpan newSpan removed added : Nat)
    (h : newSpan + removed = oldSpan + added) (p : added < removed) : newSpan < oldSpan := by omega
inductive Outcome | success | failure | unknown deriving DecidableEq
theorem failureNotSuccess : Outcome.failure ≠ Outcome.success ∧ Outcome.unknown ≠ Outcome.success := by decide
-- No induction or source equivalence is synthesized from model checks.
theorem sourceSeparate (protocol source : Prop) (h : protocol) (s : source) : protocol ∧ source := ⟨h,s⟩
end IterCompilerService

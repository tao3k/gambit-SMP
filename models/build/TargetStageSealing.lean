import Std.Tactic
namespace TargetStageSealing
structure SealState where
  admission : Bool
  writers : Nat
  aliases : Nat
def canSeal (s : SealState) : Prop := s.admission = false ∧ s.writers = 0 ∧ s.aliases = 0
theorem sealNeedsZero (s : SealState) (h : canSeal s) : s.writers = 0 ∧ s.aliases = 0 := h.2
theorem lateWriterDenied (s : SealState) (h : canSeal s) : s.admission ≠ true := by
  have p := h.1
  simp [p]
structure Store where
  snapshot : Nat
  workspace : Nat
def consume (s : Store) : Store := {s with workspace := 0}
theorem snapshotNotConsumed (s : Store) : (consume s).snapshot = s.snapshot := rfl
theorem exclusiveDisjoint (cached transferred : Bool) (h : cached = true → transferred = false)
    (t : transferred = true) : cached ≠ true := by
  intro c
  have f := h c
  simp [t] at f
structure Observation where
  declaration : List Nat
  identity : Nat
  origin : Nat
  deriving DecidableEq
theorem projectionDistinct : (Observation.mk [1,2] 0 0) ≠ (Observation.mk [1,2] 0 1) := by decide
theorem declarationOrder : (Observation.mk [1,2] 0 0) ≠ (Observation.mk [2,1] 0 0) := by decide
inductive Outcome | success | unknown | failed deriving DecidableEq
theorem unknownNotSuccess : Outcome.unknown ≠ Outcome.success := by decide
-- The source audit must establish the accounting; this is not a compiler speed proof.
theorem reusePositive (k front freeze materialize validate : Nat) (h : 1 ≤ k)
    (p : freeze + k * materialize + validate < (k-1)*front) :
    front + freeze + k * materialize + validate < k * front := by
  have e : (k-1)*front + front = k*front := by
    calc
      (k-1)*front + front = ((k-1)+1)*front := by simp [Nat.add_mul]
      _ = k*front := by congr 1; omega
  omega
end TargetStageSealing

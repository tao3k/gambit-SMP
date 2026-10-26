import FormatterRestoreAlgebra
namespace FormatterLegalAlgebra
open PrimitiveBindingAlgebra BindingWriterClosure
def exhausted (published consumed capacity : Nat) : Prop := capacity < published-consumed
theorem stringChunkExceedsCapacity : exhausted 32 0 1 := by decide
theorem fullDrainClearsPressure (published capacity : Nat) : ¬ exhausted published published capacity := by simp [exhausted]
def restoreSaved (saved current : Nat) : Nat := saved
theorem replayRestoresCaptured (saved current firstResult : Nat) : restoreSaved saved (restoreSaved firstResult current)=saved := by rfl
theorem newWriterCanBeOverwritten : restoreSaved 1 2 ≠ (2 : Nat) := by decide
theorem secondUnderNamedWriters {a b : Resource} (h : canonical a) (steps : NamedHistory a b) : demand b=b := FormatterRestoreAlgebra.secondUnderNamedWriters h steps
-- Source simulation, mutable port frontier and output equivalence are not inferred here.
end FormatterLegalAlgebra

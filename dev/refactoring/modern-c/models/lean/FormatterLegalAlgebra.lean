import FormatterRestoreAlgebra
namespace FormatterLegalAlgebra
open PrimitiveBindingAlgebra BindingWriterClosure
def exhausted (published consumed capacity : Nat) : Prop := capacity < published-consumed
theorem stringChunkExceedsCapacity : exhausted 32 0 1 := by simp [exhausted]
theorem fullDrainClearsPressure (published capacity : Nat) : ¬ exhausted published published capacity := by simp [exhausted]
def restoreSaved (saved current : Nat) : Nat := saved
theorem replayRestoresCaptured (saved current firstResult : Nat) : restoreSaved saved (restoreSaved firstResult current)=saved := by rfl
theorem newWriterCanBeOverwritten : restoreSaved 1 2 ≠ (2 : Nat) := by decide
theorem secondUnderNamedWriters {a b : Resource} (h : canonical a) (steps : NamedHistory a b) : demand b=b := FormatterRestoreAlgebra.secondUnderNamedWriters h steps
-- Source simulation, mutable port frontier and output equivalence are not inferred here.
def pending (wlo whi rlo : Int) : Int := wlo+whi-rlo
theorem readerRebaseConservesPending (wlo whi rlo n : Int) : pending (wlo-n) whi (rlo-n)=pending wlo whi rlo := by unfold pending; omega
theorem publishConservesPending (wlo whi rlo : Int) : pending (wlo+whi) 0 rlo=pending wlo whi rlo := by unfold pending; omega
theorem pausedPending : pending 32 32 0=64 := by rfl
theorem drainedPressure (r : Int) (h : 0≤r) : ¬ ((1 : Int)<0-r) := by omega
end FormatterLegalAlgebra

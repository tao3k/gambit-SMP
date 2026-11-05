import FrameCursorClosure
import FrameCursorRefinement
import FrameCursorWords
#print axioms Gambit.FrameCursorClosure.preserves
#print axioms Gambit.FrameCursorClosure.pendingRangeIsFresh
#print axioms Gambit.FrameCursorClosure.totalCorrect
#print axioms Gambit.FrameCursorClosure.initialBudget
#print axioms Gambit.FrameCursorRefinement.coverageReflects
#print axioms Gambit.FrameCursorRefinement.actualStepSimulation
#print axioms Gambit.FrameCursorRefinement.stepIdentity
#print axioms Gambit.FrameCursorRefinement.actualStepPreserves
#print axioms Gambit.FrameCursorWords.advanceWord
#print axioms Gambit.FrameCursorWords.qualifiedNext
#print axioms Gambit.FrameCursorWords.sourceTotalCorrectAll

example : Gambit.FrameCursorWords.Width 4 := Or.inl rfl
example : Gambit.FrameCursorWords.Width 32 := Or.inr (Or.inl rfl)
example : Gambit.FrameCursorWords.Width 64 := Or.inr (Or.inr rfl)

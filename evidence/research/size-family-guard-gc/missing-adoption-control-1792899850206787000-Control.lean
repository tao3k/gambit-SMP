import SizeGuardAst
open SizeGuardAst
def witness : State := {initial with phase:=2,guard:=1,attempt:=1}
example : witness = beginConversionNext (reserveSfunNext (initial)) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : completeBoxedGuard witness := by simp [completeBoxedGuard,witness,initial]
example : ¬ (Safe (completeBoxedNext witness)) := by simp [Safe,completeBoxedNext,witness,initial]
example : Safe (completeBoxedNext witness) := by simp [Safe,completeBoxedNext,witness,initial]

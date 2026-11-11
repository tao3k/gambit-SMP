import SizeGuardAst
open SizeGuardAst
def witness : State := {initial with phase:=3,direction:=1,created:=1,hold:=1,carrier:=1,guard:=1,attempt:=1}
example : witness = completeBoxedNext (beginConversionNext (reserveCfunNext (initial))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : finishNativeGuard witness := by simp [finishNativeGuard,witness,initial]
example : ¬ (Safe (finishNativeNext witness)) := by simp [Safe,finishNativeNext,witness,initial]
example : Safe (finishNativeNext witness) := by simp [Safe,finishNativeNext,witness,initial]

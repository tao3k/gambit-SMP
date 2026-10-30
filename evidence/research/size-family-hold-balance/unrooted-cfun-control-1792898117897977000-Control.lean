import SizeHoldAst
open SizeHoldAst
def witness : State := {initial with phase:=2,direction:=1,x:=1152921504606846976,created:=1,hold:=1}
example : witness = convertBoxedNext (selectAboveFixNext initial) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : finishNativeGuard witness := by simp [finishNativeGuard,witness,initial]
example : ¬ (Safe (finishNativeNext witness)) := by simp [Safe,finishNativeNext,witness,initial]
example : Safe (finishNativeNext witness) := by simp [Safe,finishNativeNext,witness,initial]

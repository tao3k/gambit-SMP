import SizeHoldAst
open SizeHoldAst
def witness : State := {initial with phase:=4,x:=18446744073709551615,created:=1,hold:=1,critical:=1,exited:=1}
example : witness = enterDropNext (finishNativeNext (convertBoxedNext (selectSizeMaxNext initial))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : physicalDropGuard witness := by simp [physicalDropGuard,witness,initial]
example : ¬ (Safe (physicalDropNext witness)) := by simp [Safe,physicalDropNext,witness,initial]
example : Safe (physicalDropNext witness) := by simp [Safe,physicalDropNext,witness,initial]

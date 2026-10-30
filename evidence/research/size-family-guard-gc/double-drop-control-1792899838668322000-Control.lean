import SizeGuardAst
open SizeGuardAst
def witness : State := {initial with phase:=5,created:=1,hold:=1,carrier:=1,guard:=1,lease:=2,exited:=1,outcome:=1,attempt:=1,leaseEpoch:=1}
example : witness = claimDropNext (finishNativeNext (completeBoxedNext (beginConversionNext (reserveSfunNext (initial))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : physicalDropGuard witness := by simp [physicalDropGuard,witness,initial]
example : ¬ (Safe (physicalDropNext witness)) := by simp [Safe,physicalDropNext,witness,initial]
example : Safe (physicalDropNext witness) := by simp [Safe,physicalDropNext,witness,initial]

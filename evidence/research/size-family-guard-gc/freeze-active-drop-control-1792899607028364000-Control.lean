import SizeGuardAst
open SizeGuardAst
def witness : State := {initial with phase:=5,created:=1,hold:=1,carrier:=1,guard:=1,lease:=2,closed:=1,exited:=1,outcome:=1,attempt:=1,leaseEpoch:=1}
example : witness = closeGateNext (claimDropNext (finishNativeNext (completeBoxedNext (beginConversionNext (reserveSfunNext (initial)))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : freezeOwnerGuard witness := by simp [freezeOwnerGuard,witness,initial]
example : ¬ (Safe (freezeOwnerNext witness)) := by simp [Safe,freezeOwnerNext,witness,initial]
example : Safe (freezeOwnerNext witness) := by simp [Safe,freezeOwnerNext,witness,initial]

import SizeGuardAst
open SizeGuardAst
def witness : State := {initial with phase:=6,created:=1,effects:=1,carrier:=1,guard:=1,lease:=2,exited:=1,outcome:=1,attempt:=1,leaseEpoch:=1}
example : witness = physicalDropNext (claimDropNext (finishNativeNext (completeBoxedNext (beginConversionNext (reserveSfunNext (initial)))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : releaseDropGuard witness := by simp [releaseDropGuard,witness,initial]
example : ¬ (Safe (releaseDropNext witness)) := by simp [Safe,releaseDropNext,witness,initial]
example : Safe (releaseDropNext witness) := by simp [Safe,releaseDropNext,witness,initial]

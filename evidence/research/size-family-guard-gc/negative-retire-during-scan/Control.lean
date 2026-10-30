import SizeGuardAst
open SizeGuardAst
def witness : State := {initial with phase:=8,created:=1,effects:=1,carrier:=1,guard:=1,closed:=1,frozen:=1,gc:=1,scanners:=1,exited:=1,outcome:=1,receiptId:=1,reply:=1,attempt:=1,leaseEpoch:=1,viewGuard:=1,viewCarrier:=1,viewAttempt:=1}
example : witness = beginScanNext (freezeOwnerNext (closeGateNext (releaseDropNext (recordDropNext (physicalDropNext (claimDropNext (finishNativeNext (completeBoxedNext (beginConversionNext (reserveSfunNext (initial))))))))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : retireGuardGuard witness := by simp [retireGuardGuard,witness,initial]
example : ¬ (Safe (retireGuardNext witness)) := by simp [Safe,retireGuardNext,witness,initial]
example : Safe (retireGuardNext witness) := by simp [Safe,retireGuardNext,witness,initial]

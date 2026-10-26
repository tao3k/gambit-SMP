import SizeGuardAst
open SizeGuardAst
def witness : State := {initial with phase:=4,direction:=1,created:=1,hold:=1,carrier:=1,guard:=1,exited:=1,outcome:=2,receiptId:=1,attempt:=2,leaseEpoch:=1}
example : witness = escapeNativeNext (completeBoxedNext (beginConversionNext (reissueCfunNext (releaseRootUpdateNext (retireGuardNext (acquireRootUpdateNext (releaseDropNext (recordDropNext (physicalDropNext (claimDropNext (finishNativeNext (completeBoxedNext (beginConversionNext (reserveSfunNext (initial))))))))))))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : queryReceiptGuard witness := by simp [queryReceiptGuard,witness,initial]
example : ¬ (Safe (queryReceiptNext witness)) := by simp [Safe,queryReceiptNext,witness,initial]
example : Safe (queryReceiptNext witness) := by simp [Safe,queryReceiptNext,witness,initial]

import RcReaderGrace
open RcReaderGraceAst
def witness : State := closeDiagnosticNext (closeAdmissionNext (saveDiagnosticNext (beginScanNext (claimLookupNext (enterLookupNext (initial))))))
example : enterLookupGuard (initial) := by simp [enterLookupGuard,initial]
example : claimLookupGuard (enterLookupNext (initial)) := by simp [claimLookupGuard,initial,enterLookupNext]
example : beginScanGuard (claimLookupNext (enterLookupNext (initial))) := by simp [beginScanGuard,initial,enterLookupNext,claimLookupNext]
example : saveDiagnosticGuard (beginScanNext (claimLookupNext (enterLookupNext (initial)))) := by simp [saveDiagnosticGuard,initial,enterLookupNext,claimLookupNext,beginScanNext]
example : closeAdmissionGuard (saveDiagnosticNext (beginScanNext (claimLookupNext (enterLookupNext (initial))))) := by simp [closeAdmissionGuard,initial,enterLookupNext,claimLookupNext,beginScanNext,saveDiagnosticNext]
example : closeDiagnosticGuard (closeAdmissionNext (saveDiagnosticNext (beginScanNext (claimLookupNext (enterLookupNext (initial)))))) := by simp [closeDiagnosticGuard,initial,enterLookupNext,claimLookupNext,beginScanNext,saveDiagnosticNext,closeAdmissionNext]
example : Safe witness := by simp [Safe,witness,initial,enterLookupNext,claimLookupNext,beginScanNext,saveDiagnosticNext,closeAdmissionNext,closeDiagnosticNext,spawnDescendantGuard,finishDescendantGuard,confirmCohortDrainGuard,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]
example : ¬ (unlinkNodeGuard witness) := by simp [Safe,witness,initial,enterLookupNext,claimLookupNext,beginScanNext,saveDiagnosticNext,closeAdmissionNext,closeDiagnosticNext,spawnDescendantGuard,finishDescendantGuard,confirmCohortDrainGuard,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]

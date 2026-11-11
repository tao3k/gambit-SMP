import RcReaderGrace
open RcReaderGraceAst
def witness : State := closeAdmissionNext (initial)
example : closeAdmissionGuard (initial) := by simp [closeAdmissionGuard,initial]
example : Safe witness := by simp [Safe,witness,initial,closeAdmissionNext,spawnDescendantGuard,finishDescendantGuard,confirmCohortDrainGuard,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]
example : ¬ (enterLookupGuard witness) := by simp [Safe,witness,initial,closeAdmissionNext,spawnDescendantGuard,finishDescendantGuard,confirmCohortDrainGuard,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]

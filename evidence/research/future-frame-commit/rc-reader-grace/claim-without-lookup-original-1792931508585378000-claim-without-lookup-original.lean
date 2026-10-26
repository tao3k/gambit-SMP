import RcReaderGrace
open RcReaderGraceAst
def witness : State := initial

example : Safe witness := by simp [Safe,witness,initial,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]
example : ¬ (claimLookupGuard witness) := by simp [Safe,witness,initial,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]

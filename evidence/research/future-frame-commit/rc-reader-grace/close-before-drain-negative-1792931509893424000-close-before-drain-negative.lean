import RcReaderGrace
open RcReaderGraceAst
def witness : State := unlinkNodeNext (closeDiagnosticNext (closeAdmissionNext (enterLookupNext (initial))))
example : enterLookupGuard (initial) := by simp [enterLookupGuard,initial]
example : closeAdmissionGuard (enterLookupNext (initial)) := by simp [closeAdmissionGuard,initial,enterLookupNext]
example : closeDiagnosticGuard (closeAdmissionNext (enterLookupNext (initial))) := by simp [closeDiagnosticGuard,initial,enterLookupNext,closeAdmissionNext]
example : unlinkNodeGuard (closeDiagnosticNext (closeAdmissionNext (enterLookupNext (initial)))) := by simp [unlinkNodeGuard,initial,enterLookupNext,closeAdmissionNext,closeDiagnosticNext]
example : Safe witness := by simp [Safe,witness,initial,enterLookupNext,closeAdmissionNext,closeDiagnosticNext,unlinkNodeNext,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]
example : ¬ (retireDomainGuard witness) := by simp [Safe,witness,initial,enterLookupNext,closeAdmissionNext,closeDiagnosticNext,unlinkNodeNext,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]
example : retireDomainGuard witness := by simp [Safe,witness,initial,enterLookupNext,closeAdmissionNext,closeDiagnosticNext,unlinkNodeNext,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]

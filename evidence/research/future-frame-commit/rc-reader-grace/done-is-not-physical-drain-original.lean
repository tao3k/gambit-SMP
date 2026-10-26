import RcReaderGrace
open RcReaderGraceAst
def witness : State := unlinkNodeNext (closeDiagnosticNext (closeAdmissionNext (completeClaimNext (claimLookupNext (enterLookupNext (initial))))))
example : enterLookupGuard (initial) := by simp [enterLookupGuard,initial]
example : claimLookupGuard (enterLookupNext (initial)) := by simp [claimLookupGuard,initial,enterLookupNext]
example : completeClaimGuard (claimLookupNext (enterLookupNext (initial))) := by simp [completeClaimGuard,initial,enterLookupNext,claimLookupNext]
example : closeAdmissionGuard (completeClaimNext (claimLookupNext (enterLookupNext (initial)))) := by simp [closeAdmissionGuard,initial,enterLookupNext,claimLookupNext,completeClaimNext]
example : closeDiagnosticGuard (closeAdmissionNext (completeClaimNext (claimLookupNext (enterLookupNext (initial))))) := by simp [closeDiagnosticGuard,initial,enterLookupNext,claimLookupNext,completeClaimNext,closeAdmissionNext]
example : unlinkNodeGuard (closeDiagnosticNext (closeAdmissionNext (completeClaimNext (claimLookupNext (enterLookupNext (initial)))))) := by simp [unlinkNodeGuard,initial,enterLookupNext,claimLookupNext,completeClaimNext,closeAdmissionNext,closeDiagnosticNext]
example : Safe witness := by simp [Safe,witness,initial,enterLookupNext,claimLookupNext,completeClaimNext,closeAdmissionNext,closeDiagnosticNext,unlinkNodeNext,spawnDescendantGuard,finishDescendantGuard,confirmCohortDrainGuard,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]
example : ¬ (retireDomainGuard witness) := by simp [Safe,witness,initial,enterLookupNext,claimLookupNext,completeClaimNext,closeAdmissionNext,closeDiagnosticNext,unlinkNodeNext,spawnDescendantGuard,finishDescendantGuard,confirmCohortDrainGuard,enterLookupGuard,claimLookupGuard,failClaimGuard,completeClaimGuard,closeAdmissionGuard,rejectLateGuard,beginScanGuard,endScanGuard,saveDiagnosticGuard,borrowDiagnosticGuard,returnDiagnosticGuard,closeDiagnosticGuard,unlinkNodeGuard,retireDomainGuard]

import SavedResultRetirement
open SavedResultRetirementAst
def witness : State := loseBNext (beginRestoreNext (installBNext (saveANext (initial))))
example : saveAGuard (initial) := by simp [saveAGuard,initial]
example : installBGuard (saveANext (initial)) := by simp [installBGuard,initial,saveANext]
example : beginRestoreGuard (installBNext (saveANext (initial))) := by simp [beginRestoreGuard,initial,saveANext,installBNext]
example : loseBGuard (beginRestoreNext (installBNext (saveANext (initial)))) := by simp [loseBGuard,initial,saveANext,installBNext,beginRestoreNext]
example : Safe witness := by simp [Safe,witness,initial,saveANext,installBNext,beginRestoreNext,loseBNext,saveAGuard,installBGuard,beginRestoreGuard,reenterPublishCGuard,loseBGuard,ackBGuard,beginCReleaseGuard,loseCGuard,ackCGuard,commitRestoreGuard,beginDiscardGuard,beginRestoredReleaseGuard,loseAGuard,ackAGuard,completeFirstGuard,completeSecondGuard,lookupRecordGuard,returnRecordGuard,closeObserverGateGuard,closeIssuerGuard,retireRecordGuard,reuseSlotGuard]
example : ¬ (beginRestoreGuard witness) := by simp [Safe,witness,initial,saveANext,installBNext,beginRestoreNext,loseBNext,saveAGuard,installBGuard,beginRestoreGuard,reenterPublishCGuard,loseBGuard,ackBGuard,beginCReleaseGuard,loseCGuard,ackCGuard,commitRestoreGuard,beginDiscardGuard,beginRestoredReleaseGuard,loseAGuard,ackAGuard,completeFirstGuard,completeSecondGuard,lookupRecordGuard,returnRecordGuard,closeObserverGateGuard,closeIssuerGuard,retireRecordGuard,reuseSlotGuard]
example : beginRestoreGuard witness := by simp [Safe,witness,initial,saveANext,installBNext,beginRestoreNext,loseBNext,saveAGuard,installBGuard,beginRestoreGuard,reenterPublishCGuard,loseBGuard,ackBGuard,beginCReleaseGuard,loseCGuard,ackCGuard,commitRestoreGuard,beginDiscardGuard,beginRestoredReleaseGuard,loseAGuard,ackAGuard,completeFirstGuard,completeSecondGuard,lookupRecordGuard,returnRecordGuard,closeObserverGateGuard,closeIssuerGuard,retireRecordGuard,reuseSlotGuard]

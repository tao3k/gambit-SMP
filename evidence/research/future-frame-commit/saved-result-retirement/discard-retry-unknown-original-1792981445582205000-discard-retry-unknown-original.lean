import SavedResultRetirement
open SavedResultRetirementAst
def witness : State := loseANext (beginDiscardNext (saveANext (initial)))
example : saveAGuard (initial) := by simp [saveAGuard,initial]
example : beginDiscardGuard (saveANext (initial)) := by simp [beginDiscardGuard,initial,saveANext]
example : loseAGuard (beginDiscardNext (saveANext (initial))) := by simp [loseAGuard,initial,saveANext,beginDiscardNext]
example : Safe witness := by simp [Safe,witness,initial,saveANext,beginDiscardNext,loseANext,saveAGuard,installBGuard,beginRestoreGuard,reenterPublishCGuard,loseBGuard,ackBGuard,beginCReleaseGuard,loseCGuard,ackCGuard,commitRestoreGuard,beginDiscardGuard,beginRestoredReleaseGuard,loseAGuard,ackAGuard,completeFirstGuard,completeSecondGuard,lookupRecordGuard,returnRecordGuard,closeObserverGateGuard,closeIssuerGuard,retireRecordGuard,reuseSlotGuard]
example : ¬ (beginDiscardGuard witness) := by simp [Safe,witness,initial,saveANext,beginDiscardNext,loseANext,saveAGuard,installBGuard,beginRestoreGuard,reenterPublishCGuard,loseBGuard,ackBGuard,beginCReleaseGuard,loseCGuard,ackCGuard,commitRestoreGuard,beginDiscardGuard,beginRestoredReleaseGuard,loseAGuard,ackAGuard,completeFirstGuard,completeSecondGuard,lookupRecordGuard,returnRecordGuard,closeObserverGateGuard,closeIssuerGuard,retireRecordGuard,reuseSlotGuard]

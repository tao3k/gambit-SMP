import CallbackProducer
open CallbackProducerAst
def witness : State := closeRootsNext (sealProducerNext (initial))
example : sealProducerGuard (initial) := by simp [sealProducerGuard,initial]
example : closeRootsGuard (sealProducerNext (initial)) := by simp [closeRootsGuard,initial,sealProducerNext]
example : Safe witness := by simp [Safe,witness,initial,sealProducerNext,closeRootsNext,closeRootsGuard,dispatchChildGuard,landingFirstGuard,landingSecondGuard,beginCleanupGuard,loseCleanupGuard,cleanupReceiptFirstGuard,cleanupReceiptSecondGuard,settleFirstGuard,settleSecondGuard,sealProducerGuard,publishResultGuard,beginResultReleaseGuard,loseResultReleaseGuard,resultReleaseReceiptGuard,settleResultReleaseGuard,retireDomainGuard]
example : ¬ (dispatchChildGuard witness) := by simp [Safe,witness,initial,sealProducerNext,closeRootsNext,closeRootsGuard,dispatchChildGuard,landingFirstGuard,landingSecondGuard,beginCleanupGuard,loseCleanupGuard,cleanupReceiptFirstGuard,cleanupReceiptSecondGuard,settleFirstGuard,settleSecondGuard,sealProducerGuard,publishResultGuard,beginResultReleaseGuard,loseResultReleaseGuard,resultReleaseReceiptGuard,settleResultReleaseGuard,retireDomainGuard]

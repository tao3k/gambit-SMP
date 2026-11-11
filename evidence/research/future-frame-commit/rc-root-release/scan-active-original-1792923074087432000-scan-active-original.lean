import RcRootRelease
open RcRootReleaseAst
def witness : State := closeSourceNext (beginScanNext (initial))
example : beginScanGuard (initial) := by simp [beginScanGuard,initial]
example : closeSourceGuard (beginScanNext (initial)) := by simp [closeSourceGuard,initial,beginScanNext]
example : Safe witness := by simp [Safe,witness,initial,beginScanNext,closeSourceNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]
example : ¬ (unlinkAndPermitGuard witness) := by simp [Safe,witness,initial,beginScanNext,closeSourceNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]

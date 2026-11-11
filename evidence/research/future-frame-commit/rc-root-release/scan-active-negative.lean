import RcRootRelease
open RcRootReleaseAst
def witness : State := beginScanNext (dropOwnerNext (closeSourceNext (initial)))
example : closeSourceGuard (initial) := by simp [closeSourceGuard,initial]
example : dropOwnerGuard (closeSourceNext (initial)) := by simp [dropOwnerGuard,initial,closeSourceNext]
example : beginScanGuard (dropOwnerNext (closeSourceNext (initial))) := by simp [beginScanGuard,initial,closeSourceNext,dropOwnerNext]
example : Safe witness := by simp [Safe,witness,initial,closeSourceNext,dropOwnerNext,beginScanNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]
example : ¬ (unlinkAndPermitGuard witness) := by simp [Safe,witness,initial,closeSourceNext,dropOwnerNext,beginScanNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]
example : unlinkAndPermitGuard witness := by simp [Safe,witness,initial,closeSourceNext,dropOwnerNext,beginScanNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]

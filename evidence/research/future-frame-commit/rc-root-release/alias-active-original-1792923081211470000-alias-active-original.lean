import RcRootRelease
open RcRootReleaseAst
def witness : State := dropOwnerNext (closeSourceNext (exportAliasNext (initial)))
example : exportAliasGuard (initial) := by simp [exportAliasGuard,initial]
example : closeSourceGuard (exportAliasNext (initial)) := by simp [closeSourceGuard,initial,exportAliasNext]
example : dropOwnerGuard (closeSourceNext (exportAliasNext (initial))) := by simp [dropOwnerGuard,initial,exportAliasNext,closeSourceNext]
example : Safe witness := by simp [Safe,witness,initial,exportAliasNext,closeSourceNext,dropOwnerNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]
example : ¬ (unlinkAndPermitGuard witness) := by simp [Safe,witness,initial,exportAliasNext,closeSourceNext,dropOwnerNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]

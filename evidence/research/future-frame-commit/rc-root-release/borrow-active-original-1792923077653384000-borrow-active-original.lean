import RcRootRelease
open RcRootReleaseAst
def witness : State := dropOwnerNext (closeSourceNext (acquireBorrowNext (initial)))
example : acquireBorrowGuard (initial) := by simp [acquireBorrowGuard,initial]
example : closeSourceGuard (acquireBorrowNext (initial)) := by simp [closeSourceGuard,initial,acquireBorrowNext]
example : dropOwnerGuard (closeSourceNext (acquireBorrowNext (initial))) := by simp [dropOwnerGuard,initial,acquireBorrowNext,closeSourceNext]
example : Safe witness := by simp [Safe,witness,initial,acquireBorrowNext,closeSourceNext,dropOwnerNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]
example : ¬ (unlinkAndPermitGuard witness) := by simp [Safe,witness,initial,acquireBorrowNext,closeSourceNext,dropOwnerNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]

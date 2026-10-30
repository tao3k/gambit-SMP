import RcRootRelease
open RcRootReleaseAst
def witness : State := loseFreeResultNext (beginFreeNext (unlinkAndPermitNext (dropOwnerNext (closeSourceNext (initial)))))
example : closeSourceGuard (initial) := by simp [closeSourceGuard,initial]
example : dropOwnerGuard (closeSourceNext (initial)) := by simp [dropOwnerGuard,initial,closeSourceNext]
example : unlinkAndPermitGuard (dropOwnerNext (closeSourceNext (initial))) := by simp [unlinkAndPermitGuard,initial,closeSourceNext,dropOwnerNext]
example : beginFreeGuard (unlinkAndPermitNext (dropOwnerNext (closeSourceNext (initial)))) := by simp [beginFreeGuard,initial,closeSourceNext,dropOwnerNext,unlinkAndPermitNext]
example : loseFreeResultGuard (beginFreeNext (unlinkAndPermitNext (dropOwnerNext (closeSourceNext (initial))))) := by simp [loseFreeResultGuard,initial,closeSourceNext,dropOwnerNext,unlinkAndPermitNext,beginFreeNext]
example : Safe witness := by simp [Safe,witness,initial,closeSourceNext,dropOwnerNext,unlinkAndPermitNext,beginFreeNext,loseFreeResultNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]
example : ¬ (settleFreeGuard witness) := by simp [Safe,witness,initial,closeSourceNext,dropOwnerNext,unlinkAndPermitNext,beginFreeNext,loseFreeResultNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]

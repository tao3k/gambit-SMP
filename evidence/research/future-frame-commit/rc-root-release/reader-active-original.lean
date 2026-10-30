import RcRootRelease
open RcRootReleaseAst
def witness : State := settleFreeNext (backendReceiptNext (beginFreeNext (unlinkAndPermitNext (dropOwnerNext (closeSourceNext (enterReaderNext (initial)))))))
example : enterReaderGuard (initial) := by simp [enterReaderGuard,initial]
example : closeSourceGuard (enterReaderNext (initial)) := by simp [closeSourceGuard,initial,enterReaderNext]
example : dropOwnerGuard (closeSourceNext (enterReaderNext (initial))) := by simp [dropOwnerGuard,initial,enterReaderNext,closeSourceNext]
example : unlinkAndPermitGuard (dropOwnerNext (closeSourceNext (enterReaderNext (initial)))) := by simp [unlinkAndPermitGuard,initial,enterReaderNext,closeSourceNext,dropOwnerNext]
example : beginFreeGuard (unlinkAndPermitNext (dropOwnerNext (closeSourceNext (enterReaderNext (initial))))) := by simp [beginFreeGuard,initial,enterReaderNext,closeSourceNext,dropOwnerNext,unlinkAndPermitNext]
example : backendReceiptGuard (beginFreeNext (unlinkAndPermitNext (dropOwnerNext (closeSourceNext (enterReaderNext (initial)))))) := by simp [backendReceiptGuard,initial,enterReaderNext,closeSourceNext,dropOwnerNext,unlinkAndPermitNext,beginFreeNext]
example : settleFreeGuard (backendReceiptNext (beginFreeNext (unlinkAndPermitNext (dropOwnerNext (closeSourceNext (enterReaderNext (initial))))))) := by simp [settleFreeGuard,initial,enterReaderNext,closeSourceNext,dropOwnerNext,unlinkAndPermitNext,beginFreeNext,backendReceiptNext]
example : Safe witness := by simp [Safe,witness,initial,enterReaderNext,closeSourceNext,dropOwnerNext,unlinkAndPermitNext,beginFreeNext,backendReceiptNext,settleFreeNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]
example : ¬ (retireDomainGuard witness) := by simp [Safe,witness,initial,enterReaderNext,closeSourceNext,dropOwnerNext,unlinkAndPermitNext,beginFreeNext,backendReceiptNext,settleFreeNext,acquireBorrowGuard,exportAliasGuard,closeSourceGuard,dropOwnerGuard,returnBorrowGuard,returnAliasGuard,beginScanGuard,endScanGuard,enterReaderGuard,exitReaderGuard,unlinkAndPermitGuard,beginFreeGuard,loseFreeResultGuard,backendReceiptGuard,settleFreeGuard,retireDomainGuard]

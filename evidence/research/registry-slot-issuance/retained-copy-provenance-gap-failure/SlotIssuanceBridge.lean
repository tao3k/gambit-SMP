import SlotIssuance
import StorageIntervals
import SlotMappingAst
namespace SlotIssuanceBridge
open SlotIssuanceAst
theorem aliasKeepsBackingPremise (q : State) (h : Safe q) (a : q.mode = 1) (l : q.reg = 2 ∨ q.reg = 3) : q.storage = 1 ∨ q.storage = 2 := by
 have lease := SlotIssuance.aliasBindingStable q h a l
 simp_all [Safe]
theorem oldParentAliasFreeDenied (p : SlotMappingAst.State) (alias : p.alias = 1) (live : p.d1 = 2) : ¬ SlotMappingAst.freeStore0Guard p := by
 simp [SlotMappingAst.freeStore0Guard,alias,live]
theorem backingReceiptSeparate (q : State) (g : reclaimStorageGuard q) : q.backing = 1 ∧ q.lease = 0 ∧ q.sourceBorrow = 0 := by
 simp_all [reclaimStorageGuard]
theorem copyLeaseDoesNotDrainTargetBorrow (q : State) (g : releaseCopyLeaseGuard q) :
 releaseCopyLeaseGuard {q with borrow := 1} := by
 simpa [releaseCopyLeaseGuard] using g
end SlotIssuanceBridge

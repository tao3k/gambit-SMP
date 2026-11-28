import SealStart
import FrameRootComposition
namespace SealStartComposition
-- The old receipt and physical cover are explicit premises, not inferred from a phase bit.
theorem copyingKeepsConditionalBudget (q : SealStartAst.State) (h : SealStartAst.Safe q)
 (copying : q.phase=2) (old : FrameSealRootAst.State)
 (oldSafe : FrameSealRootAst.Safe old) (oldReceipt : old.receipt=true)
 (pieces : List ProducerCapacity.SourcePiece) (lo hi : Int)
 (cover : ProducerCapacity.SourceCover lo hi pieces) (extent : hi-lo≤old.Q) :
 q.copyPin=true ∧ q.reclaimed=false ∧ ProducerCapacity.destinationSum pieces+old.A+old.T≤old.B := by
 have alive := SealStart.copyingAlive q h copying
 exact ⟨alive.1,alive.2,FrameRootComposition.sourceBudgetFromReceipt old oldSafe oldReceipt pieces lo hi cover extent⟩
-- Process-global loader lifetime is strictly stronger than one VM's local detach.
def GlobalRetireReady (localRetired : Bool) (otherOwners : Int) (loaderClosed : Bool) : Prop :=
 localRetired=true ∧ otherOwners=0 ∧ loaderClosed=true
theorem localReceiptIsInsufficient : ¬GlobalRetireReady true 1 true := by
 simp [GlobalRetireReady]
theorem globalReleaseNeedsAllOwners (localRetired loaderClosed : Bool) (otherOwners : Int)
 (h : GlobalRetireReady localRetired otherOwners loaderClosed) : otherOwners=0 ∧ loaderClosed=true := by
 exact ⟨h.2.1,h.2.2⟩
theorem globalReleaseFromLocalReceipt (q : SealStartAst.State) (localDone : q.reclaimed=true)
 (otherOwners : Int) (allOtherOwnersDetached : otherOwners=0) (loaderClosed : Bool)
 (admissionClosed : loaderClosed=true) : GlobalRetireReady q.reclaimed otherOwners loaderClosed := by
 exact ⟨localDone,allOtherOwnersDetached,admissionClosed⟩
end SealStartComposition

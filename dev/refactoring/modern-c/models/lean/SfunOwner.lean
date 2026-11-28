import SfunCallSteps
import SfunConversionSteps
import SfunFinalUseSteps
import SfunEscapeSteps
import SfunReleaseSteps
import SfunReceiptSteps
import SfunContinuationSteps
import SfunRetirementSteps
namespace SfunOwner
open SfunOwnerAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · exact g.2.symm ▸ bodyCallPreserves q h g.1
 · exact g.2.symm ▸ inputConversionFailsPreserves q h g.1
 · exact g.2.symm ▸ captureCurrentPreserves q h g.1
 · exact g.2.symm ▸ callReturnsPreserves q h g.1
 · exact g.2.symm ▸ resultConversionFailsPreserves q h g.1
 · exact g.2.symm ▸ retryHandlerPreserves q h g.1
 · exact g.2.symm ▸ resultConversionSucceedsPreserves q h g.1
 · exact g.2.symm ▸ closeAdmissionPreserves q h g.1
 · exact g.2.symm ▸ signLocalClosurePreserves q h g.1
 · exact g.2.symm ▸ enterNestedPreserves q h g.1
 · exact g.2.symm ▸ leaveNestedPreserves q h g.1
 · exact g.2.symm ▸ outwardUnknownPreserves q h g.1
 · exact g.2.symm ▸ drainDescendantPreserves q h g.1
 · exact g.2.symm ▸ ackNativeExitPreserves q h g.1
 · exact g.2.symm ▸ signEscapedClosurePreserves q h g.1
 · exact g.2.symm ▸ beginReleasePreserves q h g.1
 · exact g.2.symm ▸ physicalDropPreserves q h g.1
 · exact g.2.symm ▸ commitDropPreserves q h g.1
 · exact g.2.symm ▸ loseClosureReplyPreserves q h g.1
 · exact g.2.symm ▸ queryClosurePreserves q h g.1
 · exact g.2.symm ▸ observeOldInvocationPreserves q h g.1
 · exact g.2.symm ▸ observeOldOwnerPreserves q h g.1
 · exact g.2.symm ▸ resumeOldReturnPreserves q h g.1
 · exact g.2.symm ▸ resumeExpiredPrefixPreserves q h g.1
 · exact g.2.symm ▸ rejectExpiredReturnPreserves q h g.1
 · exact g.2.symm ▸ dropCapturedPreserves q h g.1
 · exact g.2.symm ▸ beginGcPreserves q h g.1
 · exact g.2.symm ▸ endGcPreserves q h g.1
 · exact g.2.symm ▸ retireRootsPreserves q h g.1
 · exact g.2.symm ▸ retireCodePreserves q h g.1
 · exact g.2.symm ▸ newOwnerPreserves q h g.1
 · simpa [g] using h
inductive Reachable : State → Prop where
 | init : Reachable initial
 | next {q t : State} : Reachable q → Step q t → Reachable t
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | init => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem invocationDoesNotClose (q : State) (h : Safe q) (g : q.stage=2) : q.valid=1 ∧ q.ref=1 ∧ q.done=0 ∧ q.closeOwner=0 := by
 grind [Safe]
theorem liveOwnerDuringRetry (q : State) (h : Safe q) (g : q.stage=3) : q.gate=1 ∧ q.valid=1 ∧ q.ref=1 := by
 grind [Safe]
theorem activeHasFreshEpoch (q : State) (h : Safe q) (g : q.active=1) : q.completed<q.epoch ∧ q.valid=1 ∧ q.gate=1 := by
 grind [Safe]
theorem signedClosureCut (q : State) (h : Safe q) (g : q.closeOwner>0) : q.closeOwner=q.owner ∧ q.closeEpoch=q.epoch ∧ q.gate=0 ∧ q.active=0 ∧ q.borrowers=0 := by
 grind [Safe]
theorem unknownRetainsCustody (q : State) (h : Safe q) (g : q.stage=10) : q.ref=1 ∧ q.done=0 ∧ q.root=1 ∧ q.code=1 ∧ q.closeOwner=0 := by
 grind [Safe]
theorem effectGapHasCustody (q : State) (h : Safe q) (g : q.stage=6) : q.critical=1 ∧ q.ref=0 ∧ q.effects=1 ∧ q.done=0 ∧ q.gc=0 ∧ q.root=1 := by
 grind [Safe]
theorem settledExactlyOnce (q : State) (h : Safe q) (g : q.done=1) : q.effects=1 ∧ q.ref=0 ∧ q.closeOwner=q.owner := by
 grind [Safe]
theorem captureKeepsRootsAndCode (q : State) (h : Safe q) (g : q.captured=1) : q.root=1 ∧ q.code=1 := by
 grind [Safe]
theorem retirementCut (q : State) (h : Safe q) (g : q.code=0) : q.root=0 ∧ q.captured=0 ∧ q.done=1 ∧ q.gc=0 := by
 grind [Safe]
theorem physicalEffectExcludedFromGc (q : State) (h : Safe q) (g : q.critical=1) : q.gc=0 ∧ q.borrowers=0 := by
 grind [Safe]
theorem expiredOwnerNotReopened (q : State) (h : Safe q) (g : q.stage=7) : q.valid=0 ∧ q.gate=0 ∧ q.active=0 := by
 grind [Safe]
theorem generationDoesNotAlias (q : State) (h : Safe q) (g : q.owner=2) : q.oldOwner=1 ∧ q.oldOwner≠q.owner := by
 grind [Safe]
theorem oldInvocationQueryDoesNotSettle (q : State) : (observeOldInvocationNext q).active=q.active ∧ (observeOldInvocationNext q).ref=q.ref ∧ (observeOldInvocationNext q).closeOwner=q.closeOwner := by exact ⟨rfl,rfl,rfl⟩
theorem oldOwnerQueryDoesNotSettle (q : State) : (observeOldOwnerNext q).effects=q.effects ∧ (observeOldOwnerNext q).ref=q.ref := by exact ⟨rfl,rfl⟩
theorem resumedOriginCompletesCurrent (q : State) : (resumeOldReturnNext q).completed=q.epoch ∧ (resumeOldReturnNext q).effects=q.effects := by exact ⟨rfl,rfl⟩
theorem receiptQueryDoesNotDrop (q : State) : (queryClosureNext q).ref=q.ref ∧ (queryClosureNext q).effects=q.effects := by exact ⟨rfl,rfl⟩
end SfunOwner

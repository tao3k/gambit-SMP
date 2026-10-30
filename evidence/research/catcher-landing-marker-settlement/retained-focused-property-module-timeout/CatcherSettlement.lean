import CatcherPreparationSteps
import CatcherLandingSteps
import CatcherMarkerSteps
import CatcherGcSteps
namespace CatcherSettlement
open CatcherSettlementAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · exact g.2.symm ▸ prepareFirstPreserves q h g.1
 · exact g.2.symm ▸ prepareSecondPreserves q h g.1
 · exact g.2.symm ▸ rollbackPartialPreserves q h g.1
 · exact g.2.symm ▸ rollbackReadyPreserves q h g.1
 · exact g.2.symm ▸ preparationUnknownPreserves q h g.1
 · exact g.2.symm ▸ auditPreparationPreserves q h g.1
 · exact g.2.symm ▸ publishEscrowPreserves q h g.1
 · exact g.2.symm ▸ escrowReplyLostPreserves q h g.1
 · exact g.2.symm ▸ queryEscrowPreserves q h g.1
 · exact g.2.symm ▸ issueTransferPreserves q h g.1
 · exact g.2.symm ▸ issueOtherErrorPreserves q h g.1
 · exact g.2.symm ▸ catchInnerPreserves q h g.1
 · exact g.2.symm ▸ restoreInnerCatcherPreserves q h g.1
 · exact g.2.symm ▸ catchOuterPreserves q h g.1
 · exact g.2.symm ▸ restoreOuterCatcherPreserves q h g.1
 · exact g.2.symm ▸ borrowFreshPreserves q h g.1
 · exact g.2.symm ▸ releaseBorrowPreserves q h g.1
 · exact g.2.symm ▸ validateLandingPreserves q h g.1
 · exact g.2.symm ▸ publishLandingPreserves q h g.1
 · exact g.2.symm ▸ landingReplyLostPreserves q h g.1
 · exact g.2.symm ▸ queryLandingPreserves q h g.1
 · exact g.2.symm ▸ beginInnerReleasePreserves q h g.1
 · exact g.2.symm ▸ decrementInnerPreserves q h g.1
 · exact g.2.symm ▸ commitInnerReleasePreserves q h g.1
 · exact g.2.symm ▸ innerReplyLostPreserves q h g.1
 · exact g.2.symm ▸ queryInnerReleasePreserves q h g.1
 · exact g.2.symm ▸ nativeTargetReturnedPreserves q h g.1
 · exact g.2.symm ▸ beginOuterReleasePreserves q h g.1
 · exact g.2.symm ▸ decrementOuterPreserves q h g.1
 · exact g.2.symm ▸ commitOuterReleasePreserves q h g.1
 · exact g.2.symm ▸ outerReplyLostPreserves q h g.1
 · exact g.2.symm ▸ queryOuterReleasePreserves q h g.1
 · exact g.2.symm ▸ settleGuardsPreserves q h g.1
 · exact g.2.symm ▸ resumeCapturedPreserves q h g.1
 · exact g.2.symm ▸ finishResumptionPreserves q h g.1
 · exact g.2.symm ▸ dropCapturedPreserves q h g.1
 · exact g.2.symm ▸ startGcPreserves q h g.1
 · exact g.2.symm ▸ rewriteRootOnlyPreserves q h g.1
 · exact g.2.symm ▸ rewriteRegistryFirstPreserves q h g.1
 · exact g.2.symm ▸ rewriteContextSlotPreserves q h g.1
 · exact g.2.symm ▸ initializeCopiedObjectPreserves q h g.1
 · exact g.2.symm ▸ finishGcPreserves q h g.1
 · exact g.2.symm ▸ closeRootAdmissionPreserves q h g.1
 · exact g.2.symm ▸ retireRootsPreserves q h g.1
 · exact g.2.symm ▸ ackDescriptorGracePreserves q h g.1
 · exact g.2.symm ▸ retireDescriptorPreserves q h g.1
 · simpa [g] using h
inductive Reachable : State → Prop where
 | init : Reachable initial
 | next {q t : State} : Reachable q → Step q t → Reachable t
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | init => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem partialKeepsOriginal (q : State) (h : Safe q) (g : q.escrow=0) : q.root=1 ∧ q.descriptor=1 ∧ q.refI=1 ∧ q.refO=1 ∧ q.validI=1 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h89,h90,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h110,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem landingIssuerCut (q : State) (h : Safe q) (g : q.receipt=1) : q.caught=1 ∧ q.current=0 ∧ q.issued=1 ∧ q.validated=1 ∧ q.errorClass=1 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h107,h108,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem transitHasNoReceipt (q : State) (h : Safe q) (g : q.phase=6) : q.receipt=0 ∧ q.caught=2 ∧ q.current=1 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,h9,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h48,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h104,_,_,_,h108,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem innerGapHasCustodian (q : State) (h : Safe q) (g : q.phase=10) : q.critical=1 ∧ q.borrow=1 ∧ q.refI=0 ∧ q.doneI=0 ∧ q.reader=0 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h112,_,_,_,_,_,_,_,_,_,h122,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem outerGapHasCustodian (q : State) (h : Safe q) (g : q.phase=12) : q.critical=2 ∧ q.borrow=1 ∧ q.refO=0 ∧ q.doneO=0 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h114,_,_,_,_,_,_,_,_,_,h124,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem innerExactlyOnce (q : State) (h : Safe q) (g : q.doneI=1) : q.effectsI=1 ∧ q.refI=0 ∧ q.receipt=1 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h54,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h116,_,h118,_,h120,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem outerAfterInner (q : State) (h : Safe q) (g : q.doneO=1) : q.doneI=1 ∧ q.effectsO=1 ∧ q.refO=0 ∧ q.targetActive=0 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h55,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h84,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h117,_,h119,_,h121,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem preReturnFrameLive (q : State) (h : Safe q) (g : q.phase=8) : q.targetActive=1 ∧ q.receipt=0 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,h9,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h48,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h82,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h108,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem nativeBorrowFresh (q : State) (h : Safe q) (g : q.borrow=1) : q.cache=q.slot ∧ q.reader=0 ∧ q.root=1 ∧ q.copyReady=1 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h22,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h61,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h123,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h141,_,_,_,_,_,_,_,_⟩
 omega
theorem unreadyObjectHasCustodian (q : State) (h : Safe q) (g : q.copyReady=0) : q.reader=1 ∧ q.borrow=0 ∧ q.critical=0 ∧ q.root=1 ∧ q.descriptor=1 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h123,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem partialCopyNotExposed (q : State) (h : Safe q) (g : q.scanStage=1) : q.reader=1 ∧ q.borrow=0 ∧ q.shotActive=1 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h140,_,_,h143,_,_,_,_,_,_⟩
 omega
theorem resumedSlotCoherent (q : State) (h : Safe q) (g : q.shotActive=1 ∧ q.reader=0) : q.contextSlot=q.slot := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h142,_,_,_,_,_,_,_⟩
 omega
theorem retirementCut (q : State) (h : Safe q) (g : q.descriptor=0) : q.rootRetired=1 ∧ q.captured=0 ∧ q.reader=0 ∧ q.doneI=1 ∧ q.doneO=1 ∧ q.targetActive=0 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h85,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h125,_,_,_,_,_,_,h132,_,h134,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem captureKeepsDescriptor (q : State) (h : Safe q) (g : q.captured=1) : q.descriptor=1 ∧ q.root=1 := by
 rcases h with ⟨_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h18,h19,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h57,h58,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,h131,_,_,h134,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_⟩
 omega
theorem queryInnerDoesNotReplay (q : State) : (queryInnerReleaseNext q).effectsI=q.effectsI ∧ (queryInnerReleaseNext q).refI=q.refI := by constructor <;> rfl
theorem queryOuterDoesNotReplay (q : State) : (queryOuterReleaseNext q).effectsO=q.effectsO ∧ (queryOuterReleaseNext q).refO=q.refO := by constructor <;> rfl
end CatcherSettlement

import CatcherLandingProperties
import CatcherLifetimeProperties
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
end CatcherSettlement

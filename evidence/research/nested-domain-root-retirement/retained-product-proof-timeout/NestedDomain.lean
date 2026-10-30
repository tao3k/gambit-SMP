import NestedDomainAst
namespace NestedDomain
open NestedDomainAst
set_option maxRecDepth 10000
set_option linter.unusedSimpArgs false
theorem publishRootsPreserves (q : State) (h : Safe q) (g : publishRootsGuard q) : Safe (publishRootsNext q) := by
 simp only [Safe,publishRootsGuard] at h g
 dsimp [Safe,publishRootsNext]
 omega
theorem publicationReplyLostPreserves (q : State) (h : Safe q) (g : publicationReplyLostGuard q) : Safe (publicationReplyLostNext q) := by
 simp only [Safe,publicationReplyLostGuard] at h g
 dsimp [Safe,publicationReplyLostNext]
 omega
theorem publicationAbsentUnknownPreserves (q : State) (h : Safe q) (g : publicationAbsentUnknownGuard q) : Safe (publicationAbsentUnknownNext q) := by
 simp only [Safe,publicationAbsentUnknownGuard] at h g
 dsimp [Safe,publicationAbsentUnknownNext]
 omega
theorem resolvePublicationPreserves (q : State) (h : Safe q) (g : resolvePublicationGuard q) : Safe (resolvePublicationNext q) := by
 simp only [Safe,resolvePublicationGuard] at h g
 dsimp [Safe,resolvePublicationNext]
 omega
theorem acknowledgeRootsPreserves (q : State) (h : Safe q) (g : acknowledgeRootsGuard q) : Safe (acknowledgeRootsNext q) := by
 simp only [Safe,acknowledgeRootsGuard] at h g
 dsimp [Safe,acknowledgeRootsNext]
 omega
theorem releaseSourcePreserves (q : State) (h : Safe q) (g : releaseSourceGuard q) : Safe (releaseSourceNext q) := by
 simp only [Safe,releaseSourceGuard] at h g
 dsimp [Safe,releaseSourceNext]
 omega
theorem enterOuterPreserves (q : State) (h : Safe q) (g : enterOuterGuard q) : Safe (enterOuterNext q) := by
 simp only [Safe,enterOuterGuard] at h g
 dsimp [Safe,enterOuterNext]
 omega
theorem reserveInnerOfferPreserves (q : State) (h : Safe q) (g : reserveInnerOfferGuard q) : Safe (reserveInnerOfferNext q) := by
 simp only [Safe,reserveInnerOfferGuard] at h g
 dsimp [Safe,reserveInnerOfferNext]
 omega
theorem publishInnerRootsPreserves (q : State) (h : Safe q) (g : publishInnerRootsGuard q) : Safe (publishInnerRootsNext q) := by
 simp only [Safe,publishInnerRootsGuard] at h g
 dsimp [Safe,publishInnerRootsNext]
 omega
theorem acknowledgeInnerRootsPreserves (q : State) (h : Safe q) (g : acknowledgeInnerRootsGuard q) : Safe (acknowledgeInnerRootsNext q) := by
 simp only [Safe,acknowledgeInnerRootsGuard] at h g
 dsimp [Safe,acknowledgeInnerRootsNext]
 omega
theorem releaseInnerSourcePreserves (q : State) (h : Safe q) (g : releaseInnerSourceGuard q) : Safe (releaseInnerSourceNext q) := by
 simp only [Safe,releaseInnerSourceGuard] at h g
 dsimp [Safe,releaseInnerSourceNext]
 omega
theorem enterInnerPreserves (q : State) (h : Safe q) (g : enterInnerGuard q) : Safe (enterInnerNext q) := by
 simp only [Safe,enterInnerGuard] at h g
 dsimp [Safe,enterInnerNext]
 omega
theorem captureInnerPreserves (q : State) (h : Safe q) (g : captureInnerGuard q) : Safe (captureInnerNext q) := by
 simp only [Safe,captureInnerGuard] at h g
 dsimp [Safe,captureInnerNext]
 omega
theorem startGcReaderPreserves (q : State) (h : Safe q) (g : startGcReaderGuard q) : Safe (startGcReaderNext q) := by
 simp only [Safe,startGcReaderGuard] at h g
 dsimp [Safe,startGcReaderNext]
 omega
theorem finishGcReaderPreserves (q : State) (h : Safe q) (g : finishGcReaderGuard q) : Safe (finishGcReaderNext q) := by
 simp only [Safe,finishGcReaderGuard] at h g
 dsimp [Safe,finishGcReaderNext]
 omega
theorem escrowOuterUnwindPreserves (q : State) (h : Safe q) (g : escrowOuterUnwindGuard q) : Safe (escrowOuterUnwindNext q) := by
 simp only [Safe,escrowOuterUnwindGuard] at h g
 dsimp [Safe,escrowOuterUnwindNext]
 omega
theorem issueOuterUnwindPreserves (q : State) (h : Safe q) (g : issueOuterUnwindGuard q) : Safe (issueOuterUnwindNext q) := by
 simp only [Safe,issueOuterUnwindGuard] at h g
 dsimp [Safe,issueOuterUnwindNext]
 omega
theorem landingObservedPreserves (q : State) (h : Safe q) (g : landingObservedGuard q) : Safe (landingObservedNext q) := by
 simp only [Safe,landingObservedGuard] at h g
 dsimp [Safe,landingObservedNext]
 omega
theorem landingReplyLostPreserves (q : State) (h : Safe q) (g : landingReplyLostGuard q) : Safe (landingReplyLostNext q) := by
 simp only [Safe,landingReplyLostGuard] at h g
 dsimp [Safe,landingReplyLostNext]
 omega
theorem reconcileLandingPreserves (q : State) (h : Safe q) (g : reconcileLandingGuard q) : Safe (reconcileLandingNext q) := by
 simp only [Safe,reconcileLandingGuard] at h g
 dsimp [Safe,reconcileLandingNext]
 omega
theorem settleInnerGuardPreserves (q : State) (h : Safe q) (g : settleInnerGuardGuard q) : Safe (settleInnerGuardNext q) := by
 simp only [Safe,settleInnerGuardGuard] at h g
 dsimp [Safe,settleInnerGuardNext]
 omega
theorem settleOuterGuardPreserves (q : State) (h : Safe q) (g : settleOuterGuardGuard q) : Safe (settleOuterGuardNext q) := by
 simp only [Safe,settleOuterGuardGuard] at h g
 dsimp [Safe,settleOuterGuardNext]
 omega
theorem resumeCapturedPreserves (q : State) (h : Safe q) (g : resumeCapturedGuard q) : Safe (resumeCapturedNext q) := by
 simp only [Safe,resumeCapturedGuard] at h g
 dsimp [Safe,resumeCapturedNext]
 omega
theorem rejectInnerReturnPreserves (q : State) (h : Safe q) (g : rejectInnerReturnGuard q) : Safe (rejectInnerReturnNext q) := by
 simp only [Safe,rejectInnerReturnGuard] at h g
 dsimp [Safe,rejectInnerReturnNext]
 omega
theorem finishResumptionPreserves (q : State) (h : Safe q) (g : finishResumptionGuard q) : Safe (finishResumptionNext q) := by
 simp only [Safe,finishResumptionGuard] at h g
 dsimp [Safe,finishResumptionNext]
 omega
theorem closeCapturedHoldersPreserves (q : State) (h : Safe q) (g : closeCapturedHoldersGuard q) : Safe (closeCapturedHoldersNext q) := by
 simp only [Safe,closeCapturedHoldersGuard] at h g
 dsimp [Safe,closeCapturedHoldersNext]
 omega
theorem closeRootAdmissionPreserves (q : State) (h : Safe q) (g : closeRootAdmissionGuard q) : Safe (closeRootAdmissionNext q) := by
 simp only [Safe,closeRootAdmissionGuard] at h g
 dsimp [Safe,closeRootAdmissionNext]
 omega
theorem closeCodeAdmissionPreserves (q : State) (h : Safe q) (g : closeCodeAdmissionGuard q) : Safe (closeCodeAdmissionNext q) := by
 simp only [Safe,closeCodeAdmissionGuard] at h g
 dsimp [Safe,closeCodeAdmissionNext]
 omega
theorem ackRootGracePreserves (q : State) (h : Safe q) (g : ackRootGraceGuard q) : Safe (ackRootGraceNext q) := by
 simp only [Safe,ackRootGraceGuard] at h g
 dsimp [Safe,ackRootGraceNext]
 omega
theorem retireRootSlotsPreserves (q : State) (h : Safe q) (g : retireRootSlotsGuard q) : Safe (retireRootSlotsNext q) := by
 simp only [Safe,retireRootSlotsGuard] at h g
 dsimp [Safe,retireRootSlotsNext]
 omega
theorem ackCodeGracePreserves (q : State) (h : Safe q) (g : ackCodeGraceGuard q) : Safe (ackCodeGraceNext q) := by
 simp only [Safe,ackCodeGraceGuard] at h g
 dsimp [Safe,ackCodeGraceNext]
 omega
theorem retireDescriptorPreserves (q : State) (h : Safe q) (g : retireDescriptorGuard q) : Safe (retireDescriptorNext q) := by
 simp only [Safe,retireDescriptorGuard] at h g
 dsimp [Safe,retireDescriptorNext]
 omega
theorem detachNativeOwnerPreserves (q : State) (h : Safe q) (g : detachNativeOwnerGuard q) : Safe (detachNativeOwnerNext q) := by
 simp only [Safe,detachNativeOwnerGuard] at h g
 dsimp [Safe,detachNativeOwnerNext]
 omega
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · exact g.2.symm ▸ publishRootsPreserves q h g.1
 · exact g.2.symm ▸ publicationReplyLostPreserves q h g.1
 · exact g.2.symm ▸ publicationAbsentUnknownPreserves q h g.1
 · exact g.2.symm ▸ resolvePublicationPreserves q h g.1
 · exact g.2.symm ▸ acknowledgeRootsPreserves q h g.1
 · exact g.2.symm ▸ releaseSourcePreserves q h g.1
 · exact g.2.symm ▸ enterOuterPreserves q h g.1
 · exact g.2.symm ▸ reserveInnerOfferPreserves q h g.1
 · exact g.2.symm ▸ publishInnerRootsPreserves q h g.1
 · exact g.2.symm ▸ acknowledgeInnerRootsPreserves q h g.1
 · exact g.2.symm ▸ releaseInnerSourcePreserves q h g.1
 · exact g.2.symm ▸ enterInnerPreserves q h g.1
 · exact g.2.symm ▸ captureInnerPreserves q h g.1
 · exact g.2.symm ▸ startGcReaderPreserves q h g.1
 · exact g.2.symm ▸ finishGcReaderPreserves q h g.1
 · exact g.2.symm ▸ escrowOuterUnwindPreserves q h g.1
 · exact g.2.symm ▸ issueOuterUnwindPreserves q h g.1
 · exact g.2.symm ▸ landingObservedPreserves q h g.1
 · exact g.2.symm ▸ landingReplyLostPreserves q h g.1
 · exact g.2.symm ▸ reconcileLandingPreserves q h g.1
 · exact g.2.symm ▸ settleInnerGuardPreserves q h g.1
 · exact g.2.symm ▸ settleOuterGuardPreserves q h g.1
 · exact g.2.symm ▸ resumeCapturedPreserves q h g.1
 · exact g.2.symm ▸ rejectInnerReturnPreserves q h g.1
 · exact g.2.symm ▸ finishResumptionPreserves q h g.1
 · exact g.2.symm ▸ closeCapturedHoldersPreserves q h g.1
 · exact g.2.symm ▸ closeRootAdmissionPreserves q h g.1
 · exact g.2.symm ▸ closeCodeAdmissionPreserves q h g.1
 · exact g.2.symm ▸ ackRootGracePreserves q h g.1
 · exact g.2.symm ▸ retireRootSlotsPreserves q h g.1
 · exact g.2.symm ▸ ackCodeGracePreserves q h g.1
 · exact g.2.symm ▸ retireDescriptorPreserves q h g.1
 · exact g.2.symm ▸ detachNativeOwnerPreserves q h g.1
 · simpa [g] using h
inductive Reachable : State → Prop where
 | init : Reachable initial
 | next {q t : State} : Reachable q → Step q t → Reachable t
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | init => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem innerEntryHandoff (q : State) (h : Safe q) (g : q.innerGuard=1) : q.innerTarget=1 ∧ q.innerAck=1 ∧ q.innerSource=0 ∧ q.descriptor=1 := by
 simp only [Safe] at h
 omega
theorem entryHandoff (q : State) (h : Safe q) (g : q.outerGuard=1) : q.target=1 ∧ q.ack=1 ∧ q.source=0 ∧ q.descriptor=1 := by
 simp only [Safe] at h
 omega
theorem outerInvalidatesInner (q : State) (h : Safe q) (g : q.unwind≥1) : q.outerRight=0 ∧ q.innerRight=0 := by
 simp only [Safe] at h
 omega
theorem unknownKeepsCustody (q : State) (h : Safe q) (g : q.outcome=1) : q.outerGuard=2 ∧ q.innerGuard=2 ∧ q.target=1 ∧ q.descriptor=1 := by
 simp only [Safe] at h
 omega
theorem scannerPinsDescriptor (q : State) (h : Safe q) (g : q.gcReader=1) : q.descriptor=1 ∧ q.target=1 := by
 simp only [Safe] at h
 omega
theorem capturePinsDescriptor (q : State) (h : Safe q) (g : q.captured=1) : q.descriptor=1 ∧ q.target=1 := by
 simp only [Safe] at h
 omega
theorem descriptorRetirementCut (q : State) (h : Safe q) (g : q.descriptor=0) : q.gcReader=0 ∧ q.captured=0 ∧ q.outerGuard=3 ∧ q.innerGuard=3 ∧ q.rootRetired=1 ∧ q.landed=1 := by
 simp only [Safe] at h
 omega
theorem lateEntryClosed (q : State) (h : Safe q) (g : q.rootClosed=1) : q.shotGuard=0 ∧ q.captured=0 := by
 simp only [Safe] at h
 omega
theorem retiredRootsNoReader (q : State) (h : Safe q) (g : q.rootRetired=1) : q.gcReader=0 ∧ q.source=0 ∧ q.target=0 := by
 simp only [Safe] at h
 omega
theorem settledOuterNeedsSettledInner (q : State) (h : Safe q) (g : q.outerGuard=3) : q.innerGuard=3 ∧ q.landed=1 := by
 simp only [Safe] at h
 omega
theorem resumptionNoNativeRevival (q : State) (h : Safe q) (g : q.shotGuard=1) : q.innerRight=0 ∧ q.outerRight=0 ∧ q.shotTicket≥1 := by
 simp only [Safe] at h
 omega
end NestedDomain

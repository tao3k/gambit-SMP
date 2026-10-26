import NestedDomainAst
namespace NestedDomain
open NestedDomainAst
set_option maxRecDepth 10000
set_option linter.unusedSimpArgs false
theorem publishRootsPreserves (q : State) (h : Safe q) (g : publishRootsGuard q) : Safe (publishRootsNext q) := by
 simp_all [publishRootsGuard,publishRootsNext,Safe]
 <;> omega
theorem publicationReplyLostPreserves (q : State) (h : Safe q) (g : publicationReplyLostGuard q) : Safe (publicationReplyLostNext q) := by
 simp_all [publicationReplyLostGuard,publicationReplyLostNext,Safe]
 <;> omega
theorem publicationAbsentUnknownPreserves (q : State) (h : Safe q) (g : publicationAbsentUnknownGuard q) : Safe (publicationAbsentUnknownNext q) := by
 simp_all [publicationAbsentUnknownGuard,publicationAbsentUnknownNext,Safe]
 <;> omega
theorem resolvePublicationPreserves (q : State) (h : Safe q) (g : resolvePublicationGuard q) : Safe (resolvePublicationNext q) := by
 simp_all [resolvePublicationGuard,resolvePublicationNext,Safe]
 <;> omega
theorem acknowledgeRootsPreserves (q : State) (h : Safe q) (g : acknowledgeRootsGuard q) : Safe (acknowledgeRootsNext q) := by
 simp_all [acknowledgeRootsGuard,acknowledgeRootsNext,Safe]
 <;> omega
theorem releaseSourcePreserves (q : State) (h : Safe q) (g : releaseSourceGuard q) : Safe (releaseSourceNext q) := by
 simp_all [releaseSourceGuard,releaseSourceNext,Safe]
 <;> omega
theorem enterOuterPreserves (q : State) (h : Safe q) (g : enterOuterGuard q) : Safe (enterOuterNext q) := by
 simp_all [enterOuterGuard,enterOuterNext,Safe]
 <;> omega
theorem enterInnerPreserves (q : State) (h : Safe q) (g : enterInnerGuard q) : Safe (enterInnerNext q) := by
 simp_all [enterInnerGuard,enterInnerNext,Safe]
 <;> omega
theorem captureInnerPreserves (q : State) (h : Safe q) (g : captureInnerGuard q) : Safe (captureInnerNext q) := by
 simp_all [captureInnerGuard,captureInnerNext,Safe]
 <;> omega
theorem startGcReaderPreserves (q : State) (h : Safe q) (g : startGcReaderGuard q) : Safe (startGcReaderNext q) := by
 simp_all [startGcReaderGuard,startGcReaderNext,Safe]
 <;> omega
theorem finishGcReaderPreserves (q : State) (h : Safe q) (g : finishGcReaderGuard q) : Safe (finishGcReaderNext q) := by
 simp_all [finishGcReaderGuard,finishGcReaderNext,Safe]
 <;> omega
theorem escrowOuterUnwindPreserves (q : State) (h : Safe q) (g : escrowOuterUnwindGuard q) : Safe (escrowOuterUnwindNext q) := by
 simp_all [escrowOuterUnwindGuard,escrowOuterUnwindNext,Safe]
 <;> omega
theorem issueOuterUnwindPreserves (q : State) (h : Safe q) (g : issueOuterUnwindGuard q) : Safe (issueOuterUnwindNext q) := by
 simp_all [issueOuterUnwindGuard,issueOuterUnwindNext,Safe]
 <;> omega
theorem landingObservedPreserves (q : State) (h : Safe q) (g : landingObservedGuard q) : Safe (landingObservedNext q) := by
 simp_all [landingObservedGuard,landingObservedNext,Safe]
 <;> omega
theorem landingReplyLostPreserves (q : State) (h : Safe q) (g : landingReplyLostGuard q) : Safe (landingReplyLostNext q) := by
 simp_all [landingReplyLostGuard,landingReplyLostNext,Safe]
 <;> omega
theorem reconcileLandingPreserves (q : State) (h : Safe q) (g : reconcileLandingGuard q) : Safe (reconcileLandingNext q) := by
 simp_all [reconcileLandingGuard,reconcileLandingNext,Safe]
 <;> omega
theorem settleInnerGuardPreserves (q : State) (h : Safe q) (g : settleInnerGuardGuard q) : Safe (settleInnerGuardNext q) := by
 simp_all [settleInnerGuardGuard,settleInnerGuardNext,Safe]
 <;> omega
theorem settleOuterGuardPreserves (q : State) (h : Safe q) (g : settleOuterGuardGuard q) : Safe (settleOuterGuardNext q) := by
 simp_all [settleOuterGuardGuard,settleOuterGuardNext,Safe]
 <;> omega
theorem resumeCapturedPreserves (q : State) (h : Safe q) (g : resumeCapturedGuard q) : Safe (resumeCapturedNext q) := by
 simp_all [resumeCapturedGuard,resumeCapturedNext,Safe]
 <;> omega
theorem rejectInnerReturnPreserves (q : State) (h : Safe q) (g : rejectInnerReturnGuard q) : Safe (rejectInnerReturnNext q) := by
 simp_all [rejectInnerReturnGuard,rejectInnerReturnNext,Safe]
 <;> omega
theorem finishResumptionPreserves (q : State) (h : Safe q) (g : finishResumptionGuard q) : Safe (finishResumptionNext q) := by
 simp_all [finishResumptionGuard,finishResumptionNext,Safe]
 <;> omega
theorem closeCapturedHoldersPreserves (q : State) (h : Safe q) (g : closeCapturedHoldersGuard q) : Safe (closeCapturedHoldersNext q) := by
 simp_all [closeCapturedHoldersGuard,closeCapturedHoldersNext,Safe]
 <;> omega
theorem closeRootAdmissionPreserves (q : State) (h : Safe q) (g : closeRootAdmissionGuard q) : Safe (closeRootAdmissionNext q) := by
 simp_all [closeRootAdmissionGuard,closeRootAdmissionNext,Safe]
 <;> omega
theorem closeCodeAdmissionPreserves (q : State) (h : Safe q) (g : closeCodeAdmissionGuard q) : Safe (closeCodeAdmissionNext q) := by
 simp_all [closeCodeAdmissionGuard,closeCodeAdmissionNext,Safe]
 <;> omega
theorem ackRootGracePreserves (q : State) (h : Safe q) (g : ackRootGraceGuard q) : Safe (ackRootGraceNext q) := by
 simp_all [ackRootGraceGuard,ackRootGraceNext,Safe]
 <;> omega
theorem retireRootSlotsPreserves (q : State) (h : Safe q) (g : retireRootSlotsGuard q) : Safe (retireRootSlotsNext q) := by
 simp_all [retireRootSlotsGuard,retireRootSlotsNext,Safe]
 <;> omega
theorem ackCodeGracePreserves (q : State) (h : Safe q) (g : ackCodeGraceGuard q) : Safe (ackCodeGraceNext q) := by
 simp_all [ackCodeGraceGuard,ackCodeGraceNext,Safe]
 <;> omega
theorem retireDescriptorPreserves (q : State) (h : Safe q) (g : retireDescriptorGuard q) : Safe (retireDescriptorNext q) := by
 simp_all [retireDescriptorGuard,retireDescriptorNext,Safe]
 <;> omega
theorem detachNativeOwnerPreserves (q : State) (h : Safe q) (g : detachNativeOwnerGuard q) : Safe (detachNativeOwnerNext q) := by
 simp_all [detachNativeOwnerGuard,detachNativeOwnerNext,Safe]
 <;> omega
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · rcases g with ⟨g,rfl⟩; exact publishRootsPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact publicationReplyLostPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact publicationAbsentUnknownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact resolvePublicationPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact acknowledgeRootsPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact releaseSourcePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact enterOuterPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact enterInnerPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact captureInnerPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact startGcReaderPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact finishGcReaderPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact escrowOuterUnwindPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact issueOuterUnwindPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact landingObservedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact landingReplyLostPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact reconcileLandingPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact settleInnerGuardPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact settleOuterGuardPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact resumeCapturedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact rejectInnerReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact finishResumptionPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact closeCapturedHoldersPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact closeRootAdmissionPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact closeCodeAdmissionPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact ackRootGracePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact retireRootSlotsPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact ackCodeGracePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact retireDescriptorPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact detachNativeOwnerPreserves q h g
 · simpa [g] using h
inductive Reachable : State → Prop where
 | init : Reachable initial
 | next {q t : State} : Reachable q → Step q t → Reachable t
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | init => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
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

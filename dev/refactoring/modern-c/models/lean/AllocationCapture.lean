import AllocationCaptureAst
namespace AllocationCapture
open AllocationCaptureAst
set_option linter.unusedSimpArgs false
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,issueGuard,issueNext]
theorem metadataRejectPreserves (q : State) (h : Safe q) (g : metadataRejectGuard q) : Safe (metadataRejectNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,metadataRejectGuard,metadataRejectNext]
theorem maskRejectPreserves (q : State) (h : Safe q) (g : maskRejectGuard q) : Safe (maskRejectNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,maskRejectGuard,maskRejectNext]
theorem cancelBeforeMaskPreserves (q : State) (h : Safe q) (g : cancelBeforeMaskGuard q) : Safe (cancelBeforeMaskNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,cancelBeforeMaskGuard,cancelBeforeMaskNext]
theorem maskConfirmedPreserves (q : State) (h : Safe q) (g : maskConfirmedGuard q) : Safe (maskConfirmedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,maskConfirmedGuard,maskConfirmedNext]
theorem invokePreserves (q : State) (h : Safe q) (g : invokeGuard q) : Safe (invokeNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,invokeGuard,invokeNext]
theorem nativeReturnPreserves (q : State) (h : Safe q) (g : nativeReturnGuard q) : Safe (nativeReturnNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,nativeReturnGuard,nativeReturnNext]
theorem capturePreserves (q : State) (h : Safe q) (g : captureGuard q) : Safe (captureNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,captureGuard,captureNext]
theorem armExitOwnerPreserves (q : State) (h : Safe q) (g : armExitOwnerGuard q) : Safe (armExitOwnerNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,armExitOwnerGuard,armExitOwnerNext]
theorem restoreReturnsPreserves (q : State) (h : Safe q) (g : restoreReturnsGuard q) : Safe (restoreReturnsNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,restoreReturnsGuard,restoreReturnsNext]
theorem restoreAbandonsPreserves (q : State) (h : Safe q) (g : restoreAbandonsGuard q) : Safe (restoreAbandonsNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,restoreAbandonsGuard,restoreAbandonsNext]
theorem restoreUnknownPreserves (q : State) (h : Safe q) (g : restoreUnknownGuard q) : Safe (restoreUnknownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,restoreUnknownGuard,restoreUnknownNext]
theorem nativeNullPreserves (q : State) (h : Safe q) (g : nativeNullGuard q) : Safe (nativeNullNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,nativeNullGuard,nativeNullNext]
theorem finishNullPreserves (q : State) (h : Safe q) (g : finishNullGuard q) : Safe (finishNullNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,finishNullGuard,finishNullNext]
theorem restoreNullAbandonsPreserves (q : State) (h : Safe q) (g : restoreNullAbandonsGuard q) : Safe (restoreNullAbandonsNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,restoreNullAbandonsGuard,restoreNullAbandonsNext]
theorem startLoggerPreserves (q : State) (h : Safe q) (g : startLoggerGuard q) : Safe (startLoggerNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,startLoggerGuard,startLoggerNext]
theorem skipLoggerPreserves (q : State) (h : Safe q) (g : skipLoggerGuard q) : Safe (skipLoggerNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,skipLoggerGuard,skipLoggerNext]
theorem loggerReturnsPreserves (q : State) (h : Safe q) (g : loggerReturnsGuard q) : Safe (loggerReturnsNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,loggerReturnsGuard,loggerReturnsNext]
theorem loggerErrorPreserves (q : State) (h : Safe q) (g : loggerErrorGuard q) : Safe (loggerErrorNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,loggerErrorGuard,loggerErrorNext]
theorem nestedEnterPreserves (q : State) (h : Safe q) (g : nestedEnterGuard q) : Safe (nestedEnterNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,nestedEnterGuard,nestedEnterNext]
theorem nestedKnownExitPreserves (q : State) (h : Safe q) (g : nestedKnownExitGuard q) : Safe (nestedKnownExitNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,nestedKnownExitGuard,nestedKnownExitNext]
theorem nestedUnknownExitPreserves (q : State) (h : Safe q) (g : nestedUnknownExitGuard q) : Safe (nestedUnknownExitNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,nestedUnknownExitGuard,nestedUnknownExitNext]
theorem capturedThrowPreserves (q : State) (h : Safe q) (g : capturedThrowGuard q) : Safe (capturedThrowNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,capturedThrowGuard,capturedThrowNext]
theorem handoffPreserves (q : State) (h : Safe q) (g : handoffGuard q) : Safe (handoffNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,handoffGuard,handoffNext]
theorem unrecordedEscapePreserves (q : State) (h : Safe q) (g : unrecordedEscapeGuard q) : Safe (unrecordedEscapeNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,unrecordedEscapeGuard,unrecordedEscapeNext]
theorem inflightEscapePreserves (q : State) (h : Safe q) (g : inflightEscapeGuard q) : Safe (inflightEscapeNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,inflightEscapeGuard,inflightEscapeNext]
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · rcases g with ⟨g,rfl⟩; exact issuePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact metadataRejectPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact maskRejectPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact cancelBeforeMaskPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact maskConfirmedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact invokePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact nativeReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact capturePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact armExitOwnerPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact restoreReturnsPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact restoreAbandonsPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact restoreUnknownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact nativeNullPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact finishNullPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact restoreNullAbandonsPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact startLoggerPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact skipLoggerPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact loggerReturnsPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact loggerErrorPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact nestedEnterPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact nestedKnownExitPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact nestedUnknownExitPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact capturedThrowPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact handoffPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact unrecordedEscapePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact inflightEscapePreserves q h g
 · simpa [g] using h
inductive Reachable : State → Prop where
 | init : Reachable initial
 | next {q t : State} : Reachable q → Step q t → Reachable t
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | init => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem loggerAfterCapture (q : State) (h : Safe q) (g : q.phase=8) : q.captured=1 ∧ q.guard=1 ∧ q.owner=2 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem nestedRetainsParent (q : State) (h : Safe q) (g : q.child=1 ∨ q.child=3) : q.captured=1 ∧ q.guard=1 ∧ q.root=1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem unknownRetainsGuard (q : State) (h : Safe q) (g : q.phase=11 ∨ q.phase=14 ∨ q.phase=17) : q.guard=1 ∧ q.root=1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem unrecordedIsMasked (q : State) (h : Safe q) (g : q.phase=4) : q.disabled=1 ∧ q.guard=1 ∧ q.captured=0 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem knownHandoff (q : State) (h : Safe q) (g : q.phase=15) : q.captured=1 ∧ q.owner=4 ∧ q.child≠1 ∧ q.child≠3 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem atMostOneInvocation (q : State) (h : Safe q) (g : True) : q.calls≤1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
def NormalStep (q t : State) : Prop := (issueGuard q ∧ t=issueNext q) ∨ (metadataRejectGuard q ∧ t=metadataRejectNext q) ∨ (maskRejectGuard q ∧ t=maskRejectNext q) ∨ (cancelBeforeMaskGuard q ∧ t=cancelBeforeMaskNext q) ∨ (maskConfirmedGuard q ∧ t=maskConfirmedNext q) ∨ (invokeGuard q ∧ t=invokeNext q) ∨ (nativeReturnGuard q ∧ t=nativeReturnNext q) ∨ (captureGuard q ∧ t=captureNext q) ∨ (armExitOwnerGuard q ∧ t=armExitOwnerNext q) ∨ (restoreReturnsGuard q ∧ t=restoreReturnsNext q) ∨ (restoreAbandonsGuard q ∧ t=restoreAbandonsNext q) ∨ (restoreUnknownGuard q ∧ t=restoreUnknownNext q) ∨ (nativeNullGuard q ∧ t=nativeNullNext q) ∨ (finishNullGuard q ∧ t=finishNullNext q) ∨ (restoreNullAbandonsGuard q ∧ t=restoreNullAbandonsNext q) ∨ (startLoggerGuard q ∧ t=startLoggerNext q) ∨ (skipLoggerGuard q ∧ t=skipLoggerNext q) ∨ (loggerReturnsGuard q ∧ t=loggerReturnsNext q) ∨ (loggerErrorGuard q ∧ t=loggerErrorNext q) ∨ (nestedEnterGuard q ∧ t=nestedEnterNext q) ∨ (nestedKnownExitGuard q ∧ t=nestedKnownExitNext q) ∨ (nestedUnknownExitGuard q ∧ t=nestedUnknownExitNext q) ∨ (capturedThrowGuard q ∧ t=capturedThrowNext q) ∨ (handoffGuard q ∧ t=handoffNext q) ∨ t=q
theorem normalStepDoesNotLosePointer (q t : State) (h : q.phase≠11) (g : NormalStep q t) : t.phase≠11 := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · rcases g with ⟨_,rfl⟩; simp [issueNext]
 · rcases g with ⟨_,rfl⟩; simp [metadataRejectNext]
 · rcases g with ⟨_,rfl⟩; simp [maskRejectNext]
 · rcases g with ⟨_,rfl⟩; simp [cancelBeforeMaskNext]
 · rcases g with ⟨_,rfl⟩; simp [maskConfirmedNext]
 · rcases g with ⟨_,rfl⟩; simp [invokeNext]
 · rcases g with ⟨_,rfl⟩; simp [nativeReturnNext]
 · rcases g with ⟨_,rfl⟩; simp [captureNext]
 · rcases g with ⟨_,rfl⟩; simp [armExitOwnerNext]
 · rcases g with ⟨_,rfl⟩; simp [restoreReturnsNext]
 · rcases g with ⟨_,rfl⟩; simp [restoreAbandonsNext]
 · rcases g with ⟨_,rfl⟩; simp [restoreUnknownNext]
 · rcases g with ⟨_,rfl⟩; simp [nativeNullNext]
 · rcases g with ⟨_,rfl⟩; simp [finishNullNext]
 · rcases g with ⟨_,rfl⟩; simp [restoreNullAbandonsNext]
 · rcases g with ⟨_,rfl⟩; simp [startLoggerNext]
 · rcases g with ⟨_,rfl⟩; simp [skipLoggerNext]
 · rcases g with ⟨_,rfl⟩; simp [loggerReturnsNext]
 · rcases g with ⟨_,rfl⟩; simp [loggerErrorNext]
 · rcases g with ⟨_,rfl⟩; simp [nestedEnterNext]
 · rcases g with ⟨_,rfl⟩; simp [nestedKnownExitNext]
 · rcases g with ⟨_,rfl⟩; simp [nestedUnknownExitNext]
 · rcases g with ⟨_,rfl⟩; simp [capturedThrowNext]
 · rcases g with ⟨_,rfl⟩; simp [handoffNext]
 · simpa [g] using h
end AllocationCapture

import NativeReturnAst
namespace NativeReturn
open NativeReturnAst
set_option linter.unusedSimpArgs false
theorem enterGuardPreserves (q : State) (h : Safe q) (g : enterGuardGuard q) : Safe (enterGuardNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,enterGuardGuard,enterGuardNext]
theorem captureSchemePreserves (q : State) (h : Safe q) (g : captureSchemeGuard q) : Safe (captureSchemeNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,captureSchemeGuard,captureSchemeNext]
theorem leaveActivationPreserves (q : State) (h : Safe q) (g : leaveActivationGuard q) : Safe (leaveActivationNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,leaveActivationGuard,leaveActivationNext]
theorem resumeFirstPreserves (q : State) (h : Safe q) (g : resumeFirstGuard q) : Safe (resumeFirstNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,resumeFirstGuard,resumeFirstNext]
theorem settleFirstPreserves (q : State) (h : Safe q) (g : settleFirstGuard q) : Safe (settleFirstNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,settleFirstGuard,settleFirstNext]
theorem physicalReturnPreserves (q : State) (h : Safe q) (g : physicalReturnGuard q) : Safe (physicalReturnNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,physicalReturnGuard,physicalReturnNext]
theorem resumeSecondPreserves (q : State) (h : Safe q) (g : resumeSecondGuard q) : Safe (resumeSecondNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,resumeSecondGuard,resumeSecondNext]
theorem rejectStaleReturnPreserves (q : State) (h : Safe q) (g : rejectStaleReturnGuard q) : Safe (rejectStaleReturnNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,rejectStaleReturnGuard,rejectStaleReturnNext]
theorem settleSecondPreserves (q : State) (h : Safe q) (g : settleSecondGuard q) : Safe (settleSecondNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,settleSecondGuard,settleSecondNext]
theorem closeCapturePreserves (q : State) (h : Safe q) (g : closeCaptureGuard q) : Safe (closeCaptureNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,closeCaptureGuard,closeCaptureNext]
theorem scanGracePreserves (q : State) (h : Safe q) (g : scanGraceGuard q) : Safe (scanGraceNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,scanGraceGuard,scanGraceNext]
theorem retireRootsPreserves (q : State) (h : Safe q) (g : retireRootsGuard q) : Safe (retireRootsNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,retireRootsGuard,retireRootsNext]
theorem detachThreadPreserves (q : State) (h : Safe q) (g : detachThreadGuard q) : Safe (detachThreadNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,detachThreadGuard,detachThreadNext]
theorem unknownExitPreserves (q : State) (h : Safe q) (g : unknownExitGuard q) : Safe (unknownExitNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,unknownExitGuard,unknownExitNext]
theorem rejectWrongOwnerPreserves (q : State) (h : Safe q) (g : rejectWrongOwnerGuard q) : Safe (rejectWrongOwnerNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,rejectWrongOwnerGuard,rejectWrongOwnerNext]
theorem settleRejectedOwnerPreserves (q : State) (h : Safe q) (g : settleRejectedOwnerGuard q) : Safe (settleRejectedOwnerNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,settleRejectedOwnerGuard,settleRejectedOwnerNext]
theorem earlyPhysicalReturnPreserves (q : State) (h : Safe q) (g : earlyPhysicalReturnGuard q) : Safe (earlyPhysicalReturnNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,earlyPhysicalReturnGuard,earlyPhysicalReturnNext]
theorem resumeAfterReturnPreserves (q : State) (h : Safe q) (g : resumeAfterReturnGuard q) : Safe (resumeAfterReturnNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,resumeAfterReturnGuard,resumeAfterReturnNext]
theorem settleAfterReturnPreserves (q : State) (h : Safe q) (g : settleAfterReturnGuard q) : Safe (settleAfterReturnNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,settleAfterReturnGuard,settleAfterReturnNext]
theorem resumeAgainLivePreserves (q : State) (h : Safe q) (g : resumeAgainLiveGuard q) : Safe (resumeAgainLiveNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,resumeAgainLiveGuard,resumeAgainLiveNext]
theorem settleAgainLivePreserves (q : State) (h : Safe q) (g : settleAgainLiveGuard q) : Safe (settleAgainLiveNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,settleAgainLiveGuard,settleAgainLiveNext]
theorem returnAfterTwoPreserves (q : State) (h : Safe q) (g : returnAfterTwoGuard q) : Safe (returnAfterTwoNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,returnAfterTwoGuard,returnAfterTwoNext]
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · rcases g with ⟨g,rfl⟩; exact enterGuardPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact captureSchemePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact leaveActivationPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact resumeFirstPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact settleFirstPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact physicalReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact resumeSecondPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact rejectStaleReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact settleSecondPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact closeCapturePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact scanGracePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact retireRootsPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact detachThreadPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact unknownExitPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact rejectWrongOwnerPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact settleRejectedOwnerPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact earlyPhysicalReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact resumeAfterReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact settleAfterReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact resumeAgainLivePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact settleAgainLivePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact returnAfterTwoPreserves q h g
 · simpa [g] using h
inductive Reachable : State → Prop where
 | init : Reachable initial
 | next {q t : State} : Reachable q → Step q t → Reachable t
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | init => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem guardRootCoverage (q : State) (h : Safe q) (g : q.guard=1) : q.root=1 ∧ q.threadLive=1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem returnNeedsLiveStack (q : State) (h : Safe q) (g : q.returnRight=1) : q.stackLive=1 ∧ q.threadLive=1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem freshSecondTicket (q : State) (h : Safe q) (g : q.shot=2) : q.ticket=3 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem unknownRetainsCustody (q : State) (h : Safe q) (g : q.phase=14) : q.guard=1 ∧ q.root=1 ∧ q.retained=1 ∧ q.stackLive=2 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem retirementCut (q : State) (h : Safe q) (g : q.root=0) : q.guard=0 ∧ q.retained=0 ∧ q.closed=1 ∧ q.grace=1 ∧ q.stackLive=0 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem staleReturnDoesNotRevive (q : State) (h : Safe q) (g : q.phase=8) : q.returnRight=0 ∧ q.stackLive=0 ∧ q.shot=2 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem threadExitCut (q : State) (h : Safe q) (g : q.threadLive=0) : q.root=0 ∧ q.guard=0 ∧ q.stackLive=0 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem consumedReturnNeverRevives (q t : State) (h : Safe q) (g : Step q t) (c : q.returnRight=0) : t.returnRight=0 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 all_goals simp_all [enterGuardGuard,enterGuardNext,captureSchemeGuard,captureSchemeNext,leaveActivationGuard,leaveActivationNext,resumeFirstGuard,resumeFirstNext,settleFirstGuard,settleFirstNext,physicalReturnGuard,physicalReturnNext,resumeSecondGuard,resumeSecondNext,rejectStaleReturnGuard,rejectStaleReturnNext,settleSecondGuard,settleSecondNext,closeCaptureGuard,closeCaptureNext,scanGraceGuard,scanGraceNext,retireRootsGuard,retireRootsNext,detachThreadGuard,detachThreadNext,unknownExitGuard,unknownExitNext,rejectWrongOwnerGuard,rejectWrongOwnerNext,settleRejectedOwnerGuard,settleRejectedOwnerNext,earlyPhysicalReturnGuard,earlyPhysicalReturnNext,resumeAfterReturnGuard,resumeAfterReturnNext,settleAfterReturnGuard,settleAfterReturnNext,resumeAgainLiveGuard,resumeAgainLiveNext,settleAgainLiveGuard,settleAgainLiveNext,returnAfterTwoGuard,returnAfterTwoNext]
theorem newShotGetsFreshTicket (q t : State) (h : Safe q) (g : Step q t) (c : t.shot>q.shot) : t.ticket>q.ticket := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 all_goals simp_all [enterGuardGuard,enterGuardNext,captureSchemeGuard,captureSchemeNext,leaveActivationGuard,leaveActivationNext,resumeFirstGuard,resumeFirstNext,settleFirstGuard,settleFirstNext,physicalReturnGuard,physicalReturnNext,resumeSecondGuard,resumeSecondNext,rejectStaleReturnGuard,rejectStaleReturnNext,settleSecondGuard,settleSecondNext,closeCaptureGuard,closeCaptureNext,scanGraceGuard,scanGraceNext,retireRootsGuard,retireRootsNext,detachThreadGuard,detachThreadNext,unknownExitGuard,unknownExitNext,rejectWrongOwnerGuard,rejectWrongOwnerNext,settleRejectedOwnerGuard,settleRejectedOwnerNext,earlyPhysicalReturnGuard,earlyPhysicalReturnNext,resumeAfterReturnGuard,resumeAfterReturnNext,settleAfterReturnGuard,settleAfterReturnNext,resumeAgainLiveGuard,resumeAgainLiveNext,settleAgainLiveGuard,settleAgainLiveNext,returnAfterTwoGuard,returnAfterTwoNext]
end NativeReturn

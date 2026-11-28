import AtomicOwnerSupport
import AtomicOwnerSplitOutcome
import AtomicOwnerChildOutcome
import AtomicOwnerActivationViews
import AtomicOwnerActivationPublish
import AtomicOwnerWorkerViews
import AtomicOwnerWorkerClaim
import AtomicOwnerResultViews
import AtomicOwnerResultGrant
import AtomicOwnerProjection
namespace AtomicOwner
open AtomicOwnerAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepProjects (q r : State) (s : Step q r) : ControlWordAst.Step (parent q) (parent r) := by
 unfold Step at s
 rcases s with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36 | h37 | h38 | h39 | h40 | h41 | h42 | h43 | h44 | h45 | h46 | h47 | h48 | h49 | h50 | h51 | h52 | h53 | h54 | h55 | h56 | h57 | h58 | h59 | h60 | h61 | h62 | h63 | h64 | h65 | h66 | h67 | h68
 · rcases h0 with ⟨g,rfl⟩
   exact allocateProjects q g
 · rcases h1 with ⟨g,rfl⟩
   exact enterProjects q g
 · rcases h2 with ⟨g,rfl⟩
   exact resolveProjects q g
 · rcases h3 with ⟨g,rfl⟩
   exact initializeProjects q g
 · rcases h4 with ⟨g,rfl⟩
   exact validateProjects q g
 · rcases h5 with ⟨g,rfl⟩
   exact prepareProjects q g
 · rcases h6 with ⟨g,rfl⟩
   exact sendPublicationProjects q g
 · rcases h7 with ⟨g,rfl⟩
   exact publicationUnknownProjects q g
 · rcases h8 with ⟨g,rfl⟩
   exact acceptPublicationProjects q g
 · rcases h9 with ⟨g,rfl⟩
   exact rejectPublicationProjects q g
 · rcases h10 with ⟨g,rfl⟩
   exact activationFailedProjects q g
 · rcases h11 with ⟨g,rfl⟩
   exact wakeFailedProjects q g
 · rcases h12 with ⟨g,rfl⟩
   exact restoreProjects q g
 · rcases h13 with ⟨g,rfl⟩
   exact finishAbortedProjects q g
 · rcases h14 with ⟨g,rfl⟩
   exact publishResultProjects q g
 · rcases h15 with ⟨g,rfl⟩
   exact runPrefixProjects q g
 · rcases h16 with ⟨g,rfl⟩
   exact grantLocalProjects q g
 · rcases h17 with ⟨g,rfl⟩
   exact leaveProjects q g
 · rcases h18 with ⟨g,rfl⟩
   exact gcEnterProjects q g
 · rcases h19 with ⟨g,rfl⟩
   exact gcFreezeProjects q g
 · rcases h20 with ⟨g,rfl⟩
   exact gcBeginProjects q g
 · rcases h21 with ⟨g,rfl⟩
   exact forwardNoCopyProjects q g
 · rcases h22 with ⟨g,rfl⟩
   exact forwardWithCopyProjects q g
 · rcases h23 with ⟨g,rfl⟩
   exact gcEndProjects q g
 · rcases h24 with ⟨g,rfl⟩
   exact gcLeaveProjects q g
 · rcases h25 with ⟨g,rfl⟩
   exact closeDomainProjects q g
 · rcases h26 with ⟨g,rfl⟩
   exact resetDomainProjects q g
 · rcases h27 with ⟨g,rfl⟩
   exact prepareResultProjects q g
 · rcases h28 with ⟨g,rfl⟩
   exact loadReserveProjects q g
 · rcases h29 with ⟨g,rfl⟩
   exact loadCommitProjects q g
 · rcases h30 with ⟨g,rfl⟩
   exact loadAbortProjects q g
 · rcases h31 with ⟨g,rfl⟩
   exact casReserveProjects q g
 · rcases h32 with ⟨g,rfl⟩
   exact casCommitProjects q g
 · rcases h33 with ⟨g,rfl⟩
   exact casAbortProjects q g
 · rcases h34 with ⟨g,rfl⟩
   exact loadChildProjects q g
 · rcases h35 with ⟨g,rfl⟩
   exact loadLocalProjects q g
 · rcases h36 with ⟨g,rfl⟩
   exact casChildLocalProjects q g
 · rcases h37 with ⟨g,rfl⟩
   exact casChildSplitProjects q g
 · rcases h38 with ⟨g,rfl⟩
   exact casCloseLocalProjects q g
 · rcases h39 with ⟨g,rfl⟩
   exact retirePreparedResultProjects q g
 · rcases h40 with ⟨g,rfl⟩
   exact splitNativeFailureProjects q g
 · rcases h41 with ⟨g,rfl⟩
   exact splitLegacyFailureProjects q g
 · rcases h42 with ⟨g,rfl⟩
   exact deliverSplitterProjects q g
 · rcases h43 with ⟨g,rfl⟩
   exact childNativeFailureProjects q g
 · rcases h44 with ⟨g,rfl⟩
   exact childLegacyFailureProjects q g
 · rcases h45 with ⟨g,rfl⟩
   exact deliverChildProjects q g
 · rcases h46 with ⟨g,rfl⟩
   exact acquireCommitA0Projects q g
 · rcases h47 with ⟨g,rfl⟩
   exact acquireChildA0Projects q g
 · rcases h48 with ⟨g,rfl⟩
   exact activateA0Projects q g
 · rcases h49 with ⟨g,rfl⟩
   exact acquireActiveW0Projects q g
 · rcases h50 with ⟨g,rfl⟩
   exact failedClaimAcquireW0Projects q g
 · rcases h51 with ⟨g,rfl⟩
   exact claimW0Projects q g
 · rcases h52 with ⟨g,rfl⟩
   exact resultChildW0Projects q g
 · rcases h53 with ⟨g,rfl⟩
   exact resultCommitW0Projects q g
 · rcases h54 with ⟨g,rfl⟩
   exact grantW0Projects q g
 · rcases h55 with ⟨g,rfl⟩
   exact renewA0Projects q g
 · rcases h56 with ⟨g,rfl⟩
   exact renewW0Projects q g
 · rcases h57 with ⟨g,rfl⟩
   exact acquireCommitA1Projects q g
 · rcases h58 with ⟨g,rfl⟩
   exact acquireChildA1Projects q g
 · rcases h59 with ⟨g,rfl⟩
   exact activateA1Projects q g
 · rcases h60 with ⟨g,rfl⟩
   exact acquireActiveW1Projects q g
 · rcases h61 with ⟨g,rfl⟩
   exact failedClaimAcquireW1Projects q g
 · rcases h62 with ⟨g,rfl⟩
   exact claimW1Projects q g
 · rcases h63 with ⟨g,rfl⟩
   exact resultChildW1Projects q g
 · rcases h64 with ⟨g,rfl⟩
   exact resultCommitW1Projects q g
 · rcases h65 with ⟨g,rfl⟩
   exact grantW1Projects q g
 · rcases h66 with ⟨g,rfl⟩
   exact renewA1Projects q g
 · rcases h67 with ⟨g,rfl⟩
   exact renewW1Projects q g
 · rcases h68 with rfl
   exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (rfl))))))))))))))))))))))))))))))))))))))))))))))))
theorem invariantPreserved (q r : State) (h : Safe q) (s : Step q r) : Invariant r := by
 unfold Step at s
 rcases s with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36 | h37 | h38 | h39 | h40 | h41 | h42 | h43 | h44 | h45 | h46 | h47 | h48 | h49 | h50 | h51 | h52 | h53 | h54 | h55 | h56 | h57 | h58 | h59 | h60 | h61 | h62 | h63 | h64 | h65 | h66 | h67 | h68
 · rcases h0 with ⟨g,rfl⟩
   exact allocateInvariant q h g
 · rcases h1 with ⟨g,rfl⟩
   exact enterInvariant q h g
 · rcases h2 with ⟨g,rfl⟩
   exact resolveInvariant q h g
 · rcases h3 with ⟨g,rfl⟩
   exact initializeInvariant q h g
 · rcases h4 with ⟨g,rfl⟩
   exact validateInvariant q h g
 · rcases h5 with ⟨g,rfl⟩
   exact prepareInvariant q h g
 · rcases h6 with ⟨g,rfl⟩
   exact sendPublicationInvariant q h g
 · rcases h7 with ⟨g,rfl⟩
   exact publicationUnknownInvariant q h g
 · rcases h8 with ⟨g,rfl⟩
   exact acceptPublicationInvariant q h g
 · rcases h9 with ⟨g,rfl⟩
   exact rejectPublicationInvariant q h g
 · rcases h10 with ⟨g,rfl⟩
   exact activationFailedInvariant q h g
 · rcases h11 with ⟨g,rfl⟩
   exact wakeFailedInvariant q h g
 · rcases h12 with ⟨g,rfl⟩
   exact restoreInvariant q h g
 · rcases h13 with ⟨g,rfl⟩
   exact finishAbortedInvariant q h g
 · rcases h14 with ⟨g,rfl⟩
   exact publishResultInvariant q h g
 · rcases h15 with ⟨g,rfl⟩
   exact runPrefixInvariant q h g
 · rcases h16 with ⟨g,rfl⟩
   exact grantLocalInvariant q h g
 · rcases h17 with ⟨g,rfl⟩
   exact leaveInvariant q h g
 · rcases h18 with ⟨g,rfl⟩
   exact gcEnterInvariant q h g
 · rcases h19 with ⟨g,rfl⟩
   exact gcFreezeInvariant q h g
 · rcases h20 with ⟨g,rfl⟩
   exact gcBeginInvariant q h g
 · rcases h21 with ⟨g,rfl⟩
   exact forwardNoCopyInvariant q h g
 · rcases h22 with ⟨g,rfl⟩
   exact forwardWithCopyInvariant q h g
 · rcases h23 with ⟨g,rfl⟩
   exact gcEndInvariant q h g
 · rcases h24 with ⟨g,rfl⟩
   exact gcLeaveInvariant q h g
 · rcases h25 with ⟨g,rfl⟩
   exact closeDomainInvariant q h g
 · rcases h26 with ⟨g,rfl⟩
   exact resetDomainInvariant q h g
 · rcases h27 with ⟨g,rfl⟩
   exact prepareResultInvariant q h g
 · rcases h28 with ⟨g,rfl⟩
   exact loadReserveInvariant q h g
 · rcases h29 with ⟨g,rfl⟩
   exact loadCommitInvariant q h g
 · rcases h30 with ⟨g,rfl⟩
   exact loadAbortInvariant q h g
 · rcases h31 with ⟨g,rfl⟩
   exact casReserveInvariant q h g
 · rcases h32 with ⟨g,rfl⟩
   exact casCommitInvariant q h g
 · rcases h33 with ⟨g,rfl⟩
   exact casAbortInvariant q h g
 · rcases h34 with ⟨g,rfl⟩
   exact loadChildInvariant q h g
 · rcases h35 with ⟨g,rfl⟩
   exact loadLocalInvariant q h g
 · rcases h36 with ⟨g,rfl⟩
   exact casChildLocalInvariant q h g
 · rcases h37 with ⟨g,rfl⟩
   exact casChildSplitInvariant q h g
 · rcases h38 with ⟨g,rfl⟩
   exact casCloseLocalInvariant q h g
 · rcases h39 with ⟨g,rfl⟩
   exact retirePreparedResultInvariant q h g
 · rcases h40 with ⟨g,rfl⟩
   exact splitNativeFailureInvariant q h g
 · rcases h41 with ⟨g,rfl⟩
   exact splitLegacyFailureInvariant q h g
 · rcases h42 with ⟨g,rfl⟩
   exact deliverSplitterInvariant q h g
 · rcases h43 with ⟨g,rfl⟩
   exact childNativeFailureInvariant q h g
 · rcases h44 with ⟨g,rfl⟩
   exact childLegacyFailureInvariant q h g
 · rcases h45 with ⟨g,rfl⟩
   exact deliverChildInvariant q h g
 · rcases h46 with ⟨g,rfl⟩
   exact acquireCommitA0Invariant q h g
 · rcases h47 with ⟨g,rfl⟩
   exact acquireChildA0Invariant q h g
 · rcases h48 with ⟨g,rfl⟩
   exact activateA0Invariant q h g
 · rcases h49 with ⟨g,rfl⟩
   exact acquireActiveW0Invariant q h g
 · rcases h50 with ⟨g,rfl⟩
   exact failedClaimAcquireW0Invariant q h g
 · rcases h51 with ⟨g,rfl⟩
   exact claimW0Invariant q h g
 · rcases h52 with ⟨g,rfl⟩
   exact resultChildW0Invariant q h g
 · rcases h53 with ⟨g,rfl⟩
   exact resultCommitW0Invariant q h g
 · rcases h54 with ⟨g,rfl⟩
   exact grantW0Invariant q h g
 · rcases h55 with ⟨g,rfl⟩
   exact renewA0Invariant q h g
 · rcases h56 with ⟨g,rfl⟩
   exact renewW0Invariant q h g
 · rcases h57 with ⟨g,rfl⟩
   exact acquireCommitA1Invariant q h g
 · rcases h58 with ⟨g,rfl⟩
   exact acquireChildA1Invariant q h g
 · rcases h59 with ⟨g,rfl⟩
   exact activateA1Invariant q h g
 · rcases h60 with ⟨g,rfl⟩
   exact acquireActiveW1Invariant q h g
 · rcases h61 with ⟨g,rfl⟩
   exact failedClaimAcquireW1Invariant q h g
 · rcases h62 with ⟨g,rfl⟩
   exact claimW1Invariant q h g
 · rcases h63 with ⟨g,rfl⟩
   exact resultChildW1Invariant q h g
 · rcases h64 with ⟨g,rfl⟩
   exact resultCommitW1Invariant q h g
 · rcases h65 with ⟨g,rfl⟩
   exact grantW1Invariant q h g
 · rcases h66 with ⟨g,rfl⟩
   exact renewA1Invariant q h g
 · rcases h67 with ⟨g,rfl⟩
   exact renewW1Invariant q h g
 · rcases h68 with rfl
   exact ((safeEquivalent _).mp h).2
theorem stepPreserves (q r : State) (h : Safe q) (s : Step q r) : Safe r := by
 exact (safeEquivalent r).mpr ⟨ControlWord.stepPreserves _ _ ((safeEquivalent q).mp h).1 (stepProjects q r s),invariantPreserved q r h s⟩
inductive Reachable : State → Prop where
 | start : Reachable initial
 | advance {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | advance _ s ih => exact stepPreserves _ _ ih s
theorem reachableParent (q : State) (h : Reachable q) : ControlWord.Reachable (parent q) := by
 induction h with
 | start => exact ControlWord.Reachable.start
 | advance _ s ih => exact ControlWord.Reachable.advance ih (stepProjects _ _ s)
theorem delayedDeliveryUsesSnapshot (q : State) : (deliverSplitterNext q).sDeliveredObserved=q.sOutObserved := by rfl
theorem a0ObservationCannotGrantA1 (q : State) (missing : q.a1View=0) : ¬ activateA1Guard q := by simp [activateA1Guard,missing]
theorem failedClaimIsNotOwnership (q : State) : (failedClaimAcquireW1Next q).claimedOwner=q.claimedOwner ∧ (failedClaimAcquireW1Next q).w1View=1 := by exact ⟨rfl,rfl⟩
theorem renewInvalidatesA0 (q : State) : (renewA0Next q).a0View=0 ∧ ¬ activateA0Guard (renewA0Next q) := by simp [renewA0Next,activateA0Guard]
theorem issuedEventSurvivesOwnerRenewal (q : State) : (renewA0Next q).activeEvidence=q.activeEvidence ∧ (renewA0Next q).activeIssuer=q.activeIssuer := by exact ⟨rfl,rfl⟩
end AtomicOwner

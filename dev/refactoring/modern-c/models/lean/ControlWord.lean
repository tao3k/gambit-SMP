import ControlWordProjection
import ControlWordPreparation
import ControlWordPublication
import ControlWordRestore
import ControlWordCollection
import ControlWordDomain
import ControlWordReservation
import ControlWordCompletion
import ControlWordActivation
namespace ControlWord
open ControlWordAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepProjects (q r : State) (s : Step q r) : FrameActivationAst.Step (parent q) (parent r) := by
 unfold Step at s
 rcases s with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36 | h37 | h38 | h39 | h40 | h41 | h42 | h43 | h44 | h45 | h46 | h47 | h48
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
   exact splitFailureProjects q g
 · rcases h32 with ⟨g,rfl⟩
   exact casReserveProjects q g
 · rcases h33 with ⟨g,rfl⟩
   exact casCommitProjects q g
 · rcases h34 with ⟨g,rfl⟩
   exact casAbortProjects q g
 · rcases h35 with ⟨g,rfl⟩
   exact loadChildProjects q g
 · rcases h36 with ⟨g,rfl⟩
   exact loadLocalProjects q g
 · rcases h37 with ⟨g,rfl⟩
   exact childFailureProjects q g
 · rcases h38 with ⟨g,rfl⟩
   exact casChildLocalProjects q g
 · rcases h39 with ⟨g,rfl⟩
   exact casChildSplitProjects q g
 · rcases h40 with ⟨g,rfl⟩
   exact casCloseLocalProjects q g
 · rcases h41 with ⟨g,rfl⟩
   exact retirePreparedResultProjects q g
 · rcases h42 with ⟨g,rfl⟩
   exact acquireCommitProjects q g
 · rcases h43 with ⟨g,rfl⟩
   exact casActivateProjects q g
 · rcases h44 with ⟨g,rfl⟩
   exact acquireActiveProjects q g
 · rcases h45 with ⟨g,rfl⟩
   exact casDequeueProjects q g
 · rcases h46 with ⟨g,rfl⟩
   exact acquireResultProjects q g
 · rcases h47 with ⟨g,rfl⟩
   exact grantRemoteProjects q g
 · rcases h48 with rfl
   exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (rfl))))))))))))))))))))))))))))))))))))
theorem invariantPreserved (q r : State) (h : Safe q) (s : Step q r) : Invariant r := by
 unfold Step at s
 rcases s with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36 | h37 | h38 | h39 | h40 | h41 | h42 | h43 | h44 | h45 | h46 | h47 | h48
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
   exact splitFailureInvariant q h g
 · rcases h32 with ⟨g,rfl⟩
   exact casReserveInvariant q h g
 · rcases h33 with ⟨g,rfl⟩
   exact casCommitInvariant q h g
 · rcases h34 with ⟨g,rfl⟩
   exact casAbortInvariant q h g
 · rcases h35 with ⟨g,rfl⟩
   exact loadChildInvariant q h g
 · rcases h36 with ⟨g,rfl⟩
   exact loadLocalInvariant q h g
 · rcases h37 with ⟨g,rfl⟩
   exact childFailureInvariant q h g
 · rcases h38 with ⟨g,rfl⟩
   exact casChildLocalInvariant q h g
 · rcases h39 with ⟨g,rfl⟩
   exact casChildSplitInvariant q h g
 · rcases h40 with ⟨g,rfl⟩
   exact casCloseLocalInvariant q h g
 · rcases h41 with ⟨g,rfl⟩
   exact retirePreparedResultInvariant q h g
 · rcases h42 with ⟨g,rfl⟩
   exact acquireCommitInvariant q h g
 · rcases h43 with ⟨g,rfl⟩
   exact casActivateInvariant q h g
 · rcases h44 with ⟨g,rfl⟩
   exact acquireActiveInvariant q h g
 · rcases h45 with ⟨g,rfl⟩
   exact casDequeueInvariant q h g
 · rcases h46 with ⟨g,rfl⟩
   exact acquireResultInvariant q h g
 · rcases h47 with ⟨g,rfl⟩
   exact grantRemoteInvariant q h g
 · rcases h48 with rfl
   exact ((safeEquivalent _).mp h).2
theorem stepPreserves (q r : State) (h : Safe q) (s : Step q r) : Safe r := by
 exact (safeEquivalent r).mpr ⟨FrameActivation.stepPreserves _ _ ((safeEquivalent q).mp h).1 (stepProjects q r s),invariantPreserved q r h s⟩
inductive Reachable : State → Prop where
 | start : Reachable initial
 | advance {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | advance _ s ih => exact stepPreserves _ _ ih s
theorem reachableParent (q : State) (h : Reachable q) : FrameActivation.Reachable (parent q) := by
 induction h with
 | start => exact FrameActivation.Reachable.start
 | advance _ s ih => exact FrameActivation.Reachable.advance ih (stepProjects _ _ s)
theorem wordMatches (q : State) (h : Safe q) : q.word=q.n_decision+4*q.n_done := by
 have hc := ((safeEquivalent q).mp h).2
 unfold Invariant at hc
 omega
theorem failureClearsIntent (q : State) : (splitFailureNext q).sMode=0 ∧ (splitFailureNext q).sExpected=q.word ∧ (splitFailureNext q).word=q.word := by exact ⟨rfl,rfl,rfl⟩
theorem failedCasCannotReserve (q : State) : ¬ casReserveGuard (splitFailureNext q) := by simp [casReserveGuard,splitFailureNext]
theorem commitPreservesDone (q : State) : (casCommitNext q).n_done=q.n_done := by rfl
theorem donePreservesRoute (q : State) : (casChildSplitNext q).n_decision=q.n_decision := by rfl
theorem crossOwnerActivation (q : State) (h : Safe q) (active : q.active=1) : q.aSeen=1 ∧ q.commitRelease=1 ∧ q.carriedCommit=1 := by
 have hc := ((safeEquivalent q).mp h).2
 unfold Invariant at hc
 omega
theorem claimHasAcquireWitness (q : State) (h : Safe q) (claimed : q.activationWord=2) : q.workerSeen=1 ∧ q.carriedCommit=1 := by
 have hc := ((safeEquivalent q).mp h).2
 unfold Invariant at hc
 omega
end ControlWord

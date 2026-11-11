import FrameActivationProjection
import FrameActivationAlignment
namespace FrameActivation
open FrameActivationAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepProjects (q r : State) (s : Step q r) : FrameCommitAst.Step (native q) (native r) ∧ LazySplitAst.Step (queue q) (queue r) := by
 unfold Step at s
 rcases s with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36
 · rcases h0 with ⟨g,rfl⟩
   exact reserveProjects q g
 · rcases h1 with ⟨g,rfl⟩
   exact allocateProjects q g
 · rcases h2 with ⟨g,rfl⟩
   exact enterProjects q g
 · rcases h3 with ⟨g,rfl⟩
   exact resolveProjects q g
 · rcases h4 with ⟨g,rfl⟩
   exact initializeProjects q g
 · rcases h5 with ⟨g,rfl⟩
   exact validateProjects q g
 · rcases h6 with ⟨g,rfl⟩
   exact prepareProjects q g
 · rcases h7 with ⟨g,rfl⟩
   exact sendPublicationProjects q g
 · rcases h8 with ⟨g,rfl⟩
   exact publicationUnknownProjects q g
 · rcases h9 with ⟨g,rfl⟩
   exact acceptPublicationProjects q g
 · rcases h10 with ⟨g,rfl⟩
   exact rejectPublicationProjects q g
 · rcases h11 with ⟨g,rfl⟩
   exact commitProjects q g
 · rcases h12 with ⟨g,rfl⟩
   exact activationFailedProjects q g
 · rcases h13 with ⟨g,rfl⟩
   exact activateProjects q g
 · rcases h14 with ⟨g,rfl⟩
   exact wakeFailedProjects q g
 · rcases h15 with ⟨g,rfl⟩
   exact dequeueProjects q g
 · rcases h16 with ⟨g,rfl⟩
   exact restoreProjects q g
 · rcases h17 with ⟨g,rfl⟩
   exact doneLocalProjects q g
 · rcases h18 with ⟨g,rfl⟩
   exact doneSplitProjects q g
 · rcases h19 with ⟨g,rfl⟩
   exact closeLocalProjects q g
 · rcases h20 with ⟨g,rfl⟩
   exact abortProjects q g
 · rcases h21 with ⟨g,rfl⟩
   exact finishAbortedProjects q g
 · rcases h22 with ⟨g,rfl⟩
   exact publishResultProjects q g
 · rcases h23 with ⟨g,rfl⟩
   exact runPrefixProjects q g
 · rcases h24 with ⟨g,rfl⟩
   exact grantLocalProjects q g
 · rcases h25 with ⟨g,rfl⟩
   exact grantRemoteProjects q g
 · rcases h26 with ⟨g,rfl⟩
   exact leaveProjects q g
 · rcases h27 with ⟨g,rfl⟩
   exact gcEnterProjects q g
 · rcases h28 with ⟨g,rfl⟩
   exact gcFreezeProjects q g
 · rcases h29 with ⟨g,rfl⟩
   exact gcBeginProjects q g
 · rcases h30 with ⟨g,rfl⟩
   exact forwardNoCopyProjects q g
 · rcases h31 with ⟨g,rfl⟩
   exact forwardWithCopyProjects q g
 · rcases h32 with ⟨g,rfl⟩
   exact gcEndProjects q g
 · rcases h33 with ⟨g,rfl⟩
   exact gcLeaveProjects q g
 · rcases h34 with ⟨g,rfl⟩
   exact closeDomainProjects q g
 · rcases h35 with ⟨g,rfl⟩
   exact resetDomainProjects q g
 · rcases h36 with rfl
   exact ⟨Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (rfl))))))))))))))))))))),Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (rfl))))))))))))))))))))))))))))⟩
theorem alignmentPreserved (q r : State) (h : Safe q) (s : Step q r) : Aligned r := by
 unfold Step at s
 rcases s with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36
 · rcases h0 with ⟨g,rfl⟩
   exact reserveAligned q h g
 · rcases h1 with ⟨g,rfl⟩
   exact allocateAligned q h g
 · rcases h2 with ⟨g,rfl⟩
   exact enterAligned q h g
 · rcases h3 with ⟨g,rfl⟩
   exact resolveAligned q h g
 · rcases h4 with ⟨g,rfl⟩
   exact initializeAligned q h g
 · rcases h5 with ⟨g,rfl⟩
   exact validateAligned q h g
 · rcases h6 with ⟨g,rfl⟩
   exact prepareAligned q h g
 · rcases h7 with ⟨g,rfl⟩
   exact sendPublicationAligned q h g
 · rcases h8 with ⟨g,rfl⟩
   exact publicationUnknownAligned q h g
 · rcases h9 with ⟨g,rfl⟩
   exact acceptPublicationAligned q h g
 · rcases h10 with ⟨g,rfl⟩
   exact rejectPublicationAligned q h g
 · rcases h11 with ⟨g,rfl⟩
   exact commitAligned q h g
 · rcases h12 with ⟨g,rfl⟩
   exact activationFailedAligned q h g
 · rcases h13 with ⟨g,rfl⟩
   exact activateAligned q h g
 · rcases h14 with ⟨g,rfl⟩
   exact wakeFailedAligned q h g
 · rcases h15 with ⟨g,rfl⟩
   exact dequeueAligned q h g
 · rcases h16 with ⟨g,rfl⟩
   exact restoreAligned q h g
 · rcases h17 with ⟨g,rfl⟩
   exact doneLocalAligned q h g
 · rcases h18 with ⟨g,rfl⟩
   exact doneSplitAligned q h g
 · rcases h19 with ⟨g,rfl⟩
   exact closeLocalAligned q h g
 · rcases h20 with ⟨g,rfl⟩
   exact abortAligned q h g
 · rcases h21 with ⟨g,rfl⟩
   exact finishAbortedAligned q h g
 · rcases h22 with ⟨g,rfl⟩
   exact publishResultAligned q h g
 · rcases h23 with ⟨g,rfl⟩
   exact runPrefixAligned q h g
 · rcases h24 with ⟨g,rfl⟩
   exact grantLocalAligned q h g
 · rcases h25 with ⟨g,rfl⟩
   exact grantRemoteAligned q h g
 · rcases h26 with ⟨g,rfl⟩
   exact leaveAligned q h g
 · rcases h27 with ⟨g,rfl⟩
   exact gcEnterAligned q h g
 · rcases h28 with ⟨g,rfl⟩
   exact gcFreezeAligned q h g
 · rcases h29 with ⟨g,rfl⟩
   exact gcBeginAligned q h g
 · rcases h30 with ⟨g,rfl⟩
   exact forwardNoCopyAligned q h g
 · rcases h31 with ⟨g,rfl⟩
   exact forwardWithCopyAligned q h g
 · rcases h32 with ⟨g,rfl⟩
   exact gcEndAligned q h g
 · rcases h33 with ⟨g,rfl⟩
   exact gcLeaveAligned q h g
 · rcases h34 with ⟨g,rfl⟩
   exact closeDomainAligned q h g
 · rcases h35 with ⟨g,rfl⟩
   exact resetDomainAligned q h g
 · rcases h36 with rfl
   exact ((safeEquivalent q).mp h).2.2
theorem stepPreserves (q r : State) (h : Safe q) (s : Step q r) : Safe r := by
 rcases (safeEquivalent q).mp h with ⟨hn,hp,hc⟩
 obtain ⟨sn,sp⟩ := stepProjects q r s
 exact (safeEquivalent r).mpr ⟨FrameCommit.stepPreserves _ _ hn sn,LazySplit.stepPreserves _ _ hp sp,alignmentPreserved q r h s⟩
inductive Reachable : State → Prop where
 | start : Reachable initial
 | advance {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | advance _ s ih => exact stepPreserves _ _ ih s
theorem reachableProjections (q : State) (h : Reachable q) : FrameCommit.Reachable (native q) ∧ LazySplit.Reachable (queue q) := by
 induction h with
 | start => exact ⟨FrameCommit.Reachable.start,LazySplit.Reachable.start⟩
 | advance _ s ih =>
   obtain ⟨sn,sp⟩ := stepProjects _ _ s
   exact ⟨FrameCommit.Reachable.advance ih.1 sn,LazySplit.Reachable.advance ih.2 sp⟩
theorem committedCutMatches (q : State) (h : Safe q) : q.n_decision=2 ↔ q.p_split=1 := by
 have hc := ((safeEquivalent q).mp h).2.2
 unfold Aligned at hc
 omega
theorem unknownCannotAbort (q : State) (h : q.publication=1) : ¬ abortGuard q := by simp [abortGuard,h]
theorem committedCannotFallback (q : State) (h : Safe q) (c : q.n_decision=2) : q.n_localGrants=0 ∧ q.p_split=1 := by
 obtain ⟨hn,hp,hc⟩ := (safeEquivalent q).mp h
 exact ⟨FrameCommit.noLocalAfterSplit (native q) hn c,(committedCutMatches q h).mp c⟩
theorem pendingActivationRooted (q : State) (h : Safe q) (c : q.n_decision=2) (a : q.active=0) : q.p_queueRoot=1 ∧ q.p_copyRoot=1 := by
 obtain ⟨hn,hp,hc⟩ := (safeEquivalent q).mp h
 have three : q.p_phase=3 → q.p_split=0 := fun t => (hp.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1 t).2
 have four : q.p_phase=4 → q.p_copyRoot=1 ∧ q.p_queueRoot=1 := fun t => ⟨(hp.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1 t).1.1.1.1,(hp.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1 t).1.1.2⟩
 clear hn hp h
 unfold Aligned at hc
 omega
theorem publicationUnknownRooted (q : State) (h : Safe q) (u : q.publication=1) : q.n_sourceRoot=1 ∧ q.n_destRoot=1 := by
 obtain ⟨hn,hp,hc⟩ := (safeEquivalent q).mp h
 have reserved : q.n_decision=1 → q.n_sourceRoot=1 := fun t => (hn.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1 t).1.1.2
 clear hn hp h
 unfold Aligned at hc
 omega
theorem noDequeueBeforeActivation (q : State) (h : q.active=0) : ¬ dequeueGuard q := by simp [dequeueGuard,h]
theorem firstGrantOnlyOnce (q : State) (h : Safe q) : q.p_parentRuns=q.n_localGrants+q.n_remoteGrants ∧ q.p_parentRuns≤1 := by
 obtain ⟨hn,hp,hc⟩ := (safeEquivalent q).mp h
 unfold Aligned at hc
 have bound := FrameCommit.oneReturnGrant (native q) hn
 change q.n_localGrants+q.n_remoteGrants≤1 at bound
 clear hn hp h
 omega
end FrameActivation

import AtomicOwnerOutcomeLaws
namespace AtomicOwner
open AtomicOwnerAst
theorem scopeRetainsObservation (q : State) : (renewA0Next q).a0Floor=q.a0Floor := by rfl
theorem olderCommitRejected (q : State) (h : q.commitValue<q.a0Floor) : ¬ acquireCommitA0Guard q := by
 unfold acquireCommitA0Guard
 omega
theorem olderCompletionRejected (q : State) (h : q.childValue<q.w0Floor) : ¬ resultChildW0Guard q := by
 unfold resultChildW0Guard
 omega
theorem olderActivationRejected (q : State) (h : q.w1ActiveFloor=2) : ¬ acquireActiveW1Guard q := by
 unfold acquireActiveW1Guard
 omega
theorem claimEvidenceIsNotRetroactive (q : State) : (resultChildW0Next q).claimFloor=q.claimFloor := by rfl
theorem observationFloorsMonotone (q r : State) (step : Step q r) : q.a0Floor≤r.a0Floor ∧ q.a1Floor≤r.a1Floor ∧ q.w0Floor≤r.w0Floor ∧ q.w1Floor≤r.w1Floor := by
 unfold Step at step
 rcases step with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36 | h37 | h38 | h39 | h40 | h41 | h42 | h43 | h44 | h45 | h46 | h47 | h48 | h49 | h50 | h51 | h52 | h53 | h54 | h55 | h56 | h57 | h58 | h59 | h60 | h61 | h62 | h63 | h64 | h65 | h66 | h67 | h68
 · rcases h0 with ⟨g,rfl⟩
   dsimp only [allocateNext]
   omega
 · rcases h1 with ⟨g,rfl⟩
   dsimp only [enterNext]
   omega
 · rcases h2 with ⟨g,rfl⟩
   dsimp only [resolveNext]
   omega
 · rcases h3 with ⟨g,rfl⟩
   dsimp only [initializeNext]
   omega
 · rcases h4 with ⟨g,rfl⟩
   dsimp only [validateNext]
   omega
 · rcases h5 with ⟨g,rfl⟩
   dsimp only [prepareNext]
   omega
 · rcases h6 with ⟨g,rfl⟩
   dsimp only [sendPublicationNext]
   omega
 · rcases h7 with ⟨g,rfl⟩
   dsimp only [publicationUnknownNext]
   omega
 · rcases h8 with ⟨g,rfl⟩
   dsimp only [acceptPublicationNext]
   omega
 · rcases h9 with ⟨g,rfl⟩
   dsimp only [rejectPublicationNext]
   omega
 · rcases h10 with ⟨g,rfl⟩
   dsimp only [activationFailedNext]
   omega
 · rcases h11 with ⟨g,rfl⟩
   dsimp only [wakeFailedNext]
   omega
 · rcases h12 with ⟨g,rfl⟩
   dsimp only [restoreNext]
   omega
 · rcases h13 with ⟨g,rfl⟩
   dsimp only [finishAbortedNext]
   omega
 · rcases h14 with ⟨g,rfl⟩
   dsimp only [publishResultNext]
   omega
 · rcases h15 with ⟨g,rfl⟩
   dsimp only [runPrefixNext]
   omega
 · rcases h16 with ⟨g,rfl⟩
   dsimp only [grantLocalNext]
   omega
 · rcases h17 with ⟨g,rfl⟩
   dsimp only [leaveNext]
   omega
 · rcases h18 with ⟨g,rfl⟩
   dsimp only [gcEnterNext]
   omega
 · rcases h19 with ⟨g,rfl⟩
   dsimp only [gcFreezeNext]
   omega
 · rcases h20 with ⟨g,rfl⟩
   dsimp only [gcBeginNext]
   omega
 · rcases h21 with ⟨g,rfl⟩
   dsimp only [forwardNoCopyNext]
   omega
 · rcases h22 with ⟨g,rfl⟩
   dsimp only [forwardWithCopyNext]
   omega
 · rcases h23 with ⟨g,rfl⟩
   dsimp only [gcEndNext]
   omega
 · rcases h24 with ⟨g,rfl⟩
   dsimp only [gcLeaveNext]
   omega
 · rcases h25 with ⟨g,rfl⟩
   dsimp only [closeDomainNext]
   omega
 · rcases h26 with ⟨g,rfl⟩
   dsimp only [resetDomainNext]
   omega
 · rcases h27 with ⟨g,rfl⟩
   dsimp only [prepareResultNext]
   omega
 · rcases h28 with ⟨g,rfl⟩
   dsimp only [loadReserveNext]
   omega
 · rcases h29 with ⟨g,rfl⟩
   dsimp only [loadCommitNext]
   omega
 · rcases h30 with ⟨g,rfl⟩
   dsimp only [loadAbortNext]
   omega
 · rcases h31 with ⟨g,rfl⟩
   dsimp only [casReserveNext]
   omega
 · rcases h32 with ⟨g,rfl⟩
   dsimp only [casCommitNext]
   omega
 · rcases h33 with ⟨g,rfl⟩
   dsimp only [casAbortNext]
   omega
 · rcases h34 with ⟨g,rfl⟩
   dsimp only [loadChildNext]
   omega
 · rcases h35 with ⟨g,rfl⟩
   dsimp only [loadLocalNext]
   omega
 · rcases h36 with ⟨g,rfl⟩
   dsimp only [casChildLocalNext]
   omega
 · rcases h37 with ⟨g,rfl⟩
   dsimp only [casChildSplitNext]
   omega
 · rcases h38 with ⟨g,rfl⟩
   dsimp only [casCloseLocalNext]
   omega
 · rcases h39 with ⟨g,rfl⟩
   dsimp only [retirePreparedResultNext]
   omega
 · rcases h40 with ⟨g,rfl⟩
   dsimp only [splitNativeFailureNext]
   omega
 · rcases h41 with ⟨g,rfl⟩
   dsimp only [splitLegacyFailureNext]
   omega
 · rcases h42 with ⟨g,rfl⟩
   dsimp only [deliverSplitterNext]
   omega
 · rcases h43 with ⟨g,rfl⟩
   dsimp only [childNativeFailureNext]
   omega
 · rcases h44 with ⟨g,rfl⟩
   dsimp only [childLegacyFailureNext]
   omega
 · rcases h45 with ⟨g,rfl⟩
   dsimp only [deliverChildNext]
   omega
 · rcases h46 with ⟨g,rfl⟩
   dsimp only [acquireCommitA0Next]
   simp only [acquireCommitA0Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4⟩
   omega
 · rcases h47 with ⟨g,rfl⟩
   dsimp only [acquireChildA0Next]
   simp only [acquireChildA0Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4,g5⟩
   omega
 · rcases h48 with ⟨g,rfl⟩
   dsimp only [activateA0Next]
   omega
 · rcases h49 with ⟨g,rfl⟩
   dsimp only [acquireActiveW0Next]
   simp only [acquireActiveW0Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4,g5,g6⟩
   omega
 · rcases h50 with ⟨g,rfl⟩
   dsimp only [failedClaimAcquireW0Next]
   simp only [failedClaimAcquireW0Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4,g5,g6,g7⟩
   omega
 · rcases h51 with ⟨g,rfl⟩
   dsimp only [claimW0Next]
   omega
 · rcases h52 with ⟨g,rfl⟩
   dsimp only [resultChildW0Next]
   simp only [resultChildW0Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4,g5⟩
   omega
 · rcases h53 with ⟨g,rfl⟩
   dsimp only [resultCommitW0Next]
   simp only [resultCommitW0Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4,g5⟩
   omega
 · rcases h54 with ⟨g,rfl⟩
   dsimp only [grantW0Next]
   omega
 · rcases h55 with ⟨g,rfl⟩
   dsimp only [renewA0Next]
   omega
 · rcases h56 with ⟨g,rfl⟩
   dsimp only [renewW0Next]
   omega
 · rcases h57 with ⟨g,rfl⟩
   dsimp only [acquireCommitA1Next]
   simp only [acquireCommitA1Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4⟩
   omega
 · rcases h58 with ⟨g,rfl⟩
   dsimp only [acquireChildA1Next]
   simp only [acquireChildA1Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4,g5⟩
   omega
 · rcases h59 with ⟨g,rfl⟩
   dsimp only [activateA1Next]
   omega
 · rcases h60 with ⟨g,rfl⟩
   dsimp only [acquireActiveW1Next]
   simp only [acquireActiveW1Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4,g5,g6⟩
   omega
 · rcases h61 with ⟨g,rfl⟩
   dsimp only [failedClaimAcquireW1Next]
   simp only [failedClaimAcquireW1Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4,g5,g6,g7⟩
   omega
 · rcases h62 with ⟨g,rfl⟩
   dsimp only [claimW1Next]
   omega
 · rcases h63 with ⟨g,rfl⟩
   dsimp only [resultChildW1Next]
   simp only [resultChildW1Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4,g5⟩
   omega
 · rcases h64 with ⟨g,rfl⟩
   dsimp only [resultCommitW1Next]
   simp only [resultCommitW1Guard,and_assoc] at g
   rcases g with ⟨g0,g1,g2,g3,g4,g5⟩
   omega
 · rcases h65 with ⟨g,rfl⟩
   dsimp only [grantW1Next]
   omega
 · rcases h66 with ⟨g,rfl⟩
   dsimp only [renewA1Next]
   omega
 · rcases h67 with ⟨g,rfl⟩
   dsimp only [renewW1Next]
   omega
 · rcases h68 with rfl
   omega
end AtomicOwner

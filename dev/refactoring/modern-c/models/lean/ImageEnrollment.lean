import ImageEnrollmentAst
namespace ImageEnrollment
open ImageEnrollmentAst
set_option maxHeartbeats 8000000
set_option maxRecDepth 14000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem enumerateHelperPreserves (q : State) (h : Safe q) (g : enumerateHelperGuard q) : Safe (enumerateHelperNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,enumerateHelperGuard,enumerateHelperNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealMembersPreserves (q : State) (h : Safe q) (g : sealMembersGuard q) : Safe (sealMembersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,sealMembersGuard,sealMembersNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem prepareOwnedPreserves (q : State) (h : Safe q) (g : prepareOwnedGuard q) : Safe (prepareOwnedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,prepareOwnedGuard,prepareOwnedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem exposeRawPreserves (q : State) (h : Safe q) (g : exposeRawGuard q) : Safe (exposeRawNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,exposeRawGuard,exposeRawNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveOwnerPreserves (q : State) (h : Safe q) (g : reserveOwnerGuard q) : Safe (reserveOwnerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,reserveOwnerGuard,reserveOwnerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitOpenPreserves (q : State) (h : Safe q) (g : commitOpenGuard q) : Safe (commitOpenNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,commitOpenGuard,commitOpenNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeGlobalPreserves (q : State) (h : Safe q) (g : closeGlobalGuard q) : Safe (closeGlobalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,closeGlobalGuard,closeGlobalNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitClosingPreserves (q : State) (h : Safe q) (g : commitClosingGuard q) : Safe (commitClosingNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,commitClosingGuard,commitClosingNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortReservedPreserves (q : State) (h : Safe q) (g : abortReservedGuard q) : Safe (abortReservedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,abortReservedGuard,abortReservedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownOwnerPreserves (q : State) (h : Safe q) (g : unknownOwnerGuard q) : Safe (unknownOwnerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,unknownOwnerGuard,unknownOwnerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem close0Preserves (q : State) (h : Safe q) (g : close0Guard q) : Safe (close0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,close0Guard,close0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem close1Preserves (q : State) (h : Safe q) (g : close1Guard q) : Safe (close1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,close1Guard,close1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem return0Preserves (q : State) (h : Safe q) (g : return0Guard q) : Safe (return0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,return0Guard,return0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem return1Preserves (q : State) (h : Safe q) (g : return1Guard q) : Safe (return1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,return1Guard,return1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem exitKnownPreserves (q : State) (h : Safe q) (g : exitKnownGuard q) : Safe (exitKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,exitKnownGuard,exitKnownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reuseBeforeClosePreserves (q : State) (h : Safe q) (g : reuseBeforeCloseGuard q) : Safe (reuseBeforeCloseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,reuseBeforeCloseGuard,reuseBeforeCloseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issue0Preserves (q : State) (h : Safe q) (g : issue0Guard q) : Safe (issue0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,issue0Guard,issue0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issue1Preserves (q : State) (h : Safe q) (g : issue1Guard q) : Safe (issue1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,issue1Guard,issue1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observePreserves (q : State) (h : Safe q) (g : observeGuard q) : Safe (observeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,observeGuard,observeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireObserverPreserves (q : State) (h : Safe q) (g : retireObserverGuard q) : Safe (retireObserverNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,retireObserverGuard,retireObserverNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem borrow0Preserves (q : State) (h : Safe q) (g : borrow0Guard q) : Safe (borrow0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,borrow0Guard,borrow0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem borrow1Preserves (q : State) (h : Safe q) (g : borrow1Guard q) : Safe (borrow1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,borrow1Guard,borrow1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectLatePreserves (q : State) (h : Safe q) (g : rejectLateGuard q) : Safe (rejectLateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,rejectLateGuard,rejectLateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectStalePreserves (q : State) (h : Safe q) (g : rejectStaleGuard q) : Safe (rejectStaleNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,rejectStaleGuard,rejectStaleNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownExternalPreserves (q : State) (h : Safe q) (g : unknownExternalGuard q) : Safe (unknownExternalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,unknownExternalGuard,unknownExternalNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem permitPreserves (q : State) (h : Safe q) (g : permitGuard q) : Safe (permitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,permitGuard,permitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem invalidateMembershipPreserves (q : State) (h : Safe q) (g : invalidateMembershipGuard q) : Safe (invalidateMembershipNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,invalidateMembershipGuard,invalidateMembershipNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18 | a19 | a20 | a21 | a22 | a23 | a24 | a25 | a26 | a27
 · rcases a0 with ⟨g,rfl⟩; exact enumerateHelperPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact sealMembersPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact prepareOwnedPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact exposeRawPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact reserveOwnerPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact commitOpenPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact closeGlobalPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact commitClosingPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact abortReservedPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact unknownOwnerPreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact close0Preserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact close1Preserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact return0Preserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact return1Preserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact exitKnownPreserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact reuseBeforeClosePreserves q h g
 · rcases a16 with ⟨g,rfl⟩; exact issue0Preserves q h g
 · rcases a17 with ⟨g,rfl⟩; exact issue1Preserves q h g
 · rcases a18 with ⟨g,rfl⟩; exact observePreserves q h g
 · rcases a19 with ⟨g,rfl⟩; exact retireObserverPreserves q h g
 · rcases a20 with ⟨g,rfl⟩; exact borrow0Preserves q h g
 · rcases a21 with ⟨g,rfl⟩; exact borrow1Preserves q h g
 · rcases a22 with ⟨g,rfl⟩; exact rejectLatePreserves q h g
 · rcases a23 with ⟨g,rfl⟩; exact rejectStalePreserves q h g
 · rcases a24 with ⟨g,rfl⟩; exact unknownExternalPreserves q h g
 · rcases a25 with ⟨g,rfl⟩; exact permitPreserves q h g
 · rcases a26 with ⟨g,rfl⟩; exact invalidateMembershipPreserves q h g
 · rw [a27]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem permitOwnerReceipts (q : State) (h : Safe q) (p : q.phase=2) : q.receipt0=true ∧ (q.expected1=true → q.receipt1=true) ∧ q.rawEscape=false ∧ q.membersSealed=true := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all <;> omega
theorem closeCapturesReservedOwner (q : State) (g : q.vm1=1) : (closeGlobalNext q).expected1=true := by simp [closeGlobalNext,g]
theorem facadeDoesNotEraseRawAlias (q : State) : (prepareOwnedNext q).rawEscape=q.rawEscape := by simp [prepareOwnedNext]
end ImageEnrollment

import FormatterRestoreAst
namespace FormatterRestore
open FormatterRestoreAst
set_option maxHeartbeats 10000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem beginScopePreserves (q : State) (h : Safe q) (g : beginScopeGuard q) : Safe (beginScopeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,beginScopeGuard,beginScopeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem bodyReturnsPreserves (q : State) (h : Safe q) (g : bodyReturnsGuard q) : Safe (bodyReturnsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,bodyReturnsGuard,bodyReturnsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem restoreOwnedPreserves (q : State) (h : Safe q) (g : restoreOwnedGuard q) : Safe (restoreOwnedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,restoreOwnedGuard,restoreOwnedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem escapeOwnedPreserves (q : State) (h : Safe q) (g : escapeOwnedGuard q) : Safe (escapeOwnedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,escapeOwnedGuard,escapeOwnedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishOtherPreserves (q : State) (h : Safe q) (g : publishOtherGuard q) : Safe (publishOtherNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,publishOtherGuard,publishOtherNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishSameIdentityPreserves (q : State) (h : Safe q) (g : publishSameIdentityGuard q) : Safe (publishSameIdentityNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,publishSameIdentityGuard,publishSameIdentityNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem yieldConflictPreserves (q : State) (h : Safe q) (g : yieldConflictGuard q) : Safe (yieldConflictNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,yieldConflictGuard,yieldConflictNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem changeEpochPreserves (q : State) (h : Safe q) (g : changeEpochGuard q) : Safe (changeEpochNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,changeEpochGuard,changeEpochNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem acceptTicketPreserves (q : State) (h : Safe q) (g : acceptTicketGuard q) : Safe (acceptTicketNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,acceptTicketGuard,acceptTicketNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem startTicketPreserves (q : State) (h : Safe q) (g : startTicketGuard q) : Safe (startTicketNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,startTicketGuard,startTicketNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishBorrowerPreserves (q : State) (h : Safe q) (g : finishBorrowerGuard q) : Safe (finishBorrowerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,finishBorrowerGuard,finishBorrowerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem capturePreserves (q : State) (h : Safe q) (g : captureGuard q) : Safe (captureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,captureGuard,captureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectStalePermitPreserves (q : State) (h : Safe q) (g : rejectStalePermitGuard q) : Safe (rejectStalePermitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,rejectStalePermitGuard,rejectStalePermitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem detachCapturePreserves (q : State) (h : Safe q) (g : detachCaptureGuard q) : Safe (detachCaptureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,detachCaptureGuard,detachCaptureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeRegistrationPreserves (q : State) (h : Safe q) (g : closeRegistrationGuard q) : Safe (closeRegistrationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,closeRegistrationGuard,closeRegistrationNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem namedDemandPreserves (q : State) (h : Safe q) (g : namedDemandGuard q) : Safe (namedDemandNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,namedDemandGuard,namedDemandNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem namedSupplyPreserves (q : State) (h : Safe q) (g : namedSupplyGuard q) : Safe (namedSupplyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,namedSupplyGuard,namedSupplyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rawMetadataPreserves (q : State) (h : Safe q) (g : rawMetadataGuard q) : Safe (rawMetadataNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,rawMetadataGuard,rawMetadataNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem ioFailurePreserves (q : State) (h : Safe q) (g : ioFailureGuard q) : Safe (ioFailureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,ioFailureGuard,ioFailureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem qualifyProfilePreserves (q : State) (h : Safe q) (g : qualifyProfileGuard q) : Safe (qualifyProfileNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,qualifyProfileGuard,qualifyProfileNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem consumeSecondPreserves (q : State) (h : Safe q) (g : consumeSecondGuard q) : Safe (consumeSecondNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,consumeSecondGuard,consumeSecondNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem legacyEnterPreserves (q : State) (h : Safe q) (g : legacyEnterGuard q) : Safe (legacyEnterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,legacyEnterGuard,legacyEnterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem legacyCapturePreserves (q : State) (h : Safe q) (g : legacyCaptureGuard q) : Safe (legacyCaptureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,legacyCaptureGuard,legacyCaptureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem legacyEscapePreserves (q : State) (h : Safe q) (g : legacyEscapeGuard q) : Safe (legacyEscapeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,legacyEscapeGuard,legacyEscapeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem legacyPublishPreserves (q : State) (h : Safe q) (g : legacyPublishGuard q) : Safe (legacyPublishNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,legacyPublishGuard,legacyPublishNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem legacyResolvePreserves (q : State) (h : Safe q) (g : legacyResolveGuard q) : Safe (legacyResolveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,legacyResolveGuard,legacyResolveNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem legacyReturnPreserves (q : State) (h : Safe q) (g : legacyReturnGuard q) : Safe (legacyReturnNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,legacyReturnGuard,legacyReturnNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem legacyRestorePreserves (q : State) (h : Safe q) (g : legacyRestoreGuard q) : Safe (legacyRestoreNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,legacyRestoreGuard,legacyRestoreNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem legacyResumePreserves (q : State) (h : Safe q) (g : legacyResumeGuard q) : Safe (legacyResumeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,legacyResumeGuard,legacyResumeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem legacyLateEntryPreserves (q : State) (h : Safe q) (g : legacyLateEntryGuard q) : Safe (legacyLateEntryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36⟩
 cases c : q.certificate <;> cases a : q.active <;> simp_all [Safe,legacyLateEntryGuard,legacyLateEntryNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31
 · rcases h0 with ⟨g,e⟩; rw [e]; exact beginScopePreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact bodyReturnsPreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact restoreOwnedPreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact escapeOwnedPreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact publishOtherPreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact publishSameIdentityPreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact yieldConflictPreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact changeEpochPreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact acceptTicketPreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact startTicketPreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact finishBorrowerPreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact capturePreserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact rejectStalePermitPreserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact detachCapturePreserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact closeRegistrationPreserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact namedDemandPreserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact namedSupplyPreserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact rawMetadataPreserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact ioFailurePreserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact qualifyProfilePreserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact issuePreserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact consumeSecondPreserves q h g
 · rcases h22 with ⟨g,e⟩; rw [e]; exact legacyEnterPreserves q h g
 · rcases h23 with ⟨g,e⟩; rw [e]; exact legacyCapturePreserves q h g
 · rcases h24 with ⟨g,e⟩; rw [e]; exact legacyEscapePreserves q h g
 · rcases h25 with ⟨g,e⟩; rw [e]; exact legacyPublishPreserves q h g
 · rcases h26 with ⟨g,e⟩; rw [e]; exact legacyResolvePreserves q h g
 · rcases h27 with ⟨g,e⟩; rw [e]; exact legacyReturnPreserves q h g
 · rcases h28 with ⟨g,e⟩; rw [e]; exact legacyRestorePreserves q h g
 · rcases h29 with ⟨g,e⟩; rw [e]; exact legacyResumePreserves q h g
 · rcases h30 with ⟨g,e⟩; rw [e]; exact legacyLateEntryPreserves q h g
 · rw [h31]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem permitNeedsDrain (q : State) (h : Safe q) (c : q.certificate=true) : q.tickets=0 ∧ q.borrowers=0 ∧ q.captures=0 := by simp_all [Safe]
theorem permitNeedsGeneration (q : State) (h : Safe q) (c : q.certificate=true) : q.generation=q.certGen ∧ q.epoch=q.scopeEpoch := by simp_all [Safe]
theorem rejectedResumeKeepsCapture (q : State) : (rejectStalePermitNext q).captures=q.captures := by rfl
end FormatterRestore

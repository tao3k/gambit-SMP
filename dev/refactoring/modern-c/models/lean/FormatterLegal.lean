import FormatterLegalAst
namespace FormatterLegal
open FormatterLegalAst
set_option maxHeartbeats 10000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem preparePreserves (q : State) (h : Safe q) (g : prepareGuard q) : Safe (prepareNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,prepareGuard,prepareNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enterPreserves (q : State) (h : Safe q) (g : enterGuard q) : Safe (enterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,enterGuard,enterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem fillPreserves (q : State) (h : Safe q) (g : fillGuard q) : Safe (fillNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,fillGuard,fillNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem timeoutPreserves (q : State) (h : Safe q) (g : timeoutGuard q) : Safe (timeoutNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,timeoutGuard,timeoutNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem captureEscapePreserves (q : State) (h : Safe q) (g : captureEscapeGuard q) : Safe (captureEscapeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,captureEscapeGuard,captureEscapeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishPreserves (q : State) (h : Safe q) (g : publishGuard q) : Safe (publishNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,publishGuard,publishNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem drainPreserves (q : State) (h : Safe q) (g : drainGuard q) : Safe (drainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,drainGuard,drainNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resumePreserves (q : State) (h : Safe q) (g : resumeGuard q) : Safe (resumeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> cases l : q.locked <;> simp_all [Safe,resumeGuard,resumeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnHandlerPreserves (q : State) (h : Safe q) (g : returnHandlerGuard q) : Safe (returnHandlerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,returnHandlerGuard,returnHandlerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem namedTailPreserves (q : State) (h : Safe q) (g : namedTailGuard q) : Safe (namedTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,namedTailGuard,namedTailNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rawTailPreserves (q : State) (h : Safe q) (g : rawTailGuard q) : Safe (rawTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,rawTailGuard,rawTailNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectDeadPreserves (q : State) (h : Safe q) (g : rejectDeadGuard q) : Safe (rejectDeadNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,rejectDeadGuard,rejectDeadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resetRegistryPreserves (q : State) (h : Safe q) (g : resetRegistryGuard q) : Safe (resetRegistryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,resetRegistryGuard,resetRegistryNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem endRegistryPreserves (q : State) (h : Safe q) (g : endRegistryGuard q) : Safe (endRegistryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,endRegistryGuard,endRegistryNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem callbackReturnsPreserves (q : State) (h : Safe q) (g : callbackReturnsGuard q) : Safe (callbackReturnsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,callbackReturnsGuard,callbackReturnsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishPreserves (q : State) (h : Safe q) (g : finishGuard q) : Safe (finishNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,finishGuard,finishNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeAdmissionPreserves (q : State) (h : Safe q) (g : closeAdmissionGuard q) : Safe (closeAdmissionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,closeAdmissionGuard,closeAdmissionNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem detachPreserves (q : State) (h : Safe q) (g : detachGuard q) : Safe (detachNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,detachGuard,detachNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem attestPreserves (q : State) (h : Safe q) (g : attestGuard q) : Safe (attestNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,attestGuard,attestNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem attemptStalePreserves (q : State) (h : Safe q) (g : attemptStaleGuard q) : Safe (attemptStaleNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31⟩
 cases c : q.certificate <;> cases k : q.captured <;> cases b : q.clobbered <;> simp_all [Safe,attemptStaleGuard,attemptStaleNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21
 · rcases h0 with ⟨g,e⟩; rw [e]; exact preparePreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact enterPreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact fillPreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact timeoutPreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact captureEscapePreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact publishPreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact drainPreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact resumePreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact returnHandlerPreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact namedTailPreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact rawTailPreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact rejectDeadPreserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact resetRegistryPreserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact endRegistryPreserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact callbackReturnsPreserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact finishPreserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact closeAdmissionPreserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact detachPreserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact attestPreserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact issuePreserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact attemptStalePreserves q h g
 · rw [h21]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem permitNeedsDrain (q : State) (h : Safe q) (c : q.certificate=true) : q.captured=false ∧ q.callbacks=0 := by simp_all [Safe]
theorem permitNeedsEpoch (q : State) (h : Safe q) (c : q.certificate=true) : q.epoch=q.planEpoch := by simp_all [Safe]
theorem resumeKeepsSaved (q : State) : (resumeNext q).savedWriter=q.savedWriter := by rfl
theorem resumeKeepsWriter (q : State) : (resumeNext q).writer=q.writer := by rfl
end FormatterLegal

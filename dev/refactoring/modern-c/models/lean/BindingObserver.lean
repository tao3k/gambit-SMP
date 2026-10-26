import BindingObserverAst
namespace BindingObserver
open BindingObserverAst
set_option maxHeartbeats 6000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem plainProfilePreserves (q : State) (h : Safe q) (g : plainProfileGuard q) : Safe (plainProfileNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,plainProfileGuard,plainProfileNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem useOnlyProfilePreserves (q : State) (h : Safe q) (g : useOnlyProfileGuard q) : Safe (useOnlyProfileNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,useOnlyProfileGuard,useOnlyProfileNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rawProfilePreserves (q : State) (h : Safe q) (g : rawProfileGuard q) : Safe (rawProfileNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,rawProfileGuard,rawProfileNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealPreserves (q : State) (h : Safe q) (g : sealGuard q) : Safe (sealNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,sealGuard,sealNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem firstElidePreserves (q : State) (h : Safe q) (g : firstElideGuard q) : Safe (firstElideNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,firstElideGuard,firstElideNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem firstRetainPreserves (q : State) (h : Safe q) (g : firstRetainGuard q) : Safe (firstRetainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,firstRetainGuard,firstRetainNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enterFormatterPreserves (q : State) (h : Safe q) (g : enterFormatterGuard q) : Safe (enterFormatterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,enterFormatterGuard,enterFormatterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enterIOHandlerPreserves (q : State) (h : Safe q) (g : enterIOHandlerGuard q) : Safe (enterIOHandlerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,enterIOHandlerGuard,enterIOHandlerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enterTimeoutPreserves (q : State) (h : Safe q) (g : enterTimeoutGuard q) : Safe (enterTimeoutNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,enterTimeoutGuard,enterTimeoutNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enterGCPreserves (q : State) (h : Safe q) (g : enterGCGuard q) : Safe (enterGCNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,enterGCGuard,enterGCNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem readObserverPreserves (q : State) (h : Safe q) (g : readObserverGuard q) : Safe (readObserverNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,readObserverGuard,readObserverNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem namedDemandPreserves (q : State) (h : Safe q) (g : namedDemandGuard q) : Safe (namedDemandNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,namedDemandGuard,namedDemandNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem namedSupplyPreserves (q : State) (h : Safe q) (g : namedSupplyGuard q) : Safe (namedSupplyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,namedSupplyGuard,namedSupplyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rawWritePreserves (q : State) (h : Safe q) (g : rawWriteGuard q) : Safe (rawWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,rawWriteGuard,rawWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem leaveHookPreserves (q : State) (h : Safe q) (g : leaveHookGuard q) : Safe (leaveHookNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,leaveHookGuard,leaveHookNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem secondReadonlyPreserves (q : State) (h : Safe q) (g : secondReadonlyGuard q) : Safe (secondReadonlyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,secondReadonlyGuard,secondReadonlyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem secondUnobservedPreserves (q : State) (h : Safe q) (g : secondUnobservedGuard q) : Safe (secondUnobservedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,secondUnobservedGuard,secondUnobservedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem secondNormalizePreserves (q : State) (h : Safe q) (g : secondNormalizeGuard q) : Safe (secondNormalizeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,secondNormalizeGuard,secondNormalizeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem ioFailurePreserves (q : State) (h : Safe q) (g : ioFailureGuard q) : Safe (ioFailureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,ioFailureGuard,ioFailureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem compilerAbortPreserves (q : State) (h : Safe q) (g : compilerAbortGuard q) : Safe (compilerAbortNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,compilerAbortGuard,compilerAbortNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem nestedCompilationPreserves (q : State) (h : Safe q) (g : nestedCompilationGuard q) : Safe (nestedCompilationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,nestedCompilationGuard,nestedCompilationNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectStalePreserves (q : State) (h : Safe q) (g : rejectStaleGuard q) : Safe (rejectStaleNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,rejectStaleGuard,rejectStaleNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem capturePreserves (q : State) (h : Safe q) (g : captureGuard q) : Safe (captureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,captureGuard,captureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resumeCapturedPreserves (q : State) (h : Safe q) (g : resumeCapturedGuard q) : Safe (resumeCapturedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,resumeCapturedGuard,resumeCapturedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem certifyNoResumePreserves (q : State) (h : Safe q) (g : certifyNoResumeGuard q) : Safe (certifyNoResumeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,certifyNoResumeGuard,certifyNoResumeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeOutputPreserves (q : State) (h : Safe q) (g : closeOutputGuard q) : Safe (closeOutputNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,closeOutputGuard,closeOutputNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownExitPreserves (q : State) (h : Safe q) (g : unknownExitGuard q) : Safe (unknownExitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,unknownExitGuard,unknownExitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem debugScalarPassPreserves (q : State) (h : Safe q) (g : debugScalarPassGuard q) : Safe (debugScalarPassNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 cases rc : q.receipt <;> cases st : q.stable <;> simp_all [Safe,debugScalarPassGuard,debugScalarPassNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29
 · rcases h0 with ⟨g,e⟩; rw [e]; exact plainProfilePreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact useOnlyProfilePreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact rawProfilePreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact sealPreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact firstElidePreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact firstRetainPreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact enterFormatterPreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact enterIOHandlerPreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact enterTimeoutPreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact enterGCPreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact readObserverPreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact namedDemandPreserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact namedSupplyPreserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact rawWritePreserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact leaveHookPreserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact secondReadonlyPreserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact secondUnobservedPreserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact secondNormalizePreserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact ioFailurePreserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact compilerAbortPreserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact nestedCompilationPreserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact rejectStalePreserves q h g
 · rcases h22 with ⟨g,e⟩; rw [e]; exact capturePreserves q h g
 · rcases h23 with ⟨g,e⟩; rw [e]; exact resumeCapturedPreserves q h g
 · rcases h24 with ⟨g,e⟩; rw [e]; exact certifyNoResumePreserves q h g
 · rcases h25 with ⟨g,e⟩; rw [e]; exact closeOutputPreserves q h g
 · rcases h26 with ⟨g,e⟩; rw [e]; exact issuePreserves q h g
 · rcases h27 with ⟨g,e⟩; rw [e]; exact unknownExitPreserves q h g
 · rcases h28 with ⟨g,e⟩; rw [e]; exact debugScalarPassPreserves q h g
 · rw [h29]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem errorBlocksReceipt (q : State) (h : Safe q) (e : q.errorSeen=true) : q.receipt=false := by simp_all [Safe]
theorem captureBlocksReceipt (q : State) (h : Safe q) (e : q.captured=true) : q.receipt=false := by simp_all [Safe]
theorem unknownKeepsCustody (q : State) : (unknownExitNext q).custody=q.custody := by rfl
end BindingObserver

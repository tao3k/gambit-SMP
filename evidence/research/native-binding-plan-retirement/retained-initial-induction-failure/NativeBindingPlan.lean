import NativeBindingPlanAst
namespace NativeBindingPlan
open NativeBindingPlanAst
set_option maxHeartbeats 6000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem discoverPreserves (q : State) (h : Safe q) (g : discoverGuard q) : Safe (discoverNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,discoverGuard,discoverNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolvePreserves (q : State) (h : Safe q) (g : resolveGuard q) : Safe (resolveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,resolveGuard,resolveNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeWritersPreserves (q : State) (h : Safe q) (g : closeWritersGuard q) : Safe (closeWritersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,closeWritersGuard,closeWritersNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem admitElisionPreserves (q : State) (h : Safe q) (g : admitElisionGuard q) : Safe (admitElisionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,admitElisionGuard,admitElisionNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem requireMetadataPreserves (q : State) (h : Safe q) (g : requireMetadataGuard q) : Safe (requireMetadataNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,requireMetadataGuard,requireMetadataNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem writeHeaderPreserves (q : State) (h : Safe q) (g : writeHeaderGuard q) : Safe (writeHeaderNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,writeHeaderGuard,writeHeaderNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealPlanPreserves (q : State) (h : Safe q) (g : sealPlanGuard q) : Safe (sealPlanNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,sealPlanGuard,sealPlanNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem firstElidePreserves (q : State) (h : Safe q) (g : firstElideGuard q) : Safe (firstElideNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,firstElideGuard,firstElideNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem firstPreservePreserves (q : State) (h : Safe q) (g : firstPreserveGuard q) : Safe (firstPreserveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,firstPreserveGuard,firstPreserveNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem emitPrmPreserves (q : State) (h : Safe q) (g : emitPrmGuard q) : Safe (emitPrmNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,emitPrmGuard,emitPrmNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem secondElidePreserves (q : State) (h : Safe q) (g : secondElideGuard q) : Safe (secondElideNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,secondElideGuard,secondElideNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem secondPreservePreserves (q : State) (h : Safe q) (g : secondPreserveGuard q) : Safe (secondPreserveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,secondPreserveGuard,secondPreserveNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem emitGloPreserves (q : State) (h : Safe q) (g : emitGloGuard q) : Safe (emitGloNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,emitGloGuard,emitGloNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeOutputPreserves (q : State) (h : Safe q) (g : closeOutputGuard q) : Safe (closeOutputNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,closeOutputGuard,closeOutputNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem pausePreserves (q : State) (h : Safe q) (g : pauseGuard q) : Safe (pauseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,pauseGuard,pauseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resumeSamePreserves (q : State) (h : Safe q) (g : resumeSameGuard q) : Safe (resumeSameNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,resumeSameGuard,resumeSameNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem foreignReentryPreserves (q : State) (h : Safe q) (g : foreignReentryGuard q) : Safe (foreignReentryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,foreignReentryGuard,foreignReentryNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem lateWriterPreserves (q : State) (h : Safe q) (g : lateWriterGuard q) : Safe (lateWriterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,lateWriterGuard,lateWriterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem escapedObserverPreserves (q : State) (h : Safe q) (g : escapedObserverGuard q) : Safe (escapedObserverNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,escapedObserverGuard,escapedObserverNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownExitPreserves (q : State) (h : Safe q) (g : unknownExitGuard q) : Safe (unknownExitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,unknownExitGuard,unknownExitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectResumePreserves (q : State) (h : Safe q) (g : rejectResumeGuard q) : Safe (rejectResumeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,rejectResumeGuard,rejectResumeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22
 · rcases h0 with ⟨g,e⟩; rw [e]; exact discoverPreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact resolvePreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact closeWritersPreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact admitElisionPreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact requireMetadataPreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact writeHeaderPreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact sealPlanPreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact firstElidePreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact firstPreservePreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact emitPrmPreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact secondElidePreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact secondPreservePreserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact emitGloPreserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact closeOutputPreserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact issuePreserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact pausePreserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact resumeSamePreserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact foreignReentryPreserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact lateWriterPreserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact escapedObserverPreserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact unknownExitPreserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact rejectResumePreserves q h g
 · rw [h22]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem headerUnaffectedByFirst (q : State) : (firstElideNext q).headerDemand=q.headerDemand ∧ (firstPreserveNext q).headerDemand=q.headerDemand := by simp [firstElideNext,firstPreserveNext]
theorem unknownKeepsCustody (q : State) : (unknownExitNext q).custody=q.custody := by rfl
theorem finalNeedsClose (q : State) (h : Safe q) (r : q.receipt=true) : q.closed=true ∧ q.revoked=false := by simp_all [Safe]
end NativeBindingPlan

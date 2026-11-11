import ContinuationRestoreAst
namespace ContinuationRestore
open ContinuationRestoreAst
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem freezeSmallPreserves (q : State) (h : Safe q) (g : freezeSmallGuard q) : Safe (freezeSmallNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,freezeSmallGuard,freezeSmallNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeLargePreserves (q : State) (h : Safe q) (g : freezeLargeGuard q) : Safe (freezeLargeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,freezeLargeGuard,freezeLargeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeOversizePreserves (q : State) (h : Safe q) (g : freezeOversizeGuard q) : Safe (freezeOversizeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,freezeOversizeGuard,freezeOversizeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem share0Preserves (q : State) (h : Safe q) (g : share0Guard q) : Safe (share0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,share0Guard,share0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem share1Preserves (q : State) (h : Safe q) (g : share1Guard q) : Safe (share1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,share1Guard,share1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem dedicate0Preserves (q : State) (h : Safe q) (g : dedicate0Guard q) : Safe (dedicate0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,dedicate0Guard,dedicate0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem dedicate1Preserves (q : State) (h : Safe q) (g : dedicate1Guard q) : Safe (dedicate1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,dedicate1Guard,dedicate1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reject0Preserves (q : State) (h : Safe q) (g : reject0Guard q) : Safe (reject0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,reject0Guard,reject0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reject1Preserves (q : State) (h : Safe q) (g : reject1Guard q) : Safe (reject1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,reject1Guard,reject1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealAcceptPreserves (q : State) (h : Safe q) (g : sealAcceptGuard q) : Safe (sealAcceptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,sealAcceptGuard,sealAcceptNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealRejectPreserves (q : State) (h : Safe q) (g : sealRejectGuard q) : Safe (sealRejectNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,sealRejectGuard,sealRejectNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem allocationFailurePreserves (q : State) (h : Safe q) (g : allocationFailureGuard q) : Safe (allocationFailureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,allocationFailureGuard,allocationFailureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem denyMutationPreserves (q : State) (h : Safe q) (g : denyMutationGuard q) : Safe (denyMutationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,denyMutationGuard,denyMutationNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retainUnknownPreserves (q : State) (h : Safe q) (g : retainUnknownGuard q) : Safe (retainUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all [Safe,retainUnknownGuard,retainUnknownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14
 · rcases a0 with ⟨g,rfl⟩; exact freezeSmallPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact freezeLargePreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact freezeOversizePreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact share0Preserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact share1Preserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact dedicate0Preserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact dedicate1Preserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact reject0Preserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact reject1Preserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact sealAcceptPreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact sealRejectPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact allocationFailurePreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact denyMutationPreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact retainUnknownPreserves q h g
 · rw [a14]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem acceptedBounds (q : State) (h : Safe q) (a : q.outcome=1) : 4≤q.r0 ∧ 4≤q.r1 ∧ q.r0+8≤q.cap0 ∧ q.r1+8≤q.cap1 := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all <;> omega
theorem largeNeedsDedicated (q : State) (h : Safe q) (a : q.outcome=1) (large : 20<q.r1+8) : q.mode1=2 ∧ q.cap1=64 := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20⟩
 simp_all <;> omega
theorem frozenLengthStable (q r : State) (h : Safe q) (f : q.frozen=true) (st : Step q r) : r.r0=q.r0 ∧ r.r1=q.r1 := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14
 · rcases a0 with ⟨g,rfl⟩; simp_all [Safe,freezeSmallGuard,freezeSmallNext] <;> omega
 · rcases a1 with ⟨g,rfl⟩; simp_all [Safe,freezeLargeGuard,freezeLargeNext] <;> omega
 · rcases a2 with ⟨g,rfl⟩; simp_all [Safe,freezeOversizeGuard,freezeOversizeNext] <;> omega
 · rcases a3 with ⟨g,rfl⟩; simp_all [Safe,share0Guard,share0Next] <;> omega
 · rcases a4 with ⟨g,rfl⟩; simp_all [Safe,share1Guard,share1Next] <;> omega
 · rcases a5 with ⟨g,rfl⟩; simp_all [Safe,dedicate0Guard,dedicate0Next] <;> omega
 · rcases a6 with ⟨g,rfl⟩; simp_all [Safe,dedicate1Guard,dedicate1Next] <;> omega
 · rcases a7 with ⟨g,rfl⟩; simp_all [Safe,reject0Guard,reject0Next] <;> omega
 · rcases a8 with ⟨g,rfl⟩; simp_all [Safe,reject1Guard,reject1Next] <;> omega
 · rcases a9 with ⟨g,rfl⟩; simp_all [Safe,sealAcceptGuard,sealAcceptNext] <;> omega
 · rcases a10 with ⟨g,rfl⟩; simp_all [Safe,sealRejectGuard,sealRejectNext] <;> omega
 · rcases a11 with ⟨g,rfl⟩; simp_all [Safe,allocationFailureGuard,allocationFailureNext] <;> omega
 · rcases a12 with ⟨g,rfl⟩; simp_all [Safe,denyMutationGuard,denyMutationNext] <;> omega
 · rcases a13 with ⟨g,rfl⟩; simp_all [Safe,retainUnknownGuard,retainUnknownNext] <;> omega
 · rw [a14]; exact ⟨rfl,rfl⟩
theorem sealedOutcomeStable (q r : State) (h : Safe q) (f : q.outcome>0) (st : Step q r) : r.outcome=q.outcome := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14
 · rcases a0 with ⟨g,rfl⟩; simp_all [Safe,freezeSmallGuard,freezeSmallNext] <;> omega
 · rcases a1 with ⟨g,rfl⟩; simp_all [Safe,freezeLargeGuard,freezeLargeNext] <;> omega
 · rcases a2 with ⟨g,rfl⟩; simp_all [Safe,freezeOversizeGuard,freezeOversizeNext] <;> omega
 · rcases a3 with ⟨g,rfl⟩; simp_all [Safe,share0Guard,share0Next] <;> omega
 · rcases a4 with ⟨g,rfl⟩; simp_all [Safe,share1Guard,share1Next] <;> omega
 · rcases a5 with ⟨g,rfl⟩; simp_all [Safe,dedicate0Guard,dedicate0Next] <;> omega
 · rcases a6 with ⟨g,rfl⟩; simp_all [Safe,dedicate1Guard,dedicate1Next] <;> omega
 · rcases a7 with ⟨g,rfl⟩; simp_all [Safe,reject0Guard,reject0Next] <;> omega
 · rcases a8 with ⟨g,rfl⟩; simp_all [Safe,reject1Guard,reject1Next] <;> omega
 · rcases a9 with ⟨g,rfl⟩; simp_all [Safe,sealAcceptGuard,sealAcceptNext] <;> omega
 · rcases a10 with ⟨g,rfl⟩; simp_all [Safe,sealRejectGuard,sealRejectNext] <;> omega
 · rcases a11 with ⟨g,rfl⟩; simp_all [Safe,allocationFailureGuard,allocationFailureNext] <;> omega
 · rcases a12 with ⟨g,rfl⟩; simp_all [Safe,denyMutationGuard,denyMutationNext] <;> omega
 · rcases a13 with ⟨g,rfl⟩; simp_all [Safe,retainUnknownGuard,retainUnknownNext] <;> omega
 · rw [a14]
end ContinuationRestore

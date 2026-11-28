import CapacityCollectiveAst
namespace CapacityCollective
open CapacityCollectiveAst
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem publishReadyPreserves (q : State) (h : Safe q) (g : publishReadyGuard q) : Safe (publishReadyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,publishReadyGuard,publishReadyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishFailurePreserves (q : State) (h : Safe q) (g : publishFailureGuard q) : Safe (publishFailureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,publishFailureGuard,publishFailureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem accept0Preserves (q : State) (h : Safe q) (g : accept0Guard q) : Safe (accept0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp only [accept0Guard] at g
 have zeroDecision : q.decision=0 := by omega
 simp_all [Safe,accept0Guard,accept0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem accept1Preserves (q : State) (h : Safe q) (g : accept1Guard q) : Safe (accept1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp only [accept1Guard] at g
 have zeroDecision : q.decision=0 := by omega
 simp_all [Safe,accept1Guard,accept1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reject0Preserves (q : State) (h : Safe q) (g : reject0Guard q) : Safe (reject0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp only [reject0Guard] at g
 have zeroDecision : q.decision=0 := by omega
 simp_all [Safe,reject0Guard,reject0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reject1Preserves (q : State) (h : Safe q) (g : reject1Guard q) : Safe (reject1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp only [reject1Guard] at g
 have zeroDecision : q.decision=0 := by omega
 simp_all [Safe,reject1Guard,reject1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem decideAcceptPreserves (q : State) (h : Safe q) (g : decideAcceptGuard q) : Safe (decideAcceptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,decideAcceptGuard,decideAcceptNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem decideRejectPreserves (q : State) (h : Safe q) (g : decideRejectGuard q) : Safe (decideRejectNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,decideRejectGuard,decideRejectNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem acknowledge0Preserves (q : State) (h : Safe q) (g : acknowledge0Guard q) : Safe (acknowledge0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,acknowledge0Guard,acknowledge0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem acknowledge1Preserves (q : State) (h : Safe q) (g : acknowledge1Guard q) : Safe (acknowledge1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,acknowledge1Guard,acknowledge1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem releasePreserves (q : State) (h : Safe q) (g : releaseGuard q) : Safe (releaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,releaseGuard,releaseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem flip0Preserves (q : State) (h : Safe q) (g : flip0Guard q) : Safe (flip0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,flip0Guard,flip0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem flip1Preserves (q : State) (h : Safe q) (g : flip1Guard q) : Safe (flip1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,flip1Guard,flip1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem deliver0Preserves (q : State) (h : Safe q) (g : deliver0Guard q) : Safe (deliver0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,deliver0Guard,deliver0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem deliver1Preserves (q : State) (h : Safe q) (g : deliver1Guard q) : Safe (deliver1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,deliver1Guard,deliver1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retainUnknownPreserves (q : State) (h : Safe q) (g : retainUnknownGuard q) : Safe (retainUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,retainUnknownGuard,retainUnknownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retainSetupUnknownPreserves (q : State) (h : Safe q) (g : retainSetupUnknownGuard q) : Safe (retainSetupUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,retainSetupUnknownGuard,retainSetupUnknownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeRejectedPreserves (q : State) (h : Safe q) (g : freeRejectedGuard q) : Safe (freeRejectedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all [Safe,freeRejectedGuard,freeRejectedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18
 · rcases a0 with ⟨g,rfl⟩; exact publishReadyPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact publishFailurePreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact accept0Preserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact accept1Preserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact reject0Preserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact reject1Preserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact decideAcceptPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact decideRejectPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact acknowledge0Preserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact acknowledge1Preserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact releasePreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact flip0Preserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact flip1Preserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact deliver0Preserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact deliver1Preserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact retainUnknownPreserves q h g
 · rcases a16 with ⟨g,rfl⟩; exact retainSetupUnknownPreserves q h g
 · rcases a17 with ⟨g,rfl⟩; exact freeRejectedPreserves q h g
 · rw [a18]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem flipRequiresAllAcknowledged (q : State) (h : Safe q) (f : q.flip0=true ∨ q.flip1=true) : q.decision=1 ∧ q.released=true ∧ q.ack0=true ∧ q.ack1=true ∧ q.freed=false := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all <;> omega
theorem rejectCannotFlip (q : State) (h : Safe q) (d : q.decision=2) : q.flip0=false ∧ q.flip1=false := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all <;> omega
theorem freeRequiresBothResults (q : State) (h : Safe q) (f : q.freed=true) : q.result0=2 ∧ q.result1=2 ∧ q.reader0=false ∧ q.reader1=false := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all <;> omega
theorem noRepeatedFree (q : State) (f : q.freed=true) : ¬freeRejectedGuard q := by simp [freeRejectedGuard,f]
end CapacityCollective

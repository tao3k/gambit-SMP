import SectionLeasesAst
namespace SectionLeases
open SectionLeasesAst
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem fresh4worker0Preserves (q : State) (h : Safe q) (g : fresh4worker0Guard q) : Safe (fresh4worker0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all [Safe,fresh4worker0Guard,fresh4worker0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem fresh4worker1Preserves (q : State) (h : Safe q) (g : fresh4worker1Guard q) : Safe (fresh4worker1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all [Safe,fresh4worker1Guard,fresh4worker1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem fresh5worker0Preserves (q : State) (h : Safe q) (g : fresh5worker0Guard q) : Safe (fresh5worker0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all [Safe,fresh5worker0Guard,fresh5worker0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem fresh5worker1Preserves (q : State) (h : Safe q) (g : fresh5worker1Guard q) : Safe (fresh5worker1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all [Safe,fresh5worker1Guard,fresh5worker1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem shareWorker0Preserves (q : State) (h : Safe q) (g : shareWorker0Guard q) : Safe (shareWorker0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 cases other : q.shared1 <;> simp_all [Safe,shareWorker0Guard,shareWorker0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem shareWorker1Preserves (q : State) (h : Safe q) (g : shareWorker1Guard q) : Safe (shareWorker1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 cases other : q.shared0 <;> simp_all [Safe,shareWorker1Guard,shareWorker1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem denyStackRebindPreserves (q : State) (h : Safe q) (g : denyStackRebindGuard q) : Safe (denyStackRebindNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all [Safe,denyStackRebindGuard,denyStackRebindNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem denyGrowPreserves (q : State) (h : Safe q) (g : denyGrowGuard q) : Safe (denyGrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all [Safe,denyGrowGuard,denyGrowNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem denyReentryPreserves (q : State) (h : Safe q) (g : denyReentryGuard q) : Safe (denyReentryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all [Safe,denyReentryGuard,denyReentryNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownWriterPreserves (q : State) (h : Safe q) (g : unknownWriterGuard q) : Safe (unknownWriterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all [Safe,unknownWriterGuard,unknownWriterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem exhaustedShared0Preserves (q : State) (h : Safe q) (g : exhaustedShared0Guard q) : Safe (exhaustedShared0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all [Safe,exhaustedShared0Guard,exhaustedShared0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeAllocatorsPreserves (q : State) (h : Safe q) (g : closeAllocatorsGuard q) : Safe (closeAllocatorsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all [Safe,closeAllocatorsGuard,closeAllocatorsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12
 · rcases a0 with ⟨g,rfl⟩; exact fresh4worker0Preserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact fresh4worker1Preserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact fresh5worker0Preserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact fresh5worker1Preserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact shareWorker0Preserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact shareWorker1Preserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact denyStackRebindPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact denyGrowPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact denyReentryPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact unknownWriterPreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact exhaustedShared0Preserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact closeAllocatorsPreserves q h g
 · rw [a12]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem visitsBound (q : State) (h : Safe q) : q.visits<=q.n := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 omega
theorem currentHeapsDistinct (q : State) (h : Safe q) : q.heap0≠q.heap1 := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp_all <;> omega
theorem unknownKeepsVisits (q : State) : (unknownWriterNext q).visits=q.visits ∧ (unknownWriterNext q).retained=true ∧ (unknownWriterNext q).certified=false := by simp [unknownWriterNext]
end SectionLeases

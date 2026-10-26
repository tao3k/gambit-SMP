import ProducerEnvelopeAst
namespace ProducerEnvelope
open ProducerEnvelopeAst
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem coverObjectsPreserves (q : State) (h : Safe q) (g : coverObjectsGuard q) : Safe (coverObjectsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,coverObjectsGuard,coverObjectsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem coverFramesPreserves (q : State) (h : Safe q) (g : coverFramesGuard q) : Safe (coverFramesNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,coverFramesGuard,coverFramesNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem chooseCapPreserves (q : State) (h : Safe q) (g : chooseCapGuard q) : Safe (chooseCapNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,chooseCapGuard,chooseCapNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abiMismatchPreserves (q : State) (h : Safe q) (g : abiMismatchGuard q) : Safe (abiMismatchNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,abiMismatchGuard,abiMismatchNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem opaqueProducerPreserves (q : State) (h : Safe q) (g : opaqueProducerGuard q) : Safe (opaqueProducerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,opaqueProducerGuard,opaqueProducerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem missingOldModulePreserves (q : State) (h : Safe q) (g : missingOldModuleGuard q) : Safe (missingOldModuleNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,missingOldModuleGuard,missingOldModuleNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem missingSourceWitnessPreserves (q : State) (h : Safe q) (g : missingSourceWitnessGuard q) : Safe (missingSourceWitnessNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,missingSourceWitnessGuard,missingSourceWitnessNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeze64Preserves (q : State) (h : Safe q) (g : freeze64Guard q) : Safe (freeze64Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,freeze64Guard,freeze64Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeze32Preserves (q : State) (h : Safe q) (g : freeze32Guard q) : Safe (freeze32Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,freeze32Guard,freeze32Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem startPreserves (q : State) (h : Safe q) (g : startGuard q) : Safe (startNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,startGuard,startNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem consumePreserves (q : State) (h : Safe q) (g : consumeGuard q) : Safe (consumeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,consumeGuard,consumeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem weakCutPreserves (q : State) (h : Safe q) (g : weakCutGuard q) : Safe (weakCutNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,weakCutGuard,weakCutNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem deferLateModulePreserves (q : State) (h : Safe q) (g : deferLateModuleGuard q) : Safe (deferLateModuleNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,deferLateModuleGuard,deferLateModuleNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem replaceBeforeStartPreserves (q : State) (h : Safe q) (g : replaceBeforeStartGuard q) : Safe (replaceBeforeStartNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all [Safe,replaceBeforeStartGuard,replaceBeforeStartNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15
 · rcases a0 with ⟨g,rfl⟩; exact coverObjectsPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact coverFramesPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact chooseCapPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact abiMismatchPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact opaqueProducerPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact missingOldModulePreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact missingSourceWitnessPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact freeze64Preserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact freeze32Preserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact issuePreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact startPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact consumePreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact weakCutPreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact deferLateModulePreserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact replaceBeforeStartPreserves q h g
 · rw [a15]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem certificateBounds (q : State) (h : Safe q) (i : q.sealed=true) : q.cap≥q.objectMax ∧ q.cap≥q.frameFs+2 ∧ q.budget≥q.u+q.threshold ∧ q.u≤q.q+q.align := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all <;> omega
theorem certificateScope (q : State) (h : Safe q) (i : q.sealed=true) : q.oldPinned=true ∧ q.abi=true ∧ q.sourceWitness=true ∧ q.seenEpoch=q.epoch := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all <;> omega
theorem alternativeCannotStart (q : State) (h : Safe q) (a : q.alternative=true) : q.started=false ∧ q.retained=true := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25⟩
 simp_all <;> omega
theorem weakCutKeepsEnvelope (q : State) : let r:=weakCutNext q; r.q=q.q ∧ r.u=q.u ∧ r.budget=q.budget ∧ r.spent=q.spent := by simp [weakCutNext]
end ProducerEnvelope

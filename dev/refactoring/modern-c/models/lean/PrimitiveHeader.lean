import PrimitiveHeaderAst
namespace PrimitiveHeader
open PrimitiveHeaderAst
set_option maxHeartbeats 4000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem seedSupplyPreserves (q : State) (h : Safe q) (g : seedSupplyGuard q) : Safe (seedSupplyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,seedSupplyGuard,seedSupplyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem seedDemandPreserves (q : State) (h : Safe q) (g : seedDemandGuard q) : Safe (seedDemandNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,seedDemandGuard,seedDemandNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem seedOtherDemandPreserves (q : State) (h : Safe q) (g : seedOtherDemandGuard q) : Safe (seedOtherDemandNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,seedOtherDemandGuard,seedOtherDemandNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem writeHeaderPreserves (q : State) (h : Safe q) (g : writeHeaderGuard q) : Safe (writeHeaderNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,writeHeaderGuard,writeHeaderNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem emitPrmPreserves (q : State) (h : Safe q) (g : emitPrmGuard q) : Safe (emitPrmNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,emitPrmGuard,emitPrmNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem emitGloPreserves (q : State) (h : Safe q) (g : emitGloGuard q) : Safe (emitGloNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,emitGloGuard,emitGloNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealSpecPreserves (q : State) (h : Safe q) (g : sealSpecGuard q) : Safe (sealSpecNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,sealSpecGuard,sealSpecNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem checkCoveragePreserves (q : State) (h : Safe q) (g : checkCoverageGuard q) : Safe (checkCoverageNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,checkCoverageGuard,checkCoverageNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closePairPreserves (q : State) (h : Safe q) (g : closePairGuard q) : Safe (closePairNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,closePairGuard,closePairNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownOutputPreserves (q : State) (h : Safe q) (g : unknownOutputGuard q) : Safe (unknownOutputNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,unknownOutputGuard,unknownOutputNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectLateUsePreserves (q : State) (h : Safe q) (g : rejectLateUseGuard q) : Safe (rejectLateUseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,rejectLateUseGuard,rejectLateUseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12
 · rcases h0 with ⟨g,e⟩; rw [e]; exact seedSupplyPreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact seedDemandPreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact seedOtherDemandPreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact writeHeaderPreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact emitPrmPreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact emitGloPreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact sealSpecPreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact checkCoveragePreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact closePairPreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact issuePreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact unknownOutputPreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact rejectLateUsePreserves q h g
 · rw [h12]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem lateBindingKeepsHeader (q : State) : (emitPrmNext q).headerDemand=q.headerDemand ∧ (emitGloNext q).headerDemand=q.headerDemand := by simp [emitPrmNext,emitGloNext]
theorem receiptNeedsPair (q : State) (h : Safe q) (r : q.receipt=true) : q.coverage=true ∧ q.closed=true := by simp_all [Safe]
end PrimitiveHeader

import WeakCoverageAst
namespace WeakCoverage
open WeakCoverageAst
set_option maxHeartbeats 4000000
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem configStrongPreserves (q : State) (h : Safe q) (g : configStrongGuard q) : Safe (configStrongNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,configStrongGuard,configStrongNext] <;> (trace_state; omega)
theorem configWeakKeyPreserves (q : State) (h : Safe q) (g : configWeakKeyGuard q) : Safe (configWeakKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,configWeakKeyGuard,configWeakKeyNext] <;> omega
theorem configWeakValPreserves (q : State) (h : Safe q) (g : configWeakValGuard q) : Safe (configWeakValNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,configWeakValGuard,configWeakValNext] <;> omega
theorem configWeakBothPreserves (q : State) (h : Safe q) (g : configWeakBothGuard q) : Safe (configWeakBothNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,configWeakBothGuard,configWeakBothNext] <;> omega
theorem configRawKeyPreserves (q : State) (h : Safe q) (g : configRawKeyGuard q) : Safe (configRawKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,configRawKeyGuard,configRawKeyNext] <;> omega
theorem deadKeyPreserves (q : State) (h : Safe q) (g : deadKeyGuard q) : Safe (deadKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,deadKeyGuard,deadKeyNext] <;> omega
theorem deadValPreserves (q : State) (h : Safe q) (g : deadValGuard q) : Safe (deadValNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,deadValGuard,deadValNext] <;> omega
theorem traceKeyPreserves (q : State) (h : Safe q) (g : traceKeyGuard q) : Safe (traceKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,traceKeyGuard,traceKeyNext] <;> omega
theorem traceValPreserves (q : State) (h : Safe q) (g : traceValGuard q) : Safe (traceValNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,traceValGuard,traceValNext] <;> omega
theorem tableScanDonePreserves (q : State) (h : Safe q) (g : tableScanDoneGuard q) : Safe (tableScanDoneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,tableScanDoneGuard,tableScanDoneNext] <;> omega
theorem strongWillPreserves (q : State) (h : Safe q) (g : strongWillGuard q) : Safe (strongWillNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,strongWillGuard,strongWillNext] <;> omega
theorem enterWeakPreserves (q : State) (h : Safe q) (g : enterWeakGuard q) : Safe (enterWeakNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,enterWeakGuard,enterWeakNext] <;> omega
theorem repairWillPreserves (q : State) (h : Safe q) (g : repairWillGuard q) : Safe (repairWillNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,repairWillGuard,repairWillNext] <;> omega
theorem freshWeakWillPreserves (q : State) (h : Safe q) (g : freshWeakWillGuard q) : Safe (freshWeakWillNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,freshWeakWillGuard,freshWeakWillNext] <;> omega
theorem skipDonePreserves (q : State) (h : Safe q) (g : skipDoneGuard q) : Safe (skipDoneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,skipDoneGuard,skipDoneNext] <;> omega
theorem finishWeakPreserves (q : State) (h : Safe q) (g : finishWeakGuard q) : Safe (finishWeakNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,finishWeakGuard,finishWeakNext] <;> omega
theorem cleanupTablePreserves (q : State) (h : Safe q) (g : cleanupTableGuard q) : Safe (cleanupTableNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,cleanupTableGuard,cleanupTableNext] <;> omega
theorem closePreserves (q : State) (h : Safe q) (g : closeGuard q) : Safe (closeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,closeGuard,closeNext] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18
 · rcases a0 with ⟨g,rfl⟩; exact configStrongPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact configWeakKeyPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact configWeakValPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact configWeakBothPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact configRawKeyPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact deadKeyPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact deadValPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact traceKeyPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact traceValPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact tableScanDonePreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact strongWillPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact enterWeakPreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact repairWillPreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact freshWeakWillPreserves q h g
 · rcases a14 with ⟨g,e⟩; rw [e]; exact skipDonePreserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact finishWeakPreserves q h g
 · rcases a16 with ⟨g,rfl⟩; exact cleanupTablePreserves q h g
 · rcases a17 with ⟨g,rfl⟩; exact closePreserves q h g
 · simpa [a18] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
end WeakCoverage

import WeakCoverageAst
namespace WeakCoverage
open WeakCoverageAst
set_option maxHeartbeats 4000000
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem configStrongPreserves (q : State) (h : Safe q) (g : configStrongGuard q) : Safe (configStrongNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,configStrongGuard,configStrongNext] <;> intros <;> simp_all <;> omega
theorem configWeakKeyPreserves (q : State) (h : Safe q) (g : configWeakKeyGuard q) : Safe (configWeakKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,configWeakKeyGuard,configWeakKeyNext] <;> intros <;> simp_all <;> omega
theorem configWeakValPreserves (q : State) (h : Safe q) (g : configWeakValGuard q) : Safe (configWeakValNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,configWeakValGuard,configWeakValNext] <;> intros <;> simp_all <;> omega
theorem configWeakBothPreserves (q : State) (h : Safe q) (g : configWeakBothGuard q) : Safe (configWeakBothNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,configWeakBothGuard,configWeakBothNext] <;> intros <;> simp_all <;> omega
theorem configRawKeyPreserves (q : State) (h : Safe q) (g : configRawKeyGuard q) : Safe (configRawKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,configRawKeyGuard,configRawKeyNext] <;> intros <;> simp_all <;> omega
theorem deadKeyPreserves (q : State) (h : Safe q) (g : deadKeyGuard q) : Safe (deadKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,deadKeyGuard,deadKeyNext] <;> intros <;> simp_all <;> omega
theorem deadValPreserves (q : State) (h : Safe q) (g : deadValGuard q) : Safe (deadValNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,deadValGuard,deadValNext] <;> intros <;> simp_all <;> omega
theorem traceKeyPreserves (q : State) (h : Safe q) (g : traceKeyGuard q) : Safe (traceKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,traceKeyGuard,traceKeyNext] <;> intros <;> simp_all <;> omega
theorem traceValPreserves (q : State) (h : Safe q) (g : traceValGuard q) : Safe (traceValNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,traceValGuard,traceValNext] <;> intros <;> simp_all <;> omega
theorem tableScanDonePreserves (q : State) (h : Safe q) (g : tableScanDoneGuard q) : Safe (tableScanDoneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,tableScanDoneGuard,tableScanDoneNext] <;> intros <;> simp_all <;> omega
theorem strongWillPreserves (q : State) (h : Safe q) (g : strongWillGuard q) : Safe (strongWillNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,strongWillGuard,strongWillNext] <;> intros <;> simp_all <;> omega
theorem enterWeakPreserves (q : State) (h : Safe q) (g : enterWeakGuard q) : Safe (enterWeakNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,enterWeakGuard,enterWeakNext] <;> intros <;> simp_all <;> omega
theorem repairWillPreserves (q : State) (h : Safe q) (g : repairWillGuard q) : Safe (repairWillNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,repairWillGuard,repairWillNext] <;> intros <;> simp_all <;> omega
theorem freshWeakWillPreserves (q : State) (h : Safe q) (g : freshWeakWillGuard q) : Safe (freshWeakWillNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,freshWeakWillGuard,freshWeakWillNext] <;> intros <;> simp_all <;> omega
theorem skipDonePreserves (q : State) (h : Safe q) (g : skipDoneGuard q) : Safe (skipDoneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,skipDoneGuard,skipDoneNext] <;> intros <;> simp_all <;> omega
theorem finishWeakPreserves (q : State) (h : Safe q) (g : finishWeakGuard q) : Safe (finishWeakNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,finishWeakGuard,finishWeakNext] <;> intros <;> simp_all <;> omega
theorem cleanupTablePreserves (q : State) (h : Safe q) (g : cleanupTableGuard q) : Safe (cleanupTableNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,cleanupTableGuard,cleanupTableNext] <;> intros <;> simp_all <;> omega
theorem closePreserves (q : State) (h : Safe q) (g : closeGuard q) : Safe (closeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,closeGuard,closeNext] <;> intros <;> simp_all <;> omega
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
theorem doneSkipKeepsRepairFlag (q : State) : (skipDoneNext q).willFlag=q.willFlag := rfl
theorem repairKeepsObjectDone (q : State) : (repairWillNext q).willKind=q.willKind := rfl
theorem hashFootprintPhaseIndependent (q : State) : traceKeyGuard {q with mode:=0} ↔ traceKeyGuard {q with mode:=1} := Iff.rfl
theorem weakBothNeverStrongRoots (q : State) (h : Safe q) (k : q.kind=3) : q.keyTraced=false ∧ q.valTraced=false := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all
end WeakCoverage

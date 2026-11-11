import WeakAdmissionAst
namespace WeakAdmission
open WeakAdmissionAst
set_option maxHeartbeats 4000000
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem drainStrongPreserves (q : State) (h : Safe q) (g : drainStrongGuard q) : Safe (drainStrongNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,drainStrongGuard,drainStrongNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeStrongPreserves (q : State) (h : Safe q) (g : freezeStrongGuard q) : Safe (freezeStrongNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,freezeStrongGuard,freezeStrongNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem classifyAPreserves (q : State) (h : Safe q) (g : classifyAGuard q) : Safe (classifyANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,classifyAGuard,classifyANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem classifyBPreserves (q : State) (h : Safe q) (g : classifyBGuard q) : Safe (classifyBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,classifyBGuard,classifyBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem openWeakPreserves (q : State) (h : Safe q) (g : openWeakGuard q) : Safe (openWeakNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,openWeakGuard,openWeakNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem listProducerPreserves (q : State) (h : Safe q) (g : listProducerGuard q) : Safe (listProducerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,listProducerGuard,listProducerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem repairProducerPreserves (q : State) (h : Safe q) (g : repairProducerGuard q) : Safe (repairProducerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,repairProducerGuard,repairProducerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freshWillProducerPreserves (q : State) (h : Safe q) (g : freshWillProducerGuard q) : Safe (freshWillProducerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,freshWillProducerGuard,freshWillProducerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem graphProducerPreserves (q : State) (h : Safe q) (g : graphProducerGuard q) : Safe (graphProducerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,graphProducerGuard,graphProducerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem continuationProducerPreserves (q : State) (h : Safe q) (g : continuationProducerGuard q) : Safe (continuationProducerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,continuationProducerGuard,continuationProducerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stillProducerPreserves (q : State) (h : Safe q) (g : stillProducerGuard q) : Safe (stillProducerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,stillProducerGuard,stillProducerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem deriveChildPreserves (q : State) (h : Safe q) (g : deriveChildGuard q) : Safe (deriveChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,deriveChildGuard,deriveChildNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem settleTaskPreserves (q : State) (h : Safe q) (g : settleTaskGuard q) : Safe (settleTaskNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,settleTaskGuard,settleTaskNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeRootsPreserves (q : State) (h : Safe q) (g : closeRootsGuard q) : Safe (closeRootsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,closeRootsGuard,closeRootsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishWeakPreserves (q : State) (h : Safe q) (g : finishWeakGuard q) : Safe (finishWeakNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,finishWeakGuard,finishWeakNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem cleanupPreserves (q : State) (h : Safe q) (g : cleanupGuard q) : Safe (cleanupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 simp_all [Safe,cleanupGuard,cleanupNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16
 · rcases a0 with ⟨g,rfl⟩; exact drainStrongPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact freezeStrongPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact classifyAPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact classifyBPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact openWeakPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact listProducerPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact repairProducerPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact freshWillProducerPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact graphProducerPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact continuationProducerPreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact stillProducerPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact deriveChildPreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact settleTaskPreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact closeRootsPreserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact finishWeakPreserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact cleanupPreserves q h g
 · rw [a16]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem producerNeedsCut (q : State) (h : Safe q) (ha : 0<q.active) :
 q.strongClosed=true ∧ q.da=true ∧ q.db=true := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12⟩
 have hp := h10 ha
 have hs := h7 (by omega)
 have hd := h9 (by omega)
 exact ⟨hs.1,hd.1,hd.2⟩
theorem completedNoDebt (q : State) (h : Safe q) (hp : 3≤q.phase) :
 q.rootsClosed=true ∧ q.active=0 := by
 simp only [Safe] at h
 exact h.2.2.2.2.2.2.2.2.2.2.2.1 hp

theorem childReservationBeforeRelease (n : Int) (h : 0<n) : n+1-1=n ∧ 0<n+1 := by omega
end WeakAdmission

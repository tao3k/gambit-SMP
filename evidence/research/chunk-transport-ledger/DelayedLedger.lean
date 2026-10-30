import DelayedLedgerAst
namespace DelayedLedger
open DelayedLedgerAst
set_option maxHeartbeats 4000000
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem drainStrongPreserves (q : State) (h : Safe q) (g : drainStrongGuard q) : Safe (drainStrongNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,drainStrongGuard,drainStrongNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeStrongPreserves (q : State) (h : Safe q) (g : freezeStrongGuard q) : Safe (freezeStrongNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,freezeStrongGuard,freezeStrongNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem classifyAPreserves (q : State) (h : Safe q) (g : classifyAGuard q) : Safe (classifyANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,classifyAGuard,classifyANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem classifyBPreserves (q : State) (h : Safe q) (g : classifyBGuard q) : Safe (classifyBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,classifyBGuard,classifyBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enterWeakPreserves (q : State) (h : Safe q) (g : enterWeakGuard q) : Safe (enterWeakNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,enterWeakGuard,enterWeakNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem acceptDelayedPreserves (q : State) (h : Safe q) (g : acceptDelayedGuard q) : Safe (acceptDelayedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,acceptDelayedGuard,acceptDelayedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealDelayedPreserves (q : State) (h : Safe q) (g : sealDelayedGuard q) : Safe (sealDelayedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,sealDelayedGuard,sealDelayedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishAcceptedPreserves (q : State) (h : Safe q) (g : publishAcceptedGuard q) : Safe (publishAcceptedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,publishAcceptedGuard,publishAcceptedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeReceiptPreserves (q : State) (h : Safe q) (g : observeReceiptGuard q) : Safe (observeReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,observeReceiptGuard,observeReceiptNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem claimPreserves (q : State) (h : Safe q) (g : claimGuard q) : Safe (claimNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,claimGuard,claimNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem deriveChildPreserves (q : State) (h : Safe q) (g : deriveChildGuard q) : Safe (deriveChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,deriveChildGuard,deriveChildNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem settleParentPreserves (q : State) (h : Safe q) (g : settleParentGuard q) : Safe (settleParentNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,settleParentGuard,settleParentNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem settleChildPreserves (q : State) (h : Safe q) (g : settleChildGuard q) : Safe (settleChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,settleChildGuard,settleChildNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeRootsPreserves (q : State) (h : Safe q) (g : closeRootsGuard q) : Safe (closeRootsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,closeRootsGuard,closeRootsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishWeakPreserves (q : State) (h : Safe q) (g : finishWeakGuard q) : Safe (finishWeakNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,finishWeakGuard,finishWeakNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeFutureUsersPreserves (q : State) (h : Safe q) (g : closeFutureUsersGuard q) : Safe (closeFutureUsersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,closeFutureUsersGuard,closeFutureUsersNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem releaseHeadPreserves (q : State) (h : Safe q) (g : releaseHeadGuard q) : Safe (releaseHeadNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,releaseHeadGuard,releaseHeadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireEpochPreserves (q : State) (h : Safe q) (g : retireEpochGuard q) : Safe (retireEpochNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 simp_all [Safe,retireEpochGuard,retireEpochNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18
 · rcases a0 with ⟨g,rfl⟩; exact drainStrongPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact freezeStrongPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact classifyAPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact classifyBPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact enterWeakPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact acceptDelayedPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact sealDelayedPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact publishAcceptedPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact observeReceiptPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact claimPreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact deriveChildPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact settleParentPreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact settleChildPreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact closeRootsPreserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact finishWeakPreserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact closeFutureUsersPreserves q h g
 · rcases a16 with ⟨g,rfl⟩; exact releaseHeadPreserves q h g
 · rcases a17 with ⟨g,rfl⟩; exact retireEpochPreserves q h g
 · rw [a18]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem workConservation (q : State) (h : Safe q) : q.debt=q.accepted-q.settled := by
 simp only [Safe] at h; omega
theorem publicationPreservesDebt (q : State) : (publishAcceptedNext q).debt=q.debt ∧
 (publishAcceptedNext q).accepted=q.accepted := by simp [publishAcceptedNext]
theorem retirementRequiresNoPins (q : State) (h : Safe q) (hr : q.phase=4) :
 q.debt=0 ∧ q.headPin=false ∧ q.receiptPin=false := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 have hc := h21 (by omega)
 have hp := h26 hr
 simp_all
theorem childrenCoveredByDebt (q : State) (h : Safe q) : q.children≤q.debt := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 by_cases hc:1≤q.chunk ∧ q.chunk≤4
 · have he := h13 hc; omega
 · have hc2 : q.chunk=0 ∨ q.chunk=5 := by omega
   have he := h14 hc2; omega
end DelayedLedger

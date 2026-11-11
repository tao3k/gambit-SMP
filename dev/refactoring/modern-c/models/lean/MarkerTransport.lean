import MarkerTransportAst
namespace MarkerTransport
open MarkerTransportAst
set_option maxHeartbeats 4000000
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem chooseAtomicPreserves (q : State) (h : Safe q) (g : chooseAtomicGuard q) : Safe (chooseAtomicNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,chooseAtomicGuard,chooseAtomicNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,chooseAtomicGuard,chooseAtomicNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem chooseSplitPreserves (q : State) (h : Safe q) (g : chooseSplitGuard q) : Safe (chooseSplitNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,chooseSplitGuard,chooseSplitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,chooseSplitGuard,chooseSplitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem exposePreserves (q : State) (h : Safe q) (g : exposeGuard q) : Safe (exposeNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,exposeGuard,exposeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,exposeGuard,exposeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem plainReadPreserves (q : State) (h : Safe q) (g : plainReadGuard q) : Safe (plainReadNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,plainReadGuard,plainReadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,plainReadGuard,plainReadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem atomicReadPreserves (q : State) (h : Safe q) (g : atomicReadGuard q) : Safe (atomicReadNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,atomicReadGuard,atomicReadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,atomicReadGuard,atomicReadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem acquireGatePreserves (q : State) (h : Safe q) (g : acquireGateGuard q) : Safe (acquireGateNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,acquireGateGuard,acquireGateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,acquireGateGuard,acquireGateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem plainWritePreserves (q : State) (h : Safe q) (g : plainWriteGuard q) : Safe (plainWriteNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,plainWriteGuard,plainWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,plainWriteGuard,plainWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem atomicWritePreserves (q : State) (h : Safe q) (g : atomicWriteGuard q) : Safe (atomicWriteNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,atomicWriteGuard,atomicWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,atomicWriteGuard,atomicWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishReadPreserves (q : State) (h : Safe q) (g : finishReadGuard q) : Safe (finishReadNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,finishReadGuard,finishReadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,finishReadGuard,finishReadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishWritePreserves (q : State) (h : Safe q) (g : finishWriteGuard q) : Safe (finishWriteNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,finishWriteGuard,finishWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,finishWriteGuard,finishWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem releaseGatePreserves (q : State) (h : Safe q) (g : releaseGateGuard q) : Safe (releaseGateNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,releaseGateGuard,releaseGateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,releaseGateGuard,releaseGateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireStoragePreserves (q : State) (h : Safe q) (g : retireStorageGuard q) : Safe (retireStorageNext q) := by
 by_cases hm:q.mode≥1
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
   simp_all [Safe,retireStorageGuard,retireStorageNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,retireStorageGuard,retireStorageNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12
 · rcases a0 with ⟨g,rfl⟩; exact chooseAtomicPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact chooseSplitPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact exposePreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact plainReadPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact atomicReadPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact acquireGatePreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact plainWritePreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact atomicWritePreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact finishReadPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact finishWritePreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact releaseGatePreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact retireStoragePreserves q h g
 · rw [a12]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem noMixedSharedAccess (q : State) (h : Safe q) (hm : 1≤q.mode) :
 ¬(q.mode≠2 ∧ 0<q.reader ∧ 0<q.writer ∧ (q.reader=1 ∨ q.writer=1)) := by
 have hs := h hm
 rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10⟩
 intro hc; rcases hc with ⟨hc0,hc1,hc2,hc3⟩
 have he : q.mode=1 := by omega
 have hr := h6 ⟨he,hc1⟩
 have hw := h7 ⟨he,hc2⟩
 omega
end MarkerTransport

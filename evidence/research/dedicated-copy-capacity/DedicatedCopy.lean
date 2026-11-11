import DedicatedCopyAst
namespace DedicatedCopy
open DedicatedCopyAst
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem freezePreserves (q : State) (h : Safe q) (g : freezeGuard q) : Safe (freezeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,freezeGuard,freezeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sharedUnsuitablePreserves (q : State) (h : Safe q) (g : sharedUnsuitableGuard q) : Safe (sharedUnsuitableNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,sharedUnsuitableGuard,sharedUnsuitableNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem growFullPreserves (q : State) (h : Safe q) (g : growFullGuard q) : Safe (growFullNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,growFullGuard,growFullNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem growPartialPreserves (q : State) (h : Safe q) (g : growPartialGuard q) : Safe (growPartialNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,growPartialGuard,growPartialNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem growFailedPreserves (q : State) (h : Safe q) (g : growFailedGuard q) : Safe (growFailedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,growFailedGuard,growFailedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem growUnknownPreserves (q : State) (h : Safe q) (g : growUnknownGuard q) : Safe (growUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,growUnknownGuard,growUnknownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveFullPreserves (q : State) (h : Safe q) (g : resolveFullGuard q) : Safe (resolveFullNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,resolveFullGuard,resolveFullNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolvePartialPreserves (q : State) (h : Safe q) (g : resolvePartialGuard q) : Safe (resolvePartialNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,resolvePartialGuard,resolvePartialNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem chooseDedicatedPreserves (q : State) (h : Safe q) (g : chooseDedicatedGuard q) : Safe (chooseDedicatedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,chooseDedicatedGuard,chooseDedicatedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem planUnavailablePreserves (q : State) (h : Safe q) (g : planUnavailableGuard q) : Safe (planUnavailableNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,planUnavailableGuard,planUnavailableNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retryPlanPreserves (q : State) (h : Safe q) (g : retryPlanGuard q) : Safe (retryPlanNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,retryPlanGuard,retryPlanNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginCopyPreserves (q : State) (h : Safe q) (g : beginCopyGuard q) : Safe (beginCopyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,beginCopyGuard,beginCopyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireChargedPreserves (q : State) (h : Safe q) (g : retireChargedGuard q) : Safe (retireChargedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,retireChargedGuard,retireChargedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem consumeOnePreserves (q : State) (h : Safe q) (g : consumeOneGuard q) : Safe (consumeOneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,consumeOneGuard,consumeOneNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retainUnknownPreserves (q : State) (h : Safe q) (g : retainUnknownGuard q) : Safe (retainUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,retainUnknownGuard,retainUnknownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem cleanupKnownBatchPreserves (q : State) (h : Safe q) (g : cleanupKnownBatchGuard q) : Safe (cleanupKnownBatchNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,cleanupKnownBatchGuard,cleanupKnownBatchNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16
 · rcases a0 with ⟨g,rfl⟩; exact freezePreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact sharedUnsuitablePreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact growFullPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact growPartialPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact growFailedPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact growUnknownPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact resolveFullPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact resolvePartialPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact chooseDedicatedPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact planUnavailablePreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact retryPlanPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact beginCopyPreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact retireChargedPreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact consumeOnePreserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact retainUnknownPreserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact cleanupKnownBatchPreserves q h g
 · rw [a16]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem acceptedPhysicalCapacity (q : State) (h : Safe q) (a : q.sealed=true) : q.actual-2-1≥q.retired+2 := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all <;> omega
theorem unknownCannotSetupOrFree (q : State) (h : Safe q) (u : q.unknown=true) : q.sealed=false ∧ q.cleaned=false := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all <;> omega
theorem knownFailureIsNotExecution (q : State) (h : Safe q) (f : q.outcome=2) : q.collecting=false := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all <;> omega
theorem oldSourceImmutable (q r : State) (h : Safe q) (st : Step q r) : r.sourceN=q.sourceN := by
 have := stepPreserves q r h st
 simp_all [Safe]
theorem sealedStable (q r : State) (h : Safe q) (f : q.sealed=true) (st : Step q r) : r.sealed=true ∧ r.outcome=q.outcome ∧ r.actual=q.actual := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16
 · rcases a0 with ⟨g,rfl⟩; simp_all [Safe,freezeGuard,freezeNext] <;> omega
 · rcases a1 with ⟨g,rfl⟩; simp_all [Safe,sharedUnsuitableGuard,sharedUnsuitableNext] <;> omega
 · rcases a2 with ⟨g,rfl⟩; simp_all [Safe,growFullGuard,growFullNext] <;> omega
 · rcases a3 with ⟨g,rfl⟩; simp_all [Safe,growPartialGuard,growPartialNext] <;> omega
 · rcases a4 with ⟨g,rfl⟩; simp_all [Safe,growFailedGuard,growFailedNext] <;> omega
 · rcases a5 with ⟨g,rfl⟩; simp_all [Safe,growUnknownGuard,growUnknownNext] <;> omega
 · rcases a6 with ⟨g,rfl⟩; simp_all [Safe,resolveFullGuard,resolveFullNext] <;> omega
 · rcases a7 with ⟨g,rfl⟩; simp_all [Safe,resolvePartialGuard,resolvePartialNext] <;> omega
 · rcases a8 with ⟨g,rfl⟩; simp_all [Safe,chooseDedicatedGuard,chooseDedicatedNext] <;> omega
 · rcases a9 with ⟨g,rfl⟩; simp_all [Safe,planUnavailableGuard,planUnavailableNext] <;> omega
 · rcases a10 with ⟨g,rfl⟩; simp_all [Safe,retryPlanGuard,retryPlanNext] <;> omega
 · rcases a11 with ⟨g,rfl⟩; simp_all [Safe,beginCopyGuard,beginCopyNext] <;> omega
 · rcases a12 with ⟨g,rfl⟩; simp_all [Safe,retireChargedGuard,retireChargedNext] <;> omega
 · rcases a13 with ⟨g,rfl⟩; simp_all [Safe,consumeOneGuard,consumeOneNext] <;> omega
 · rcases a14 with ⟨g,rfl⟩; simp_all [Safe,retainUnknownGuard,retainUnknownNext] <;> omega
 · rcases a15 with ⟨g,rfl⟩; simp_all [Safe,cleanupKnownBatchGuard,cleanupKnownBatchNext] <;> omega
 · rw [a16]; simp [f]
theorem cleanupIsTerminal (q r : State) (h : Safe q) (f : q.cleaned=true) (st : Step q r) : r.actual=q.actual ∧ r.cleaned=true := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16
 · rcases a0 with ⟨g,rfl⟩; simp_all [Safe,freezeGuard,freezeNext] <;> omega
 · rcases a1 with ⟨g,rfl⟩; simp_all [Safe,sharedUnsuitableGuard,sharedUnsuitableNext] <;> omega
 · rcases a2 with ⟨g,rfl⟩; simp_all [Safe,growFullGuard,growFullNext] <;> omega
 · rcases a3 with ⟨g,rfl⟩; simp_all [Safe,growPartialGuard,growPartialNext] <;> omega
 · rcases a4 with ⟨g,rfl⟩; simp_all [Safe,growFailedGuard,growFailedNext] <;> omega
 · rcases a5 with ⟨g,rfl⟩; simp_all [Safe,growUnknownGuard,growUnknownNext] <;> omega
 · rcases a6 with ⟨g,rfl⟩; simp_all [Safe,resolveFullGuard,resolveFullNext] <;> omega
 · rcases a7 with ⟨g,rfl⟩; simp_all [Safe,resolvePartialGuard,resolvePartialNext] <;> omega
 · rcases a8 with ⟨g,rfl⟩; simp_all [Safe,chooseDedicatedGuard,chooseDedicatedNext] <;> omega
 · rcases a9 with ⟨g,rfl⟩; simp_all [Safe,planUnavailableGuard,planUnavailableNext] <;> omega
 · rcases a10 with ⟨g,rfl⟩; simp_all [Safe,retryPlanGuard,retryPlanNext] <;> omega
 · rcases a11 with ⟨g,rfl⟩; simp_all [Safe,beginCopyGuard,beginCopyNext] <;> omega
 · rcases a12 with ⟨g,rfl⟩; simp_all [Safe,retireChargedGuard,retireChargedNext] <;> omega
 · rcases a13 with ⟨g,rfl⟩; simp_all [Safe,consumeOneGuard,consumeOneNext] <;> omega
 · rcases a14 with ⟨g,rfl⟩; simp_all [Safe,retainUnknownGuard,retainUnknownNext] <;> omega
 · rcases a15 with ⟨g,rfl⟩; simp_all [Safe,cleanupKnownBatchGuard,cleanupKnownBatchNext] <;> omega
 · rw [a16]; simp [f]
end DedicatedCopy

import CallbackCarryAst
namespace CallbackCarry
open CallbackCarryAst
set_option maxHeartbeats 2000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem beginLegalPreserves (q : State) (h : Safe q) (g : beginLegalGuard q) : Safe (beginLegalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,beginLegalGuard,beginLegalNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginInternalCarryPreserves (q : State) (h : Safe q) (g : beginInternalCarryGuard q) : Safe (beginInternalCarryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,beginInternalCarryGuard,beginInternalCarryNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem advanceFifoPreserves (q : State) (h : Safe q) (g : advanceFifoGuard q) : Safe (advanceFifoNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,advanceFifoGuard,advanceFifoNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem allocateCandidatePreserves (q : State) (h : Safe q) (g : allocateCandidateGuard q) : Safe (allocateCandidateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,allocateCandidateGuard,allocateCandidateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem installSharedPreserves (q : State) (h : Safe q) (g : installSharedGuard q) : Safe (installSharedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,installSharedGuard,installSharedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem exposePreserves (q : State) (h : Safe q) (g : exposeGuard q) : Safe (exposeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,exposeGuard,exposeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem allocationFailurePreserves (q : State) (h : Safe q) (g : allocationFailureGuard q) : Safe (allocationFailureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,allocationFailureGuard,allocationFailureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem capturePreserves (q : State) (h : Safe q) (g : captureGuard q) : Safe (captureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,captureGuard,captureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resumePreserves (q : State) (h : Safe q) (g : resumeGuard q) : Safe (resumeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,resumeGuard,resumeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnActivationPreserves (q : State) (h : Safe q) (g : returnActivationGuard q) : Safe (returnActivationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,returnActivationGuard,returnActivationNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem attestRootRetirementPreserves (q : State) (h : Safe q) (g : attestRootRetirementGuard q) : Safe (attestRootRetirementNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,attestRootRetirementGuard,attestRootRetirementNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem releasePreserves (q : State) (h : Safe q) (g : releaseGuard q) : Safe (releaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,releaseGuard,releaseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem changeRegistrationPreserves (q : State) (h : Safe q) (g : changeRegistrationGuard q) : Safe (changeRegistrationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,changeRegistrationGuard,changeRegistrationNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownCallbackPreserves (q : State) (h : Safe q) (g : unknownCallbackGuard q) : Safe (unknownCallbackNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,unknownCallbackGuard,unknownCallbackNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem attestEffectsPreserves (q : State) (h : Safe q) (g : attestEffectsGuard q) : Safe (attestEffectsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16⟩
 simp_all [Safe,attestEffectsGuard,attestEffectsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (edge : Step q r) : Safe r := by
 rcases edge with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15
 · rcases h0 with ⟨g,e⟩; rw [e]; exact beginLegalPreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact beginInternalCarryPreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact advanceFifoPreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact allocateCandidatePreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact installSharedPreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact exposePreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact allocationFailurePreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact capturePreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact resumePreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact returnActivationPreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact attestRootRetirementPreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact releasePreserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact changeRegistrationPreserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact unknownCallbackPreserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact attestEffectsPreserves q h g
 · rw [h15]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem sharedCounterBias (q : State) (h : Safe q) (p : q.pc=4 ∨ q.pc=5) : q.wlo+q.whi-q.rlo-q.physical=q.carry := by simp_all [Safe]; omega
theorem capturePreventsRelease (q : State) (h : Safe q) (r : q.roots>0) : q.released=false := by cases c : q.released <;> simp_all [Safe]; omega
theorem replayRetainsCapture (q : State) : (resumeNext q).roots=q.roots := by rfl
theorem releaseNeedsReceipt (q : State) (g : releaseGuard q) : q.mapped=true ∧ q.closed=true := by simp_all [releaseGuard]
theorem permitEpoch (q : State) (h : Safe q) (p : q.permit=true) : q.sealedEpoch=q.epoch := by simp_all [Safe]
theorem failedAllocationRetainsRoots (q : State) : (allocationFailureNext q).roots=q.roots := by rfl
theorem noCarryConserves (q : State) (h : Safe q) (p : q.pc=4 ∨ q.pc=5) (c : q.carry=0) : q.physical=q.wlo+q.whi-q.rlo := by simp_all [Safe]; omega
theorem sharedCarryDelta (b h r t : Int) : ((b-r)+(h+(t-r)))-(b+h-r)=t-r := by omega
theorem nonsharedCarryDelta (b h r : Int) : ((b-r)+h)-(b+h-r)=0 := by omega
end CallbackCarry

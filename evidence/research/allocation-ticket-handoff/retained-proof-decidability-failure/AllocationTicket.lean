import AllocationTicketAst
namespace AllocationTicket
open AllocationTicketAst
set_option linter.unusedSimpArgs false
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,issueGuard,issueNext]
theorem metadataExhaustedPreserves (q : State) (h : Safe q) (g : metadataExhaustedGuard q) : Safe (metadataExhaustedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,metadataExhaustedGuard,metadataExhaustedNext]
theorem invokePreserves (q : State) (h : Safe q) (g : invokeGuard q) : Safe (invokeNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,invokeGuard,invokeNext]
theorem cancelBeforeInvokePreserves (q : State) (h : Safe q) (g : cancelBeforeInvokeGuard q) : Safe (cancelBeforeInvokeNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,cancelBeforeInvokeGuard,cancelBeforeInvokeNext]
theorem allocatorNullPreserves (q : State) (h : Safe q) (g : allocatorNullGuard q) : Safe (allocatorNullNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,allocatorNullGuard,allocatorNullNext]
theorem allocatorReturnPreserves (q : State) (h : Safe q) (g : allocatorReturnGuard q) : Safe (allocatorReturnNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,allocatorReturnGuard,allocatorReturnNext]
theorem captureReturnPreserves (q : State) (h : Safe q) (g : captureReturnGuard q) : Safe (captureReturnNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,captureReturnGuard,captureReturnNext]
theorem interruptUnrecordedReturnPreserves (q : State) (h : Safe q) (g : interruptUnrecordedReturnGuard q) : Safe (interruptUnrecordedReturnNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,interruptUnrecordedReturnGuard,interruptUnrecordedReturnNext]
theorem allocatorOutcomeUnknownPreserves (q : State) (h : Safe q) (g : allocatorOutcomeUnknownGuard q) : Safe (allocatorOutcomeUnknownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,allocatorOutcomeUnknownGuard,allocatorOutcomeUnknownNext]
theorem commitPreserves (q : State) (h : Safe q) (g : commitGuard q) : Safe (commitNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,commitGuard,commitNext]
theorem indexOutcomeUnknownPreserves (q : State) (h : Safe q) (g : indexOutcomeUnknownGuard q) : Safe (indexOutcomeUnknownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,indexOutcomeUnknownGuard,indexOutcomeUnknownNext]
theorem resolveCommittedPreserves (q : State) (h : Safe q) (g : resolveCommittedGuard q) : Safe (resolveCommittedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,resolveCommittedGuard,resolveCommittedNext]
theorem resolveAbsentPreserves (q : State) (h : Safe q) (g : resolveAbsentGuard q) : Safe (resolveAbsentNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,resolveAbsentGuard,resolveAbsentNext]
theorem observeCommitPreserves (q : State) (h : Safe q) (g : observeCommitGuard q) : Safe (observeCommitNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,observeCommitGuard,observeCommitNext]
theorem retryCommitQueryPreserves (q : State) (h : Safe q) (g : retryCommitQueryGuard q) : Safe (retryCommitQueryNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,retryCommitQueryGuard,retryCommitQueryNext]
theorem requestPrivateAbortPreserves (q : State) (h : Safe q) (g : requestPrivateAbortGuard q) : Safe (requestPrivateAbortNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,requestPrivateAbortGuard,requestPrivateAbortNext]
theorem invokePrivateFreePreserves (q : State) (h : Safe q) (g : invokePrivateFreeGuard q) : Safe (invokePrivateFreeNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,invokePrivateFreeGuard,invokePrivateFreeNext]
theorem privateFreeKnownPreserves (q : State) (h : Safe q) (g : privateFreeKnownGuard q) : Safe (privateFreeKnownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,privateFreeKnownGuard,privateFreeKnownNext]
theorem privateFreeUnknownPreserves (q : State) (h : Safe q) (g : privateFreeUnknownGuard q) : Safe (privateFreeUnknownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,privateFreeUnknownGuard,privateFreeUnknownNext]
theorem initialSafe : Safe initial := by decide
theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · rcases g with ⟨g,rfl⟩; exact issuePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact metadataExhaustedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact invokePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact cancelBeforeInvokePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact allocatorNullPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact allocatorReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact captureReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact interruptUnrecordedReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact allocatorOutcomeUnknownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact commitPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact indexOutcomeUnknownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact resolveCommittedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact resolveAbsentPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact observeCommitPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact retryCommitQueryPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact requestPrivateAbortPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact invokePrivateFreePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact privateFreeKnownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact privateFreeUnknownPreserves q h g
 · simpa [g] using h
inductive Reachable : State → Prop where
 | init : Reachable initial
 | next {q t : State} : Reachable q → Step q t → Reachable t
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | init => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem unknownRetainsTicket (q : State) (h : Safe q) (g : q.phase=8 ∨ q.phase=9 ∨ q.phase=12) : q.ticket=1 ∧ q.owner=3 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem noSecondAllocation (q : State) (h : Safe q) : q.calls ≤ 1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem noSecondFree (q : State) (h : Safe q) : q.frees ≤ 1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem poolBudget (active uncertain receipts nested reserve capacity : Nat)
 (h : active + uncertain + receipts + nested + reserve ≤ capacity) :
 active + uncertain + receipts + nested ≤ capacity := by omega
end AllocationTicket

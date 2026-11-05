import RcStorageAllocation
import RcStoragePublication
import RcStorageAccess
import RcStorageCleanup
import RcStorageReuse
namespace RcStorage
open RcStorageAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with g0 | g1 | g2 | g3 | g4 | g5 | g6 | g7 | g8 | g9 | g10 | g11 | g12 | g13 | g14 | g15 | g16 | g17 | g18 | g19 | g20 | g21 | g22 | g23 | g24 | g25 | g26 | g27 | g28 | g29 | g30 | g31 | g32 | g33 | g34 | g35 | g36 | g37
 · rcases g0 with ⟨guard, rfl⟩
   exact beginPreserves q h guard
 · rcases g1 with ⟨guard, rfl⟩
   exact beginZeroPreserves q h guard
 · rcases g2 with ⟨guard, rfl⟩
   exact beginTooLargePreserves q h guard
 · rcases g3 with ⟨guard, rfl⟩
   exact ticketFailurePreserves q h guard
 · rcases g4 with ⟨guard, rfl⟩
   exact checkSizePreserves q h guard
 · rcases g5 with ⟨guard, rfl⟩
   exact rejectSizePreserves q h guard
 · rcases g6 with ⟨guard, rfl⟩
   exact allocNullPreserves q h guard
 · rcases g7 with ⟨guard, rfl⟩
   exact allocSuccessPreserves q h guard
 · rcases g8 with ⟨guard, rfl⟩
   exact saveKeyPreserves q h guard
 · rcases g9 with ⟨guard, rfl⟩
   exact reserveIndexPreserves q h guard
 · rcases g10 with ⟨guard, rfl⟩
   exact prepareRootPreserves q h guard
 · rcases g11 with ⟨guard, rfl⟩
   exact publishPreserves q h guard
 · rcases g12 with ⟨guard, rfl⟩
   exact queryCommitPreserves q h guard
 · rcases g13 with ⟨guard, rfl⟩
   exact releaseSourcePreserves q h guard
 · rcases g14 with ⟨guard, rfl⟩
   exact retainExtraPreserves q h guard
 · rcases g15 with ⟨guard, rfl⟩
   exact releaseExtraPreserves q h guard
 · rcases g16 with ⟨guard, rfl⟩
   exact releaseBasePreserves q h guard
 · rcases g17 with ⟨guard, rfl⟩
   exact borrowPreserves q h guard
 · rcases g18 with ⟨guard, rfl⟩
   exact returnBorrowPreserves q h guard
 · rcases g19 with ⟨guard, rfl⟩
   exact nativePinPreserves q h guard
 · rcases g20 with ⟨guard, rfl⟩
   exact nativeReturnPreserves q h guard
 · rcases g21 with ⟨guard, rfl⟩
   exact scanPreserves q h guard
 · rcases g22 with ⟨guard, rfl⟩
   exact finishScanPreserves q h guard
 · rcases g23 with ⟨guard, rfl⟩
   exact closeEntryPreserves q h guard
 · rcases g24 with ⟨guard, rfl⟩
   exact requestCleanupPreserves q h guard
 · rcases g25 with ⟨guard, rfl⟩
   exact handoffVMPreserves q h guard
 · rcases g26 with ⟨guard, rfl⟩
   exact exitContextPreserves q h guard
 · rcases g27 with ⟨guard, rfl⟩
   exact settleEffectsPreserves q h guard
 · rcases g28 with ⟨guard, rfl⟩
   exact abortPrivatePreserves q h guard
 · rcases g29 with ⟨guard, rfl⟩
   exact unpublishPreserves q h guard
 · rcases g30 with ⟨guard, rfl⟩
   exact scanGracePreserves q h guard
 · rcases g31 with ⟨guard, rfl⟩
   exact startFreePreserves q h guard
 · rcases g32 with ⟨guard, rfl⟩
   exact finishFreePreserves q h guard
 · rcases g33 with ⟨guard, rfl⟩
   exact loseFreeOutcomePreserves q h guard
 · rcases g34 with ⟨guard, rfl⟩
   exact reuseAddressPreserves q h guard
 · rcases g35 with ⟨guard, rfl⟩
   exact queryOldPreserves q h guard
 · rcases g36 with ⟨guard, rfl⟩
   exact rejectOldReleasePreserves q h guard
 · subst r; exact h
inductive Reachable : State → Prop where
 | initial : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | initial => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem unknownCommitBlocksUnpublish (q : State) (u : q.known = 0) : ¬ unpublishGuard q := by simp [unpublishGuard,u]
theorem privateHasNoPublication (q : State) (u : q.phase = 2) : ¬ publishGuard q := by simp [publishGuard,u]
theorem nullAllocHasNoStorage (q : State) (g : allocNullGuard q) (h : Safe q) : (allocNullNext q).owned = 0 := by
 simp only [allocNullGuard] at g
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 change q.owned = 0
 apply h63
 omega
theorem staleGenerationRejected (q : State) (a : q.savedGeneration > 0) (b : q.savedGeneration ≠ q.generation) : rejectOldReleaseGuard q := by simp_all [rejectOldReleaseGuard]
theorem reuseAdvances (q : State) : (reuseAddressNext q).generation > q.generation := by simp [reuseAddressNext]; omega
theorem freeUnknownCannotRetry (q : State) (h : q.phase = 9) : ¬ startFreeGuard q ∧ ¬ finishFreeGuard q ∧ ¬ reuseAddressGuard q := by simp [startFreeGuard,finishFreeGuard,reuseAddressGuard,h]
theorem duplicateExtraReleaseRejected (q : State) (h : Safe q) (d : q.extraSeen = 1) : ¬ releaseExtraGuard q := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 have zero := h75 d
 simp [releaseExtraGuard,zero]
end RcStorage

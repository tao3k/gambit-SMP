import TargetLeaseAst
import NativePrefix
namespace TargetLease
open TargetLeaseAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem publishPlainPreserves (q : State) (h : Safe q) (g : publishPlainGuard q) : Safe (publishPlainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [publishPlainGuard,publishPlainNext,Safe] <;> omega
theorem publishAdmittedHooksPreserves (q : State) (h : Safe q) (g : publishAdmittedHooksGuard q) : Safe (publishAdmittedHooksNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [publishAdmittedHooksGuard,publishAdmittedHooksNext,Safe] <;> omega
theorem acquireOuterPreserves (q : State) (h : Safe q) (g : acquireOuterGuard q) : Safe (acquireOuterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [acquireOuterGuard,acquireOuterNext,Safe] <;> omega
theorem closeOrdinaryPreserves (q : State) (h : Safe q) (g : closeOrdinaryGuard q) : Safe (closeOrdinaryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [closeOrdinaryGuard,closeOrdinaryNext,Safe] <;> omega
theorem publishReplacementPreserves (q : State) (h : Safe q) (g : publishReplacementGuard q) : Safe (publishReplacementNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [publishReplacementGuard,publishReplacementNext,Safe] <;> omega
theorem beginMallocPreserves (q : State) (h : Safe q) (g : beginMallocGuard q) : Safe (beginMallocNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [beginMallocGuard,beginMallocNext,Safe] <;> omega
theorem obtainPointerPreserves (q : State) (h : Safe q) (g : obtainPointerGuard q) : Safe (obtainPointerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [obtainPointerGuard,obtainPointerNext,Safe] <;> omega
theorem recordSuccessPreserves (q : State) (h : Safe q) (g : recordSuccessGuard q) : Safe (recordSuccessNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [recordSuccessGuard,recordSuccessNext,Safe] <;> omega
theorem recordNullPreserves (q : State) (h : Safe q) (g : recordNullGuard q) : Safe (recordNullNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [recordNullGuard,recordNullNext,Safe] <;> omega
theorem enterNestedPreserves (q : State) (h : Safe q) (g : enterNestedGuard q) : Safe (enterNestedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [enterNestedGuard,enterNestedNext,Safe] <;> omega
theorem leaveNestedPreserves (q : State) (h : Safe q) (g : leaveNestedGuard q) : Safe (leaveNestedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [leaveNestedGuard,leaveNestedNext,Safe] <;> omega
theorem loseBeforeCapturePreserves (q : State) (h : Safe q) (g : loseBeforeCaptureGuard q) : Safe (loseBeforeCaptureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [loseBeforeCaptureGuard,loseBeforeCaptureNext,Safe] <;> omega
theorem loseRecordedAckPreserves (q : State) (h : Safe q) (g : loseRecordedAckGuard q) : Safe (loseRecordedAckNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [loseRecordedAckGuard,loseRecordedAckNext,Safe] <;> omega
theorem recoverRecordedPreserves (q : State) (h : Safe q) (g : recoverRecordedGuard q) : Safe (recoverRecordedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [recoverRecordedGuard,recoverRecordedNext,Safe] <;> omega
theorem releaseOuterPreserves (q : State) (h : Safe q) (g : releaseOuterGuard q) : Safe (releaseOuterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [releaseOuterGuard,releaseOuterNext,Safe] <;> omega
theorem beginOriginFreePreserves (q : State) (h : Safe q) (g : beginOriginFreeGuard q) : Safe (beginOriginFreeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [beginOriginFreeGuard,beginOriginFreeNext,Safe] <;> omega
theorem applyFreePreserves (q : State) (h : Safe q) (g : applyFreeGuard q) : Safe (applyFreeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [applyFreeGuard,applyFreeNext,Safe] <;> omega
theorem recordFreeBackendPreserves (q : State) (h : Safe q) (g : recordFreeBackendGuard q) : Safe (recordFreeBackendNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [recordFreeBackendGuard,recordFreeBackendNext,Safe] <;> omega
theorem loseFreeReturnPreserves (q : State) (h : Safe q) (g : loseFreeReturnGuard q) : Safe (loseFreeReturnNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [loseFreeReturnGuard,loseFreeReturnNext,Safe] <;> omega
theorem settleFreePreserves (q : State) (h : Safe q) (g : settleFreeGuard q) : Safe (settleFreeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [settleFreeGuard,settleFreeNext,Safe] <;> omega
theorem reconcileFreePreserves (q : State) (h : Safe q) (g : reconcileFreeGuard q) : Safe (reconcileFreeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [reconcileFreeGuard,reconcileFreeNext,Safe] <;> omega
theorem releaseMaintenancePreserves (q : State) (h : Safe q) (g : releaseMaintenanceGuard q) : Safe (releaseMaintenanceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [releaseMaintenanceGuard,releaseMaintenanceNext,Safe] <;> omega
theorem retireOldBundlePreserves (q : State) (h : Safe q) (g : retireOldBundleGuard q) : Safe (retireOldBundleNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57⟩
 simp_all [retireOldBundleGuard,retireOldBundleNext,Safe] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23
 · rcases h0 with ⟨g,rfl⟩
   exact publishPlainPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact publishAdmittedHooksPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact acquireOuterPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact closeOrdinaryPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact publishReplacementPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact beginMallocPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact obtainPointerPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact recordSuccessPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact recordNullPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact enterNestedPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact leaveNestedPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact loseBeforeCapturePreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact loseRecordedAckPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact recoverRecordedPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact releaseOuterPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact beginOriginFreePreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact applyFreePreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact recordFreeBackendPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact loseFreeReturnPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact settleFreePreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact reconcileFreePreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact releaseMaintenancePreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact retireOldBundlePreserves q h g
 · simpa [h23] using h
inductive Reachable : State → Prop where
 | initial : Reachable initial
 | step {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | initial => exact initialSafe
 | step _ g ih => exact stepPreserves _ _ ih g
theorem closeDoesNotDrain (q : State) :
 (closeOrdinaryNext q).outer=q.outer ∧ (closeOrdinaryNext q).origin=q.origin ∧
 (closeOrdinaryNext q).maintenance=q.maintenance := by simp [closeOrdinaryNext]
theorem oldOriginPinsProvider (q : State) (h : Safe q) (o : q.origin=1) : q.oldLive=1 := by
 simp_all [Safe] <;> omega
theorem originFreeUsesOldFamily (q : State) (h : Safe q) (g : beginOriginFreeGuard q) :
 (beginOriginFreeNext q).freeFamily=1 := by simp_all [Safe,beginOriginFreeGuard,beginOriginFreeNext] <;> omega
theorem retirementNeedsAllDebts (q : State) (g : retireOldBundleGuard q) :
 q.outer=0 ∧ q.nested=0 ∧ q.maintenance=0 ∧ q.origin=0 ∧ q.unknown=0 := by
 simp_all [retireOldBundleGuard]
theorem closureBlocksOrdinaryAcquire (q : State) (h : q.gate=0) : ¬ acquireOuterGuard q := by
 simp_all [acquireOuterGuard]
theorem unknownAllocationCannotRecoverWithoutRecord (q : State) (h : q.recorded=0) : ¬ recoverRecordedGuard q := by
 simp_all [recoverRecordedGuard]
theorem appliedFreeIsNotReceipt (q : State) (h : q.freeReceipt=0) : ¬ reconcileFreeGuard q := by
 simp_all [reconcileFreeGuard]
theorem unknownKeepsOrigin (q : State) (h : Safe q) (u : q.unknown=1) :
 q.origin=1 ∧ q.oldLive=1 ∧ q.custodian=2 := by simp_all [Safe] <;> omega
-- The selected effect summary, source identity, roots and ABI certificate are
-- native premises. The model joins only a fresh prefix grant at acquisition.
def prefixSeed (q : State) : NativePrefixAst.State := {NativePrefixAst.initial with phase:=1,profile:=3*q.mayAbandon,bindingEpoch:=1,sealEpoch:=1,gate:=q.gate}
theorem prefixSeedSafe (q : State) (h : Safe q) : NativePrefixAst.Safe (prefixSeed q) := by
 simp_all [Safe,prefixSeed,NativePrefixAst.Safe,NativePrefixAst.initial] <;> omega
theorem plainEnablesPrefix (q : State) (g : acquireOuterGuard q) (a : q.mayAbandon=0) :
 NativePrefixAst.grantFastGuard (prefixSeed q) := by
 simp_all [acquireOuterGuard,prefixSeed,NativePrefixAst.grantFastGuard,NativePrefixAst.initial]
theorem admittedHooksEnablePrefix (q : State) (g : acquireOuterGuard q) (a : q.mayAbandon=1) :
 NativePrefixAst.grantDurableGuard (prefixSeed q) := by
 simp_all [acquireOuterGuard,prefixSeed,NativePrefixAst.grantDurableGuard,NativePrefixAst.initial]

theorem plainPrefixStep (q : State) (g : acquireOuterGuard q) (a : q.mayAbandon=0) :
 NativePrefixAst.Step (prefixSeed q) (NativePrefixAst.grantFastNext (prefixSeed q)) := by
 right
 right
 right
 right
 right
 right
 right
 right
 left
 exact ⟨plainEnablesPrefix q g a,rfl⟩
theorem hookPrefixStep (q : State) (g : acquireOuterGuard q) (a : q.mayAbandon=1) :
 NativePrefixAst.Step (prefixSeed q) (NativePrefixAst.grantDurableNext (prefixSeed q)) := by
 right
 right
 right
 right
 right
 right
 right
 right
 right
 left
 exact ⟨admittedHooksEnablePrefix q g a,rfl⟩
end TargetLease

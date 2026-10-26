import NativeScopeAst
import AtomicOwnerAst
namespace NativeScope
open NativeScopeAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [issueGuard, issueNext, Safe] <;> omega
theorem beginWritePreserves (q : State) (h : Safe q) (g : beginWriteGuard q) : Safe (beginWriteNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [beginWriteGuard, beginWriteNext, Safe] <;> omega
theorem publishReleasePreserves (q : State) (h : Safe q) (g : publishReleaseGuard q) : Safe (publishReleaseNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [publishReleaseGuard, publishReleaseNext, Safe] <;> omega
theorem recordOutcomePreserves (q : State) (h : Safe q) (g : recordOutcomeGuard q) : Safe (recordOutcomeNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [recordOutcomeGuard, recordOutcomeNext, Safe] <;> omega
theorem deliverOutcomePreserves (q : State) (h : Safe q) (g : deliverOutcomeGuard q) : Safe (deliverOutcomeNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [deliverOutcomeGuard, deliverOutcomeNext, Safe] <;> omega
theorem loseResponsePreserves (q : State) (h : Safe q) (g : loseResponseGuard q) : Safe (loseResponseNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [loseResponseGuard, loseResponseNext, Safe] <;> omega
theorem recoverRecordedPreserves (q : State) (h : Safe q) (g : recoverRecordedGuard q) : Safe (recoverRecordedNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [recoverRecordedGuard, recoverRecordedNext, Safe] <;> omega
theorem enterNestedPreserves (q : State) (h : Safe q) (g : enterNestedGuard q) : Safe (enterNestedNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [enterNestedGuard, enterNestedNext, Safe] <;> omega
theorem leaveNestedPreserves (q : State) (h : Safe q) (g : leaveNestedGuard q) : Safe (leaveNestedNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [leaveNestedGuard, leaveNestedNext, Safe] <;> omega
theorem catcherSubtreePreserves (q : State) (h : Safe q) (g : catcherSubtreeGuard q) : Safe (catcherSubtreeNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [catcherSubtreeGuard, catcherSubtreeNext, Safe] <;> omega
theorem acquire0Preserves (q : State) (h : Safe q) (g : acquire0Guard q) : Safe (acquire0Next q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [acquire0Guard, acquire0Next, Safe] <;> omega
theorem acquire1Preserves (q : State) (h : Safe q) (g : acquire1Guard q) : Safe (acquire1Next q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [acquire1Guard, acquire1Next, Safe] <;> omega
theorem closeAdmissionPreserves (q : State) (h : Safe q) (g : closeAdmissionGuard q) : Safe (closeAdmissionNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [closeAdmissionGuard, closeAdmissionNext, Safe] <;> omega
theorem renewSameThreadPreserves (q : State) (h : Safe q) (g : renewSameThreadGuard q) : Safe (renewSameThreadNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [renewSameThreadGuard, renewSameThreadNext, Safe] <;> omega
theorem prepareMigrationPreserves (q : State) (h : Safe q) (g : prepareMigrationGuard q) : Safe (prepareMigrationNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [prepareMigrationGuard, prepareMigrationNext, Safe] <;> omega
theorem targetAcquirePreserves (q : State) (h : Safe q) (g : targetAcquireGuard q) : Safe (targetAcquireNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [targetAcquireGuard, targetAcquireNext, Safe] <;> omega
theorem issueTargetPreserves (q : State) (h : Safe q) (g : issueTargetGuard q) : Safe (issueTargetNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [issueTargetGuard, issueTargetNext, Safe] <;> omega
theorem rejectStaleDeliveryPreserves (q : State) (h : Safe q) (g : rejectStaleDeliveryGuard q) : Safe (rejectStaleDeliveryNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [rejectStaleDeliveryGuard, rejectStaleDeliveryNext, Safe] <;> omega
theorem rawInterferencePreserves (q : State) (h : Safe q) (g : rawInterferenceGuard q) : Safe (rawInterferenceNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [rawInterferenceGuard, rawInterferenceNext, Safe] <;> omega
theorem retirePreserves (q : State) (h : Safe q) (g : retireGuard q) : Safe (retireNext q) := by
 simp only [Safe, and_assoc] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61⟩
 simp_all [retireGuard, retireNext, Safe] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20
 · rcases h0 with ⟨g, rfl⟩
   exact issuePreserves q h g
 · rcases h1 with ⟨g, rfl⟩
   exact beginWritePreserves q h g
 · rcases h2 with ⟨g, rfl⟩
   exact publishReleasePreserves q h g
 · rcases h3 with ⟨g, rfl⟩
   exact recordOutcomePreserves q h g
 · rcases h4 with ⟨g, rfl⟩
   exact deliverOutcomePreserves q h g
 · rcases h5 with ⟨g, rfl⟩
   exact loseResponsePreserves q h g
 · rcases h6 with ⟨g, rfl⟩
   exact recoverRecordedPreserves q h g
 · rcases h7 with ⟨g, rfl⟩
   exact enterNestedPreserves q h g
 · rcases h8 with ⟨g, rfl⟩
   exact leaveNestedPreserves q h g
 · rcases h9 with ⟨g, rfl⟩
   exact catcherSubtreePreserves q h g
 · rcases h10 with ⟨g, rfl⟩
   exact acquire0Preserves q h g
 · rcases h11 with ⟨g, rfl⟩
   exact acquire1Preserves q h g
 · rcases h12 with ⟨g, rfl⟩
   exact closeAdmissionPreserves q h g
 · rcases h13 with ⟨g, rfl⟩
   exact renewSameThreadPreserves q h g
 · rcases h14 with ⟨g, rfl⟩
   exact prepareMigrationPreserves q h g
 · rcases h15 with ⟨g, rfl⟩
   exact targetAcquirePreserves q h g
 · rcases h16 with ⟨g, rfl⟩
   exact issueTargetPreserves q h g
 · rcases h17 with ⟨g, rfl⟩
   exact rejectStaleDeliveryPreserves q h g
 · rcases h18 with ⟨g, rfl⟩
   exact rawInterferencePreserves q h g
 · rcases h19 with ⟨g, rfl⟩
   exact retirePreserves q h g
 · simpa [h20] using h
inductive Reachable : State → Prop where
 | initial : Reachable initial
 | step {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | initial => exact initialSafe
 | step _ g ih => exact stepPreserves _ _ ih g
def CanUse (q : State) : Prop := q.phase=1 ∧ q.closedWorld=1 ∧ q.unknown=0 ∧ q.view=1 ∧ q.cap=q.generation
theorem unknownRetains (q : State) (h : Safe q) (u : q.unknown=1) :
 q.phase=1 ∧ q.pending=1 ∧ q.pins=1 ∧ q.roots=1 ∧ q.descriptors=1 ∧ q.custodian=2 ∧ q.view=0 := by
 simp_all [Safe] <;> omega
theorem renewalKeepsHistory (q : State) :
 (renewSameThreadNext q).floor0=q.floor0 ∧ (renewSameThreadNext q).floor1=q.floor1 := by
 simp [renewSameThreadNext]
theorem nestedKeepsHistory (q : State) :
 (enterNestedNext q).floor0=q.floor0 ∧ (leaveNestedNext q).floor0=q.floor0 := by
 simp [enterNestedNext,leaveNestedNext]
theorem migrationRevokes (q : State) :
 (prepareMigrationNext q).view=0 ∧ (prepareMigrationNext q).cap=0 ∧
 (prepareMigrationNext q).returnRight=0 := by simp [prepareMigrationNext]
theorem targetNeedsAcquire (q : State) (g : issueTargetGuard q) : q.targetAcquired=1 := by
 simp_all [issueTargetGuard]
theorem pendingBlocksRetire (q : State) (g : retireGuard q) : q.pending=0 ∧ q.nested=0 := by
 simp_all [retireGuard]
theorem unknownBeforeRecordRetained (q : State) (u : q.recorded=0) : ¬ recoverRecordedGuard q := by
 simp_all [recoverRecordedGuard]
theorem staleDeliveryCannotSettle (q : State) :
 (rejectStaleDeliveryNext q).pending=q.pending ∧ (rejectStaleDeliveryNext q).recorded=q.recorded := by
 simp [rejectStaleDeliveryNext]
theorem viewRequiresRf (q : State) (h : Safe q) (v : q.view=1) :
 q.rf=1 ∧ q.observed=1 ∧ q.pub=1 ∧ q.closedWorld=1 := by
 simp_all [Safe] <;> omega
theorem rawWriterBlocksUse (q : State) : ¬ CanUse (rawInterferenceNext q) := by
 simp [CanUse,rawInterferenceNext]
 -- Exact interface to the existing owner AST, not a product-step simulation.
theorem a0Authority (q : State) (b : AtomicOwnerAst.State) (h : CanUse q)
 (link : b.a0View=q.view ∧ b.a0Gen=q.generation ∧ b.a0CapGen=q.cap) :
 b.a0View=1 ∧ b.a0CapGen=b.a0Gen := by
 simp_all [CanUse]
theorem activationNeedsScopeHalf (b : AtomicOwnerAst.State)
 (g : AtomicOwnerAst.activateA0Guard b) : b.a0View=1 ∧ b.a0CapGen=b.a0Gen := by
 simp_all [AtomicOwnerAst.activateA0Guard]
 -- Event identities are mathematical witnesses, not fields returned by C atomics.
structure Event where
  storage : Nat
  generation : Nat
  serial : Nat
  release : Bool
  value : Int
def SourceKeyMatches (w r : Event) : Prop :=
  w.storage=r.storage ∧ w.generation=r.generation ∧ w.serial=r.serial
theorem sourceKeySameGeneration (w r : Event) (rf : SourceKeyMatches w r) :
 w.storage=r.storage ∧ w.generation=r.generation := by exact ⟨rf.1,rf.2.1⟩
theorem equalValueDoesNotIdentifyEvent :
 ∃ w r : Event, w.value=r.value ∧ ¬ SourceKeyMatches w r := by
 refine ⟨⟨0,1,1,true,6⟩,⟨0,2,2,true,6⟩,?_,?_⟩ <;> simp [SourceKeyMatches]
end NativeScope


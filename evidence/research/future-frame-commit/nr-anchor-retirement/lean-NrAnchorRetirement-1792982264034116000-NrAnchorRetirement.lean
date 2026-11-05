import NrAnchorRetirementAst
import SavedResultRetirementAst
namespace NrAnchorRetirement
open NrAnchorRetirementAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem produceErrorTokenPreserves (q : State) (h : Safe q) (g : produceErrorTokenGuard q) : Safe (produceErrorTokenNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [produceErrorTokenGuard] at g
 simp [produceErrorTokenNext,Safe] <;> omega
theorem completeNoTokenPreserves (q : State) (h : Safe q) (g : completeNoTokenGuard q) : Safe (completeNoTokenNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [completeNoTokenGuard] at g
 simp [completeNoTokenNext,Safe] <;> omega
theorem enqueueTokenPreserves (q : State) (h : Safe q) (g : enqueueTokenGuard q) : Safe (enqueueTokenNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [enqueueTokenGuard] at g
 simp [enqueueTokenNext,Safe] <;> omega
theorem claimPrivateTokenPreserves (q : State) (h : Safe q) (g : claimPrivateTokenGuard q) : Safe (claimPrivateTokenNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [claimPrivateTokenGuard] at g
 simp [claimPrivateTokenNext,Safe] <;> omega
theorem popCallbackPreserves (q : State) (h : Safe q) (g : popCallbackGuard q) : Safe (popCallbackNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [popCallbackGuard] at g
 simp [popCallbackNext,Safe] <;> omega
theorem knownTokenConsumptionPreserves (q : State) (h : Safe q) (g : knownTokenConsumptionGuard q) : Safe (knownTokenConsumptionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [knownTokenConsumptionGuard] at g
 simp [knownTokenConsumptionNext,Safe] <;> omega
theorem unknownCallbackExitPreserves (q : State) (h : Safe q) (g : unknownCallbackExitGuard q) : Safe (unknownCallbackExitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [unknownCallbackExitGuard] at g
 simp [unknownCallbackExitNext,Safe] <;> omega
theorem reconcileKnownConsumptionPreserves (q : State) (h : Safe q) (g : reconcileKnownConsumptionGuard q) : Safe (reconcileKnownConsumptionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [reconcileKnownConsumptionGuard] at g
 simp [reconcileKnownConsumptionNext,Safe] <;> omega
theorem finishLandingPreserves (q : State) (h : Safe q) (g : finishLandingGuard q) : Safe (finishLandingNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [finishLandingGuard] at g
 simp [finishLandingNext,Safe] <;> omega
theorem exitOwnerEnvPreserves (q : State) (h : Safe q) (g : exitOwnerEnvGuard q) : Safe (exitOwnerEnvNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [exitOwnerEnvGuard] at g
 simp [exitOwnerEnvNext,Safe] <;> omega
theorem acquireAnchorPreserves (q : State) (h : Safe q) (g : acquireAnchorGuard q) : Safe (acquireAnchorNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [acquireAnchorGuard] at g
 simp [acquireAnchorNext,Safe] <;> omega
theorem lookupFirstRecordPreserves (q : State) (h : Safe q) (g : lookupFirstRecordGuard q) : Safe (lookupFirstRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [lookupFirstRecordGuard] at g
 simp [lookupFirstRecordNext,Safe] <;> omega
theorem lookupSecondRecordPreserves (q : State) (h : Safe q) (g : lookupSecondRecordGuard q) : Safe (lookupSecondRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [lookupSecondRecordGuard] at g
 simp [lookupSecondRecordNext,Safe] <;> omega
theorem releaseRecordPreserves (q : State) (h : Safe q) (g : releaseRecordGuard q) : Safe (releaseRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [releaseRecordGuard] at g
 simp [releaseRecordNext,Safe] <;> omega
theorem releaseAnchorPreserves (q : State) (h : Safe q) (g : releaseAnchorGuard q) : Safe (releaseAnchorNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [releaseAnchorGuard] at g
 simp [releaseAnchorNext,Safe] <;> omega
theorem closeRecordGatePreserves (q : State) (h : Safe q) (g : closeRecordGateGuard q) : Safe (closeRecordGateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [closeRecordGateGuard] at g
 simp [closeRecordGateNext,Safe] <;> omega
theorem closeSendersPreserves (q : State) (h : Safe q) (g : closeSendersGuard q) : Safe (closeSendersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [closeSendersGuard] at g
 simp [closeSendersNext,Safe] <;> omega
theorem closeRawRoutesPreserves (q : State) (h : Safe q) (g : closeRawRoutesGuard q) : Safe (closeRawRoutesNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [closeRawRoutesGuard] at g
 simp [closeRawRoutesNext,Safe] <;> omega
theorem retireRecordPreserves (q : State) (h : Safe q) (g : retireRecordGuard q) : Safe (retireRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [retireRecordGuard] at g
 simp [retireRecordNext,Safe] <;> omega
theorem reuseSlotPreserves (q : State) (h : Safe q) (g : reuseSlotGuard q) : Safe (reuseSlotNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [reuseSlotGuard] at g
 simp [reuseSlotNext,Safe] <;> omega
theorem acceptFirstAckPreserves (q : State) (h : Safe q) (g : acceptFirstAckGuard q) : Safe (acceptFirstAckNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [acceptFirstAckGuard] at g
 simp [acceptFirstAckNext,Safe] <;> omega
theorem rejectFirstAfterReusePreserves (q : State) (h : Safe q) (g : rejectFirstAfterReuseGuard q) : Safe (rejectFirstAfterReuseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37⟩
 simp only [rejectFirstAfterReuseGuard] at g
 simp [rejectFirstAfterReuseNext,Safe] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22
 · rcases h0 with ⟨g,rfl⟩
   exact produceErrorTokenPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact completeNoTokenPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact enqueueTokenPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact claimPrivateTokenPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact popCallbackPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact knownTokenConsumptionPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact unknownCallbackExitPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact reconcileKnownConsumptionPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact finishLandingPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact exitOwnerEnvPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact acquireAnchorPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact lookupFirstRecordPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact lookupSecondRecordPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact releaseRecordPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact releaseAnchorPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact closeRecordGatePreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact closeSendersPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact closeRawRoutesPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact retireRecordPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact reuseSlotPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact acceptFirstAckPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact rejectFirstAfterReusePreserves q h g
 · simpa [h22] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem popKeepsNode (q : State) : (popCallbackNext q).node=q.node ∧ (popCallbackNext q).done=q.done := by simp [popCallbackNext]
theorem oldGenerationCannotAck (q : State) (hg : q.generation=2) : ¬ acceptFirstAckGuard q := by simp [acceptFirstAckGuard,hg]
def CompletionMirror (q : State) (r : SavedResultRetirementAst.State) : Prop := (q.done=1 → r.complete=1 ∧ r.a=6 ∧ (r.b=0 ∨ r.b=4) ∧ (r.c=0 ∨ r.c=4)) ∧ q.recordPin=r.observer ∧ q.recordGate=r.observerGate ∧ q.senders=r.issuer ∧ r.recordLive=1
theorem suppliesPriorGuard (q : State) (r : SavedResultRetirementAst.State) (g : retireRecordGuard q) (hm : CompletionMirror q r) : SavedResultRetirementAst.retireRecordGuard r := by
 simp only [retireRecordGuard] at g
 simp only [CompletionMirror] at hm
 simp only [SavedResultRetirementAst.retireRecordGuard]
 omega
theorem guardedPriorRetirement (q : State) (r : SavedResultRetirementAst.State) (g : retireRecordGuard q) (hm : CompletionMirror q r) : SavedResultRetirementAst.Step r (SavedResultRetirementAst.retireRecordNext r) := by
 have h := suppliesPriorGuard q r g hm
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩))))))))))))))))))))
end NrAnchorRetirement

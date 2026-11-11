import SavedResultRetirementAst
import CallbackProducerAst
namespace SavedResultRetirement
open SavedResultRetirementAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem saveAPreserves (q : State) (h : Safe q) (g : saveAGuard q) : Safe (saveANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [saveAGuard] at g
 simp [saveANext,Safe] <;> omega
theorem installBPreserves (q : State) (h : Safe q) (g : installBGuard q) : Safe (installBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [installBGuard] at g
 simp [installBNext,Safe] <;> omega
theorem beginRestorePreserves (q : State) (h : Safe q) (g : beginRestoreGuard q) : Safe (beginRestoreNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [beginRestoreGuard] at g
 simp [beginRestoreNext,Safe] <;> omega
theorem reenterPublishCPreserves (q : State) (h : Safe q) (g : reenterPublishCGuard q) : Safe (reenterPublishCNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [reenterPublishCGuard] at g
 simp [reenterPublishCNext,Safe] <;> omega
theorem loseBPreserves (q : State) (h : Safe q) (g : loseBGuard q) : Safe (loseBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [loseBGuard] at g
 simp [loseBNext,Safe] <;> omega
theorem ackBPreserves (q : State) (h : Safe q) (g : ackBGuard q) : Safe (ackBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [ackBGuard] at g
 simp [ackBNext,Safe] <;> omega
theorem beginCReleasePreserves (q : State) (h : Safe q) (g : beginCReleaseGuard q) : Safe (beginCReleaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [beginCReleaseGuard] at g
 simp [beginCReleaseNext,Safe] <;> omega
theorem loseCPreserves (q : State) (h : Safe q) (g : loseCGuard q) : Safe (loseCNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [loseCGuard] at g
 simp [loseCNext,Safe] <;> omega
theorem ackCPreserves (q : State) (h : Safe q) (g : ackCGuard q) : Safe (ackCNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [ackCGuard] at g
 simp [ackCNext,Safe] <;> omega
theorem commitRestorePreserves (q : State) (h : Safe q) (g : commitRestoreGuard q) : Safe (commitRestoreNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [commitRestoreGuard] at g
 simp [commitRestoreNext,Safe] <;> omega
theorem beginDiscardPreserves (q : State) (h : Safe q) (g : beginDiscardGuard q) : Safe (beginDiscardNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [beginDiscardGuard] at g
 simp [beginDiscardNext,Safe] <;> omega
theorem beginRestoredReleasePreserves (q : State) (h : Safe q) (g : beginRestoredReleaseGuard q) : Safe (beginRestoredReleaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [beginRestoredReleaseGuard] at g
 simp [beginRestoredReleaseNext,Safe] <;> omega
theorem loseAPreserves (q : State) (h : Safe q) (g : loseAGuard q) : Safe (loseANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [loseAGuard] at g
 simp [loseANext,Safe] <;> omega
theorem ackAPreserves (q : State) (h : Safe q) (g : ackAGuard q) : Safe (ackANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [ackAGuard] at g
 simp [ackANext,Safe] <;> omega
theorem completeFirstPreserves (q : State) (h : Safe q) (g : completeFirstGuard q) : Safe (completeFirstNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [completeFirstGuard] at g
 simp [completeFirstNext,Safe] <;> omega
theorem completeSecondPreserves (q : State) (h : Safe q) (g : completeSecondGuard q) : Safe (completeSecondNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [completeSecondGuard] at g
 simp [completeSecondNext,Safe] <;> omega
theorem lookupRecordPreserves (q : State) (h : Safe q) (g : lookupRecordGuard q) : Safe (lookupRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [lookupRecordGuard] at g
 simp [lookupRecordNext,Safe] <;> omega
theorem returnRecordPreserves (q : State) (h : Safe q) (g : returnRecordGuard q) : Safe (returnRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [returnRecordGuard] at g
 simp [returnRecordNext,Safe] <;> omega
theorem closeObserverGatePreserves (q : State) (h : Safe q) (g : closeObserverGateGuard q) : Safe (closeObserverGateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [closeObserverGateGuard] at g
 simp [closeObserverGateNext,Safe] <;> omega
theorem closeIssuerPreserves (q : State) (h : Safe q) (g : closeIssuerGuard q) : Safe (closeIssuerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [closeIssuerGuard] at g
 simp [closeIssuerNext,Safe] <;> omega
theorem retireRecordPreserves (q : State) (h : Safe q) (g : retireRecordGuard q) : Safe (retireRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [retireRecordGuard] at g
 simp [retireRecordNext,Safe] <;> omega
theorem reuseSlotPreserves (q : State) (h : Safe q) (g : reuseSlotGuard q) : Safe (reuseSlotNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28⟩
 simp only [reuseSlotGuard] at g
 simp [reuseSlotNext,Safe] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22
 · rcases h0 with ⟨g,rfl⟩
   exact saveAPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact installBPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact beginRestorePreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact reenterPublishCPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact loseBPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact ackBPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact beginCReleasePreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact loseCPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact ackCPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact commitRestorePreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact beginDiscardPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact beginRestoredReleasePreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact loseAPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact ackAPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact completeFirstPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact completeSecondPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact lookupRecordPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact returnRecordPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact closeObserverGatePreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact closeIssuerPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact retireRecordPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact reuseSlotPreserves q h g
 · simpa [h22] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem completionDoesNotDrainObserver (q : State) : (completeFirstNext q).observer=q.observer ∧ (completeFirstNext q).a=q.a ∧ (completeFirstNext q).issuer=q.issuer := by simp [completeFirstNext]
theorem oldGenerationCannotComplete (q : State) (hg : q.generation=2) : ¬ completeFirstGuard q := by simp [completeFirstGuard,hg]
def ResultMirror (q : State) (r : CallbackProducerAst.State) : Prop := (q.a=6 ∧ (q.b=0 ∨ q.b=4) ∧ (q.c=0 ∨ q.c=4)) → r.resultPhase=4 ∧ r.origin=0
def ControlExit (r : CallbackProducerAst.State) : Prop := r.gate=0 ∧ r.producer=0 ∧ r.done=r.ticket ∧ r.phase=5 ∧ r.retired=0
theorem suppliesPriorGuard (q : State) (r : CallbackProducerAst.State) (g : retireRecordGuard q) (hm : ResultMirror q r) (hc : ControlExit r) : CallbackProducerAst.retireDomainGuard r := by
 simp only [retireRecordGuard] at g
 simp only [ResultMirror] at hm
 simp only [ControlExit] at hc
 simp only [CallbackProducerAst.retireDomainGuard]
 omega
theorem guardedPriorRetirement (q : State) (r : CallbackProducerAst.State) (g : retireRecordGuard q) (hm : ResultMirror q r) (hc : ControlExit r) : CallbackProducerAst.Step r (CallbackProducerAst.retireDomainNext r) := by
 have h := suppliesPriorGuard q r g hm hc
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩))))))))))))))))
end SavedResultRetirement

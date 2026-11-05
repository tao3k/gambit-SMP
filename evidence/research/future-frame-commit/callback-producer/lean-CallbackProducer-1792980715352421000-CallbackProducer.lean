import CallbackProducerAst
import CleanupIngressAst
namespace CallbackProducer
open CallbackProducerAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem closeRootsPreserves (q : State) (h : Safe q) (g : closeRootsGuard q) : Safe (closeRootsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [closeRootsGuard] at g
 simp only [closeRootsNext,Safe]
 omega
theorem dispatchChildPreserves (q : State) (h : Safe q) (g : dispatchChildGuard q) : Safe (dispatchChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [dispatchChildGuard] at g
 simp only [dispatchChildNext,Safe]
 omega
theorem landingFirstPreserves (q : State) (h : Safe q) (g : landingFirstGuard q) : Safe (landingFirstNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [landingFirstGuard] at g
 simp only [landingFirstNext,Safe]
 omega
theorem landingSecondPreserves (q : State) (h : Safe q) (g : landingSecondGuard q) : Safe (landingSecondNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [landingSecondGuard] at g
 simp only [landingSecondNext,Safe]
 omega
theorem beginCleanupPreserves (q : State) (h : Safe q) (g : beginCleanupGuard q) : Safe (beginCleanupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [beginCleanupGuard] at g
 simp only [beginCleanupNext,Safe]
 omega
theorem loseCleanupPreserves (q : State) (h : Safe q) (g : loseCleanupGuard q) : Safe (loseCleanupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [loseCleanupGuard] at g
 simp only [loseCleanupNext,Safe]
 omega
theorem cleanupReceiptFirstPreserves (q : State) (h : Safe q) (g : cleanupReceiptFirstGuard q) : Safe (cleanupReceiptFirstNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [cleanupReceiptFirstGuard] at g
 simp only [cleanupReceiptFirstNext,Safe]
 omega
theorem cleanupReceiptSecondPreserves (q : State) (h : Safe q) (g : cleanupReceiptSecondGuard q) : Safe (cleanupReceiptSecondNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [cleanupReceiptSecondGuard] at g
 simp only [cleanupReceiptSecondNext,Safe]
 omega
theorem settleFirstPreserves (q : State) (h : Safe q) (g : settleFirstGuard q) : Safe (settleFirstNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [settleFirstGuard] at g
 simp only [settleFirstNext,Safe]
 omega
theorem settleSecondPreserves (q : State) (h : Safe q) (g : settleSecondGuard q) : Safe (settleSecondNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [settleSecondGuard] at g
 simp only [settleSecondNext,Safe]
 omega
theorem sealProducerPreserves (q : State) (h : Safe q) (g : sealProducerGuard q) : Safe (sealProducerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [sealProducerGuard] at g
 simp only [sealProducerNext,Safe]
 omega
theorem publishResultPreserves (q : State) (h : Safe q) (g : publishResultGuard q) : Safe (publishResultNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [publishResultGuard] at g
 simp only [publishResultNext,Safe]
 omega
theorem beginResultReleasePreserves (q : State) (h : Safe q) (g : beginResultReleaseGuard q) : Safe (beginResultReleaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [beginResultReleaseGuard] at g
 simp only [beginResultReleaseNext,Safe]
 omega
theorem loseResultReleasePreserves (q : State) (h : Safe q) (g : loseResultReleaseGuard q) : Safe (loseResultReleaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [loseResultReleaseGuard] at g
 simp only [loseResultReleaseNext,Safe]
 omega
theorem resultReleaseReceiptPreserves (q : State) (h : Safe q) (g : resultReleaseReceiptGuard q) : Safe (resultReleaseReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [resultReleaseReceiptGuard] at g
 simp only [resultReleaseReceiptNext,Safe]
 omega
theorem settleResultReleasePreserves (q : State) (h : Safe q) (g : settleResultReleaseGuard q) : Safe (settleResultReleaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [settleResultReleaseGuard] at g
 simp only [settleResultReleaseNext,Safe]
 omega
theorem retireDomainPreserves (q : State) (h : Safe q) (g : retireDomainGuard q) : Safe (retireDomainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33⟩
 simp only [retireDomainGuard] at g
 simp only [retireDomainNext,Safe]
 omega
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17
 · rcases h0 with ⟨g,rfl⟩
   exact closeRootsPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact dispatchChildPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact landingFirstPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact landingSecondPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact beginCleanupPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact loseCleanupPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact cleanupReceiptFirstPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact cleanupReceiptSecondPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact settleFirstPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact settleSecondPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact sealProducerPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact publishResultPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact beginResultReleasePreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact loseResultReleasePreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact resultReleaseReceiptPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact settleResultReleasePreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact retireDomainPreserves q h g
 · simpa [h17] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem closeDoesNotSealProducer (q : State) : (closeRootsNext q).producer=q.producer := by rfl
theorem wrongTicketCannotSettle (q : State) (ht : q.ticket=2) : ¬ settleFirstGuard q := by simp [settleFirstGuard,ht]
def ExitMirror (q : State) (r : CleanupIngressAst.State) : Prop := (q.gate=0 → r.closed=1) ∧ (q.producer=0 → r.outer=0 ∧ r.child=0 ∧ r.permit=0 ∧ r.guard=0 ∧ r.roots=0 ∧ r.settled=1 ∧ r.unknown=0) ∧ ((q.resultPhase=0 ∨ q.resultPhase=4) → r.resultDebt=0)
def Remaining (r : CleanupIngressAst.State) : Prop := r.collective=1 ∧ r.joined=1 ∧ r.retired=0
theorem suppliesPriorGuard (q : State) (r : CleanupIngressAst.State) (g : retireDomainGuard q) (hm : ExitMirror q r) (hr : Remaining r) : CleanupIngressAst.retireDomainGuard r := by
 simp only [retireDomainGuard] at g
 simp only [ExitMirror] at hm
 simp only [Remaining] at hr
 simp only [CleanupIngressAst.retireDomainGuard]
 omega
theorem guardedPriorRetirement (q : State) (r : CleanupIngressAst.State) (g : retireDomainGuard q) (hm : ExitMirror q r) (hr : Remaining r) : CleanupIngressAst.Step r (CleanupIngressAst.retireDomainNext r) := by
 have h := suppliesPriorGuard q r g hm hr
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩)))))))))))))
end CallbackProducer

import NrInflightHandoffAst
import NrAnchorRetirementAst
namespace NrInflightHandoff
open NrInflightHandoffAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem prepareEscrowPreserves (q : State) (h : Safe q) (g : prepareEscrowGuard q) : Safe (prepareEscrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [prepareEscrowGuard] at g
 simp [prepareEscrowNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem popNodePreserves (q : State) (h : Safe q) (g : popNodeGuard q) : Safe (popNodeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [popNodeGuard] at g
 simp [popNodeNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem beginTokenPreserves (q : State) (h : Safe q) (g : beginTokenGuard q) : Safe (beginTokenNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [beginTokenGuard] at g
 simp [beginTokenNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem applyTokenEffectPreserves (q : State) (h : Safe q) (g : applyTokenEffectGuard q) : Safe (applyTokenEffectNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [applyTokenEffectGuard] at g
 simp [applyTokenEffectNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem loseTokenReturnPreserves (q : State) (h : Safe q) (g : loseTokenReturnGuard q) : Safe (loseTokenReturnNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [loseTokenReturnGuard] at g
 simp [loseTokenReturnNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem receiveTokenReceiptPreserves (q : State) (h : Safe q) (g : receiveTokenReceiptGuard q) : Safe (receiveTokenReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [receiveTokenReceiptGuard] at g
 simp [receiveTokenReceiptNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem confirmTokenPreserves (q : State) (h : Safe q) (g : confirmTokenGuard q) : Safe (confirmTokenNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [confirmTokenGuard] at g
 simp [confirmTokenNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem beginNodeReleasePreserves (q : State) (h : Safe q) (g : beginNodeReleaseGuard q) : Safe (beginNodeReleaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [beginNodeReleaseGuard] at g
 simp [beginNodeReleaseNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem applyNodeEffectPreserves (q : State) (h : Safe q) (g : applyNodeEffectGuard q) : Safe (applyNodeEffectNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [applyNodeEffectGuard] at g
 simp [applyNodeEffectNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem loseNodeReturnPreserves (q : State) (h : Safe q) (g : loseNodeReturnGuard q) : Safe (loseNodeReturnNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [loseNodeReturnGuard] at g
 simp [loseNodeReturnNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem receiveNodeReceiptPreserves (q : State) (h : Safe q) (g : receiveNodeReceiptGuard q) : Safe (receiveNodeReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [receiveNodeReceiptGuard] at g
 simp [receiveNodeReceiptNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem confirmNodePreserves (q : State) (h : Safe q) (g : confirmNodeGuard q) : Safe (confirmNodeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [confirmNodeGuard] at g
 simp [confirmNodeNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem publishDonePreserves (q : State) (h : Safe q) (g : publishDoneGuard q) : Safe (publishDoneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [publishDoneGuard] at g
 simp [publishDoneNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem releaseEscrowPreserves (q : State) (h : Safe q) (g : releaseEscrowGuard q) : Safe (releaseEscrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [releaseEscrowGuard] at g
 simp [releaseEscrowNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem beginLookupPreserves (q : State) (h : Safe q) (g : beginLookupGuard q) : Safe (beginLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [beginLookupGuard] at g
 simp [beginLookupNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem validateFirstPreserves (q : State) (h : Safe q) (g : validateFirstGuard q) : Safe (validateFirstNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [validateFirstGuard] at g
 simp [validateFirstNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem validateSecondPreserves (q : State) (h : Safe q) (g : validateSecondGuard q) : Safe (validateSecondNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [validateSecondGuard] at g
 simp [validateSecondNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem installPinPreserves (q : State) (h : Safe q) (g : installPinGuard q) : Safe (installPinNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [installPinGuard] at g
 simp [installPinNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem unlockLookupPreserves (q : State) (h : Safe q) (g : unlockLookupGuard q) : Safe (unlockLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [unlockLookupGuard] at g
 simp [unlockLookupNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem releasePinPreserves (q : State) (h : Safe q) (g : releasePinGuard q) : Safe (releasePinNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [releasePinGuard] at g
 simp [releasePinNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem rejectClosedLookupPreserves (q : State) (h : Safe q) (g : rejectClosedLookupGuard q) : Safe (rejectClosedLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [rejectClosedLookupGuard] at g
 simp [rejectClosedLookupNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem rejectOldFirstPreserves (q : State) (h : Safe q) (g : rejectOldFirstGuard q) : Safe (rejectOldFirstNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [rejectOldFirstGuard] at g
 simp [rejectOldFirstNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem acquireClosePreserves (q : State) (h : Safe q) (g : acquireCloseGuard q) : Safe (acquireCloseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [acquireCloseGuard] at g
 simp [acquireCloseNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem closeGatePreserves (q : State) (h : Safe q) (g : closeGateGuard q) : Safe (closeGateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [closeGateGuard] at g
 simp [closeGateNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem closeSendersPreserves (q : State) (h : Safe q) (g : closeSendersGuard q) : Safe (closeSendersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [closeSendersGuard] at g
 simp [closeSendersNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem closeRawRoutesPreserves (q : State) (h : Safe q) (g : closeRawRoutesGuard q) : Safe (closeRawRoutesNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [closeRawRoutesGuard] at g
 simp [closeRawRoutesNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem retireRecordPreserves (q : State) (h : Safe q) (g : retireRecordGuard q) : Safe (retireRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [retireRecordGuard] at g
 simp [retireRecordNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem unlockClosePreserves (q : State) (h : Safe q) (g : unlockCloseGuard q) : Safe (unlockCloseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [unlockCloseGuard] at g
 simp [unlockCloseNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem acquireReusePreserves (q : State) (h : Safe q) (g : acquireReuseGuard q) : Safe (acquireReuseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [acquireReuseGuard] at g
 simp [acquireReuseNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem commitReusePreserves (q : State) (h : Safe q) (g : commitReuseGuard q) : Safe (commitReuseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [commitReuseGuard] at g
 simp [commitReuseNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem unlockReusePreserves (q : State) (h : Safe q) (g : unlockReuseGuard q) : Safe (unlockReuseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [unlockReuseGuard] at g
 simp [unlockReuseNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | (simp <;> omega)
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31
 · rcases h0 with ⟨g,rfl⟩
   exact prepareEscrowPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact popNodePreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact beginTokenPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact applyTokenEffectPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact loseTokenReturnPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact receiveTokenReceiptPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact confirmTokenPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact beginNodeReleasePreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact applyNodeEffectPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact loseNodeReturnPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact receiveNodeReceiptPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact confirmNodePreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact publishDonePreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact releaseEscrowPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact beginLookupPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact validateFirstPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact validateSecondPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact installPinPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact unlockLookupPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact releasePinPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact rejectClosedLookupPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact rejectOldFirstPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact acquireClosePreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact closeGatePreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact closeSendersPreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact closeRawRoutesPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact retireRecordPreserves q h g
 · rcases h27 with ⟨g,rfl⟩
   exact unlockClosePreserves q h g
 · rcases h28 with ⟨g,rfl⟩
   exact acquireReusePreserves q h g
 · rcases h29 with ⟨g,rfl⟩
   exact commitReusePreserves q h g
 · rcases h30 with ⟨g,rfl⟩
   exact unlockReusePreserves q h g
 · simpa [h31] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem appliedTokenDoesNotPublishReceipt (q : State) : (applyTokenEffectNext q).tokenReceipt=q.tokenReceipt := by rfl
theorem nodeEffectDoesNotPublishDone (q : State) : (applyNodeEffectNext q).stage=q.stage := by rfl
theorem validatedLookupExcludesClose (q : State) (h : Safe q) (hv : q.validated=1) : ¬ acquireCloseGuard q := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [acquireCloseGuard]
 omega
def RetireMirror (q : State) (r : NrAnchorRetirementAst.State) : Prop := (q.stage=9 → r.token=5 ∧ r.node=0 ∧ r.queue=0 ∧ r.done=1) ∧ q.gate=r.recordGate ∧ q.pin=r.recordPin ∧ q.senders=r.senders ∧ q.rawClosed=r.rawClosed ∧ r.recordLive=1
theorem suppliesPriorGuard (q : State) (r : NrAnchorRetirementAst.State) (g : retireRecordGuard q) (hm : RetireMirror q r) : NrAnchorRetirementAst.retireRecordGuard r := by
 simp only [retireRecordGuard] at g
 simp only [RetireMirror] at hm
 simp only [NrAnchorRetirementAst.retireRecordGuard]
 omega
theorem guardedPriorRetirement (q : State) (r : NrAnchorRetirementAst.State) (g : retireRecordGuard q) (hm : RetireMirror q r) : NrAnchorRetirementAst.Step r (NrAnchorRetirementAst.retireRecordNext r) := by
 have h := suppliesPriorGuard q r g hm
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩))))))))))))))))))
end NrInflightHandoff

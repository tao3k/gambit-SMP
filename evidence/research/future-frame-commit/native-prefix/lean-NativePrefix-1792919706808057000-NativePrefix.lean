import NativePrefixAst
import NativeEntry
namespace NativePrefix
open NativePrefixAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem selectPlainPreserves (q : State) (h : Safe q) (g : selectPlainGuard q) : Safe (selectPlainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [selectPlainGuard,selectPlainNext,Safe] <;> omega
theorem selectCollectingPreserves (q : State) (h : Safe q) (g : selectCollectingGuard q) : Safe (selectCollectingNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [selectCollectingGuard,selectCollectingNext,Safe] <;> omega
theorem selectReentrantPreserves (q : State) (h : Safe q) (g : selectReentrantGuard q) : Safe (selectReentrantNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [selectReentrantGuard,selectReentrantNext,Safe] <;> omega
theorem selectAbandoningPreserves (q : State) (h : Safe q) (g : selectAbandoningGuard q) : Safe (selectAbandoningNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [selectAbandoningGuard,selectAbandoningNext,Safe] <;> omega
theorem selectOpaquePreserves (q : State) (h : Safe q) (g : selectOpaqueGuard q) : Safe (selectOpaqueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [selectOpaqueGuard,selectOpaqueNext,Safe] <;> omega
theorem selectWrongSelfPreserves (q : State) (h : Safe q) (g : selectWrongSelfGuard q) : Safe (selectWrongSelfNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [selectWrongSelfGuard,selectWrongSelfNext,Safe] <;> omega
theorem selectDebugIOPreserves (q : State) (h : Safe q) (g : selectDebugIOGuard q) : Safe (selectDebugIONext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [selectDebugIOGuard,selectDebugIONext,Safe] <;> omega
theorem replaceBeforeGrantPreserves (q : State) (h : Safe q) (g : replaceBeforeGrantGuard q) : Safe (replaceBeforeGrantNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [replaceBeforeGrantGuard,replaceBeforeGrantNext,Safe] <;> omega
theorem grantFastPreserves (q : State) (h : Safe q) (g : grantFastGuard q) : Safe (grantFastNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [grantFastGuard,grantFastNext,Safe] <;> omega
theorem grantDurablePreserves (q : State) (h : Safe q) (g : grantDurableGuard q) : Safe (grantDurableNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [grantDurableGuard,grantDurableNext,Safe] <;> omega
theorem denyProfilePreserves (q : State) (h : Safe q) (g : denyProfileGuard q) : Safe (denyProfileNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [denyProfileGuard,denyProfileNext,Safe] <;> omega
theorem closeAdmissionPreserves (q : State) (h : Safe q) (g : closeAdmissionGuard q) : Safe (closeAdmissionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [closeAdmissionGuard,closeAdmissionNext,Safe] <;> omega
theorem beginAllocationPreserves (q : State) (h : Safe q) (g : beginAllocationGuard q) : Safe (beginAllocationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [beginAllocationGuard,beginAllocationNext,Safe] <;> omega
theorem obtainNativeMemoryPreserves (q : State) (h : Safe q) (g : obtainNativeMemoryGuard q) : Safe (obtainNativeMemoryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [obtainNativeMemoryGuard,obtainNativeMemoryNext,Safe] <;> omega
theorem enterHookPreserves (q : State) (h : Safe q) (g : enterHookGuard q) : Safe (enterHookNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [enterHookGuard,enterHookNext,Safe] <;> omega
theorem returnHookPreserves (q : State) (h : Safe q) (g : returnHookGuard q) : Safe (returnHookNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [returnHookGuard,returnHookNext,Safe] <;> omega
theorem gcRoundPreserves (q : State) (h : Safe q) (g : gcRoundGuard q) : Safe (gcRoundNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [gcRoundGuard,gcRoundNext,Safe] <;> omega
theorem reloadRootPreserves (q : State) (h : Safe q) (g : reloadRootGuard q) : Safe (reloadRootNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [reloadRootGuard,reloadRootNext,Safe] <;> omega
theorem captureOutcomePreserves (q : State) (h : Safe q) (g : captureOutcomeGuard q) : Safe (captureOutcomeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [captureOutcomeGuard,captureOutcomeNext,Safe] <;> omega
theorem publishInputsPreserves (q : State) (h : Safe q) (g : publishInputsGuard q) : Safe (publishInputsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [publishInputsGuard,publishInputsNext,Safe] <;> omega
theorem abandonBeforeRecordPreserves (q : State) (h : Safe q) (g : abandonBeforeRecordGuard q) : Safe (abandonBeforeRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [abandonBeforeRecordGuard,abandonBeforeRecordNext,Safe] <;> omega
theorem loseRecordedResponsePreserves (q : State) (h : Safe q) (g : loseRecordedResponseGuard q) : Safe (loseRecordedResponseNext q) := by
 simp only [loseRecordedResponseGuard] at g
 rcases g with g | g
 all_goals
  simp only [Safe] at h
  rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
  simp_all [loseRecordedResponseGuard,loseRecordedResponseNext,Safe] <;> omega
theorem recoverPrivateRecordPreserves (q : State) (h : Safe q) (g : recoverPrivateRecordGuard q) : Safe (recoverPrivateRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [recoverPrivateRecordGuard,recoverPrivateRecordNext,Safe] <;> omega
theorem recoverPublishedRecordPreserves (q : State) (h : Safe q) (g : recoverPublishedRecordGuard q) : Safe (recoverPublishedRecordNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [recoverPublishedRecordGuard,recoverPublishedRecordNext,Safe] <;> omega
theorem releaseSourcePreserves (q : State) (h : Safe q) (g : releaseSourceGuard q) : Safe (releaseSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [releaseSourceGuard,releaseSourceNext,Safe] <;> omega
theorem handoffBankPreserves (q : State) (h : Safe q) (g : handoffBankGuard q) : Safe (handoffBankNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [handoffBankGuard,handoffBankNext,Safe] <;> omega
theorem rollbackPlainPreserves (q : State) (h : Safe q) (g : rollbackPlainGuard q) : Safe (rollbackPlainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55⟩
 simp_all [rollbackPlainGuard,rollbackPlainNext,Safe] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27
 · rcases h0 with ⟨g,rfl⟩
   exact selectPlainPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact selectCollectingPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact selectReentrantPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact selectAbandoningPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact selectOpaquePreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact selectWrongSelfPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact selectDebugIOPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact replaceBeforeGrantPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact grantFastPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact grantDurablePreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact denyProfilePreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact closeAdmissionPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact beginAllocationPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact obtainNativeMemoryPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact enterHookPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact returnHookPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact gcRoundPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact reloadRootPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact captureOutcomePreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact publishInputsPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact abandonBeforeRecordPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact loseRecordedResponsePreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact recoverPrivateRecordPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact recoverPublishedRecordPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact releaseSourcePreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact handoffBankPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact rollbackPlainPreserves q h g
 · simpa [h27] using h
inductive Reachable : State → Prop where
 | initial : Reachable initial
 | step {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | initial => exact initialSafe
 | step _ g ih => exact stepPreserves _ _ ih g
theorem fastExcludesGc (q : State) (h : Safe q) (f : q.fast=1) : ¬ gcRoundGuard q := by
 simp_all [Safe,gcRoundGuard] <;> omega
theorem wrongSelfCannotBorrowItsWayIn (q : State) (p : q.profile=5) :
 ¬ grantFastGuard q ∧ ¬ grantDurableGuard q := by
 simp_all [grantFastGuard,grantDurableGuard] <;> omega
theorem opaqueCannotObtainGrant (q : State) (p : q.profile=4) :
 ¬ grantFastGuard q ∧ ¬ grantDurableGuard q := by
 simp_all [grantFastGuard,grantDurableGuard] <;> omega
theorem staleBindingCannotGrant (q : State) (p : q.bindingEpoch≠q.sealEpoch) :
 ¬ grantFastGuard q ∧ ¬ grantDurableGuard q := by simp_all [grantFastGuard,grantDurableGuard]
theorem publishRequiresCurrentLocal (q : State) (g : publishInputsGuard q) : q.localEpoch=q.epoch := by
 simp_all [publishInputsGuard]
theorem callbackReturnIsNotReload (q : State) : (returnHookNext q).localEpoch=q.localEpoch := by rfl
theorem allocationRecordedBeforeInputPublication (q : State) (g : publishInputsGuard q) : q.recorded=1 := by
 simp_all [publishInputsGuard]
theorem unknownRetains (q : State) (h : Safe q) (u : q.unknown=1) :
 q.intent=1 ∧ q.sourceRoot+q.carrierRoot≥1 ∧ q.custodian=2 := by
 simp_all [Safe] <;> omega
theorem noRecordNoRecovery (q : State) (h : q.recorded=0) :
 ¬ recoverPrivateRecordGuard q ∧ ¬ recoverPublishedRecordGuard q := by
 simp_all [recoverPrivateRecordGuard,recoverPublishedRecordGuard]
theorem fastAvoidsPersistentSourceRoot (q : State) (h : Safe q) (f : q.fast=1) : q.sourceRoot=0 := by
 simp_all [Safe] <;> omega
-- A registered bank becomes a source for actual NativeEntry root preparation.
-- Host/source eligibility and physical storage handoff remain native premises.
def entrySeed (q : State) : NativeEntryAst.State :=
 { NativeEntryAst.initial with phase:=2,host:=1,sourceRoot:=1,sourcePin:=1,epoch:=q.epoch,sourceEpoch:=q.rootEpoch,entryOpen:=q.gate }
theorem entrySeedSafe (q : State) (h : Safe q) (p : q.phase=6) : NativeEntryAst.Safe (entrySeed q) := by
 simp_all [Safe,entrySeed,NativeEntryAst.Safe,NativeEntryAst.initial] <;> omega
theorem entryPublishGuard (q : State) : NativeEntryAst.publishCarrierGuard (entrySeed q) := by
 simp [entrySeed,NativeEntryAst.publishCarrierGuard,NativeEntryAst.initial]
theorem prefixToEntryStep (q : State) :
 NativeEntryAst.Step (entrySeed q) (NativeEntryAst.publishCarrierNext (entrySeed q)) := by
 right; right; right
 left
 exact ⟨entryPublishGuard q,rfl⟩
theorem prefixToEntrySafe (q : State) (h : Safe q) (p : q.phase=6) :
 NativeEntryAst.Safe (NativeEntryAst.publishCarrierNext (entrySeed q)) := by
 exact NativeEntry.publishCarrierPreserves _ (entrySeedSafe q h p) (entryPublishGuard q)
theorem preservesClosedIngress (q : State) (g : q.gate=0) :
 ¬ NativeEntryAst.jointIssueGuard (NativeEntryAst.publishCarrierNext (entrySeed q)) := by
 simp [entrySeed,NativeEntryAst.publishCarrierNext,NativeEntryAst.jointIssueGuard,NativeEntryAst.initial,g]
end NativePrefix


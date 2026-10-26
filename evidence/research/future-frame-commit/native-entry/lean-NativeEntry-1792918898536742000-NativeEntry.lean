import NativeEntryAst
import NativeScope
namespace NativeEntry
open NativeEntryAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem pinSourcePreserves (q : State) (h : Safe q) (g : pinSourceGuard q) : Safe (pinSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [pinSourceGuard,pinSourceNext,Safe] <;> omega
theorem reserveCarrierPreserves (q : State) (h : Safe q) (g : reserveCarrierGuard q) : Safe (reserveCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [reserveCarrierGuard,reserveCarrierNext,Safe] <;> omega
theorem qualifyHostPreserves (q : State) (h : Safe q) (g : qualifyHostGuard q) : Safe (qualifyHostNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [qualifyHostGuard,qualifyHostNext,Safe] <;> omega
theorem publishCarrierPreserves (q : State) (h : Safe q) (g : publishCarrierGuard q) : Safe (publishCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [publishCarrierGuard,publishCarrierNext,Safe] <;> omega
theorem loseRegistrationAckPreserves (q : State) (h : Safe q) (g : loseRegistrationAckGuard q) : Safe (loseRegistrationAckNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [loseRegistrationAckGuard,loseRegistrationAckNext,Safe] <;> omega
theorem confirmSameRegistrationPreserves (q : State) (h : Safe q) (g : confirmSameRegistrationGuard q) : Safe (confirmSameRegistrationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [confirmSameRegistrationGuard,confirmSameRegistrationNext,Safe] <;> omega
theorem jointIssuePreserves (q : State) (h : Safe q) (g : jointIssueGuard q) : Safe (jointIssueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [jointIssueGuard,jointIssueNext,Safe] <;> omega
theorem writeEntryStatePreserves (q : State) (h : Safe q) (g : writeEntryStateGuard q) : Safe (writeEntryStateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [writeEntryStateGuard,writeEntryStateNext,Safe] <;> omega
theorem allocateMarkerPreserves (q : State) (h : Safe q) (g : allocateMarkerGuard q) : Safe (allocateMarkerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [allocateMarkerGuard,allocateMarkerNext,Safe] <;> omega
theorem certifyTransferPreserves (q : State) (h : Safe q) (g : certifyTransferGuard q) : Safe (certifyTransferNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [certifyTransferGuard,certifyTransferNext,Safe] <;> omega
theorem releaseSourcePreserves (q : State) (h : Safe q) (g : releaseSourceGuard q) : Safe (releaseSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [releaseSourceGuard,releaseSourceNext,Safe] <;> omega
theorem closeIngressPreserves (q : State) (h : Safe q) (g : closeIngressGuard q) : Safe (closeIngressNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [closeIngressGuard,closeIngressNext,Safe] <;> omega
theorem exhaustCarrierPreserves (q : State) (h : Safe q) (g : exhaustCarrierGuard q) : Safe (exhaustCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [exhaustCarrierGuard,exhaustCarrierNext,Safe] <;> omega
theorem rejectClosedPreserves (q : State) (h : Safe q) (g : rejectClosedGuard q) : Safe (rejectClosedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [rejectClosedGuard,rejectClosedNext,Safe] <;> omega
theorem freezeWritersPreserves (q : State) (h : Safe q) (g : freezeWritersGuard q) : Safe (freezeWritersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [freezeWritersGuard,freezeWritersNext,Safe] <;> omega
theorem scanSourcePreserves (q : State) (h : Safe q) (g : scanSourceGuard q) : Safe (scanSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [scanSourceGuard,scanSourceNext,Safe] <;> omega
theorem scanBothPreserves (q : State) (h : Safe q) (g : scanBothGuard q) : Safe (scanBothNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [scanBothGuard,scanBothNext,Safe] <;> omega
theorem scanCarrierPreserves (q : State) (h : Safe q) (g : scanCarrierGuard q) : Safe (scanCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [scanCarrierGuard,scanCarrierNext,Safe] <;> omega
theorem thawWritersPreserves (q : State) (h : Safe q) (g : thawWritersGuard q) : Safe (thawWritersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [thawWritersGuard,thawWritersNext,Safe] <;> omega
theorem enterNestedPreserves (q : State) (h : Safe q) (g : enterNestedGuard q) : Safe (enterNestedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [enterNestedGuard,enterNestedNext,Safe] <;> omega
theorem leaveNestedPreserves (q : State) (h : Safe q) (g : leaveNestedGuard q) : Safe (leaveNestedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [leaveNestedGuard,leaveNestedNext,Safe] <;> omega
theorem recordOutcomePreserves (q : State) (h : Safe q) (g : recordOutcomeGuard q) : Safe (recordOutcomeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [recordOutcomeGuard,recordOutcomeNext,Safe] <;> omega
theorem loseCompletionPreserves (q : State) (h : Safe q) (g : loseCompletionGuard q) : Safe (loseCompletionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [loseCompletionGuard,loseCompletionNext,Safe] <;> omega
theorem landNestedPreserves (q : State) (h : Safe q) (g : landNestedGuard q) : Safe (landNestedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [landNestedGuard,landNestedNext,Safe] <;> omega
theorem settleKnownPreserves (q : State) (h : Safe q) (g : settleKnownGuard q) : Safe (settleKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [settleKnownGuard,settleKnownNext,Safe] <;> omega
theorem recoverRecordedPreserves (q : State) (h : Safe q) (g : recoverRecordedGuard q) : Safe (recoverRecordedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [recoverRecordedGuard,recoverRecordedNext,Safe] <;> omega
theorem closeScanAdmissionPreserves (q : State) (h : Safe q) (g : closeScanAdmissionGuard q) : Safe (closeScanAdmissionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [closeScanAdmissionGuard,closeScanAdmissionNext,Safe] <;> omega
theorem confirmGracePreserves (q : State) (h : Safe q) (g : confirmGraceGuard q) : Safe (confirmGraceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [confirmGraceGuard,confirmGraceNext,Safe] <;> omega
theorem retireCarrierPreserves (q : State) (h : Safe q) (g : retireCarrierGuard q) : Safe (retireCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp_all [retireCarrierGuard,retireCarrierNext,Safe] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29
 · rcases h0 with ⟨g,rfl⟩
   exact pinSourcePreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact reserveCarrierPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact qualifyHostPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact publishCarrierPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact loseRegistrationAckPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact confirmSameRegistrationPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact jointIssuePreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact writeEntryStatePreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact allocateMarkerPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact certifyTransferPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact releaseSourcePreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact closeIngressPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact exhaustCarrierPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact rejectClosedPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact freezeWritersPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact scanSourcePreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact scanBothPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact scanCarrierPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact thawWritersPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact enterNestedPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact leaveNestedPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact recordOutcomePreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact loseCompletionPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact landNestedPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact settleKnownPreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact recoverRecordedPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact closeScanAdmissionPreserves q h g
 · rcases h27 with ⟨g,rfl⟩
   exact confirmGracePreserves q h g
 · rcases h28 with ⟨g,rfl⟩
   exact retireCarrierPreserves q h g
 · simpa [h29] using h
inductive Reachable : State → Prop where
 | initial : Reachable initial
 | step {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | initial => exact initialSafe
 | step _ g ih => exact stepPreserves _ _ ih g
-- This embeds only the root/guard side of the existing NativeScope initial boundary.
def seed (q : State) : NativeScopeAst.State :=
 { NativeScopeAst.initial with roots:=q.carrierRoot, pins:=q.registry, descriptors:=q.guard }
theorem registeredSeed (q : State) (h : Safe q) (g : jointIssueGuard q) :
 seed q = NativeScopeAst.initial := by
 simp_all [jointIssueGuard,seed,NativeScopeAst.initial]
theorem jointIssueNativeStep (q : State) (h : Safe q) (g : jointIssueGuard q) :
 NativeScopeAst.Step (seed q) (NativeScopeAst.issueNext (seed q)) := by
 have e := registeredSeed q h g
 rw [e]
 apply Or.inl
 exact ⟨by simp [NativeScopeAst.issueGuard,NativeScopeAst.initial],rfl⟩
theorem jointIssueNativeSafe (q : State) (h : Safe q) (g : jointIssueGuard q) :
 NativeScopeAst.Safe (NativeScopeAst.issueNext (seed q)) := by
 rw [registeredSeed q h g]
 exact NativeScope.issuePreserves _ NativeScope.initialSafe (by simp [NativeScopeAst.issueGuard,NativeScopeAst.initial])
theorem markerHasRootAndGuard (q : State) (h : Safe q) (g : allocateMarkerGuard q) :
 q.registry=1 ∧ q.carrierRoot=1 ∧ q.guard=1 ∧ q.inflight=1 := by
 simp_all [Safe,allocateMarkerGuard] <;> omega
theorem issuerNeedsKnownRegistration (q : State) (g : jointIssueGuard q) : q.registrationUnknown=0 := by
 simp_all [jointIssueGuard]
theorem closePreservesEnrolled (q : State) :
 (closeIngressNext q).inflight=q.inflight ∧ (closeIngressNext q).nested=q.nested ∧
 (closeIngressNext q).registry=q.registry := by simp [closeIngressNext]
theorem freezeDoesNotWaitForBorrow (q : State) (g : freezeWritersGuard q) :
 (freezeWritersNext q).sourcePin=q.sourcePin ∧ (freezeWritersNext q).inflight=q.inflight := by
 simp [freezeWritersNext]
theorem transferNeedsCurrentSlot (q : State) (h : Safe q) (g : releaseSourceGuard q) :
 q.registry=1 ∧ q.carrierRoot=1 ∧ q.carrierEpoch=q.epoch := by
 simp_all [Safe,releaseSourceGuard] <;> omega
theorem freezeRevokesTransfer (q : State) : (freezeWritersNext q).receipt=0 := by rfl
theorem unknownRetainsCarrier (q : State) (h : Safe q) (u : q.unknown=1) :
 q.registry=1 ∧ q.carrierRoot=1 ∧ q.guard=1 ∧ q.inflight=1 ∧ q.holder=2 := by
 simp_all [Safe] <;> omega
theorem unrecordedCannotRecover (q : State) (h : q.outcome=0) : ¬ recoverRecordedGuard q := by
 simp_all [recoverRecordedGuard]
theorem retireNeedsGraceAndDrain (q : State) (g : retireCarrierGuard q) :
 q.grace=1 ∧ q.inflight=0 ∧ q.nested=0 ∧ q.unknown=0 ∧ q.registrationUnknown=0 ∧ q.frozen=0 := by
 simp_all [retireCarrierGuard]
theorem closedEntryCannotPin (q : State) (h : q.entryOpen=0) : ¬ pinSourceGuard q := by
 simp_all [pinSourceGuard]
theorem sourceScanUpdates (q : State) :
 (scanSourceNext q).sourceEpoch=q.epoch ∧ (scanSourceNext q).sourcePin=q.sourcePin := by simp [scanSourceNext]
theorem carrierScanUpdates (q : State) :
 (scanCarrierNext q).carrierEpoch=q.epoch ∧ (scanCarrierNext q).registry=q.registry := by simp [scanCarrierNext]
theorem freezeAdvancesEpoch (q : State) : (freezeWritersNext q).epoch=q.epoch+1 := by rfl
end NativeEntry


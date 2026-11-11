import PutObjsCustodyAst
import ThreadCacheTailAst
namespace PutObjsCustody
open PutObjsCustodyAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem admitOwnerPreserves (q : State) (h : Safe q) (g : admitOwnerGuard q) : Safe (admitOwnerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [admitOwnerGuard] at g
 simp [admitOwnerNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem chooseEmptyPreserves (q : State) (h : Safe q) (g : chooseEmptyGuard q) : Safe (chooseEmptyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [chooseEmptyGuard] at g
 simp [chooseEmptyNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem chooseNonemptyPreserves (q : State) (h : Safe q) (g : chooseNonemptyGuard q) : Safe (chooseNonemptyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [chooseNonemptyGuard] at g
 simp [chooseNonemptyNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem trimLocalPreserves (q : State) (h : Safe q) (g : trimLocalGuard q) : Safe (trimLocalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [trimLocalGuard] at g
 simp [trimLocalNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem loadLocalHeadPreserves (q : State) (h : Safe q) (g : loadLocalHeadGuard q) : Safe (loadLocalHeadNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [loadLocalHeadGuard] at g
 simp [loadLocalHeadNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem assignLastPreserves (q : State) (h : Safe q) (g : assignLastGuard q) : Safe (assignLastNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [assignLastGuard] at g
 simp [assignLastNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem advanceCursorPreserves (q : State) (h : Safe q) (g : advanceCursorGuard q) : Safe (advanceCursorNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [advanceCursorGuard] at g
 simp [advanceCursorNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem loopAgainPreserves (q : State) (h : Safe q) (g : loopAgainGuard q) : Safe (loopAgainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [loopAgainGuard] at g
 simp [loopAgainNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem cutLocalPreserves (q : State) (h : Safe q) (g : cutLocalGuard q) : Safe (cutLocalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [cutLocalGuard] at g
 simp [cutLocalNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem lockKnownPreserves (q : State) (h : Safe q) (g : lockKnownGuard q) : Safe (lockKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [lockKnownGuard] at g
 simp [lockKnownNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem lockUnknownPreserves (q : State) (h : Safe q) (g : lockUnknownGuard q) : Safe (lockUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [lockUnknownGuard] at g
 simp [lockUnknownNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem linkOldTailPreserves (q : State) (h : Safe q) (g : linkOldTailGuard q) : Safe (linkOldTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [linkOldTailGuard] at g
 simp [linkOldTailNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem publishSharedHeadPreserves (q : State) (h : Safe q) (g : publishSharedHeadGuard q) : Safe (publishSharedHeadNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [publishSharedHeadGuard] at g
 simp [publishSharedHeadNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem updateEmptySharedTailPreserves (q : State) (h : Safe q) (g : updateEmptySharedTailGuard q) : Safe (updateEmptySharedTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [updateEmptySharedTailGuard] at g
 simp [updateEmptySharedTailNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem keepSharedTailPreserves (q : State) (h : Safe q) (g : keepSharedTailGuard q) : Safe (keepSharedTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [keepSharedTailGuard] at g
 simp [keepSharedTailNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem addSharedCountPreserves (q : State) (h : Safe q) (g : addSharedCountGuard q) : Safe (addSharedCountNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [addSharedCountGuard] at g
 simp [addSharedCountNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem unlockKnownPreserves (q : State) (h : Safe q) (g : unlockKnownGuard q) : Safe (unlockKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [unlockKnownGuard] at g
 simp [unlockKnownNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem unlockUnknownPreserves (q : State) (h : Safe q) (g : unlockUnknownGuard q) : Safe (unlockUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [unlockUnknownGuard] at g
 simp [unlockUnknownNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem fixLocalLastPreserves (q : State) (h : Safe q) (g : fixLocalLastGuard q) : Safe (fixLocalLastNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [fixLocalLastGuard] at g
 simp [fixLocalLastNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem publishReceiptPreserves (q : State) (h : Safe q) (g : publishReceiptGuard q) : Safe (publishReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [publishReceiptGuard] at g
 simp [publishReceiptNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem escapePreserves (q : State) (h : Safe q) (g : escapeGuard q) : Safe (escapeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [escapeGuard] at g
 simp [escapeNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem loseReceiptAckPreserves (q : State) (h : Safe q) (g : loseReceiptAckGuard q) : Safe (loseReceiptAckNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [loseReceiptAckGuard] at g
 simp [loseReceiptAckNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem acceptReceiptPreserves (q : State) (h : Safe q) (g : acceptReceiptGuard q) : Safe (acceptReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [acceptReceiptGuard] at g
 simp [acceptReceiptNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem closeAdmissionPreserves (q : State) (h : Safe q) (g : closeAdmissionGuard q) : Safe (closeAdmissionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [closeAdmissionGuard] at g
 simp [closeAdmissionNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem readersDetachedPreserves (q : State) (h : Safe q) (g : readersDetachedGuard q) : Safe (readersDetachedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [readersDetachedGuard] at g
 simp [readersDetachedNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem attestFinalizationPreserves (q : State) (h : Safe q) (g : attestFinalizationGuard q) : Safe (attestFinalizationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [attestFinalizationGuard] at g
 simp [attestFinalizationNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem reuseAddressPreserves (q : State) (h : Safe q) (g : reuseAddressGuard q) : Safe (reuseAddressNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 simp only [reuseAddressGuard] at g
 simp [reuseAddressNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27
 · rcases h0 with ⟨g,rfl⟩
   exact admitOwnerPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact chooseEmptyPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact chooseNonemptyPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact trimLocalPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact loadLocalHeadPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact assignLastPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact advanceCursorPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact loopAgainPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact cutLocalPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact lockKnownPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact lockUnknownPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact linkOldTailPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact publishSharedHeadPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact updateEmptySharedTailPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact keepSharedTailPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact addSharedCountPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact unlockKnownPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact unlockUnknownPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact fixLocalLastPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact publishReceiptPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact escapePreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact loseReceiptAckPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact acceptReceiptPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact closeAdmissionPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact readersDetachedPreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact attestFinalizationPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact reuseAddressPreserves q h g
 · simpa [h27] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem publishedNotCompleted (q : State) (h : Safe q) (hp : q.phase=8) : q.receipt=0 ∧ q.lastFixed=0 ∧ q.uncredited=800 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 omega
theorem unlockedNotCompleted (q : State) (h : Safe q) (hp : q.phase=11) : q.receipt=0 ∧ q.lastFixed=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 omega
theorem unknownRetainsCache (q : State) (h : Safe q) (hp : q.escaped=1) (hr : q.receipt=0) : q.held=1 ∧ q.generation=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 omega
theorem cacheBudget (q : State) (h : Safe q)  : q.localCount+q.uncredited+q.delta=1201 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 omega
theorem staleReceiptRejected (q : State) (h : Safe q) (hp : q.phase=15) : q.stamp≠q.generation := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72, h73, h74, h75⟩
 omega
-- Coarse parent Flush800 endpoint only; external observation exclusion is a premise.
def BeforeMirror (q : State) (r : ThreadCacheTailAst.State) : Prop := q.phase=12 → r.phase=4 ∧ r.count=1201 ∧ r.shared=0
theorem suppliesPriorGuard (q : State) (r : ThreadCacheTailAst.State) (g : publishReceiptGuard q) (hm : BeforeMirror q r) : ThreadCacheTailAst.helperFlush800Guard r := by
 simp only [publishReceiptGuard] at g
 simp only [BeforeMirror] at hm
 simp only [ThreadCacheTailAst.helperFlush800Guard]
 omega
theorem guardedPriorFlush (q : State) (r : ThreadCacheTailAst.State) (g : publishReceiptGuard q) (hm : BeforeMirror q r) : ThreadCacheTailAst.Step r (ThreadCacheTailAst.helperFlush800Next r) := by
 have h := suppliesPriorGuard q r g hm
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩)))))))))))))))))))
theorem coarseCredits (q : State) (r : ThreadCacheTailAst.State) (g : publishReceiptGuard q) (hm : BeforeMirror q r) : (ThreadCacheTailAst.helperFlush800Next r).count=401 ∧ (ThreadCacheTailAst.helperFlush800Next r).shared=800 := by
 simp only [publishReceiptGuard] at g
 simp only [BeforeMirror] at hm
 simp only [ThreadCacheTailAst.helperFlush800Next]
 constructor <;> omega
end PutObjsCustody

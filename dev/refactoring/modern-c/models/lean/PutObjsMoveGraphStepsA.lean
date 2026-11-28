import PutObjsMoveGraphAst
namespace PutObjsMoveGraph
open PutObjsMoveGraphAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem knownProducerUnlockPreserves (q : State) (h : Safe q) (g : knownProducerUnlockGuard q) : Safe (knownProducerUnlockNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 rcases h20 with ⟨hl20,hu20⟩
 rcases h21 with ⟨hl21,hu21⟩
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [knownProducerUnlockGuard] at g
 simp_all [knownProducerUnlockNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem unknownReleasedPreserves (q : State) (h : Safe q) (g : unknownReleasedGuard q) : Safe (unknownReleasedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 rcases h20 with ⟨hl20,hu20⟩
 rcases h21 with ⟨hl21,hu21⟩
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [unknownReleasedGuard] at g
 simp_all [unknownReleasedNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem unknownStillHeldPreserves (q : State) (h : Safe q) (g : unknownStillHeldGuard q) : Safe (unknownStillHeldNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 rcases h20 with ⟨hl20,hu20⟩
 rcases h21 with ⟨hl21,hu21⟩
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [unknownStillHeldGuard] at g
 simp_all [unknownStillHeldNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem fixProducerLastPreserves (q : State) (h : Safe q) (g : fixProducerLastGuard q) : Safe (fixProducerLastNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 rcases h20 with ⟨hl20,hu20⟩
 rcases h21 with ⟨hl21,hu21⟩
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [fixProducerLastGuard] at g
 simp_all [fixProducerLastNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem publishReceiptPreserves (q : State) (h : Safe q) (g : publishReceiptGuard q) : Safe (publishReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 rcases h20 with ⟨hl20,hu20⟩
 rcases h21 with ⟨hl21,hu21⟩
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [publishReceiptGuard] at g
 simp_all [publishReceiptNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem closeSourceAdmissionPreserves (q : State) (h : Safe q) (g : closeSourceAdmissionGuard q) : Safe (closeSourceAdmissionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 rcases h20 with ⟨hl20,hu20⟩
 rcases h21 with ⟨hl21,hu21⟩
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [closeSourceAdmissionGuard] at g
 simp_all [closeSourceAdmissionNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem sourceReadersDetachedPreserves (q : State) (h : Safe q) (g : sourceReadersDetachedGuard q) : Safe (sourceReadersDetachedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 rcases h20 with ⟨hl20,hu20⟩
 rcases h21 with ⟨hl21,hu21⟩
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [sourceReadersDetachedGuard] at g
 simp_all [sourceReadersDetachedNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
end PutObjsMoveGraph

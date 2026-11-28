import CacheReadyPublicationAst
namespace CacheReadyPublication
open CacheReadyPublicationAst
set_option maxRecDepth 10000
theorem ownerSnapshotAckPreserves (q : State) (h : Safe q) (g : ownerSnapshotAckGuard q) : Safe (ownerSnapshotAckNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
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
 simp only [ownerSnapshotAckGuard] at g
 simp_all [ownerSnapshotAckNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem releaseDiagnosticPinPreserves (q : State) (h : Safe q) (g : releaseDiagnosticPinGuard q) : Safe (releaseDiagnosticPinNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
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
 simp only [releaseDiagnosticPinGuard] at g
 simp_all [releaseDiagnosticPinNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem formatSnapshotPreserves (q : State) (h : Safe q) (g : formatSnapshotGuard q) : Safe (formatSnapshotNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
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
 simp only [formatSnapshotGuard] at g
 simp_all [formatSnapshotNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
end CacheReadyPublication

import TclBorrowAst
open TclBorrowAst
namespace TclBorrow
theorem selectDispatchPreserves (q : State) (h : Safe q) (g : selectDispatchGuard q) : Safe (selectDispatchNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77⟩
 simp only [selectDispatchGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3⟩
 dsimp only [Safe,selectDispatchNext]
 simp_all
 all_goals first | omega | grind
theorem acquireBorrowPreserves (q : State) (h : Safe q) (g : acquireBorrowGuard q) : Safe (acquireBorrowNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77⟩
 simp only [acquireBorrowGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4,g5,g6,g7,g8⟩
 dsimp only [Safe,acquireBorrowNext]
 simp_all
 all_goals first | omega | grind
theorem refuseLateDispatchPreserves (q : State) (h : Safe q) (g : refuseLateDispatchGuard q) : Safe (refuseLateDispatchNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77⟩
 simp only [refuseLateDispatchGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3⟩
 dsimp only [Safe,refuseLateDispatchNext]
 simp_all
 all_goals first | omega | grind
theorem refuseGcClosedPreserves (q : State) (h : Safe q) (g : refuseGcClosedGuard q) : Safe (refuseGcClosedNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77⟩
 simp only [refuseGcClosedGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3⟩
 dsimp only [Safe,refuseGcClosedNext]
 simp_all
 all_goals first | omega | grind
end TclBorrow

import SfunAdmissionAst
open SfunAdmissionAst
namespace SfunAdmission
theorem refuseBeforeEntryPreserves (q : State) (h : Safe q) (g : refuseBeforeEntryGuard q) : Safe (refuseBeforeEntryNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63⟩
 simp only [refuseBeforeEntryGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,refuseBeforeEntryNext]
 simp_all
 all_goals first | omega | grind
theorem exhaustPoolPreserves (q : State) (h : Safe q) (g : exhaustPoolGuard q) : Safe (exhaustPoolNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63⟩
 simp only [exhaustPoolGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,exhaustPoolNext]
 simp_all
 all_goals first | omega | grind
theorem refuseNoRecordPreserves (q : State) (h : Safe q) (g : refuseNoRecordGuard q) : Safe (refuseNoRecordNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63⟩
 simp only [refuseNoRecordGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3⟩
 dsimp only [Safe,refuseNoRecordNext]
 simp_all
 all_goals first | omega | grind
theorem reserveGuardPreserves (q : State) (h : Safe q) (g : reserveGuardGuard q) : Safe (reserveGuardNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63⟩
 simp only [reserveGuardGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3⟩
 dsimp only [Safe,reserveGuardNext]
 simp_all
 all_goals first | omega | grind
end SfunAdmission

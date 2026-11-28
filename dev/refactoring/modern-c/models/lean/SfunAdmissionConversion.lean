import SfunAdmissionAst
open SfunAdmissionAst
namespace SfunAdmission
theorem beginBodyPreserves (q : State) (h : Safe q) (g : beginBodyGuard q) : Safe (beginBodyNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66⟩
 simp only [beginBodyGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,beginBodyNext]
 simp_all
 all_goals first | omega | grind
theorem conversionFailurePreserves (q : State) (h : Safe q) (g : conversionFailureGuard q) : Safe (conversionFailureNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66⟩
 simp only [conversionFailureGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,conversionFailureNext]
 simp_all
 all_goals first | omega | grind
theorem opaqueConversionFailurePreserves (q : State) (h : Safe q) (g : opaqueConversionFailureGuard q) : Safe (opaqueConversionFailureNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66⟩
 simp only [opaqueConversionFailureGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,opaqueConversionFailureNext]
 simp_all
 all_goals first | omega | grind
theorem finishSuccessPreserves (q : State) (h : Safe q) (g : finishSuccessGuard q) : Safe (finishSuccessNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66⟩
 simp only [finishSuccessGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,finishSuccessNext]
 simp_all
 all_goals first | omega | grind
end SfunAdmission

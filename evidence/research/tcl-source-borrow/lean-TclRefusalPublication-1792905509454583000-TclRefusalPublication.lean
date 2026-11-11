import TclRefusalAst
open TclRefusalAst
namespace TclRefusal
theorem mergeChildRefusalPreserves (q : State) (h : Safe q) (g : mergeChildRefusalGuard q) : Safe (mergeChildRefusalNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [mergeChildRefusalGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,mergeChildRefusalNext]
 simp_all
 all_goals first | omega | grind
theorem popNestedPreserves (q : State) (h : Safe q) (g : popNestedGuard q) : Safe (popNestedNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [popNestedGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,popNestedNext]
 simp_all
 all_goals first | omega | grind
theorem finishEvalPreserves (q : State) (h : Safe q) (g : finishEvalGuard q) : Safe (finishEvalNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [finishEvalGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,finishEvalNext]
 simp_all
 all_goals first | omega | grind
theorem deliverRefusalPreserves (q : State) (h : Safe q) (g : deliverRefusalGuard q) : Safe (deliverRefusalNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [deliverRefusalGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3⟩
 dsimp only [Safe,deliverRefusalNext]
 simp_all
 all_goals first | omega | grind
end TclRefusal

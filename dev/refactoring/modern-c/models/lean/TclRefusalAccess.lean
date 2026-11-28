import TclRefusalAst
open TclRefusalAst
namespace TclRefusal
theorem beginEvalPreserves (q : State) (h : Safe q) (g : beginEvalGuard q) : Safe (beginEvalNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [beginEvalGuard,and_assoc] at g
 rcases g with ⟨g0,g1⟩
 dsimp only [Safe,beginEvalNext]
 simp_all
 all_goals first | omega | grind
theorem beginNestedPreserves (q : State) (h : Safe q) (g : beginNestedGuard q) : Safe (beginNestedNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [beginNestedGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,beginNestedNext]
 simp_all
 all_goals first | omega | grind
theorem recordOuterRefusalPreserves (q : State) (h : Safe q) (g : recordOuterRefusalGuard q) : Safe (recordOuterRefusalNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [recordOuterRefusalGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,recordOuterRefusalNext]
 simp_all
 all_goals first | omega | grind
theorem recordChildRefusalPreserves (q : State) (h : Safe q) (g : recordChildRefusalGuard q) : Safe (recordChildRefusalNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [recordChildRefusalGuard,and_assoc] at g
 rcases g with ⟨g0,g1⟩
 dsimp only [Safe,recordChildRefusalNext]
 simp_all
 all_goals first | omega | grind
end TclRefusal

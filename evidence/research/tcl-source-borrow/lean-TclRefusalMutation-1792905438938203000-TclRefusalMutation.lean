import TclRefusalAst
open TclRefusalAst
namespace TclRefusal
theorem publishOuterDiagnosticPreserves (q : State) (h : Safe q) (g : publishOuterDiagnosticGuard q) : Safe (publishOuterDiagnosticNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [publishOuterDiagnosticGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3⟩
 dsimp only [Safe,publishOuterDiagnosticNext]
 simp_all
 all_goals first | omega | grind
theorem publishChildDiagnosticPreserves (q : State) (h : Safe q) (g : publishChildDiagnosticGuard q) : Safe (publishChildDiagnosticNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [publishChildDiagnosticGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,publishChildDiagnosticNext]
 simp_all
 all_goals first | omega | grind
theorem catchOrResetResultPreserves (q : State) (h : Safe q) (g : catchOrResetResultGuard q) : Safe (catchOrResetResultNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [catchOrResetResultGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,catchOrResetResultNext]
 simp_all
 all_goals first | omega | grind
theorem ordinaryTclErrorPreserves (q : State) (h : Safe q) (g : ordinaryTclErrorGuard q) : Safe (ordinaryTclErrorNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [ordinaryTclErrorGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,ordinaryTclErrorNext]
 simp_all
 all_goals first | omega | grind
end TclRefusal

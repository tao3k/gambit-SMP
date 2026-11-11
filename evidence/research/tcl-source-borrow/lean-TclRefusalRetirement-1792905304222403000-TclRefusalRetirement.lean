import TclRefusalAst
open TclRefusalAst
namespace TclRefusal
theorem resumeVmPreserves (q : State) (h : Safe q) (g : resumeVmGuard q) : Safe (resumeVmNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [resumeVmGuard,and_assoc] at g
 rcases g with ⟨g0,g1⟩
 dsimp only [Safe,resumeVmNext]
 simp_all
 all_goals first | omega | grind
end TclRefusal

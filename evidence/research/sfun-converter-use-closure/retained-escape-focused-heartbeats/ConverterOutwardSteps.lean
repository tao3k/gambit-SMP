import ConverterUseAst
namespace ConverterUse
open ConverterUseAst
set_option maxRecDepth 10000
theorem escapeOwnerPreserves (q : State) (h : Safe q) (g : escapeOwnerGuard q) : Safe (escapeOwnerNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp only [escapeOwnerGuard] at g
 have phaseBound : 3 ≤ q.phase ∧ q.phase ≤ 7 := by omega
 have nativeState := h51 phaseBound.2
 have privateZero : q.privateCopy=0 := by
  rcases g.1 with gp|gp|gp|gp|gp
  · exact (h45 gp).1.1.1.1
  · exact (h46 gp).1.1.1.1
  · exact (h47 (Or.inl (Or.inl gp))).1.1
  · exact (h47 (Or.inl (Or.inr gp))).1.1
  · exact (h47 (Or.inr gp)).1.1
 have noDtor : q.dtor≠1 ∧ q.dtor≠2 := by grind only [h69,phaseBound]
 have noAck : q.exitAck=0 := by grind only [h78,nativeState,h19,h39,phaseBound]
 have noReply : q.reply=0 := by grind only [h71,phaseBound,h20,h40]
 clear g
 dsimp only [Safe,escapeOwnerNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
end ConverterUse

import ControlWordMaps
namespace ControlWord
open ControlWordAst
theorem allocateInvariant (q : State) (h : Safe q) (g : allocateGuard q) : Invariant (allocateNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,allocateNext]
 simp only [allocateGuard] at g
 simp_all
 all_goals omega
theorem enterInvariant (q : State) (h : Safe q) (g : enterGuard q) : Invariant (enterNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,enterNext]
 simp only [enterGuard] at g
 simp_all
 all_goals omega
theorem resolveInvariant (q : State) (h : Safe q) (g : resolveGuard q) : Invariant (resolveNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,resolveNext]
 simp only [resolveGuard] at g
 simp_all
 all_goals omega
theorem initializeInvariant (q : State) (h : Safe q) (g : initializeGuard q) : Invariant (initializeNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,initializeNext]
 simp only [initializeGuard] at g
 simp_all
 all_goals omega
theorem validateInvariant (q : State) (h : Safe q) (g : validateGuard q) : Invariant (validateNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,validateNext]
 simp only [validateGuard] at g
 simp_all
 all_goals omega
theorem prepareInvariant (q : State) (h : Safe q) (g : prepareGuard q) : Invariant (prepareNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,prepareNext]
 simp only [prepareGuard] at g
 simp_all
 all_goals omega
end ControlWord

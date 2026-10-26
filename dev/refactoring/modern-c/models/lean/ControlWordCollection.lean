import ControlWordMaps
namespace ControlWord
open ControlWordAst
theorem gcEnterInvariant (q : State) (h : Safe q) (g : gcEnterGuard q) : Invariant (gcEnterNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,gcEnterNext]
 simp only [gcEnterGuard] at g
 simp_all
 all_goals omega
theorem gcFreezeInvariant (q : State) (h : Safe q) (g : gcFreezeGuard q) : Invariant (gcFreezeNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,gcFreezeNext]
 simp only [gcFreezeGuard] at g
 simp_all
 all_goals omega
theorem gcBeginInvariant (q : State) (h : Safe q) (g : gcBeginGuard q) : Invariant (gcBeginNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,gcBeginNext]
 simp only [gcBeginGuard] at g
 simp_all
 all_goals omega
theorem forwardNoCopyInvariant (q : State) (h : Safe q) (g : forwardNoCopyGuard q) : Invariant (forwardNoCopyNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,forwardNoCopyNext]
 simp only [forwardNoCopyGuard] at g
 simp_all
 all_goals omega
theorem forwardWithCopyInvariant (q : State) (h : Safe q) (g : forwardWithCopyGuard q) : Invariant (forwardWithCopyNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,forwardWithCopyNext]
 simp only [forwardWithCopyGuard] at g
 simp_all
 all_goals omega
theorem gcEndInvariant (q : State) (h : Safe q) (g : gcEndGuard q) : Invariant (gcEndNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,gcEndNext]
 simp only [gcEndGuard] at g
 simp_all
 all_goals omega
end ControlWord

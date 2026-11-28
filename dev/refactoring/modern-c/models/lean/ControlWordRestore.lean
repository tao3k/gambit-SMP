import ControlWordMaps
namespace ControlWord
open ControlWordAst
theorem restoreInvariant (q : State) (h : Safe q) (g : restoreGuard q) : Invariant (restoreNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,restoreNext]
 simp only [restoreGuard] at g
 simp_all
 all_goals omega
theorem finishAbortedInvariant (q : State) (h : Safe q) (g : finishAbortedGuard q) : Invariant (finishAbortedNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,finishAbortedNext]
 simp only [finishAbortedGuard] at g
 simp_all
 all_goals omega
theorem publishResultInvariant (q : State) (h : Safe q) (g : publishResultGuard q) : Invariant (publishResultNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,publishResultNext]
 simp only [publishResultGuard] at g
 simp_all
 all_goals omega
theorem runPrefixInvariant (q : State) (h : Safe q) (g : runPrefixGuard q) : Invariant (runPrefixNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,runPrefixNext]
 simp only [runPrefixGuard] at g
 simp_all
 all_goals omega
theorem grantLocalInvariant (q : State) (h : Safe q) (g : grantLocalGuard q) : Invariant (grantLocalNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,grantLocalNext]
 simp only [grantLocalGuard] at g
 simp_all
 all_goals omega
theorem leaveInvariant (q : State) (h : Safe q) (g : leaveGuard q) : Invariant (leaveNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,leaveNext]
 simp only [leaveGuard] at g
 simp_all
 all_goals omega
end ControlWord

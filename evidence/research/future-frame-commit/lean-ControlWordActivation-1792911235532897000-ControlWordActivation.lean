import ControlWordMaps
namespace ControlWord
open ControlWordAst
theorem acquireCommitInvariant (q : State) (h : Safe q) (g : acquireCommitGuard q) : Invariant (acquireCommitNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,acquireCommitNext]
 simp only [acquireCommitGuard] at g
 simp_all
 all_goals omega
theorem casActivateInvariant (q : State) (h : Safe q) (g : casActivateGuard q) : Invariant (casActivateNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,casActivateNext]
 simp only [casActivateGuard] at g
 simp_all
 all_goals omega
theorem acquireActiveInvariant (q : State) (h : Safe q) (g : acquireActiveGuard q) : Invariant (acquireActiveNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,acquireActiveNext]
 simp only [acquireActiveGuard] at g
 simp_all
 all_goals omega
theorem casDequeueInvariant (q : State) (h : Safe q) (g : casDequeueGuard q) : Invariant (casDequeueNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,casDequeueNext]
 simp only [casDequeueGuard] at g
 simp_all
 all_goals omega
theorem acquireResultInvariant (q : State) (h : Safe q) (g : acquireResultGuard q) : Invariant (acquireResultNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,acquireResultNext]
 simp only [acquireResultGuard] at g
 simp_all
 all_goals omega
theorem grantRemoteInvariant (q : State) (h : Safe q) (g : grantRemoteGuard q) : Invariant (grantRemoteNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,grantRemoteNext]
 simp only [grantRemoteGuard] at g
 simp_all
 all_goals omega
end ControlWord

import ControlWordMaps
namespace ControlWord
open ControlWordAst
theorem gcLeaveInvariant (q : State) (h : Safe q) (g : gcLeaveGuard q) : Invariant (gcLeaveNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,gcLeaveNext]
 simp only [gcLeaveGuard] at g
 simp_all
 all_goals omega
theorem closeDomainInvariant (q : State) (h : Safe q) (g : closeDomainGuard q) : Invariant (closeDomainNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,closeDomainNext]
 simp only [closeDomainGuard] at g
 simp_all
 all_goals omega
theorem resetDomainInvariant (q : State) (h : Safe q) (g : resetDomainGuard q) : Invariant (resetDomainNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,resetDomainNext]
 simp only [resetDomainGuard] at g
 simp_all
 all_goals omega
theorem prepareResultInvariant (q : State) (h : Safe q) (g : prepareResultGuard q) : Invariant (prepareResultNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,prepareResultNext]
 simp only [prepareResultGuard] at g
 simp_all
 all_goals omega
theorem loadReserveInvariant (q : State) (h : Safe q) (g : loadReserveGuard q) : Invariant (loadReserveNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,loadReserveNext]
 simp only [loadReserveGuard] at g
 simp_all
 all_goals omega
theorem loadCommitInvariant (q : State) (h : Safe q) (g : loadCommitGuard q) : Invariant (loadCommitNext q) := by
 have bounds := nativeBounds q h
 have hc := ((safeEquivalent q).mp h).2
 simp only [Invariant,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44⟩
 dsimp only [Invariant,loadCommitNext]
 simp only [loadCommitGuard] at g
 simp_all
 all_goals omega
end ControlWord

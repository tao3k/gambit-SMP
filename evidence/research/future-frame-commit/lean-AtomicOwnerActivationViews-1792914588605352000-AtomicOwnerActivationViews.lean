import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem acquireCommitA0Invariant (q : State) (h : Safe q) (g : acquireCommitA0Guard q) : Invariant (acquireCommitA0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (acquireCommitA0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · exact dChild
 · have use : A0Facts q ∧ LogFacts q := ⟨dA0,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [A0Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35⟩
   dsimp only [A0Facts,acquireCommitA0Next]
   simp only [acquireCommitA0Guard] at g
   simp_all
   all_goals omega
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem acquireChildA0Invariant (q : State) (h : Safe q) (g : acquireChildA0Guard q) : Invariant (acquireChildA0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (acquireChildA0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · exact dChild
 · have use : A0Facts q ∧ LogFacts q := ⟨dA0,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [A0Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35⟩
   dsimp only [A0Facts,acquireChildA0Next]
   simp only [acquireChildA0Guard] at g
   simp_all
   all_goals omega
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem renewA0Invariant (q : State) (h : Safe q) (g : renewA0Guard q) : Invariant (renewA0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (renewA0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q := dPublished
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,renewA0Next]
   simp only [renewA0Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · have use : A0Facts q ∧ LogFacts q := ⟨dA0,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [A0Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35⟩
   dsimp only [A0Facts,renewA0Next]
   simp only [renewA0Guard] at g
   simp_all
   all_goals omega
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem acquireCommitA1Invariant (q : State) (h : Safe q) (g : acquireCommitA1Guard q) : Invariant (acquireCommitA1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (acquireCommitA1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · exact dChild
 · exact dA0
 · have use : A1Facts q ∧ LogFacts q := ⟨dA1,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [A1Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35⟩
   dsimp only [A1Facts,acquireCommitA1Next]
   simp only [acquireCommitA1Guard] at g
   simp_all
   all_goals omega
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem acquireChildA1Invariant (q : State) (h : Safe q) (g : acquireChildA1Guard q) : Invariant (acquireChildA1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (acquireChildA1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · exact dChild
 · exact dA0
 · have use : A1Facts q ∧ LogFacts q := ⟨dA1,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [A1Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35⟩
   dsimp only [A1Facts,acquireChildA1Next]
   simp only [acquireChildA1Guard] at g
   simp_all
   all_goals omega
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem renewA1Invariant (q : State) (h : Safe q) (g : renewA1Guard q) : Invariant (renewA1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (renewA1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q := dPublished
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,renewA1Next]
   simp only [renewA1Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · have use : A1Facts q ∧ LogFacts q := ⟨dA1,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [A1Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35⟩
   dsimp only [A1Facts,renewA1Next]
   simp only [renewA1Guard] at g
   simp_all
   all_goals omega
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
end AtomicOwner

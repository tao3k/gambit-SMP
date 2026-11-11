import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem resultChildW0Invariant (q : State) (h : Safe q) (g : resultChildW0Guard q) : Invariant (resultChildW0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (resultChildW0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q := dPublished
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,resultChildW0Next]
   simp only [resultChildW0Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · have use : W0Facts q := dW0
   have v := publishedVisibility q dPublished
   dsimp only [VisibilityFacts] at v
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W0Facts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16⟩
   dsimp only [W0Facts,resultChildW0Next]
   simp only [resultChildW0Guard] at g
   simp_all
   all_goals omega
 · exact dW1
 · have use : R0Facts q ∧ LogFacts q := ⟨dR0,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [R0Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28⟩
   dsimp only [R0Facts,resultChildW0Next]
   simp only [resultChildW0Guard] at g
   simp_all
   all_goals omega
 · exact dR1
theorem resultCommitW0Invariant (q : State) (h : Safe q) (g : resultCommitW0Guard q) : Invariant (resultCommitW0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (resultCommitW0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q := dPublished
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,resultCommitW0Next]
   simp only [resultCommitW0Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · have use : W0Facts q := dW0
   have v := publishedVisibility q dPublished
   dsimp only [VisibilityFacts] at v
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W0Facts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16⟩
   dsimp only [W0Facts,resultCommitW0Next]
   simp only [resultCommitW0Guard] at g
   simp_all
   all_goals omega
 · exact dW1
 · have use : R0Facts q ∧ LogFacts q := ⟨dR0,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [R0Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28⟩
   dsimp only [R0Facts,resultCommitW0Next]
   simp only [resultCommitW0Guard] at g
   simp_all
   all_goals omega
 · exact dR1
theorem resultChildW1Invariant (q : State) (h : Safe q) (g : resultChildW1Guard q) : Invariant (resultChildW1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (resultChildW1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q := dPublished
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,resultChildW1Next]
   simp only [resultChildW1Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · have use : W1Facts q := dW1
   have v := publishedVisibility q dPublished
   dsimp only [VisibilityFacts] at v
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W1Facts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16⟩
   dsimp only [W1Facts,resultChildW1Next]
   simp only [resultChildW1Guard] at g
   simp_all
   all_goals omega
 · exact dR0
 · have use : R1Facts q ∧ LogFacts q := ⟨dR1,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [R1Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28⟩
   dsimp only [R1Facts,resultChildW1Next]
   simp only [resultChildW1Guard] at g
   simp_all
   all_goals omega
theorem resultCommitW1Invariant (q : State) (h : Safe q) (g : resultCommitW1Guard q) : Invariant (resultCommitW1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (resultCommitW1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q := dPublished
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,resultCommitW1Next]
   simp only [resultCommitW1Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · have use : W1Facts q := dW1
   have v := publishedVisibility q dPublished
   dsimp only [VisibilityFacts] at v
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W1Facts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16⟩
   dsimp only [W1Facts,resultCommitW1Next]
   simp only [resultCommitW1Guard] at g
   simp_all
   all_goals omega
 · exact dR0
 · have use : R1Facts q ∧ LogFacts q := ⟨dR1,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [R1Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28⟩
   dsimp only [R1Facts,resultCommitW1Next]
   simp only [resultCommitW1Guard] at g
   simp_all
   all_goals omega
end AtomicOwner

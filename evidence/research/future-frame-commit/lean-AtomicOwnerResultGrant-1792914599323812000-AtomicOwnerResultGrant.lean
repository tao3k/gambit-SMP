import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem grantW0Invariant (q : State) (h : Safe q) (g : grantW0Guard q) : Invariant (grantW0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (grantW0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q := dPublished
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,grantW0Next]
   simp only [grantW0Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem grantW1Invariant (q : State) (h : Safe q) (g : grantW1Guard q) : Invariant (grantW1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (grantW1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q := dPublished
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,grantW1Next]
   simp only [grantW1Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
end AtomicOwner

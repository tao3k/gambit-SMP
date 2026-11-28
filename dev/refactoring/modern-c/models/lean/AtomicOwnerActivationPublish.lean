import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem activateA0Invariant (q : State) (h : Safe q) (g : activateA0Guard q) : Invariant (activateA0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (activateA0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q ∧ A0Facts q ∧ LogFacts q := ⟨dPublished,dA0,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,A0Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35,u36,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53,u54,u55,u56,u57,u58,u59,u60,u61⟩
   dsimp only [PublishedFacts,activateA0Next]
   simp only [activateA0Guard] at g
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
   dsimp only [W0Facts,activateA0Next]
   simp only [activateA0Guard] at g
   simp_all
   all_goals omega
 · have use : W1Facts q := dW1
   have v := publishedVisibility q dPublished
   dsimp only [VisibilityFacts] at v
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W1Facts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16⟩
   dsimp only [W1Facts,activateA0Next]
   simp only [activateA0Guard] at g
   simp_all
   all_goals omega
 · exact dR0
 · exact dR1
theorem activateA1Invariant (q : State) (h : Safe q) (g : activateA1Guard q) : Invariant (activateA1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (activateA1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q ∧ A1Facts q ∧ LogFacts q := ⟨dPublished,dA1,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,A1Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35,u36,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53,u54,u55,u56,u57,u58,u59,u60,u61⟩
   dsimp only [PublishedFacts,activateA1Next]
   simp only [activateA1Guard] at g
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
   dsimp only [W0Facts,activateA1Next]
   simp only [activateA1Guard] at g
   simp_all
   all_goals omega
 · have use : W1Facts q := dW1
   have v := publishedVisibility q dPublished
   dsimp only [VisibilityFacts] at v
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W1Facts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16⟩
   dsimp only [W1Facts,activateA1Next]
   simp only [activateA1Guard] at g
   simp_all
   all_goals omega
 · exact dR0
 · exact dR1
end AtomicOwner

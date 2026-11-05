import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem acquireActiveW0Invariant (q : State) (h : Safe q) (g : acquireActiveW0Guard q) : Invariant (acquireActiveW0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (acquireActiveW0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · have use : W0Facts q ∧ PublishedFacts q ∧ LogFacts q := ⟨dW0,dPublished,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W0Facts,PublishedFacts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35,u36,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53,u54,u55,u56,u57,u58,u59,u60,u61,u62⟩
   dsimp only [W0Facts,acquireActiveW0Next]
   simp only [acquireActiveW0Guard] at g
   simp_all
   all_goals omega
 · exact dW1
 · exact dR0
 · exact dR1
theorem failedClaimAcquireW0Invariant (q : State) (h : Safe q) (g : failedClaimAcquireW0Guard q) : Invariant (failedClaimAcquireW0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (failedClaimAcquireW0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · have use : W0Facts q ∧ PublishedFacts q ∧ LogFacts q := ⟨dW0,dPublished,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W0Facts,PublishedFacts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35,u36,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53,u54,u55,u56,u57,u58,u59,u60,u61,u62⟩
   dsimp only [W0Facts,failedClaimAcquireW0Next]
   simp only [failedClaimAcquireW0Guard] at g
   simp_all
   all_goals omega
 · exact dW1
 · exact dR0
 · exact dR1
theorem renewW0Invariant (q : State) (h : Safe q) (g : renewW0Guard q) : Invariant (renewW0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (renewW0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q := dPublished
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,renewW0Next]
   simp only [renewW0Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · have use : W0Facts q ∧ PublishedFacts q ∧ LogFacts q := ⟨dW0,dPublished,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W0Facts,PublishedFacts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35,u36,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53,u54,u55,u56,u57,u58,u59,u60,u61,u62⟩
   dsimp only [W0Facts,renewW0Next]
   simp only [renewW0Guard] at g
   simp_all
   all_goals omega
 · exact dW1
 · have use : R0Facts q ∧ LogFacts q := ⟨dR0,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [R0Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28⟩
   dsimp only [R0Facts,renewW0Next]
   simp only [renewW0Guard] at g
   simp_all
   all_goals omega
 · exact dR1
theorem acquireActiveW1Invariant (q : State) (h : Safe q) (g : acquireActiveW1Guard q) : Invariant (acquireActiveW1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (acquireActiveW1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · have use : W1Facts q ∧ PublishedFacts q ∧ LogFacts q := ⟨dW1,dPublished,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W1Facts,PublishedFacts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35,u36,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53,u54,u55,u56,u57,u58,u59,u60,u61,u62⟩
   dsimp only [W1Facts,acquireActiveW1Next]
   simp only [acquireActiveW1Guard] at g
   simp_all
   all_goals omega
 · exact dR0
 · exact dR1
theorem failedClaimAcquireW1Invariant (q : State) (h : Safe q) (g : failedClaimAcquireW1Guard q) : Invariant (failedClaimAcquireW1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (failedClaimAcquireW1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · have use : W1Facts q ∧ PublishedFacts q ∧ LogFacts q := ⟨dW1,dPublished,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W1Facts,PublishedFacts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35,u36,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53,u54,u55,u56,u57,u58,u59,u60,u61,u62⟩
   dsimp only [W1Facts,failedClaimAcquireW1Next]
   simp only [failedClaimAcquireW1Guard] at g
   simp_all
   all_goals omega
 · exact dR0
 · exact dR1
theorem renewW1Invariant (q : State) (h : Safe q) (g : renewW1Guard q) : Invariant (renewW1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (renewW1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q := dPublished
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,renewW1Next]
   simp only [renewW1Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · have use : W1Facts q ∧ PublishedFacts q ∧ LogFacts q := ⟨dW1,dPublished,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [W1Facts,PublishedFacts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35,u36,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53,u54,u55,u56,u57,u58,u59,u60,u61,u62⟩
   dsimp only [W1Facts,renewW1Next]
   simp only [renewW1Guard] at g
   simp_all
   all_goals omega
 · exact dR0
 · have use : R1Facts q ∧ LogFacts q := ⟨dR1,dLog⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [R1Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28⟩
   dsimp only [R1Facts,renewW1Next]
   simp only [renewW1Guard] at g
   simp_all
   all_goals omega
end AtomicOwner

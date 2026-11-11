import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem casReserveInvariant (q : State) (h : Safe q) (g : casReserveGuard q) : Invariant (casReserveNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (casReserveNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · have use : LogFacts q := dLog
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19⟩
   dsimp only [LogFacts,casReserveNext]
   simp only [casReserveGuard] at g
   simp_all
   all_goals omega
 · exact dPublished
 · have use : SplitterFacts q := dSplitter
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [SplitterFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26⟩
   dsimp only [SplitterFacts,casReserveNext]
   simp only [casReserveGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem casCommitInvariant (q : State) (h : Safe q) (g : casCommitGuard q) : Invariant (casCommitNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (casCommitNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · have use : LogFacts q := dLog
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19⟩
   dsimp only [LogFacts,casCommitNext]
   simp only [casCommitGuard] at g
   simp_all
   all_goals omega
 · have use : PublishedFacts q := dPublished
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [PublishedFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25⟩
   dsimp only [PublishedFacts,casCommitNext]
   simp only [casCommitGuard] at g
   simp_all
   all_goals omega
 · have use : SplitterFacts q := dSplitter
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [SplitterFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26⟩
   dsimp only [SplitterFacts,casCommitNext]
   simp only [casCommitGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · have use : A0Facts q ∧ LogFacts q := ⟨dA0,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [A0Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35⟩
   dsimp only [A0Facts,casCommitNext]
   simp only [casCommitGuard] at g
   simp_all
   all_goals omega
 · have use : A1Facts q ∧ LogFacts q := ⟨dA1,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [A1Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28,u29,u30,u31,u32,u33,u34,u35⟩
   dsimp only [A1Facts,casCommitNext]
   simp only [casCommitGuard] at g
   simp_all
   all_goals omega
 · exact dW0
 · exact dW1
 · have use : R0Facts q ∧ LogFacts q := ⟨dR0,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [R0Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28⟩
   dsimp only [R0Facts,casCommitNext]
   simp only [casCommitGuard] at g
   have noCommit : q.commitRelease=0 := by omega
   simp_all
   all_goals omega
 · have use : R1Facts q ∧ LogFacts q := ⟨dR1,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [R1Facts,LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26,u27,u28⟩
   dsimp only [R1Facts,casCommitNext]
   simp only [casCommitGuard] at g
   have noCommit : q.commitRelease=0 := by omega
   simp_all
   all_goals omega
theorem casAbortInvariant (q : State) (h : Safe q) (g : casAbortGuard q) : Invariant (casAbortNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (casAbortNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · have use : LogFacts q := dLog
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [LogFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19⟩
   dsimp only [LogFacts,casAbortNext]
   simp only [casAbortGuard] at g
   simp_all
   all_goals omega
 · exact dPublished
 · have use : SplitterFacts q := dSplitter
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [SplitterFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26⟩
   dsimp only [SplitterFacts,casAbortNext]
   simp only [casAbortGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem splitNativeFailureInvariant (q : State) (h : Safe q) (g : splitNativeFailureGuard q) : Invariant (splitNativeFailureNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (splitNativeFailureNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · have use : SplitterFacts q := dSplitter
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [SplitterFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26⟩
   dsimp only [SplitterFacts,splitNativeFailureNext]
   simp only [splitNativeFailureGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem splitLegacyFailureInvariant (q : State) (h : Safe q) (g : splitLegacyFailureGuard q) : Invariant (splitLegacyFailureNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (splitLegacyFailureNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · have use : SplitterFacts q := dSplitter
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   simp only [and_assoc] at hp
   rcases hp with ⟨p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44⟩
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [SplitterFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26⟩
   dsimp only [SplitterFacts,splitLegacyFailureNext]
   simp only [splitLegacyFailureGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem deliverSplitterInvariant (q : State) (h : Safe q) (g : deliverSplitterGuard q) : Invariant (deliverSplitterNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (deliverSplitterNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · have use : SplitterFacts q := dSplitter
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   simp only [SplitterFacts,and_assoc] at use
   rcases use with ⟨u0,u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24,u25,u26⟩
   dsimp only [SplitterFacts,deliverSplitterNext]
   simp only [deliverSplitterGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
end AtomicOwner

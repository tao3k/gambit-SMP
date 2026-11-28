import ExitDomainDrainAst
namespace ExitDomainDrain
open ExitDomainDrainAst
set_option maxRecDepth 10000
theorem finishSubsystemTailPreserves (q : State) (h : Safe q) (g : finishSubsystemTailGuard q) : Safe (finishSubsystemTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [finishSubsystemTailGuard] at g
 simp_all [finishSubsystemTailNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem closeProducersPreserves (q : State) (h : Safe q) (g : closeProducersGuard q) : Safe (closeProducersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [closeProducersGuard] at g
 simp_all [closeProducersNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem attestNoTsdDependenciesPreserves (q : State) (h : Safe q) (g : attestNoTsdDependenciesGuard q) : Safe (attestNoTsdDependenciesNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [attestNoTsdDependenciesGuard] at g
 simp_all [attestNoTsdDependenciesNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem acquireLookupPreserves (q : State) (h : Safe q) (g : acquireLookupGuard q) : Safe (acquireLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [acquireLookupGuard] at g
 simp_all [acquireLookupNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem lookupAbsentPreserves (q : State) (h : Safe q) (g : lookupAbsentGuard q) : Safe (lookupAbsentNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [lookupAbsentGuard] at g
 simp_all [lookupAbsentNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem releaseLookupPreserves (q : State) (h : Safe q) (g : releaseLookupGuard q) : Safe (releaseLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [releaseLookupGuard] at g
 simp_all [releaseLookupNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem detachTableSlotPreserves (q : State) (h : Safe q) (g : detachTableSlotGuard q) : Safe (detachTableSlotNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [detachTableSlotGuard] at g
 simp_all [detachTableSlotNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem freeTsdDataPreserves (q : State) (h : Safe q) (g : freeTsdDataGuard q) : Safe (freeTsdDataNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [freeTsdDataGuard] at g
 simp_all [freeTsdDataNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem issueDataDrainReceiptPreserves (q : State) (h : Safe q) (g : issueDataDrainReceiptGuard q) : Safe (issueDataDrainReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [issueDataDrainReceiptGuard] at g
 simp_all [issueDataDrainReceiptNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem cancelAbsentFromReceiptPreserves (q : State) (h : Safe q) (g : cancelAbsentFromReceiptGuard q) : Safe (cancelAbsentFromReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [cancelAbsentFromReceiptGuard] at g
 simp_all [cancelAbsentFromReceiptNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem attestCacheAndOwnerRosterPreserves (q : State) (h : Safe q) (g : attestCacheAndOwnerRosterGuard q) : Safe (attestCacheAndOwnerRosterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [attestCacheAndOwnerRosterGuard] at g
 simp_all [attestCacheAndOwnerRosterNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem deleteGenericKeyPreserves (q : State) (h : Safe q) (g : deleteGenericKeyGuard q) : Safe (deleteGenericKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 simp only [deleteGenericKeyGuard] at g
 simp_all [deleteGenericKeyNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
end ExitDomainDrain

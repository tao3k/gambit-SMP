import RuntimeTlsReadyAst
namespace RuntimeTlsReady
open RuntimeTlsReadyAst
set_option maxRecDepth 10000
theorem drainLateTsdWorkPreserves (q : State) (h : Safe q) (g : drainLateTsdWorkGuard q) : Safe (drainLateTsdWorkNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [drainLateTsdWorkGuard] at g
 simp_all [drainLateTsdWorkNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem finishFinalizerPreserves (q : State) (h : Safe q) (g : finishFinalizerGuard q) : Safe (finishFinalizerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [finishFinalizerGuard] at g
 simp_all [finishFinalizerNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem closeCachePreserves (q : State) (h : Safe q) (g : closeCacheGuard q) : Safe (closeCacheNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [closeCacheGuard] at g
 simp_all [closeCacheNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem clearFastKnownPreserves (q : State) (h : Safe q) (g : clearFastKnownGuard q) : Safe (clearFastKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [clearFastKnownGuard] at g
 simp_all [clearFastKnownNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem clearTlsKnownPreserves (q : State) (h : Safe q) (g : clearTlsKnownGuard q) : Safe (clearTlsKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [clearTlsKnownGuard] at g
 simp_all [clearTlsKnownNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem clearTlsUnknownPreserves (q : State) (h : Safe q) (g : clearTlsUnknownGuard q) : Safe (clearTlsUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [clearTlsUnknownGuard] at g
 simp_all [clearTlsUnknownNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem freeCacheKnownPreserves (q : State) (h : Safe q) (g : freeCacheKnownGuard q) : Safe (freeCacheKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [freeCacheKnownGuard] at g
 simp_all [freeCacheKnownNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem attestRosterClosedPreserves (q : State) (h : Safe q) (g : attestRosterClosedGuard q) : Safe (attestRosterClosedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [attestRosterClosedGuard] at g
 simp_all [attestRosterClosedNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem deleteGenericKeyPreserves (q : State) (h : Safe q) (g : deleteGenericKeyGuard q) : Safe (deleteGenericKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [deleteGenericKeyGuard] at g
 simp_all [deleteGenericKeyNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem deleteAllocKeyKnownPreserves (q : State) (h : Safe q) (g : deleteAllocKeyKnownGuard q) : Safe (deleteAllocKeyKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [deleteAllocKeyKnownGuard] at g
 simp_all [deleteAllocKeyKnownNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem deleteAllocKeyUnknownPreserves (q : State) (h : Safe q) (g : deleteAllocKeyUnknownGuard q) : Safe (deleteAllocKeyUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [deleteAllocKeyUnknownGuard] at g
 simp_all [deleteAllocKeyUnknownNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem freeGlobalLocksPreserves (q : State) (h : Safe q) (g : freeGlobalLocksGuard q) : Safe (freeGlobalLocksNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [freeGlobalLocksGuard] at g
 simp_all [freeGlobalLocksNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem retireRuntimePreserves (q : State) (h : Safe q) (g : retireRuntimeGuard q) : Safe (retireRuntimeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 simp only [retireRuntimeGuard] at g
 simp_all [retireRuntimeNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
end RuntimeTlsReady

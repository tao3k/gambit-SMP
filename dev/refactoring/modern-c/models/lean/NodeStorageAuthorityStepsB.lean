import NodeStorageAuthorityAst
namespace NodeStorageAuthority
open NodeStorageAuthorityAst
set_option maxRecDepth 10000
theorem returnPayloadPreserves (q : State) (h : Safe q) (g : returnPayloadGuard q) : Safe (returnPayloadNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [returnPayloadGuard] at g
 simp_all [returnPayloadNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem knownHandoffPreserves (q : State) (h : Safe q) (g : knownHandoffGuard q) : Safe (knownHandoffNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [knownHandoffGuard] at g
 simp_all [knownHandoffNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem unknownHandoffPreserves (q : State) (h : Safe q) (g : unknownHandoffGuard q) : Safe (unknownHandoffNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [unknownHandoffGuard] at g
 simp_all [unknownHandoffNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem consumerAllocatePreserves (q : State) (h : Safe q) (g : consumerAllocateGuard q) : Safe (consumerAllocateNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [consumerAllocateGuard] at g
 simp_all [consumerAllocateNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem fixSourceLastPreserves (q : State) (h : Safe q) (g : fixSourceLastGuard q) : Safe (fixSourceLastNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [fixSourceLastGuard] at g
 simp_all [fixSourceLastNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem publishCompletionPreserves (q : State) (h : Safe q) (g : publishCompletionGuard q) : Safe (publishCompletionNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [publishCompletionGuard] at g
 simp_all [publishCompletionNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem closeAdmissionPreserves (q : State) (h : Safe q) (g : closeAdmissionGuard q) : Safe (closeAdmissionNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [closeAdmissionGuard] at g
 simp_all [closeAdmissionNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem attestCleanupPreserves (q : State) (h : Safe q) (g : attestCleanupGuard q) : Safe (attestCleanupNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [attestCleanupGuard] at g
 simp_all [attestCleanupNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem retireCachePreserves (q : State) (h : Safe q) (g : retireCacheGuard q) : Safe (retireCacheNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [retireCacheGuard] at g
 simp_all [retireCacheNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem lookupOpaquePreserves (q : State) (h : Safe q) (g : lookupOpaqueGuard q) : Safe (lookupOpaqueNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [lookupOpaqueGuard] at g
 simp_all [lookupOpaqueNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
theorem probeCurrentCachePreserves (q : State) (h : Safe q) (g : probeCurrentCacheGuard q) : Safe (probeCurrentCacheNext q) := by
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
 rcases h20 with ⟨hl20,hu20⟩
 simp only [probeCurrentCacheGuard] at g
 simp_all [probeCurrentCacheNext,Safe]
 all_goals (repeat' apply And.intro)
 all_goals omega
end NodeStorageAuthority

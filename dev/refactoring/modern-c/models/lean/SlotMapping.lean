import SlotMappingAst
namespace SlotMapping
open SlotMappingAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem registerAliasPreserves (q : State) (h : Safe q) (g : registerAliasGuard q) : Safe (registerAliasNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,registerAliasGuard,registerAliasNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem registerCopyPreserves (q : State) (h : Safe q) (g : registerCopyGuard q) : Safe (registerCopyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,registerCopyGuard,registerCopyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginLookup0Preserves (q : State) (h : Safe q) (g : beginLookup0Guard q) : Safe (beginLookup0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,beginLookup0Guard,beginLookup0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem acceptBorrow0Preserves (q : State) (h : Safe q) (g : acceptBorrow0Guard q) : Safe (acceptBorrow0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,acceptBorrow0Guard,acceptBorrow0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem lookupUnknown0Preserves (q : State) (h : Safe q) (g : lookupUnknown0Guard q) : Safe (lookupUnknown0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,lookupUnknown0Guard,lookupUnknown0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveLookup0Preserves (q : State) (h : Safe q) (g : resolveLookup0Guard q) : Safe (resolveLookup0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,resolveLookup0Guard,resolveLookup0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectLookup0Preserves (q : State) (h : Safe q) (g : rejectLookup0Guard q) : Safe (rejectLookup0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,rejectLookup0Guard,rejectLookup0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnBorrow0Preserves (q : State) (h : Safe q) (g : returnBorrow0Guard q) : Safe (returnBorrow0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,returnBorrow0Guard,returnBorrow0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem close0Preserves (q : State) (h : Safe q) (g : close0Guard q) : Safe (close0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,close0Guard,close0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retire0Preserves (q : State) (h : Safe q) (g : retire0Guard q) : Safe (retire0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,retire0Guard,retire0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem lateRequest0Preserves (q : State) (h : Safe q) (g : lateRequest0Guard q) : Safe (lateRequest0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,lateRequest0Guard,lateRequest0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem claim0Preserves (q : State) (h : Safe q) (g : claim0Guard q) : Safe (claim0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,claim0Guard,claim0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scan0Preserves (q : State) (h : Safe q) (g : scan0Guard q) : Safe (scan0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,scan0Guard,scan0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scanUnknown0Preserves (q : State) (h : Safe q) (g : scanUnknown0Guard q) : Safe (scanUnknown0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,scanUnknown0Guard,scanUnknown0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveScan0Preserves (q : State) (h : Safe q) (g : resolveScan0Guard q) : Safe (resolveScan0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,resolveScan0Guard,resolveScan0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginLookup1Preserves (q : State) (h : Safe q) (g : beginLookup1Guard q) : Safe (beginLookup1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,beginLookup1Guard,beginLookup1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem acceptBorrow1Preserves (q : State) (h : Safe q) (g : acceptBorrow1Guard q) : Safe (acceptBorrow1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,acceptBorrow1Guard,acceptBorrow1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem lookupUnknown1Preserves (q : State) (h : Safe q) (g : lookupUnknown1Guard q) : Safe (lookupUnknown1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,lookupUnknown1Guard,lookupUnknown1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveLookup1Preserves (q : State) (h : Safe q) (g : resolveLookup1Guard q) : Safe (resolveLookup1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,resolveLookup1Guard,resolveLookup1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectLookup1Preserves (q : State) (h : Safe q) (g : rejectLookup1Guard q) : Safe (rejectLookup1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,rejectLookup1Guard,rejectLookup1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnBorrow1Preserves (q : State) (h : Safe q) (g : returnBorrow1Guard q) : Safe (returnBorrow1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,returnBorrow1Guard,returnBorrow1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem close1Preserves (q : State) (h : Safe q) (g : close1Guard q) : Safe (close1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,close1Guard,close1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retire1Preserves (q : State) (h : Safe q) (g : retire1Guard q) : Safe (retire1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,retire1Guard,retire1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem lateRequest1Preserves (q : State) (h : Safe q) (g : lateRequest1Guard q) : Safe (lateRequest1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,lateRequest1Guard,lateRequest1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem claim1Preserves (q : State) (h : Safe q) (g : claim1Guard q) : Safe (claim1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,claim1Guard,claim1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scan1Preserves (q : State) (h : Safe q) (g : scan1Guard q) : Safe (scan1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,scan1Guard,scan1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scanUnknown1Preserves (q : State) (h : Safe q) (g : scanUnknown1Guard q) : Safe (scanUnknown1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,scanUnknown1Guard,scanUnknown1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveScan1Preserves (q : State) (h : Safe q) (g : resolveScan1Guard q) : Safe (resolveScan1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,resolveScan1Guard,resolveScan1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeze000Preserves (q : State) (h : Safe q) (g : freeze000Guard q) : Safe (freeze000Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,freeze000Guard,freeze000Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeze001Preserves (q : State) (h : Safe q) (g : freeze001Guard q) : Safe (freeze001Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,freeze001Guard,freeze001Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeze010Preserves (q : State) (h : Safe q) (g : freeze010Guard q) : Safe (freeze010Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,freeze010Guard,freeze010Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeze011Preserves (q : State) (h : Safe q) (g : freeze011Guard q) : Safe (freeze011Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,freeze011Guard,freeze011Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeze100Preserves (q : State) (h : Safe q) (g : freeze100Guard q) : Safe (freeze100Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,freeze100Guard,freeze100Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeze101Preserves (q : State) (h : Safe q) (g : freeze101Guard q) : Safe (freeze101Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,freeze101Guard,freeze101Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeze110Preserves (q : State) (h : Safe q) (g : freeze110Guard q) : Safe (freeze110Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,freeze110Guard,freeze110Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeze111Preserves (q : State) (h : Safe q) (g : freeze111Guard q) : Safe (freeze111Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,freeze111Guard,freeze111Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishRoundPreserves (q : State) (h : Safe q) (g : finishRoundGuard q) : Safe (finishRoundNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,finishRoundGuard,finishRoundNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeStore0Preserves (q : State) (h : Safe q) (g : freeStore0Guard q) : Safe (freeStore0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,freeStore0Guard,freeStore0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freeStore1Preserves (q : State) (h : Safe q) (g : freeStore1Guard q) : Safe (freeStore1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,freeStore1Guard,freeStore1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem exitProcessorPreserves (q : State) (h : Safe q) (g : exitProcessorGuard q) : Safe (exitProcessorNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58⟩
 simp_all [Safe,exitProcessorGuard,exitProcessorNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (step : Step q r) : Safe r := by
 rcases step with g0 | g1 | g2 | g3 | g4 | g5 | g6 | g7 | g8 | g9 | g10 | g11 | g12 | g13 | g14 | g15 | g16 | g17 | g18 | g19 | g20 | g21 | g22 | g23 | g24 | g25 | g26 | g27 | g28 | g29 | g30 | g31 | g32 | g33 | g34 | g35 | g36 | g37 | g38 | g39 | g40
 · rcases g0 with ⟨guard, rfl⟩
   exact registerAliasPreserves q h guard
 · rcases g1 with ⟨guard, rfl⟩
   exact registerCopyPreserves q h guard
 · rcases g2 with ⟨guard, rfl⟩
   exact beginLookup0Preserves q h guard
 · rcases g3 with ⟨guard, rfl⟩
   exact acceptBorrow0Preserves q h guard
 · rcases g4 with ⟨guard, rfl⟩
   exact lookupUnknown0Preserves q h guard
 · rcases g5 with ⟨guard, rfl⟩
   exact resolveLookup0Preserves q h guard
 · rcases g6 with ⟨guard, rfl⟩
   exact rejectLookup0Preserves q h guard
 · rcases g7 with ⟨guard, rfl⟩
   exact returnBorrow0Preserves q h guard
 · rcases g8 with ⟨guard, rfl⟩
   exact close0Preserves q h guard
 · rcases g9 with ⟨guard, rfl⟩
   exact retire0Preserves q h guard
 · rcases g10 with ⟨guard, rfl⟩
   exact lateRequest0Preserves q h guard
 · rcases g11 with ⟨guard, rfl⟩
   exact claim0Preserves q h guard
 · rcases g12 with ⟨guard, rfl⟩
   exact scan0Preserves q h guard
 · rcases g13 with ⟨guard, rfl⟩
   exact scanUnknown0Preserves q h guard
 · rcases g14 with ⟨guard, rfl⟩
   exact resolveScan0Preserves q h guard
 · rcases g15 with ⟨guard, rfl⟩
   exact beginLookup1Preserves q h guard
 · rcases g16 with ⟨guard, rfl⟩
   exact acceptBorrow1Preserves q h guard
 · rcases g17 with ⟨guard, rfl⟩
   exact lookupUnknown1Preserves q h guard
 · rcases g18 with ⟨guard, rfl⟩
   exact resolveLookup1Preserves q h guard
 · rcases g19 with ⟨guard, rfl⟩
   exact rejectLookup1Preserves q h guard
 · rcases g20 with ⟨guard, rfl⟩
   exact returnBorrow1Preserves q h guard
 · rcases g21 with ⟨guard, rfl⟩
   exact close1Preserves q h guard
 · rcases g22 with ⟨guard, rfl⟩
   exact retire1Preserves q h guard
 · rcases g23 with ⟨guard, rfl⟩
   exact lateRequest1Preserves q h guard
 · rcases g24 with ⟨guard, rfl⟩
   exact claim1Preserves q h guard
 · rcases g25 with ⟨guard, rfl⟩
   exact scan1Preserves q h guard
 · rcases g26 with ⟨guard, rfl⟩
   exact scanUnknown1Preserves q h guard
 · rcases g27 with ⟨guard, rfl⟩
   exact resolveScan1Preserves q h guard
 · rcases g28 with ⟨guard, rfl⟩
   exact freeze000Preserves q h guard
 · rcases g29 with ⟨guard, rfl⟩
   exact freeze001Preserves q h guard
 · rcases g30 with ⟨guard, rfl⟩
   exact freeze010Preserves q h guard
 · rcases g31 with ⟨guard, rfl⟩
   exact freeze011Preserves q h guard
 · rcases g32 with ⟨guard, rfl⟩
   exact freeze100Preserves q h guard
 · rcases g33 with ⟨guard, rfl⟩
   exact freeze101Preserves q h guard
 · rcases g34 with ⟨guard, rfl⟩
   exact freeze110Preserves q h guard
 · rcases g35 with ⟨guard, rfl⟩
   exact freeze111Preserves q h guard
 · rcases g36 with ⟨guard, rfl⟩
   exact finishRoundPreserves q h guard
 · rcases g37 with ⟨guard, rfl⟩
   exact freeStore0Preserves q h guard
 · rcases g38 with ⟨guard, rfl⟩
   exact freeStore1Preserves q h guard
 · rcases g39 with ⟨guard, rfl⟩
   exact exitProcessorPreserves q h guard
 · subst r; exact h
inductive Reachable : State → Prop where
 | initial : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | initial => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem sameSlotUsesOneTask (q : State) (h : Safe q) (a : q.alias = 1) (f : q.gc = 1) : q.m1 = 0 := by
 simp_all [Safe] <;> omega
theorem bothDistinctCovered (q : State) (h : Safe q) (a : q.alias = 0) (f : q.gc = 1) (d0 : q.d0 = 2) (d1 : q.d1 = 2) : q.m0 = 1 ∧ q.m1 = 1 := by
 simp_all [Safe] <;> omega
theorem lateBorrowDenied (q : State) (closed : q.d0 = 3) : ¬ acceptBorrow0Guard q := by
 simp [acceptBorrow0Guard, closed]
theorem unknownLookupBlocksRetirement (q : State) (u : q.lookup0 = 2) : ¬ retire0Guard q := by
 simp [retire0Guard, u]
theorem closingAliasRetainsSlot (q : State) (h : Safe q) (a : q.alias = 1) (closed : q.d1 = 3) : q.store0 = 1 := by
 simp_all [Safe]
theorem sharedSlotBlocksFree (q : State) (a : q.alias = 1) (live : q.d1 = 2) : ¬ freeStore0Guard q := by
 simp [freeStore0Guard, a, live]
theorem acceptedLookupRetainsDescriptor (q : State) (h : Safe q) (u : q.lookup0 > 0) : q.mem0 = 1 := by
 simp_all [Safe]
theorem secondClaimDenied (q : State) (claimed : q.task0 = 2) : ¬ claim0Guard q := by
 simp [claim0Guard, claimed]
theorem unknownScanBlocksFinish (q : State) (u : q.task0 = 3) : ¬ finishRoundGuard q := by
 simp [finishRoundGuard, u]
end SlotMapping

import SlotIssuanceAst
namespace SlotIssuance
open SlotIssuanceAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem probeSubviewPreserves (q : State) (h : Safe q) (g : probeSubviewGuard q) : Safe (probeSubviewNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,probeSubviewGuard,probeSubviewNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem probeAdjacentPreserves (q : State) (h : Safe q) (g : probeAdjacentGuard q) : Safe (probeAdjacentNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,probeAdjacentGuard,probeAdjacentNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem probeOverlapPreserves (q : State) (h : Safe q) (g : probeOverlapGuard q) : Safe (probeOverlapNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,probeOverlapGuard,probeOverlapNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem probeUnownedExactPreserves (q : State) (h : Safe q) (g : probeUnownedExactGuard q) : Safe (probeUnownedExactNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,probeUnownedExactGuard,probeUnownedExactNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issueSubviewPreserves (q : State) (h : Safe q) (g : issueSubviewGuard q) : Safe (issueSubviewNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,issueSubviewGuard,issueSubviewNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issueFreshPreserves (q : State) (h : Safe q) (g : issueFreshGuard q) : Safe (issueFreshNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,issueFreshGuard,issueFreshNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectOverlapPreserves (q : State) (h : Safe q) (g : rejectOverlapGuard q) : Safe (rejectOverlapNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,rejectOverlapGuard,rejectOverlapNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectUnownedExactPreserves (q : State) (h : Safe q) (g : rejectUnownedExactGuard q) : Safe (rejectUnownedExactNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,rejectUnownedExactGuard,rejectUnownedExactNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem saveKeyPreserves (q : State) (h : Safe q) (g : saveKeyGuard q) : Safe (saveKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,saveKeyGuard,saveKeyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem prepareAliasPreserves (q : State) (h : Safe q) (g : prepareAliasGuard q) : Safe (prepareAliasNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,prepareAliasGuard,prepareAliasNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem prepareCopyPreserves (q : State) (h : Safe q) (g : prepareCopyGuard q) : Safe (prepareCopyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,prepareCopyGuard,prepareCopyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem materializeCopyPreserves (q : State) (h : Safe q) (g : materializeCopyGuard q) : Safe (materializeCopyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,materializeCopyGuard,materializeCopyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishAliasPreserves (q : State) (h : Safe q) (g : publishAliasGuard q) : Safe (publishAliasNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,publishAliasGuard,publishAliasNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishCopyPreserves (q : State) (h : Safe q) (g : publishCopyGuard q) : Safe (publishCopyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,publishCopyGuard,publishCopyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem queryCommitPreserves (q : State) (h : Safe q) (g : queryCommitGuard q) : Safe (queryCommitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,queryCommitGuard,queryCommitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem releaseCopyLeasePreserves (q : State) (h : Safe q) (g : releaseCopyLeaseGuard q) : Safe (releaseCopyLeaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,releaseCopyLeaseGuard,releaseCopyLeaseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginLookupPreserves (q : State) (h : Safe q) (g : beginLookupGuard q) : Safe (beginLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,beginLookupGuard,beginLookupNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem acceptBorrowPreserves (q : State) (h : Safe q) (g : acceptBorrowGuard q) : Safe (acceptBorrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,acceptBorrowGuard,acceptBorrowNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem lookupUnknownPreserves (q : State) (h : Safe q) (g : lookupUnknownGuard q) : Safe (lookupUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,lookupUnknownGuard,lookupUnknownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveLookupPreserves (q : State) (h : Safe q) (g : resolveLookupGuard q) : Safe (resolveLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,resolveLookupGuard,resolveLookupNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectLookupPreserves (q : State) (h : Safe q) (g : rejectLookupGuard q) : Safe (rejectLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,rejectLookupGuard,rejectLookupNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnBorrowPreserves (q : State) (h : Safe q) (g : returnBorrowGuard q) : Safe (returnBorrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,returnBorrowGuard,returnBorrowNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeRegistryPreserves (q : State) (h : Safe q) (g : closeRegistryGuard q) : Safe (closeRegistryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,closeRegistryGuard,closeRegistryNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginScanPreserves (q : State) (h : Safe q) (g : beginScanGuard q) : Safe (beginScanNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,beginScanGuard,beginScanNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishScanPreserves (q : State) (h : Safe q) (g : finishScanGuard q) : Safe (finishScanNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,finishScanGuard,finishScanNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scanUnknownPreserves (q : State) (h : Safe q) (g : scanUnknownGuard q) : Safe (scanUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,scanUnknownGuard,scanUnknownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveScanPreserves (q : State) (h : Safe q) (g : resolveScanGuard q) : Safe (resolveScanNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,resolveScanGuard,resolveScanNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireRegistryPreserves (q : State) (h : Safe q) (g : retireRegistryGuard q) : Safe (retireRegistryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,retireRegistryGuard,retireRegistryNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem releaseRetiredAliasLeasePreserves (q : State) (h : Safe q) (g : releaseRetiredAliasLeaseGuard q) : Safe (releaseRetiredAliasLeaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,releaseRetiredAliasLeaseGuard,releaseRetiredAliasLeaseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortCandidatePreserves (q : State) (h : Safe q) (g : abortCandidateGuard q) : Safe (abortCandidateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,abortCandidateGuard,abortCandidateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sourceWritePreserves (q : State) (h : Safe q) (g : sourceWriteGuard q) : Safe (sourceWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,sourceWriteGuard,sourceWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sourceBorrowBeginPreserves (q : State) (h : Safe q) (g : sourceBorrowBeginGuard q) : Safe (sourceBorrowBeginNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,sourceBorrowBeginGuard,sourceBorrowBeginNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sourceBorrowReturnPreserves (q : State) (h : Safe q) (g : sourceBorrowReturnGuard q) : Safe (sourceBorrowReturnNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,sourceBorrowReturnGuard,sourceBorrowReturnNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeStoragePreserves (q : State) (h : Safe q) (g : closeStorageGuard q) : Safe (closeStorageNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,closeStorageGuard,closeStorageNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem settleBackingPreserves (q : State) (h : Safe q) (g : settleBackingGuard q) : Safe (settleBackingNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,settleBackingGuard,settleBackingNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reclaimStoragePreserves (q : State) (h : Safe q) (g : reclaimStorageGuard q) : Safe (reclaimStorageNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,reclaimStorageGuard,reclaimStorageNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reuseStoragePreserves (q : State) (h : Safe q) (g : reuseStorageGuard q) : Safe (reuseStorageNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,reuseStorageGuard,reuseStorageNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectStaleKeyPreserves (q : State) (h : Safe q) (g : rejectStaleKeyGuard q) : Safe (rejectStaleKeyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65⟩
 simp_all [Safe,rejectStaleKeyGuard,rejectStaleKeyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (step : Step q r) : Safe r := by
 rcases step with g0 | g1 | g2 | g3 | g4 | g5 | g6 | g7 | g8 | g9 | g10 | g11 | g12 | g13 | g14 | g15 | g16 | g17 | g18 | g19 | g20 | g21 | g22 | g23 | g24 | g25 | g26 | g27 | g28 | g29 | g30 | g31 | g32 | g33 | g34 | g35 | g36 | g37 | g38
 · rcases g0 with ⟨guard, rfl⟩
   exact probeSubviewPreserves q h guard
 · rcases g1 with ⟨guard, rfl⟩
   exact probeAdjacentPreserves q h guard
 · rcases g2 with ⟨guard, rfl⟩
   exact probeOverlapPreserves q h guard
 · rcases g3 with ⟨guard, rfl⟩
   exact probeUnownedExactPreserves q h guard
 · rcases g4 with ⟨guard, rfl⟩
   exact issueSubviewPreserves q h guard
 · rcases g5 with ⟨guard, rfl⟩
   exact issueFreshPreserves q h guard
 · rcases g6 with ⟨guard, rfl⟩
   exact rejectOverlapPreserves q h guard
 · rcases g7 with ⟨guard, rfl⟩
   exact rejectUnownedExactPreserves q h guard
 · rcases g8 with ⟨guard, rfl⟩
   exact saveKeyPreserves q h guard
 · rcases g9 with ⟨guard, rfl⟩
   exact prepareAliasPreserves q h guard
 · rcases g10 with ⟨guard, rfl⟩
   exact prepareCopyPreserves q h guard
 · rcases g11 with ⟨guard, rfl⟩
   exact materializeCopyPreserves q h guard
 · rcases g12 with ⟨guard, rfl⟩
   exact publishAliasPreserves q h guard
 · rcases g13 with ⟨guard, rfl⟩
   exact publishCopyPreserves q h guard
 · rcases g14 with ⟨guard, rfl⟩
   exact queryCommitPreserves q h guard
 · rcases g15 with ⟨guard, rfl⟩
   exact releaseCopyLeasePreserves q h guard
 · rcases g16 with ⟨guard, rfl⟩
   exact beginLookupPreserves q h guard
 · rcases g17 with ⟨guard, rfl⟩
   exact acceptBorrowPreserves q h guard
 · rcases g18 with ⟨guard, rfl⟩
   exact lookupUnknownPreserves q h guard
 · rcases g19 with ⟨guard, rfl⟩
   exact resolveLookupPreserves q h guard
 · rcases g20 with ⟨guard, rfl⟩
   exact rejectLookupPreserves q h guard
 · rcases g21 with ⟨guard, rfl⟩
   exact returnBorrowPreserves q h guard
 · rcases g22 with ⟨guard, rfl⟩
   exact closeRegistryPreserves q h guard
 · rcases g23 with ⟨guard, rfl⟩
   exact beginScanPreserves q h guard
 · rcases g24 with ⟨guard, rfl⟩
   exact finishScanPreserves q h guard
 · rcases g25 with ⟨guard, rfl⟩
   exact scanUnknownPreserves q h guard
 · rcases g26 with ⟨guard, rfl⟩
   exact resolveScanPreserves q h guard
 · rcases g27 with ⟨guard, rfl⟩
   exact retireRegistryPreserves q h guard
 · rcases g28 with ⟨guard, rfl⟩
   exact releaseRetiredAliasLeasePreserves q h guard
 · rcases g29 with ⟨guard, rfl⟩
   exact abortCandidatePreserves q h guard
 · rcases g30 with ⟨guard, rfl⟩
   exact sourceWritePreserves q h guard
 · rcases g31 with ⟨guard, rfl⟩
   exact sourceBorrowBeginPreserves q h guard
 · rcases g32 with ⟨guard, rfl⟩
   exact sourceBorrowReturnPreserves q h guard
 · rcases g33 with ⟨guard, rfl⟩
   exact closeStoragePreserves q h guard
 · rcases g34 with ⟨guard, rfl⟩
   exact settleBackingPreserves q h guard
 · rcases g35 with ⟨guard, rfl⟩
   exact reclaimStoragePreserves q h guard
 · rcases g36 with ⟨guard, rfl⟩
   exact reuseStoragePreserves q h guard
 · rcases g37 with ⟨guard, rfl⟩
   exact rejectStaleKeyPreserves q h guard
 · subst r; exact h
inductive Reachable : State → Prop where
 | initial : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | initial => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem aliasBindingStable (q : State) (h : Safe q) (m : q.mode = 1) (r : q.reg = 2 ∨ q.reg = 3) : q.lease = 1 ∧ q.boundGeneration = q.generation ∧ q.boundPayload = q.payload := by
 simp_all [Safe]
theorem publicationUnknownBlocksCopyRelease (q : State) (u : q.known = 0) : ¬ releaseCopyLeaseGuard q := by
 simp [releaseCopyLeaseGuard,u]
theorem aliasBlocksSourceWrite (q : State) (h : Safe q) (m : q.mode = 1) (r : q.reg = 2 ∨ q.reg = 3) : ¬ sourceWriteGuard q := by
 have x := aliasBindingStable q h m r
 simp_all [sourceWriteGuard]
theorem aliasReleaseRequiresRetirement (q : State) (g : releaseRetiredAliasLeaseGuard q) : q.reg = 4 ∧ q.lookup = 0 ∧ q.borrow = 0 ∧ q.scan = 0 := by
 simp_all [releaseRetiredAliasLeaseGuard]
theorem copyReleaseRequiresKnownRoot (q : State) (g : releaseCopyLeaseGuard q) : q.mode = 2 ∧ q.copy = 1 ∧ q.known = 1 := by
 simp_all [releaseCopyLeaseGuard]
theorem reuseAdvancesGeneration (q : State) : (reuseStorageNext q).generation = q.generation + 1 := rfl
theorem exhaustionDeniesReuse (q : State) (n : q.generation = 2) : ¬ reuseStorageGuard q := by
 simp [reuseStorageGuard,n]
theorem staleKeyCannotPrepare (q : State) (k : q.keyGeneration ≠ q.generation) : ¬ prepareAliasGuard q ∧ ¬ prepareCopyGuard q := by
 simp [prepareAliasGuard,prepareCopyGuard,k]
theorem freshIssuedDisjoint (q : State) (h : Safe q) (f : q.fresh = 1) : q.freshLo ≥ 8 ∨ q.freshHi ≤ 0 := by
 simp_all [Safe]
end SlotIssuance

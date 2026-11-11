import SourceOwnerAst
namespace SourceOwner
open SourceOwnerAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem reserveOwnerPreserves (q : State) (h : Safe q) (g : reserveOwnerGuard q) : Safe (reserveOwnerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,reserveOwnerGuard,reserveOwnerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem prepareRootPreserves (q : State) (h : Safe q) (g : prepareRootGuard q) : Safe (prepareRootNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,prepareRootGuard,prepareRootNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishOwnerPreserves (q : State) (h : Safe q) (g : publishOwnerGuard q) : Safe (publishOwnerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,publishOwnerGuard,publishOwnerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortPrivatePreserves (q : State) (h : Safe q) (g : abortPrivateGuard q) : Safe (abortPrivateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,abortPrivateGuard,abortPrivateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeRegistryPreserves (q : State) (h : Safe q) (g : closeRegistryGuard q) : Safe (closeRegistryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,closeRegistryGuard,closeRegistryNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeOwnerPreserves (q : State) (h : Safe q) (g : closeOwnerGuard q) : Safe (closeOwnerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,closeOwnerGuard,closeOwnerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealRosterPreserves (q : State) (h : Safe q) (g : sealRosterGuard q) : Safe (sealRosterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,sealRosterGuard,sealRosterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectLatePreserves (q : State) (h : Safe q) (g : rejectLateGuard q) : Safe (rejectLateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,rejectLateGuard,rejectLateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginWritePreserves (q : State) (h : Safe q) (g : beginWriteGuard q) : Safe (beginWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,beginWriteGuard,beginWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownWritePreserves (q : State) (h : Safe q) (g : unknownWriteGuard q) : Safe (unknownWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,unknownWriteGuard,unknownWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem presentCurrentWritePreserves (q : State) (h : Safe q) (g : presentCurrentWriteGuard q) : Safe (presentCurrentWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,presentCurrentWriteGuard,presentCurrentWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem presentOldWritePreserves (q : State) (h : Safe q) (g : presentOldWriteGuard q) : Safe (presentOldWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,presentOldWriteGuard,presentOldWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitWritePreserves (q : State) (h : Safe q) (g : commitWriteGuard q) : Safe (commitWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,commitWriteGuard,commitWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortWritePreserves (q : State) (h : Safe q) (g : abortWriteGuard q) : Safe (abortWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,abortWriteGuard,abortWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem queryWritePreserves (q : State) (h : Safe q) (g : queryWriteGuard q) : Safe (queryWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,queryWriteGuard,queryWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem pin0Preserves (q : State) (h : Safe q) (g : pin0Guard q) : Safe (pin0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,pin0Guard,pin0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enrollTarget0Preserves (q : State) (h : Safe q) (g : enrollTarget0Guard q) : Safe (enrollTarget0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,enrollTarget0Guard,enrollTarget0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem ackRound0Preserves (q : State) (h : Safe q) (g : ackRound0Guard q) : Safe (ackRound0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,ackRound0Guard,ackRound0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveGuard0Preserves (q : State) (h : Safe q) (g : reserveGuard0Guard q) : Safe (reserveGuard0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,reserveGuard0Guard,reserveGuard0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitGuard0Preserves (q : State) (h : Safe q) (g : commitGuard0Guard q) : Safe (commitGuard0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,commitGuard0Guard,commitGuard0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownGuard0Preserves (q : State) (h : Safe q) (g : unknownGuard0Guard q) : Safe (unknownGuard0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,unknownGuard0Guard,unknownGuard0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveGuard0Preserves (q : State) (h : Safe q) (g : resolveGuard0Guard q) : Safe (resolveGuard0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,resolveGuard0Guard,resolveGuard0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnPin0Preserves (q : State) (h : Safe q) (g : returnPin0Guard q) : Safe (returnPin0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,returnPin0Guard,returnPin0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishGuard0Preserves (q : State) (h : Safe q) (g : finishGuard0Guard q) : Safe (finishGuard0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,finishGuard0Guard,finishGuard0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireTarget0Preserves (q : State) (h : Safe q) (g : retireTarget0Guard q) : Safe (retireTarget0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,retireTarget0Guard,retireTarget0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem pin1Preserves (q : State) (h : Safe q) (g : pin1Guard q) : Safe (pin1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,pin1Guard,pin1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enrollTarget1Preserves (q : State) (h : Safe q) (g : enrollTarget1Guard q) : Safe (enrollTarget1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,enrollTarget1Guard,enrollTarget1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem ackRound1Preserves (q : State) (h : Safe q) (g : ackRound1Guard q) : Safe (ackRound1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,ackRound1Guard,ackRound1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveGuard1Preserves (q : State) (h : Safe q) (g : reserveGuard1Guard q) : Safe (reserveGuard1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,reserveGuard1Guard,reserveGuard1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitGuard1Preserves (q : State) (h : Safe q) (g : commitGuard1Guard q) : Safe (commitGuard1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,commitGuard1Guard,commitGuard1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownGuard1Preserves (q : State) (h : Safe q) (g : unknownGuard1Guard q) : Safe (unknownGuard1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,unknownGuard1Guard,unknownGuard1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveGuard1Preserves (q : State) (h : Safe q) (g : resolveGuard1Guard q) : Safe (resolveGuard1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,resolveGuard1Guard,resolveGuard1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnPin1Preserves (q : State) (h : Safe q) (g : returnPin1Guard q) : Safe (returnPin1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,returnPin1Guard,returnPin1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishGuard1Preserves (q : State) (h : Safe q) (g : finishGuard1Guard q) : Safe (finishGuard1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,finishGuard1Guard,finishGuard1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireTarget1Preserves (q : State) (h : Safe q) (g : retireTarget1Guard q) : Safe (retireTarget1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,retireTarget1Guard,retireTarget1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeGcPreserves (q : State) (h : Safe q) (g : freezeGcGuard q) : Safe (freezeGcNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,freezeGcGuard,freezeGcNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishGcPreserves (q : State) (h : Safe q) (g : finishGcGuard q) : Safe (finishGcNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,finishGcGuard,finishGcNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem storageReceiptPreserves (q : State) (h : Safe q) (g : storageReceiptGuard q) : Safe (storageReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,storageReceiptGuard,storageReceiptNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem bulkCleanupPreserves (q : State) (h : Safe q) (g : bulkCleanupGuard q) : Safe (bulkCleanupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64⟩
 simp_all [Safe,bulkCleanupGuard,bulkCleanupNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36 | h37 | h38 | h39
 · rcases h0 with ⟨g,e⟩; rw [e]; exact reserveOwnerPreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact prepareRootPreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact publishOwnerPreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact abortPrivatePreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact closeRegistryPreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact closeOwnerPreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact sealRosterPreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact rejectLatePreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact beginWritePreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact unknownWritePreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact presentCurrentWritePreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact presentOldWritePreserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact commitWritePreserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact abortWritePreserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact queryWritePreserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact pin0Preserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact enrollTarget0Preserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact ackRound0Preserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact reserveGuard0Preserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact commitGuard0Preserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact unknownGuard0Preserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact resolveGuard0Preserves q h g
 · rcases h22 with ⟨g,e⟩; rw [e]; exact returnPin0Preserves q h g
 · rcases h23 with ⟨g,e⟩; rw [e]; exact finishGuard0Preserves q h g
 · rcases h24 with ⟨g,e⟩; rw [e]; exact retireTarget0Preserves q h g
 · rcases h25 with ⟨g,e⟩; rw [e]; exact pin1Preserves q h g
 · rcases h26 with ⟨g,e⟩; rw [e]; exact enrollTarget1Preserves q h g
 · rcases h27 with ⟨g,e⟩; rw [e]; exact ackRound1Preserves q h g
 · rcases h28 with ⟨g,e⟩; rw [e]; exact reserveGuard1Preserves q h g
 · rcases h29 with ⟨g,e⟩; rw [e]; exact commitGuard1Preserves q h g
 · rcases h30 with ⟨g,e⟩; rw [e]; exact unknownGuard1Preserves q h g
 · rcases h31 with ⟨g,e⟩; rw [e]; exact resolveGuard1Preserves q h g
 · rcases h32 with ⟨g,e⟩; rw [e]; exact returnPin1Preserves q h g
 · rcases h33 with ⟨g,e⟩; rw [e]; exact finishGuard1Preserves q h g
 · rcases h34 with ⟨g,e⟩; rw [e]; exact retireTarget1Preserves q h g
 · rcases h35 with ⟨g,e⟩; rw [e]; exact freezeGcPreserves q h g
 · rcases h36 with ⟨g,e⟩; rw [e]; exact finishGcPreserves q h g
 · rcases h37 with ⟨g,e⟩; rw [e]; exact storageReceiptPreserves q h g
 · rcases h38 with ⟨g,e⟩; rw [e]; exact bulkCleanupPreserves q h g
 · rw [h39]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem staleRoundCannotReturn (q : State) (stale : q.ack0≠q.round) : ¬returnPin0Guard q := by simp_all [returnPin0Guard]
theorem unknownWriterBlocksCleanup (q : State) (u : q.writer=2) : ¬bulkCleanupGuard q := by simp_all [bulkCleanupGuard]
theorem oldWriteCannotCommit (q : State) (old : q.seenWrite≠q.writeId) : ¬commitWriteGuard q := by simp_all [commitWriteGuard]
theorem closeRetainsAcceptedWriter (q : State) : (closeOwnerNext q).writer=q.writer ∧ (closeOwnerNext q).writerRoot=q.writerRoot := by constructor <;> rfl
theorem sourceReplacementKeepsOldTarget (q : State) : (commitWriteNext q).targetView0=q.targetView0 ∧ (commitWriteNext q).target0=q.target0 := by constructor <;> rfl
theorem nestedPinBlocksCleanup (q : State) (pin : q.pin1=1) : ¬bulkCleanupGuard q := by simp_all [bulkCleanupGuard]
theorem unknownGuardRetainsPin (q : State) (h : Safe q) (u : q.guard0=3) : q.pin0=1 ∧ q.target0=1 := by simp_all [Safe]
end SourceOwner

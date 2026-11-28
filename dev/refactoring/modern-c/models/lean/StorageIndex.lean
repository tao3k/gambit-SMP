import StorageIndexAst
namespace StorageIndex
open StorageIndexAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem chooseAdjacentPreserves (q : State) (h : Safe q) (g : chooseAdjacentGuard q) : Safe (chooseAdjacentNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,chooseAdjacentGuard,chooseAdjacentNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeAPreserves (q : State) (h : Safe q) (g : observeAGuard q) : Safe (observeANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,observeAGuard,observeANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveAPreserves (q : State) (h : Safe q) (g : reserveAGuard q) : Safe (reserveANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,reserveAGuard,reserveANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem prepareAPreserves (q : State) (h : Safe q) (g : prepareAGuard q) : Safe (prepareANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,prepareAGuard,prepareANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishAPreserves (q : State) (h : Safe q) (g : publishAGuard q) : Safe (publishANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,publishAGuard,publishANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem queryAPreserves (q : State) (h : Safe q) (g : queryAGuard q) : Safe (queryANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,queryAGuard,queryANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem borrowAPreserves (q : State) (h : Safe q) (g : borrowAGuard q) : Safe (borrowANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,borrowAGuard,borrowANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnAPreserves (q : State) (h : Safe q) (g : returnAGuard q) : Safe (returnANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,returnAGuard,returnANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scanAPreserves (q : State) (h : Safe q) (g : scanAGuard q) : Safe (scanANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,scanAGuard,scanANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishScanAPreserves (q : State) (h : Safe q) (g : finishScanAGuard q) : Safe (finishScanANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,finishScanAGuard,finishScanANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem revokeAPreserves (q : State) (h : Safe q) (g : revokeAGuard q) : Safe (revokeANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,revokeAGuard,revokeANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem drainAPreserves (q : State) (h : Safe q) (g : drainAGuard q) : Safe (drainANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,drainAGuard,drainANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortAPreserves (q : State) (h : Safe q) (g : abortAGuard q) : Safe (abortANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,abortAGuard,abortANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem settleAPreserves (q : State) (h : Safe q) (g : settleAGuard q) : Safe (settleANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,settleAGuard,settleANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectOldAPreserves (q : State) (h : Safe q) (g : rejectOldAGuard q) : Safe (rejectOldANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,rejectOldAGuard,rejectOldANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeBPreserves (q : State) (h : Safe q) (g : observeBGuard q) : Safe (observeBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,observeBGuard,observeBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveBPreserves (q : State) (h : Safe q) (g : reserveBGuard q) : Safe (reserveBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,reserveBGuard,reserveBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem prepareBPreserves (q : State) (h : Safe q) (g : prepareBGuard q) : Safe (prepareBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,prepareBGuard,prepareBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishBPreserves (q : State) (h : Safe q) (g : publishBGuard q) : Safe (publishBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,publishBGuard,publishBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem queryBPreserves (q : State) (h : Safe q) (g : queryBGuard q) : Safe (queryBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,queryBGuard,queryBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem borrowBPreserves (q : State) (h : Safe q) (g : borrowBGuard q) : Safe (borrowBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,borrowBGuard,borrowBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnBPreserves (q : State) (h : Safe q) (g : returnBGuard q) : Safe (returnBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,returnBGuard,returnBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scanBPreserves (q : State) (h : Safe q) (g : scanBGuard q) : Safe (scanBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,scanBGuard,scanBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishScanBPreserves (q : State) (h : Safe q) (g : finishScanBGuard q) : Safe (finishScanBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,finishScanBGuard,finishScanBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem revokeBPreserves (q : State) (h : Safe q) (g : revokeBGuard q) : Safe (revokeBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,revokeBGuard,revokeBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem drainBPreserves (q : State) (h : Safe q) (g : drainBGuard q) : Safe (drainBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,drainBGuard,drainBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortBPreserves (q : State) (h : Safe q) (g : abortBGuard q) : Safe (abortBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,abortBGuard,abortBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem settleBPreserves (q : State) (h : Safe q) (g : settleBGuard q) : Safe (settleBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,settleBGuard,settleBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectOldBPreserves (q : State) (h : Safe q) (g : rejectOldBGuard q) : Safe (rejectOldBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,rejectOldBGuard,rejectOldBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sourceWritePreserves (q : State) (h : Safe q) (g : sourceWriteGuard q) : Safe (sourceWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,sourceWriteGuard,sourceWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeIndexPreserves (q : State) (h : Safe q) (g : closeIndexGuard q) : Safe (closeIndexNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,closeIndexGuard,closeIndexNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reusePreserves (q : State) (h : Safe q) (g : reuseGuard q) : Safe (reuseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59⟩
 simp_all [Safe,reuseGuard,reuseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with g0 | g1 | g2 | g3 | g4 | g5 | g6 | g7 | g8 | g9 | g10 | g11 | g12 | g13 | g14 | g15 | g16 | g17 | g18 | g19 | g20 | g21 | g22 | g23 | g24 | g25 | g26 | g27 | g28 | g29 | g30 | g31 | g32
 · rcases g0 with ⟨guard, rfl⟩
   exact chooseAdjacentPreserves q h guard
 · rcases g1 with ⟨guard, rfl⟩
   exact observeAPreserves q h guard
 · rcases g2 with ⟨guard, rfl⟩
   exact reserveAPreserves q h guard
 · rcases g3 with ⟨guard, rfl⟩
   exact prepareAPreserves q h guard
 · rcases g4 with ⟨guard, rfl⟩
   exact publishAPreserves q h guard
 · rcases g5 with ⟨guard, rfl⟩
   exact queryAPreserves q h guard
 · rcases g6 with ⟨guard, rfl⟩
   exact borrowAPreserves q h guard
 · rcases g7 with ⟨guard, rfl⟩
   exact returnAPreserves q h guard
 · rcases g8 with ⟨guard, rfl⟩
   exact scanAPreserves q h guard
 · rcases g9 with ⟨guard, rfl⟩
   exact finishScanAPreserves q h guard
 · rcases g10 with ⟨guard, rfl⟩
   exact revokeAPreserves q h guard
 · rcases g11 with ⟨guard, rfl⟩
   exact drainAPreserves q h guard
 · rcases g12 with ⟨guard, rfl⟩
   exact abortAPreserves q h guard
 · rcases g13 with ⟨guard, rfl⟩
   exact settleAPreserves q h guard
 · rcases g14 with ⟨guard, rfl⟩
   exact rejectOldAPreserves q h guard
 · rcases g15 with ⟨guard, rfl⟩
   exact observeBPreserves q h guard
 · rcases g16 with ⟨guard, rfl⟩
   exact reserveBPreserves q h guard
 · rcases g17 with ⟨guard, rfl⟩
   exact prepareBPreserves q h guard
 · rcases g18 with ⟨guard, rfl⟩
   exact publishBPreserves q h guard
 · rcases g19 with ⟨guard, rfl⟩
   exact queryBPreserves q h guard
 · rcases g20 with ⟨guard, rfl⟩
   exact borrowBPreserves q h guard
 · rcases g21 with ⟨guard, rfl⟩
   exact returnBPreserves q h guard
 · rcases g22 with ⟨guard, rfl⟩
   exact scanBPreserves q h guard
 · rcases g23 with ⟨guard, rfl⟩
   exact finishScanBPreserves q h guard
 · rcases g24 with ⟨guard, rfl⟩
   exact revokeBPreserves q h guard
 · rcases g25 with ⟨guard, rfl⟩
   exact drainBPreserves q h guard
 · rcases g26 with ⟨guard, rfl⟩
   exact abortBPreserves q h guard
 · rcases g27 with ⟨guard, rfl⟩
   exact settleBPreserves q h guard
 · rcases g28 with ⟨guard, rfl⟩
   exact rejectOldBPreserves q h guard
 · rcases g29 with ⟨guard, rfl⟩
   exact sourceWritePreserves q h guard
 · rcases g30 with ⟨guard, rfl⟩
   exact closeIndexPreserves q h guard
 · rcases g31 with ⟨guard, rfl⟩
   exact reusePreserves q h guard
 · subst r; exact h
inductive Reachable : State → Prop where
 | initial : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | initial => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem unknownBlocksDrain (q : State) (u : q.aKnown = 0) : ¬ drainAGuard q := by simp [drainAGuard,u]
theorem staleSnapshotRejected (q : State) (u : q.bSnapshot ≠ q.revision) : ¬ reserveBGuard q := by simp [reserveBGuard,u]
theorem staleGenerationRejected (q : State) (u : q.aGeneration ≠ q.generation) : ¬ settleAGuard q := by simp [settleAGuard,u]
theorem generationAdvances (q : State) : (reuseNext q).generation > q.generation := by simp [reuseNext]; omega
theorem pendingOverlapRejected (q : State) (a : q.a = 1) (o : q.adjacent = 0) : ¬ reserveBGuard q := by simp [reserveBGuard,a,o]
theorem revokeRetainsLease (q : State) : (revokeANext q).aLease = q.aLease := rfl
theorem queryPreservesCustody (q : State) : (queryANext q).aLease = q.aLease := rfl
theorem duplicateSettlementRejected (q : State) (u : q.a = 5) : ¬ settleAGuard q := by simp [settleAGuard,u]
end StorageIndex

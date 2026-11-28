import SourcePinAst
namespace SourcePin
open SourcePinAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem pinOuterPreserves (q : State) (h : Safe q) (g : pinOuterGuard q) : Safe (pinOuterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,pinOuterGuard,pinOuterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem pinNestedPreserves (q : State) (h : Safe q) (g : pinNestedGuard q) : Safe (pinNestedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,pinNestedGuard,pinNestedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeSourcePreserves (q : State) (h : Safe q) (g : closeSourceGuard q) : Safe (closeSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,closeSourceGuard,closeSourceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectLatePinPreserves (q : State) (h : Safe q) (g : rejectLatePinGuard q) : Safe (rejectLatePinNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,rejectLatePinGuard,rejectLatePinNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem copy0Preserves (q : State) (h : Safe q) (g : copy0Guard q) : Safe (copy0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,copy0Guard,copy0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem refresh0Preserves (q : State) (h : Safe q) (g : refresh0Guard q) : Safe (refresh0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,refresh0Guard,refresh0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enroll0Preserves (q : State) (h : Safe q) (g : enroll0Guard q) : Safe (enroll0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,enroll0Guard,enroll0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveGuard0Preserves (q : State) (h : Safe q) (g : reserveGuard0Guard q) : Safe (reserveGuard0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,reserveGuard0Guard,reserveGuard0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitGuard0Preserves (q : State) (h : Safe q) (g : commitGuard0Guard q) : Safe (commitGuard0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,commitGuard0Guard,commitGuard0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem lostReservation0Preserves (q : State) (h : Safe q) (g : lostReservation0Guard q) : Safe (lostReservation0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,lostReservation0Guard,lostReservation0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveCommitted0Preserves (q : State) (h : Safe q) (g : resolveCommitted0Guard q) : Safe (resolveCommitted0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,resolveCommitted0Guard,resolveCommitted0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveFailed0Preserves (q : State) (h : Safe q) (g : resolveFailed0Guard q) : Safe (resolveFailed0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,resolveFailed0Guard,resolveFailed0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem queryAck0Preserves (q : State) (h : Safe q) (g : queryAck0Guard q) : Safe (queryAck0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp only [queryAck0Guard] at g
 rcases g with g | g <;> simp_all [Safe,queryAck0Guard,queryAck0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnPin0Preserves (q : State) (h : Safe q) (g : returnPin0Guard q) : Safe (returnPin0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,returnPin0Guard,returnPin0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem repeatReturn0Preserves (q : State) (h : Safe q) (g : repeatReturn0Guard q) : Safe (repeatReturn0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,repeatReturn0Guard,repeatReturn0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortBeforeGuard0Preserves (q : State) (h : Safe q) (g : abortBeforeGuard0Guard q) : Safe (abortBeforeGuard0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,abortBeforeGuard0Guard,abortBeforeGuard0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem outerExit0Preserves (q : State) (h : Safe q) (g : outerExit0Guard q) : Safe (outerExit0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,outerExit0Guard,outerExit0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireCarrier0Preserves (q : State) (h : Safe q) (g : retireCarrier0Guard q) : Safe (retireCarrier0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,retireCarrier0Guard,retireCarrier0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem copy1Preserves (q : State) (h : Safe q) (g : copy1Guard q) : Safe (copy1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,copy1Guard,copy1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem refresh1Preserves (q : State) (h : Safe q) (g : refresh1Guard q) : Safe (refresh1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,refresh1Guard,refresh1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enroll1Preserves (q : State) (h : Safe q) (g : enroll1Guard q) : Safe (enroll1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,enroll1Guard,enroll1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveGuard1Preserves (q : State) (h : Safe q) (g : reserveGuard1Guard q) : Safe (reserveGuard1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,reserveGuard1Guard,reserveGuard1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitGuard1Preserves (q : State) (h : Safe q) (g : commitGuard1Guard q) : Safe (commitGuard1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,commitGuard1Guard,commitGuard1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem lostReservation1Preserves (q : State) (h : Safe q) (g : lostReservation1Guard q) : Safe (lostReservation1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,lostReservation1Guard,lostReservation1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveCommitted1Preserves (q : State) (h : Safe q) (g : resolveCommitted1Guard q) : Safe (resolveCommitted1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,resolveCommitted1Guard,resolveCommitted1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveFailed1Preserves (q : State) (h : Safe q) (g : resolveFailed1Guard q) : Safe (resolveFailed1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,resolveFailed1Guard,resolveFailed1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem queryAck1Preserves (q : State) (h : Safe q) (g : queryAck1Guard q) : Safe (queryAck1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp only [queryAck1Guard] at g
 rcases g with g | g <;> simp_all [Safe,queryAck1Guard,queryAck1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnPin1Preserves (q : State) (h : Safe q) (g : returnPin1Guard q) : Safe (returnPin1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,returnPin1Guard,returnPin1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem repeatReturn1Preserves (q : State) (h : Safe q) (g : repeatReturn1Guard q) : Safe (repeatReturn1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,repeatReturn1Guard,repeatReturn1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortBeforeGuard1Preserves (q : State) (h : Safe q) (g : abortBeforeGuard1Guard q) : Safe (abortBeforeGuard1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,abortBeforeGuard1Guard,abortBeforeGuard1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem outerExit1Preserves (q : State) (h : Safe q) (g : outerExit1Guard q) : Safe (outerExit1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,outerExit1Guard,outerExit1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireCarrier1Preserves (q : State) (h : Safe q) (g : retireCarrier1Guard q) : Safe (retireCarrier1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,retireCarrier1Guard,retireCarrier1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireSourcePreserves (q : State) (h : Safe q) (g : retireSourceGuard q) : Safe (retireSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,retireSourceGuard,retireSourceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeGcPreserves (q : State) (h : Safe q) (g : freezeGcGuard q) : Safe (freezeGcNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,freezeGcGuard,freezeGcNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishGcNonePreserves (q : State) (h : Safe q) (g : finishGcNoneGuard q) : Safe (finishGcNoneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,finishGcNoneGuard,finishGcNoneNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishGcOuterPreserves (q : State) (h : Safe q) (g : finishGcOuterGuard q) : Safe (finishGcOuterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,finishGcOuterGuard,finishGcOuterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishGcNestedPreserves (q : State) (h : Safe q) (g : finishGcNestedGuard q) : Safe (finishGcNestedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,finishGcNestedGuard,finishGcNestedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishGcBothPreserves (q : State) (h : Safe q) (g : finishGcBothGuard q) : Safe (finishGcBothNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57⟩
 simp_all [Safe,finishGcBothGuard,finishGcBothNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36 | h37 | h38
 · rcases h0 with ⟨g,e⟩; rw [e]; exact pinOuterPreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact pinNestedPreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact closeSourcePreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact rejectLatePinPreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact copy0Preserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact refresh0Preserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact enroll0Preserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact reserveGuard0Preserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact commitGuard0Preserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact lostReservation0Preserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact resolveCommitted0Preserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact resolveFailed0Preserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact queryAck0Preserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact returnPin0Preserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact repeatReturn0Preserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact abortBeforeGuard0Preserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact outerExit0Preserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact retireCarrier0Preserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact copy1Preserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact refresh1Preserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact enroll1Preserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact reserveGuard1Preserves q h g
 · rcases h22 with ⟨g,e⟩; rw [e]; exact commitGuard1Preserves q h g
 · rcases h23 with ⟨g,e⟩; rw [e]; exact lostReservation1Preserves q h g
 · rcases h24 with ⟨g,e⟩; rw [e]; exact resolveCommitted1Preserves q h g
 · rcases h25 with ⟨g,e⟩; rw [e]; exact resolveFailed1Preserves q h g
 · rcases h26 with ⟨g,e⟩; rw [e]; exact queryAck1Preserves q h g
 · rcases h27 with ⟨g,e⟩; rw [e]; exact returnPin1Preserves q h g
 · rcases h28 with ⟨g,e⟩; rw [e]; exact repeatReturn1Preserves q h g
 · rcases h29 with ⟨g,e⟩; rw [e]; exact abortBeforeGuard1Preserves q h g
 · rcases h30 with ⟨g,e⟩; rw [e]; exact outerExit1Preserves q h g
 · rcases h31 with ⟨g,e⟩; rw [e]; exact retireCarrier1Preserves q h g
 · rcases h32 with ⟨g,e⟩; rw [e]; exact retireSourcePreserves q h g
 · rcases h33 with ⟨g,e⟩; rw [e]; exact freezeGcPreserves q h g
 · rcases h34 with ⟨g,e⟩; rw [e]; exact finishGcNonePreserves q h g
 · rcases h35 with ⟨g,e⟩; rw [e]; exact finishGcOuterPreserves q h g
 · rcases h36 with ⟨g,e⟩; rw [e]; exact finishGcNestedPreserves q h g
 · rcases h37 with ⟨g,e⟩; rw [e]; exact finishGcBothPreserves q h g
 · rw [h38]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem noRetireWithOuterPin (q : State) (pin : q.pin0=1) : ¬retireSourceGuard q := by simp_all [retireSourceGuard]
theorem noRetireWithNestedPin (q : State) (pin : q.pin1=1) : ¬retireSourceGuard q := by simp_all [retireSourceGuard]
theorem staleCandidateCannotEnroll (q : State) (stale : q.value0≠q.epoch) : ¬enroll0Guard q := by simp_all [enroll0Guard]
theorem unknownRetainsCustody (q : State) (h : Safe q) (u : q.guard0=3) : q.pin0=1 ∧ q.carrier0=2 ∧ q.alive=1 := by simp_all [Safe]
theorem duplicateReturnPreservesChild (q : State) : (repeatReturn0Next q).pin1=q.pin1 := by rfl
theorem enrolledCarrierFresh (q : State) (h : Safe q) (e : q.carrier0=2) : q.value0=q.epoch := by simp_all [Safe]
theorem closedSourceRejectsPin (q : State) (closed : q.gate=0) : ¬pinOuterGuard q := by simp_all [pinOuterGuard]
theorem sourceReleaseOutsideScan (q : State) (g : retireSourceGuard q) : q.gc=0 := by simp_all [retireSourceGuard]
end SourcePin

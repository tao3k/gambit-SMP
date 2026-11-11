import RestoreEntryAst
namespace RestoreEntry
open RestoreEntryAst
set_option maxHeartbeats 5000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem reserveInitial0Preserves (q : State) (h : Safe q) (g : reserveInitial0Guard q) : Safe (reserveInitial0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,reserveInitial0Guard,reserveInitial0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishRoot0Preserves (q : State) (h : Safe q) (g : publishRoot0Guard q) : Safe (publishRoot0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,publishRoot0Guard,publishRoot0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enterInitial0Preserves (q : State) (h : Safe q) (g : enterInitial0Guard q) : Safe (enterInitial0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,enterInitial0Guard,enterInitial0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem internalGraft0Preserves (q : State) (h : Safe q) (g : internalGraft0Guard q) : Safe (internalGraft0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,internalGraft0Guard,internalGraft0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem suspend0Preserves (q : State) (h : Safe q) (g : suspend0Guard q) : Safe (suspend0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,suspend0Guard,suspend0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem schedulerResume0Preserves (q : State) (h : Safe q) (g : schedulerResume0Guard q) : Safe (schedulerResume0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,schedulerResume0Guard,schedulerResume0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem bodyReturn0Preserves (q : State) (h : Safe q) (g : bodyReturn0Guard q) : Safe (bodyReturn0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,bodyReturn0Guard,bodyReturn0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem restoreOuter0Preserves (q : State) (h : Safe q) (g : restoreOuter0Guard q) : Safe (restoreOuter0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,restoreOuter0Guard,restoreOuter0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeExit0Preserves (q : State) (h : Safe q) (g : observeExit0Guard q) : Safe (observeExit0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,observeExit0Guard,observeExit0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem settle0Preserves (q : State) (h : Safe q) (g : settle0Guard q) : Safe (settle0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,settle0Guard,settle0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveSemantic1Preserves (q : State) (h : Safe q) (g : reserveSemantic1Guard q) : Safe (reserveSemantic1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,reserveSemantic1Guard,reserveSemantic1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveCrossRestore1Preserves (q : State) (h : Safe q) (g : reserveCrossRestore1Guard q) : Safe (reserveCrossRestore1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,reserveCrossRestore1Guard,reserveCrossRestore1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveForeignChild1Preserves (q : State) (h : Safe q) (g : reserveForeignChild1Guard q) : Safe (reserveForeignChild1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,reserveForeignChild1Guard,reserveForeignChild1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishRoot1Preserves (q : State) (h : Safe q) (g : publishRoot1Guard q) : Safe (publishRoot1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,publishRoot1Guard,publishRoot1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem allocateMarker1Preserves (q : State) (h : Safe q) (g : allocateMarker1Guard q) : Safe (allocateMarker1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,allocateMarker1Guard,allocateMarker1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enter1Preserves (q : State) (h : Safe q) (g : enter1Guard q) : Safe (enter1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,enter1Guard,enter1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem internalGraft1Preserves (q : State) (h : Safe q) (g : internalGraft1Guard q) : Safe (internalGraft1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,internalGraft1Guard,internalGraft1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem bodyReturn1Preserves (q : State) (h : Safe q) (g : bodyReturn1Guard q) : Safe (bodyReturn1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,bodyReturn1Guard,bodyReturn1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem restoreOuter1Preserves (q : State) (h : Safe q) (g : restoreOuter1Guard q) : Safe (restoreOuter1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,restoreOuter1Guard,restoreOuter1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem invalidateMarker1Preserves (q : State) (h : Safe q) (g : invalidateMarker1Guard q) : Safe (invalidateMarker1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,invalidateMarker1Guard,invalidateMarker1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeExit1Preserves (q : State) (h : Safe q) (g : observeExit1Guard q) : Safe (observeExit1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,observeExit1Guard,observeExit1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem settle1Preserves (q : State) (h : Safe q) (g : settle1Guard q) : Safe (settle1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,settle1Guard,settle1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortMarkerAllocation1Preserves (q : State) (h : Safe q) (g : abortMarkerAllocation1Guard q) : Safe (abortMarkerAllocation1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,abortMarkerAllocation1Guard,abortMarkerAllocation1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownForeignExit1Preserves (q : State) (h : Safe q) (g : unknownForeignExit1Guard q) : Safe (unknownForeignExit1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,unknownForeignExit1Guard,unknownForeignExit1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem confirmOuterCatch1Preserves (q : State) (h : Safe q) (g : confirmOuterCatch1Guard q) : Safe (confirmOuterCatch1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,confirmOuterCatch1Guard,confirmOuterCatch1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem presentOldPreserves (q : State) (h : Safe q) (g : presentOldGuard q) : Safe (presentOldNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,presentOldGuard,presentOldNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem presentNewPreserves (q : State) (h : Safe q) (g : presentNewGuard q) : Safe (presentNewNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,presentNewGuard,presentNewNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem presentOldAsNewPreserves (q : State) (h : Safe q) (g : presentOldAsNewGuard q) : Safe (presentOldAsNewNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,presentOldAsNewGuard,presentOldAsNewNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectMismatchedGuardPreserves (q : State) (h : Safe q) (g : rejectMismatchedGuardGuard q) : Safe (rejectMismatchedGuardNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,rejectMismatchedGuardGuard,rejectMismatchedGuardNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem repeatOldReceiptPreserves (q : State) (h : Safe q) (g : repeatOldReceiptGuard q) : Safe (repeatOldReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,repeatOldReceiptGuard,repeatOldReceiptNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectUnobservedOldExitPreserves (q : State) (h : Safe q) (g : rejectUnobservedOldExitGuard q) : Safe (rejectUnobservedOldExitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,rejectUnobservedOldExitGuard,rejectUnobservedOldExitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem loseReply0Preserves (q : State) (h : Safe q) (g : loseReply0Guard q) : Safe (loseReply0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,loseReply0Guard,loseReply0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem query0Preserves (q : State) (h : Safe q) (g : query0Guard q) : Safe (query0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,query0Guard,query0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem loseReply1Preserves (q : State) (h : Safe q) (g : loseReply1Guard q) : Safe (loseReply1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,loseReply1Guard,loseReply1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem query1Preserves (q : State) (h : Safe q) (g : query1Guard q) : Safe (query1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48⟩
 cases m : q.markerLive1 <;> simp_all [Safe,query1Guard,query1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35
 · rcases h0 with ⟨g,e⟩; rw [e]; exact reserveInitial0Preserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact publishRoot0Preserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact enterInitial0Preserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact internalGraft0Preserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact suspend0Preserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact schedulerResume0Preserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact bodyReturn0Preserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact restoreOuter0Preserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact observeExit0Preserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact settle0Preserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact reserveSemantic1Preserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact reserveCrossRestore1Preserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact reserveForeignChild1Preserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact publishRoot1Preserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact allocateMarker1Preserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact enter1Preserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact internalGraft1Preserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact bodyReturn1Preserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact restoreOuter1Preserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact invalidateMarker1Preserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact observeExit1Preserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact settle1Preserves q h g
 · rcases h22 with ⟨g,e⟩; rw [e]; exact abortMarkerAllocation1Preserves q h g
 · rcases h23 with ⟨g,e⟩; rw [e]; exact unknownForeignExit1Preserves q h g
 · rcases h24 with ⟨g,e⟩; rw [e]; exact confirmOuterCatch1Preserves q h g
 · rcases h25 with ⟨g,e⟩; rw [e]; exact presentOldPreserves q h g
 · rcases h26 with ⟨g,e⟩; rw [e]; exact presentNewPreserves q h g
 · rcases h27 with ⟨g,e⟩; rw [e]; exact presentOldAsNewPreserves q h g
 · rcases h28 with ⟨g,e⟩; rw [e]; exact rejectMismatchedGuardPreserves q h g
 · rcases h29 with ⟨g,e⟩; rw [e]; exact repeatOldReceiptPreserves q h g
 · rcases h30 with ⟨g,e⟩; rw [e]; exact rejectUnobservedOldExitPreserves q h g
 · rcases h31 with ⟨g,e⟩; rw [e]; exact loseReply0Preserves q h g
 · rcases h32 with ⟨g,e⟩; rw [e]; exact query0Preserves q h g
 · rcases h33 with ⟨g,e⟩; rw [e]; exact loseReply1Preserves q h g
 · rcases h34 with ⟨g,e⟩; rw [e]; exact query1Preserves q h g
 · rw [h35]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem schedulerPreservesTicket (q : State) : (schedulerResume0Next q).t0issued=q.t0issued ∧ (schedulerResume0Next q).t0guard=q.t0guard := by constructor <;> rfl
theorem navigationPreservesTicket (q : State) : (internalGraft0Next q).t0issued=q.t0issued := by rfl
theorem oldReceiptCannotSettleNew (q : State) : (repeatOldReceiptNext q).t1phase=q.t1phase ∧ (repeatOldReceiptNext q).t1settles=q.t1settles := by constructor <;> rfl
theorem newSettlementNeedsNewGuard (q : State) (g : settle1Guard q) : q.presented=2 ∧ q.nonce=102 := by simp_all [settle1Guard]
theorem oldNonceCannotSettleNew (q : State) (old : q.nonce=101) : ¬settle1Guard q := by simp_all [settle1Guard]
theorem completionRequiresRestoration (q : State) (h : Safe q) (done : q.t1phase=6) : q.t1restored=true ∧ q.markerLive1=false := by simp_all [Safe]
theorem unknownRetainsGuard (q : State) (h : Safe q) (u : q.t1phase=7) : q.t1guard=true ∧ q.t1settles=0 := by simp_all [Safe]
theorem queryKeepsInvocation (q : State) : (query0Next q).t0issued=q.t0issued := by rfl
theorem bodyReturnHasNoWitness (q : State) : (bodyReturn1Next q).t1witness=q.t1witness := by rfl
theorem atMostOnce (q : State) (h : Safe q) : q.t0settles≤1 ∧ q.t1settles≤1 := by simp_all [Safe]
end RestoreEntry

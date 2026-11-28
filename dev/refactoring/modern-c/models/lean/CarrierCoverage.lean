import CarrierCoverageAst
namespace CarrierCoverage
open CarrierCoverageAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem admitManagedWritersPreserves (q : State) (h : Safe q) (g : admitManagedWritersGuard q) : Safe (admitManagedWritersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,admitManagedWritersGuard,admitManagedWritersNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveCarrierPreserves (q : State) (h : Safe q) (g : reserveCarrierGuard q) : Safe (reserveCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,reserveCarrierGuard,reserveCarrierNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem initializeCarrierPreserves (q : State) (h : Safe q) (g : initializeCarrierGuard q) : Safe (initializeCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,initializeCarrierGuard,initializeCarrierNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishCarrierPreserves (q : State) (h : Safe q) (g : publishCarrierGuard q) : Safe (publishCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,publishCarrierGuard,publishCarrierNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem queryPublicationPreserves (q : State) (h : Safe q) (g : queryPublicationGuard q) : Safe (queryPublicationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,queryPublicationGuard,queryPublicationNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnSourcePinPreserves (q : State) (h : Safe q) (g : returnSourcePinGuard q) : Safe (returnSourcePinNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,returnSourcePinGuard,returnSourcePinNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem borrowPayloadPreserves (q : State) (h : Safe q) (g : borrowPayloadGuard q) : Safe (borrowPayloadNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,borrowPayloadGuard,borrowPayloadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnPayloadPreserves (q : State) (h : Safe q) (g : returnPayloadGuard q) : Safe (returnPayloadNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,returnPayloadGuard,returnPayloadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeReceiptPreserves (q : State) (h : Safe q) (g : observeReceiptGuard q) : Safe (observeReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,observeReceiptGuard,observeReceiptNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem releaseObserverPreserves (q : State) (h : Safe q) (g : releaseObserverGuard q) : Safe (releaseObserverNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,releaseObserverGuard,releaseObserverNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem revokeCarrierPreserves (q : State) (h : Safe q) (g : revokeCarrierGuard q) : Safe (revokeCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,revokeCarrierGuard,revokeCarrierNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeSourcePreserves (q : State) (h : Safe q) (g : closeSourceGuard q) : Safe (closeSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,closeSourceGuard,closeSourceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem managedSetterPreserves (q : State) (h : Safe q) (g : managedSetterGuard q) : Safe (managedSetterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,managedSetterGuard,managedSetterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem recordRawInterferencePreserves (q : State) (h : Safe q) (g : recordRawInterferenceGuard q) : Safe (recordRawInterferenceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,recordRawInterferenceGuard,recordRawInterferenceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem storageHandoffPreserves (q : State) (h : Safe q) (g : storageHandoffGuard q) : Safe (storageHandoffNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,storageHandoffGuard,storageHandoffNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem cleanupSourcePreserves (q : State) (h : Safe q) (g : cleanupSourceGuard q) : Safe (cleanupSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,cleanupSourceGuard,cleanupSourceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireCarrierPreserves (q : State) (h : Safe q) (g : retireCarrierGuard q) : Safe (retireCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,retireCarrierGuard,retireCarrierNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem shrinkProcessorsPreserves (q : State) (h : Safe q) (g : shrinkProcessorsGuard q) : Safe (shrinkProcessorsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,shrinkProcessorsGuard,shrinkProcessorsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeBothPreserves (q : State) (h : Safe q) (g : freezeBothGuard q) : Safe (freezeBothNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 rcases g with ⟨g0, gprivate, ga, gb⟩
 clear gprivate
 simp_all [Safe,freezeBothGuard,freezeBothNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeSourcePreserves (q : State) (h : Safe q) (g : freezeSourceGuard q) : Safe (freezeSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 rcases g with ⟨g0, gprivate, ga, gb⟩
 clear gprivate
 simp_all [Safe,freezeSourceGuard,freezeSourceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeCarrierPreserves (q : State) (h : Safe q) (g : freezeCarrierGuard q) : Safe (freezeCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 rcases g with ⟨g0, gprivate, ga, gb⟩
 clear gprivate
 simp_all [Safe,freezeCarrierGuard,freezeCarrierNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeNeitherPreserves (q : State) (h : Safe q) (g : freezeNeitherGuard q) : Safe (freezeNeitherNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 rcases g with ⟨g0, gprivate, ga, gb⟩
 clear gprivate
 simp_all [Safe,freezeNeitherGuard,freezeNeitherNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem claim0Preserves (q : State) (h : Safe q) (g : claim0Guard q) : Safe (claim0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,claim0Guard,claim0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scanDone0Preserves (q : State) (h : Safe q) (g : scanDone0Guard q) : Safe (scanDone0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,scanDone0Guard,scanDone0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scanUnknown0Preserves (q : State) (h : Safe q) (g : scanUnknown0Guard q) : Safe (scanUnknown0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,scanUnknown0Guard,scanUnknown0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveScan0Preserves (q : State) (h : Safe q) (g : resolveScan0Guard q) : Safe (resolveScan0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,resolveScan0Guard,resolveScan0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem claim1Preserves (q : State) (h : Safe q) (g : claim1Guard q) : Safe (claim1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,claim1Guard,claim1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scanDone1Preserves (q : State) (h : Safe q) (g : scanDone1Guard q) : Safe (scanDone1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,scanDone1Guard,scanDone1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scanUnknown1Preserves (q : State) (h : Safe q) (g : scanUnknown1Guard q) : Safe (scanUnknown1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,scanUnknown1Guard,scanUnknown1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveScan1Preserves (q : State) (h : Safe q) (g : resolveScan1Guard q) : Safe (resolveScan1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,resolveScan1Guard,resolveScan1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishRoundPreserves (q : State) (h : Safe q) (g : finishRoundGuard q) : Safe (finishRoundNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68⟩
 simp_all [Safe,finishRoundGuard,finishRoundNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31
 · rcases h0 with ⟨g,e⟩; rw [e]; exact admitManagedWritersPreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact reserveCarrierPreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact initializeCarrierPreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact publishCarrierPreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact queryPublicationPreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact returnSourcePinPreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact borrowPayloadPreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact returnPayloadPreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact observeReceiptPreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact releaseObserverPreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact revokeCarrierPreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact closeSourcePreserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact managedSetterPreserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact recordRawInterferencePreserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact storageHandoffPreserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact cleanupSourcePreserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact retireCarrierPreserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact shrinkProcessorsPreserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact freezeBothPreserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact freezeSourcePreserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact freezeCarrierPreserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact freezeNeitherPreserves q h g
 · rcases h22 with ⟨g,e⟩; rw [e]; exact claim0Preserves q h g
 · rcases h23 with ⟨g,e⟩; rw [e]; exact scanDone0Preserves q h g
 · rcases h24 with ⟨g,e⟩; rw [e]; exact scanUnknown0Preserves q h g
 · rcases h25 with ⟨g,e⟩; rw [e]; exact resolveScan0Preserves q h g
 · rcases h26 with ⟨g,e⟩; rw [e]; exact claim1Preserves q h g
 · rcases h27 with ⟨g,e⟩; rw [e]; exact scanDone1Preserves q h g
 · rcases h28 with ⟨g,e⟩; rw [e]; exact scanUnknown1Preserves q h g
 · rcases h29 with ⟨g,e⟩; rw [e]; exact resolveScan1Preserves q h g
 · rcases h30 with ⟨g,e⟩; rw [e]; exact finishRoundPreserves q h g
 · rw [h31]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem activeCarrierEnumerated (q : State) (h : Safe q) (gc : q.gc=1) (live : q.d1=2 ∨ q.d1=3) : q.snap1=1 := by simp_all [Safe]
theorem closingCarrierRetained (q : State) (h : Safe q) (closed : q.d1=3) : q.mem1=1 := by simp_all [Safe]
theorem readerRetainsDescriptor (q : State) (h : Safe q) (reading : q.read1>0) : q.mem1=1 ∧ q.gc=1 := by simp_all [Safe]
theorem unknownScanBlocksFinish (q : State) (unknown : q.read1=2) : ¬finishRoundGuard q := by simp_all [finishRoundGuard]
theorem observerBlocksRetirement (q : State) (observer : q.observe1=1) : ¬retireCarrierGuard q := by simp_all [retireCarrierGuard]
theorem interferenceBlocksAdmission (q : State) (raw : q.rawUnknown=1) : ¬borrowPayloadGuard q := by simp_all [borrowPayloadGuard]
theorem setterPreservesOldBinding (q : State) : (managedSetterNext q).payload1=q.payload1 := by rfl
theorem shrinkPreservesRegistration (q : State) : (shrinkProcessorsNext q).d1=q.d1 := by rfl
theorem unknownPublicationRetainsSource (q : State) (unknown : q.known1=0) : ¬returnSourcePinGuard q := by simp_all [returnSourcePinGuard]
end CarrierCoverage

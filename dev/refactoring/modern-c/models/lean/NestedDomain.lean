import NestedDomainAst
namespace NestedDomain
open NestedDomainAst
set_option maxRecDepth 10000
set_option linter.unusedSimpArgs false
theorem publishRootsPreserves (q : State) (h : Safe q) (g : publishRootsGuard q) : Safe (publishRootsNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,publishRootsGuard,publishRootsNext]
 all_goals omega
theorem publicationReplyLostPreserves (q : State) (h : Safe q) (g : publicationReplyLostGuard q) : Safe (publicationReplyLostNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,publicationReplyLostGuard,publicationReplyLostNext]
 all_goals omega
theorem publicationAbsentUnknownPreserves (q : State) (h : Safe q) (g : publicationAbsentUnknownGuard q) : Safe (publicationAbsentUnknownNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,publicationAbsentUnknownGuard,publicationAbsentUnknownNext]
 all_goals omega
theorem resolvePublicationPreserves (q : State) (h : Safe q) (g : resolvePublicationGuard q) : Safe (resolvePublicationNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,resolvePublicationGuard,resolvePublicationNext]
 all_goals omega
theorem acknowledgeRootsPreserves (q : State) (h : Safe q) (g : acknowledgeRootsGuard q) : Safe (acknowledgeRootsNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,acknowledgeRootsGuard,acknowledgeRootsNext]
 all_goals omega
theorem releaseSourcePreserves (q : State) (h : Safe q) (g : releaseSourceGuard q) : Safe (releaseSourceNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,releaseSourceGuard,releaseSourceNext]
 all_goals omega
theorem enterOuterPreserves (q : State) (h : Safe q) (g : enterOuterGuard q) : Safe (enterOuterNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,enterOuterGuard,enterOuterNext]
 all_goals omega
theorem reserveInnerOfferPreserves (q : State) (h : Safe q) (g : reserveInnerOfferGuard q) : Safe (reserveInnerOfferNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,reserveInnerOfferGuard,reserveInnerOfferNext]
 all_goals omega
theorem publishInnerRootsPreserves (q : State) (h : Safe q) (g : publishInnerRootsGuard q) : Safe (publishInnerRootsNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,publishInnerRootsGuard,publishInnerRootsNext]
 all_goals omega
theorem acknowledgeInnerRootsPreserves (q : State) (h : Safe q) (g : acknowledgeInnerRootsGuard q) : Safe (acknowledgeInnerRootsNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,acknowledgeInnerRootsGuard,acknowledgeInnerRootsNext]
 all_goals omega
theorem releaseInnerSourcePreserves (q : State) (h : Safe q) (g : releaseInnerSourceGuard q) : Safe (releaseInnerSourceNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,releaseInnerSourceGuard,releaseInnerSourceNext]
 all_goals omega
theorem enterInnerPreserves (q : State) (h : Safe q) (g : enterInnerGuard q) : Safe (enterInnerNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,enterInnerGuard,enterInnerNext]
 all_goals omega
theorem captureInnerPreserves (q : State) (h : Safe q) (g : captureInnerGuard q) : Safe (captureInnerNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,captureInnerGuard,captureInnerNext]
 all_goals omega
theorem startGcReaderPreserves (q : State) (h : Safe q) (g : startGcReaderGuard q) : Safe (startGcReaderNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,startGcReaderGuard,startGcReaderNext]
 all_goals omega
theorem finishGcReaderPreserves (q : State) (h : Safe q) (g : finishGcReaderGuard q) : Safe (finishGcReaderNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,finishGcReaderGuard,finishGcReaderNext]
 all_goals omega
theorem escrowOuterUnwindPreserves (q : State) (h : Safe q) (g : escrowOuterUnwindGuard q) : Safe (escrowOuterUnwindNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,escrowOuterUnwindGuard,escrowOuterUnwindNext]
 all_goals omega
theorem issueOuterUnwindPreserves (q : State) (h : Safe q) (g : issueOuterUnwindGuard q) : Safe (issueOuterUnwindNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,issueOuterUnwindGuard,issueOuterUnwindNext]
 all_goals omega
theorem landingObservedPreserves (q : State) (h : Safe q) (g : landingObservedGuard q) : Safe (landingObservedNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,landingObservedGuard,landingObservedNext]
 all_goals omega
theorem landingReplyLostPreserves (q : State) (h : Safe q) (g : landingReplyLostGuard q) : Safe (landingReplyLostNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,landingReplyLostGuard,landingReplyLostNext]
 all_goals omega
theorem reconcileLandingPreserves (q : State) (h : Safe q) (g : reconcileLandingGuard q) : Safe (reconcileLandingNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,reconcileLandingGuard,reconcileLandingNext]
 all_goals omega
theorem settleInnerGuardPreserves (q : State) (h : Safe q) (g : settleInnerGuardGuard q) : Safe (settleInnerGuardNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,settleInnerGuardGuard,settleInnerGuardNext]
 all_goals omega
theorem settleOuterGuardPreserves (q : State) (h : Safe q) (g : settleOuterGuardGuard q) : Safe (settleOuterGuardNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,settleOuterGuardGuard,settleOuterGuardNext]
 all_goals omega
theorem resumeCapturedPreserves (q : State) (h : Safe q) (g : resumeCapturedGuard q) : Safe (resumeCapturedNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,resumeCapturedGuard,resumeCapturedNext]
 all_goals omega
theorem rejectInnerReturnPreserves (q : State) (h : Safe q) (g : rejectInnerReturnGuard q) : Safe (rejectInnerReturnNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,rejectInnerReturnGuard,rejectInnerReturnNext]
 all_goals omega
theorem finishResumptionPreserves (q : State) (h : Safe q) (g : finishResumptionGuard q) : Safe (finishResumptionNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,finishResumptionGuard,finishResumptionNext]
 all_goals omega
theorem closeCapturedHoldersPreserves (q : State) (h : Safe q) (g : closeCapturedHoldersGuard q) : Safe (closeCapturedHoldersNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,closeCapturedHoldersGuard,closeCapturedHoldersNext]
 all_goals omega
theorem closeRootAdmissionPreserves (q : State) (h : Safe q) (g : closeRootAdmissionGuard q) : Safe (closeRootAdmissionNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,closeRootAdmissionGuard,closeRootAdmissionNext]
 all_goals omega
theorem closeCodeAdmissionPreserves (q : State) (h : Safe q) (g : closeCodeAdmissionGuard q) : Safe (closeCodeAdmissionNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,closeCodeAdmissionGuard,closeCodeAdmissionNext]
 all_goals omega
theorem ackRootGracePreserves (q : State) (h : Safe q) (g : ackRootGraceGuard q) : Safe (ackRootGraceNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,ackRootGraceGuard,ackRootGraceNext]
 all_goals omega
theorem retireRootSlotsPreserves (q : State) (h : Safe q) (g : retireRootSlotsGuard q) : Safe (retireRootSlotsNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,retireRootSlotsGuard,retireRootSlotsNext]
 all_goals omega
theorem ackCodeGracePreserves (q : State) (h : Safe q) (g : ackCodeGraceGuard q) : Safe (ackCodeGraceNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,ackCodeGraceGuard,ackCodeGraceNext]
 all_goals omega
theorem retireDescriptorPreserves (q : State) (h : Safe q) (g : retireDescriptorGuard q) : Safe (retireDescriptorNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,retireDescriptorGuard,retireDescriptorNext]
 all_goals omega
theorem detachNativeOwnerPreserves (q : State) (h : Safe q) (g : detachNativeOwnerGuard q) : Safe (detachNativeOwnerNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78,h79,h80,h81,h82,h83⟩
 simp_all [Safe,detachNativeOwnerGuard,detachNativeOwnerNext]
 all_goals omega
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · exact g.2.symm ▸ publishRootsPreserves q h g.1
 · exact g.2.symm ▸ publicationReplyLostPreserves q h g.1
 · exact g.2.symm ▸ publicationAbsentUnknownPreserves q h g.1
 · exact g.2.symm ▸ resolvePublicationPreserves q h g.1
 · exact g.2.symm ▸ acknowledgeRootsPreserves q h g.1
 · exact g.2.symm ▸ releaseSourcePreserves q h g.1
 · exact g.2.symm ▸ enterOuterPreserves q h g.1
 · exact g.2.symm ▸ reserveInnerOfferPreserves q h g.1
 · exact g.2.symm ▸ publishInnerRootsPreserves q h g.1
 · exact g.2.symm ▸ acknowledgeInnerRootsPreserves q h g.1
 · exact g.2.symm ▸ releaseInnerSourcePreserves q h g.1
 · exact g.2.symm ▸ enterInnerPreserves q h g.1
 · exact g.2.symm ▸ captureInnerPreserves q h g.1
 · exact g.2.symm ▸ startGcReaderPreserves q h g.1
 · exact g.2.symm ▸ finishGcReaderPreserves q h g.1
 · exact g.2.symm ▸ escrowOuterUnwindPreserves q h g.1
 · exact g.2.symm ▸ issueOuterUnwindPreserves q h g.1
 · exact g.2.symm ▸ landingObservedPreserves q h g.1
 · exact g.2.symm ▸ landingReplyLostPreserves q h g.1
 · exact g.2.symm ▸ reconcileLandingPreserves q h g.1
 · exact g.2.symm ▸ settleInnerGuardPreserves q h g.1
 · exact g.2.symm ▸ settleOuterGuardPreserves q h g.1
 · exact g.2.symm ▸ resumeCapturedPreserves q h g.1
 · exact g.2.symm ▸ rejectInnerReturnPreserves q h g.1
 · exact g.2.symm ▸ finishResumptionPreserves q h g.1
 · exact g.2.symm ▸ closeCapturedHoldersPreserves q h g.1
 · exact g.2.symm ▸ closeRootAdmissionPreserves q h g.1
 · exact g.2.symm ▸ closeCodeAdmissionPreserves q h g.1
 · exact g.2.symm ▸ ackRootGracePreserves q h g.1
 · exact g.2.symm ▸ retireRootSlotsPreserves q h g.1
 · exact g.2.symm ▸ ackCodeGracePreserves q h g.1
 · exact g.2.symm ▸ retireDescriptorPreserves q h g.1
 · exact g.2.symm ▸ detachNativeOwnerPreserves q h g.1
 · simpa [g] using h
inductive Reachable : State → Prop where
 | init : Reachable initial
 | next {q t : State} : Reachable q → Step q t → Reachable t
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | init => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem innerEntryHandoff (q : State) (h : Safe q) (g : q.innerGuard=1) : q.innerTarget=1 ∧ q.innerAck=1 ∧ q.innerSource=0 ∧ q.descriptor=1 := by
 simp only [Safe] at h
 omega
theorem entryHandoff (q : State) (h : Safe q) (g : q.outerGuard=1) : q.target=1 ∧ q.ack=1 ∧ q.source=0 ∧ q.descriptor=1 := by
 simp only [Safe] at h
 omega
theorem outerInvalidatesInner (q : State) (h : Safe q) (g : q.unwind≥1) : q.outerRight=0 ∧ q.innerRight=0 := by
 simp only [Safe] at h
 omega
theorem unknownKeepsCustody (q : State) (h : Safe q) (g : q.outcome=1) : q.outerGuard=2 ∧ q.innerGuard=2 ∧ q.target=1 ∧ q.descriptor=1 := by
 simp only [Safe] at h
 omega
theorem scannerPinsDescriptor (q : State) (h : Safe q) (g : q.gcReader=1) : q.descriptor=1 ∧ q.target=1 := by
 simp only [Safe] at h
 omega
theorem capturePinsDescriptor (q : State) (h : Safe q) (g : q.captured=1) : q.descriptor=1 ∧ q.target=1 := by
 simp only [Safe] at h
 omega
theorem descriptorRetirementCut (q : State) (h : Safe q) (g : q.descriptor=0) : q.gcReader=0 ∧ q.captured=0 ∧ q.outerGuard=3 ∧ q.innerGuard=3 ∧ q.rootRetired=1 ∧ q.landed=1 := by
 simp only [Safe] at h
 omega
theorem lateEntryClosed (q : State) (h : Safe q) (g : q.rootClosed=1) : q.shotGuard=0 ∧ q.captured=0 := by
 simp only [Safe] at h
 omega
theorem retiredRootsNoReader (q : State) (h : Safe q) (g : q.rootRetired=1) : q.gcReader=0 ∧ q.source=0 ∧ q.target=0 := by
 simp only [Safe] at h
 omega
theorem settledOuterNeedsSettledInner (q : State) (h : Safe q) (g : q.outerGuard=3) : q.innerGuard=3 ∧ q.landed=1 := by
 simp only [Safe] at h
 omega
theorem resumptionNoNativeRevival (q : State) (h : Safe q) (g : q.shotGuard=1) : q.innerRight=0 ∧ q.outerRight=0 ∧ q.shotTicket≥1 := by
 simp only [Safe] at h
 omega
theorem unwindCannotReviveInner (q t : State) (h : Safe q) (g : Step q t) (c : q.unwind≥1) : t.innerRight=0 ∧ t.outerRight=0 := by
 have rights := outerInvalidatesInner q h c
 have excluded : q.outerGuard≠0 ∧ q.outerGuard≠1 := by
  simp only [Safe] at h
  omega
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · rw [g.2]; simp_all [publishRootsGuard,publishRootsNext] <;> omega
 · rw [g.2]; simp_all [publicationReplyLostGuard,publicationReplyLostNext] <;> omega
 · rw [g.2]; simp_all [publicationAbsentUnknownGuard,publicationAbsentUnknownNext] <;> omega
 · rw [g.2]; simp_all [resolvePublicationGuard,resolvePublicationNext] <;> omega
 · rw [g.2]; simp_all [acknowledgeRootsGuard,acknowledgeRootsNext] <;> omega
 · rw [g.2]; simp_all [releaseSourceGuard,releaseSourceNext] <;> omega
 · rw [g.2]; simp_all [enterOuterGuard,enterOuterNext] <;> omega
 · rw [g.2]; simp_all [reserveInnerOfferGuard,reserveInnerOfferNext] <;> omega
 · rw [g.2]; simp_all [publishInnerRootsGuard,publishInnerRootsNext] <;> omega
 · rw [g.2]; simp_all [acknowledgeInnerRootsGuard,acknowledgeInnerRootsNext] <;> omega
 · rw [g.2]; simp_all [releaseInnerSourceGuard,releaseInnerSourceNext] <;> omega
 · rw [g.2]; simp_all [enterInnerGuard,enterInnerNext] <;> omega
 · rw [g.2]; simp_all [captureInnerGuard,captureInnerNext] <;> omega
 · rw [g.2]; simp_all [startGcReaderGuard,startGcReaderNext] <;> omega
 · rw [g.2]; simp_all [finishGcReaderGuard,finishGcReaderNext] <;> omega
 · rw [g.2]; simp_all [escrowOuterUnwindGuard,escrowOuterUnwindNext] <;> omega
 · rw [g.2]; simp_all [issueOuterUnwindGuard,issueOuterUnwindNext] <;> omega
 · rw [g.2]; simp_all [landingObservedGuard,landingObservedNext] <;> omega
 · rw [g.2]; simp_all [landingReplyLostGuard,landingReplyLostNext] <;> omega
 · rw [g.2]; simp_all [reconcileLandingGuard,reconcileLandingNext] <;> omega
 · rw [g.2]; simp_all [settleInnerGuardGuard,settleInnerGuardNext] <;> omega
 · rw [g.2]; simp_all [settleOuterGuardGuard,settleOuterGuardNext] <;> omega
 · rw [g.2]; simp_all [resumeCapturedGuard,resumeCapturedNext] <;> omega
 · rw [g.2]; simp_all [rejectInnerReturnGuard,rejectInnerReturnNext] <;> omega
 · rw [g.2]; simp_all [finishResumptionGuard,finishResumptionNext] <;> omega
 · rw [g.2]; simp_all [closeCapturedHoldersGuard,closeCapturedHoldersNext] <;> omega
 · rw [g.2]; simp_all [closeRootAdmissionGuard,closeRootAdmissionNext] <;> omega
 · rw [g.2]; simp_all [closeCodeAdmissionGuard,closeCodeAdmissionNext] <;> omega
 · rw [g.2]; simp_all [ackRootGraceGuard,ackRootGraceNext] <;> omega
 · rw [g.2]; simp_all [retireRootSlotsGuard,retireRootSlotsNext] <;> omega
 · rw [g.2]; simp_all [ackCodeGraceGuard,ackCodeGraceNext] <;> omega
 · rw [g.2]; simp_all [retireDescriptorGuard,retireDescriptorNext] <;> omega
 · rw [g.2]; simp_all [detachNativeOwnerGuard,detachNativeOwnerNext] <;> omega
 · simp_all
theorem resumptionTicketIncrements (q t : State) (h : Safe q) (g : Step q t) (c : t.shotTicket>q.shotTicket) : t.shotTicket=q.shotTicket+1 ∧ t.innerRight=0 := by
 have nonnegative : q.shotTicket≥0 := by
  simp only [Safe] at h
  omega
 have post := stepPreserves q t h g
 constructor
 · rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
   · rw [g.2] at c ⊢; dsimp [publishRootsNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [publicationReplyLostNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [publicationAbsentUnknownNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [resolvePublicationNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [acknowledgeRootsNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [releaseSourceNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [enterOuterNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [reserveInnerOfferNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [publishInnerRootsNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [acknowledgeInnerRootsNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [releaseInnerSourceNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [enterInnerNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [captureInnerNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [startGcReaderNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [finishGcReaderNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [escrowOuterUnwindNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [issueOuterUnwindNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [landingObservedNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [landingReplyLostNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [reconcileLandingNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [settleInnerGuardNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [settleOuterGuardNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [resumeCapturedNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [rejectInnerReturnNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [finishResumptionNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [closeCapturedHoldersNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [closeRootAdmissionNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [closeCodeAdmissionNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [ackRootGraceNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [retireRootSlotsNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [ackCodeGraceNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [retireDescriptorNext] at c ⊢ <;> omega
   · rw [g.2] at c ⊢; dsimp [detachNativeOwnerNext] at c ⊢ <;> omega
   · simp_all <;> omega
 · simp only [Safe] at post
   omega
end NestedDomain

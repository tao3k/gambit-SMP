import RcStorageAst
namespace RcStorage
open RcStorageAst
theorem reserveIndexPreserves (q : State) (h : Safe q) (g : reserveIndexGuard q) : Safe (reserveIndexNext q) := by
 simp only [reserveIndexGuard] at g
 have phaseNonzero : q.phase ≠ 0 := by omega
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp_all [Safe,reserveIndexGuard,reserveIndexNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega

theorem prepareRootPreserves (q : State) (h : Safe q) (g : prepareRootGuard q) : Safe (prepareRootNext q) := by
 simp only [prepareRootGuard] at g
 have phaseNonzero : q.phase ≠ 0 := by omega
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp_all [Safe,prepareRootGuard,prepareRootNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega

theorem publishPreserves (q : State) (h : Safe q) (g : publishGuard q) : Safe (publishNext q) := by
 simp only [publishGuard] at g
 have phaseNonzero : q.phase ≠ 0 := by omega
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp_all [Safe,publishGuard,publishNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega

theorem queryCommitPreserves (q : State) (h : Safe q) (g : queryCommitGuard q) : Safe (queryCommitNext q) := by
 simp only [queryCommitGuard] at g
 have phaseNonzero : q.phase ≠ 0 := by omega
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp_all [Safe,queryCommitGuard,queryCommitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega

theorem releaseSourcePreserves (q : State) (h : Safe q) (g : releaseSourceGuard q) : Safe (releaseSourceNext q) := by
 simp only [releaseSourceGuard] at g
 have phaseNonzero : q.phase ≠ 0 := by omega
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp_all [Safe,releaseSourceGuard,releaseSourceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega

theorem retainExtraPreserves (q : State) (h : Safe q) (g : retainExtraGuard q) : Safe (retainExtraNext q) := by
 simp only [retainExtraGuard] at g
 have phaseNonzero : q.phase ≠ 0 := by omega
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp_all [Safe,retainExtraGuard,retainExtraNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega

theorem releaseExtraPreserves (q : State) (h : Safe q) (g : releaseExtraGuard q) : Safe (releaseExtraNext q) := by
 simp only [releaseExtraGuard] at g
 have phaseNonzero : q.phase ≠ 0 := by omega
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp_all [Safe,releaseExtraGuard,releaseExtraNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega

theorem releaseBasePreserves (q : State) (h : Safe q) (g : releaseBaseGuard q) : Safe (releaseBaseNext q) := by
 simp only [releaseBaseGuard] at g
 have phaseNonzero : q.phase ≠ 0 := by omega
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp_all [Safe,releaseBaseGuard,releaseBaseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega

end RcStorage

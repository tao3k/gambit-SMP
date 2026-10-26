import RcStorageAst
namespace RcStorage
open RcStorageAst
theorem beginPreserves (q : State) (h : Safe q) (g : beginGuard q) : Safe (beginNext q) := by
 simp only [beginGuard] at g
 simp only [Safe] at h ⊢
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 refine ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · exact h4
 · exact h5
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · exact h10
 · exact h11
 · exact h12
 · exact h13
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · exact h16
 · exact h17
 · exact h18
 · exact h19
 · exact h20
 · exact h21
 · exact h22
 · exact h23
 · exact h24
 · exact h25
 · exact h26
 · exact h27
 · exact h28
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · exact h31
 · exact h32
 · exact h33
 · exact h34
 · exact h35
 · exact h36
 · exact h37
 · exact h38
 · exact h39
 · exact h40
 · exact h41
 · exact h42
 · exact h43
 · exact h44
 · exact h45
 · exact h46
 · exact h47
 · exact h48
 · exact h49
 · exact h50
 · exact h51
 · exact h52
 · exact h53
 · exact h54
 · exact h55
 · exact h56
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · exact h75
 · simp only [beginNext]
   omega
 · simp only [beginNext]
   omega
 · exact h78
theorem beginZeroPreserves (q : State) (h : Safe q) (g : beginZeroGuard q) : Safe (beginZeroNext q) := by
 simp only [beginZeroGuard] at g
 simp only [Safe] at h ⊢
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 refine ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · exact h4
 · exact h5
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · exact h10
 · exact h11
 · exact h12
 · exact h13
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · exact h16
 · exact h17
 · exact h18
 · exact h19
 · exact h20
 · exact h21
 · exact h22
 · exact h23
 · exact h24
 · exact h25
 · exact h26
 · exact h27
 · exact h28
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · exact h31
 · exact h32
 · exact h33
 · exact h34
 · exact h35
 · exact h36
 · exact h37
 · exact h38
 · exact h39
 · exact h40
 · exact h41
 · exact h42
 · exact h43
 · exact h44
 · exact h45
 · exact h46
 · exact h47
 · exact h48
 · exact h49
 · exact h50
 · exact h51
 · exact h52
 · exact h53
 · exact h54
 · exact h55
 · exact h56
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · exact h75
 · simp only [beginZeroNext]
   omega
 · simp only [beginZeroNext]
   omega
 · exact h78
theorem beginTooLargePreserves (q : State) (h : Safe q) (g : beginTooLargeGuard q) : Safe (beginTooLargeNext q) := by
 simp only [beginTooLargeGuard] at g
 simp only [Safe] at h ⊢
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 refine ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · exact h4
 · exact h5
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · exact h10
 · exact h11
 · exact h12
 · exact h13
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · exact h16
 · exact h17
 · exact h18
 · exact h19
 · exact h20
 · exact h21
 · exact h22
 · exact h23
 · exact h24
 · exact h25
 · exact h26
 · exact h27
 · exact h28
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · exact h31
 · exact h32
 · exact h33
 · exact h34
 · exact h35
 · exact h36
 · exact h37
 · exact h38
 · exact h39
 · exact h40
 · exact h41
 · exact h42
 · exact h43
 · exact h44
 · exact h45
 · exact h46
 · exact h47
 · exact h48
 · exact h49
 · exact h50
 · exact h51
 · exact h52
 · exact h53
 · exact h54
 · exact h55
 · exact h56
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · exact h75
 · simp only [beginTooLargeNext]
   omega
 · simp only [beginTooLargeNext]
   omega
 · exact h78
theorem ticketFailurePreserves (q : State) (h : Safe q) (g : ticketFailureGuard q) : Safe (ticketFailureNext q) := by
 simp only [ticketFailureGuard] at g
 simp only [Safe] at h ⊢
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 refine ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · exact h4
 · exact h5
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · exact h8
 · exact h9
 · exact h10
 · exact h11
 · exact h12
 · exact h13
 · exact h14
 · exact h15
 · exact h16
 · exact h17
 · exact h18
 · exact h19
 · exact h20
 · exact h21
 · exact h22
 · exact h23
 · exact h24
 · exact h25
 · exact h26
 · exact h27
 · exact h28
 · exact h29
 · exact h30
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · exact h33
 · exact h34
 · exact h35
 · exact h36
 · exact h37
 · exact h38
 · exact h39
 · exact h40
 · exact h41
 · exact h42
 · exact h43
 · exact h44
 · exact h45
 · exact h46
 · exact h47
 · exact h48
 · exact h49
 · exact h50
 · exact h51
 · exact h52
 · exact h53
 · exact h54
 · exact h55
 · exact h56
 · simp only [ticketFailureNext]
   omega
 · exact h58
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · exact h70
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · simp only [ticketFailureNext]
   omega
 · exact h75
 · exact h76
 · simp only [ticketFailureNext]
   omega
 · exact h78
theorem checkSizePreserves (q : State) (h : Safe q) (g : checkSizeGuard q) : Safe (checkSizeNext q) := by
 simp only [checkSizeGuard] at g
 simp only [Safe] at h ⊢
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 refine ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · simp only [checkSizeNext]
   omega
 · exact h1
 · exact h2
 · exact h3
 · exact h4
 · exact h5
 · exact h6
 · exact h7
 · exact h8
 · exact h9
 · exact h10
 · exact h11
 · exact h12
 · exact h13
 · exact h14
 · exact h15
 · exact h16
 · exact h17
 · exact h18
 · exact h19
 · exact h20
 · exact h21
 · exact h22
 · exact h23
 · exact h24
 · simp only [checkSizeNext]
   omega
 · simp only [checkSizeNext]
   omega
 · exact h27
 · exact h28
 · exact h29
 · exact h30
 · exact h31
 · exact h32
 · exact h33
 · exact h34
 · exact h35
 · exact h36
 · exact h37
 · exact h38
 · exact h39
 · exact h40
 · exact h41
 · exact h42
 · exact h43
 · exact h44
 · exact h45
 · exact h46
 · exact h47
 · exact h48
 · exact h49
 · exact h50
 · exact h51
 · exact h52
 · exact h53
 · exact h54
 · exact h55
 · exact h56
 · exact h57
 · simp only [checkSizeNext]
   omega
 · exact h59
 · exact h60
 · exact h61
 · exact h62
 · exact h63
 · exact h64
 · exact h65
 · exact h66
 · exact h67
 · exact h68
 · exact h69
 · exact h70
 · exact h71
 · exact h72
 · exact h73
 · exact h74
 · exact h75
 · exact h76
 · exact h77
 · exact h78
theorem rejectSizePreserves (q : State) (h : Safe q) (g : rejectSizeGuard q) : Safe (rejectSizeNext q) := by
 simp only [rejectSizeGuard] at g
 simp only [Safe] at h ⊢
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 refine ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · exact h4
 · exact h5
 · exact h6
 · exact h7
 · exact h8
 · exact h9
 · exact h10
 · exact h11
 · exact h12
 · exact h13
 · exact h14
 · exact h15
 · exact h16
 · exact h17
 · exact h18
 · exact h19
 · exact h20
 · exact h21
 · exact h22
 · exact h23
 · exact h24
 · exact h25
 · exact h26
 · exact h27
 · exact h28
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · exact h33
 · exact h34
 · exact h35
 · exact h36
 · exact h37
 · exact h38
 · exact h39
 · exact h40
 · exact h41
 · exact h42
 · exact h43
 · exact h44
 · exact h45
 · exact h46
 · exact h47
 · exact h48
 · exact h49
 · exact h50
 · exact h51
 · exact h52
 · exact h53
 · exact h54
 · exact h55
 · exact h56
 · simp only [rejectSizeNext]
   omega
 · exact h58
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · exact h75
 · simp only [rejectSizeNext]
   omega
 · simp only [rejectSizeNext]
   omega
 · exact h78
theorem allocNullPreserves (q : State) (h : Safe q) (g : allocNullGuard q) : Safe (allocNullNext q) := by
 simp only [allocNullGuard] at g
 simp only [Safe] at h ⊢
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 refine ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · exact h4
 · exact h5
 · exact h6
 · exact h7
 · exact h8
 · exact h9
 · exact h10
 · exact h11
 · exact h12
 · exact h13
 · exact h14
 · exact h15
 · exact h16
 · exact h17
 · exact h18
 · exact h19
 · exact h20
 · exact h21
 · exact h22
 · exact h23
 · exact h24
 · exact h25
 · exact h26
 · exact h27
 · exact h28
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · exact h33
 · exact h34
 · exact h35
 · exact h36
 · exact h37
 · exact h38
 · exact h39
 · exact h40
 · exact h41
 · exact h42
 · exact h43
 · exact h44
 · exact h45
 · exact h46
 · exact h47
 · exact h48
 · exact h49
 · exact h50
 · exact h51
 · exact h52
 · exact h53
 · exact h54
 · exact h55
 · exact h56
 · simp only [allocNullNext]
   omega
 · exact h58
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · exact h75
 · simp only [allocNullNext]
   omega
 · simp only [allocNullNext]
   omega
 · exact h78
theorem allocSuccessPreserves (q : State) (h : Safe q) (g : allocSuccessGuard q) : Safe (allocSuccessNext q) := by
 simp only [allocSuccessGuard] at g
 simp only [Safe] at h ⊢
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 refine ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · exact h4
 · exact h5
 · exact h6
 · exact h7
 · exact h8
 · exact h9
 · exact h10
 · exact h11
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · exact h14
 · exact h15
 · exact h16
 · exact h17
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · exact h20
 · exact h21
 · exact h22
 · exact h23
 · exact h24
 · exact h25
 · exact h26
 · exact h27
 · exact h28
 · exact h29
 · exact h30
 · exact h31
 · exact h32
 · exact h33
 · exact h34
 · exact h35
 · exact h36
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · exact h39
 · exact h40
 · exact h41
 · exact h42
 · exact h43
 · exact h44
 · exact h45
 · exact h46
 · exact h47
 · exact h48
 · exact h49
 · exact h50
 · exact h51
 · exact h52
 · exact h53
 · exact h54
 · exact h55
 · exact h56
 · simp only [allocSuccessNext]
   omega
 · exact h58
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · exact h70
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · exact h75
 · simp only [allocSuccessNext]
   omega
 · simp only [allocSuccessNext]
   omega
 · exact h78
theorem saveKeyPreserves (q : State) (h : Safe q) (g : saveKeyGuard q) : Safe (saveKeyNext q) := by
 simp only [saveKeyGuard] at g
 simp only [Safe] at h ⊢
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 refine ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact h0
 · exact h1
 · exact h2
 · exact h3
 · exact h4
 · exact h5
 · exact h6
 · exact h7
 · exact h8
 · exact h9
 · exact h10
 · exact h11
 · exact h12
 · exact h13
 · exact h14
 · exact h15
 · simp only [saveKeyNext]
   omega
 · simp only [saveKeyNext]
   omega
 · exact h18
 · exact h19
 · exact h20
 · exact h21
 · exact h22
 · exact h23
 · exact h24
 · exact h25
 · exact h26
 · exact h27
 · exact h28
 · exact h29
 · exact h30
 · exact h31
 · exact h32
 · exact h33
 · exact h34
 · exact h35
 · exact h36
 · exact h37
 · exact h38
 · exact h39
 · exact h40
 · exact h41
 · exact h42
 · exact h43
 · exact h44
 · exact h45
 · exact h46
 · exact h47
 · exact h48
 · exact h49
 · exact h50
 · exact h51
 · exact h52
 · exact h53
 · exact h54
 · exact h55
 · exact h56
 · exact h57
 · exact h58
 · exact h59
 · exact h60
 · exact h61
 · exact h62
 · exact h63
 · exact h64
 · exact h65
 · exact h66
 · exact h67
 · exact h68
 · exact h69
 · exact h70
 · exact h71
 · exact h72
 · exact h73
 · exact h74
 · exact h75
 · exact h76
 · exact h77
 · exact h78
end RcStorage

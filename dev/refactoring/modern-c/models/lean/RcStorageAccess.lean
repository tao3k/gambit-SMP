import RcStorageAst
namespace RcStorage
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false
open RcStorageAst
theorem borrowPreserves (q : State) (h : Safe q) (g : borrowGuard q) : Safe (borrowNext q) := by
 simp only [borrowGuard] at g
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
 · simp only [borrowNext]
   first
   | (solve | simp [borrowNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · simp only [borrowNext]
   first
   | (solve | simp [borrowNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
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
 · simp only [borrowNext]
   first
   | (solve | simp [borrowNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · exact h73
 · exact h74
 · exact h75
 · exact h76
 · exact h77
 · exact h78
#check borrowPreserves
theorem returnBorrowPreserves (q : State) (h : Safe q) (g : returnBorrowGuard q) : Safe (returnBorrowNext q) := by
 simp only [returnBorrowGuard] at g
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
 · simp only [returnBorrowNext]
   first
   | (solve | simp [returnBorrowNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · simp only [returnBorrowNext]
   first
   | (solve | simp [returnBorrowNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
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
 · simp only [returnBorrowNext]
   first
   | (solve | simp [returnBorrowNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · exact h73
 · exact h74
 · exact h75
 · exact h76
 · exact h77
 · exact h78
#check returnBorrowPreserves
theorem nativePinPreserves (q : State) (h : Safe q) (g : nativePinGuard q) : Safe (nativePinNext q) := by
 simp only [nativePinGuard] at g
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
 · simp only [nativePinNext]
   first
   | (solve | simp [nativePinNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · simp only [nativePinNext]
   first
   | (solve | simp [nativePinNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
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
 · simp only [nativePinNext]
   first
   | (solve | simp [nativePinNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · exact h73
 · exact h74
 · exact h75
 · exact h76
 · exact h77
 · exact h78
#check nativePinPreserves
theorem nativeReturnPreserves (q : State) (h : Safe q) (g : nativeReturnGuard q) : Safe (nativeReturnNext q) := by
 simp only [nativeReturnGuard] at g
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
 · simp only [nativeReturnNext]
   first
   | (solve | simp [nativeReturnNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · simp only [nativeReturnNext]
   first
   | (solve | simp [nativeReturnNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
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
 · simp only [nativeReturnNext]
   first
   | (solve | simp [nativeReturnNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · exact h73
 · exact h74
 · exact h75
 · exact h76
 · exact h77
 · exact h78
#check nativeReturnPreserves
theorem scanPreserves (q : State) (h : Safe q) (g : scanGuard q) : Safe (scanNext q) := by
 simp only [scanGuard] at g
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
 · simp only [scanNext]
   first
   | (solve | simp [scanNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · simp only [scanNext]
   first
   | (solve | simp [scanNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
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
 · simp only [scanNext]
   first
   | (solve | simp [scanNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h69 h70 h72 h74 h75 h76 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · exact h74
 · exact h75
 · exact h76
 · exact h77
 · exact h78
#check scanPreserves
theorem finishScanPreserves (q : State) (h : Safe q) (g : finishScanGuard q) : Safe (finishScanNext q) := by
 simp only [finishScanGuard] at g
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
 · simp only [finishScanNext]
   first
   | (solve | simp [finishScanNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · simp only [finishScanNext]
   first
   | (solve | simp [finishScanNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
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
 · simp only [finishScanNext]
   first
   | (solve | simp [finishScanNext])
   | (clear h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h69 h70 h72 h74 h75 h76 h78; (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega)
 · exact h74
 · exact h75
 · exact h76
 · exact h77
 · exact h78
#check finishScanPreserves
end RcStorage

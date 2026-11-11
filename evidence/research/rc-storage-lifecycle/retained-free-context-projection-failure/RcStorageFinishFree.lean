import RcStorageAst
namespace RcStorage
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false
open RcStorageAst
theorem finishFreePreserves (q : State) (h : Safe q) (g : finishFreeGuard q) : Safe (finishFreeNext q) := by
 simp only [finishFreeGuard] at g
 simp only [Safe] at h ⊢
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 refine ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h8 h9 h12 h13 h14 h15 h16 h18 h20 h21 h22 h23 h24 h33 h34 h35 h36 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h60 h61 h62 h63 h72 h74 h75 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h4 h5 h6 h7 h8 h9 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h69 h70 h71 h72 h73 h74 h75 h76 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · exact h4
 · exact h5
 · exact h6
 · exact h7
 · exact h8
 · exact h9
 · exact h10
 · exact h11
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · exact h14
 · exact h15
 · exact h16
 · exact h17
 · exact h18
 · exact h19
 · exact h20
 · exact h21
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
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
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h8 h9 h10 h11 h12 h13 h14 h15 h16 h18 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h58 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · exact h58
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h58 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h63 h64 h65 h66 h67 h68 h69 h71 h72 h73 h74 h75 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h64 h65 h66 h67 h68 h69 h70 h71 h72 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h66 h67 h71 h72 h73 h74 h75 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h4 h5 h6 h7 h8 h9 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h71 h72 h73 h74 h75 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h4 h5 h6 h7 h8 h9 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h69 h70 h72 h74 h75 h76 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h4 h5 h6 h7 h8 h9 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h69 h70 h72 h74 h75 h76 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h4 h5 h6 h7 h8 h9 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h33 h34 h35 h36 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h72 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h66 h67 h71 h72 h73 h74 h75 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · exact h70
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h69 h70 h72 h74 h75 h76 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h45 h46 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h68 h69 h70 h71 h73 h74 h75 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h39 h40 h41 h42 h43 h44 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h69 h70 h72 h74 h75 h76 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h29 h30 h31 h32 h33 h34 h35 h36 h37 h38 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h64 h65 h66 h67 h69 h70 h71 h72 h73 h76 h77 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · exact h75
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h1 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h27 h28 h31 h32 h37 h38 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h63 h66 h67 h71 h72 h73 h74 h75 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · simp only [finishFreeNext]
   first
   | (solve | simp [finishFreeNext])
   | (clear h0 h4 h5 h6 h7 h8 h9 h10 h11 h12 h13 h14 h15 h16 h17 h18 h19 h20 h21 h22 h23 h24 h25 h26 h31 h32 h33 h34 h35 h36 h39 h40 h41 h42 h43 h44 h45 h46 h47 h48 h49 h50 h51 h52 h53 h54 h55 h56 h57 h58 h59 h60 h61 h62 h63 h72 h74 h75 h78; intros <;> (repeat' apply And.intro) <;> intros <;> (first | trivial | omega))
 · exact h78
#check finishFreePreserves
end RcStorage

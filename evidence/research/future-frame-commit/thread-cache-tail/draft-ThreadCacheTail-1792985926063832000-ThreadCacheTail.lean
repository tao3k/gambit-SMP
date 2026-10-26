import ThreadCacheTailAst
import EscrowCriticalTailAst
namespace ThreadCacheTail
open ThreadCacheTailAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem enterChildPreserves (q : State) (h : Safe q) (g : enterChildGuard q) : Safe (enterChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [enterChildGuard] at g
 simp [enterChildNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem childCleanupKnownPreserves (q : State) (h : Safe q) (g : childCleanupKnownGuard q) : Safe (childCleanupKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [childCleanupKnownGuard] at g
 simp [childCleanupKnownNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem beginChildRestorePreserves (q : State) (h : Safe q) (g : beginChildRestoreGuard q) : Safe (beginChildRestoreNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [beginChildRestoreGuard] at g
 simp [beginChildRestoreNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem knownChildRestorePreserves (q : State) (h : Safe q) (g : knownChildRestoreGuard q) : Safe (knownChildRestoreNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [knownChildRestoreGuard] at g
 simp [knownChildRestoreNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem claimExtraPreserves (q : State) (h : Safe q) (g : claimExtraGuard q) : Safe (claimExtraNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [claimExtraGuard] at g
 simp [claimExtraNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem returnExtraPreserves (q : State) (h : Safe q) (g : returnExtraGuard q) : Safe (returnExtraNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [returnExtraGuard] at g
 simp [returnExtraNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem denyOwnerPreserves (q : State) (h : Safe q) (g : denyOwnerGuard q) : Safe (denyOwnerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [denyOwnerGuard] at g
 simp [denyOwnerNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem sampleEmptyPreserves (q : State) (h : Safe q) (g : sampleEmptyGuard q) : Safe (sampleEmptyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [sampleEmptyGuard] at g
 simp [sampleEmptyNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem sampleLowPreserves (q : State) (h : Safe q) (g : sampleLowGuard q) : Safe (sampleLowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [sampleLowGuard] at g
 simp [sampleLowNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem sampleNearPreserves (q : State) (h : Safe q) (g : sampleNearGuard q) : Safe (sampleNearNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [sampleNearGuard] at g
 simp [sampleNearNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem sampleHighPreserves (q : State) (h : Safe q) (g : sampleHighGuard q) : Safe (sampleHighNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [sampleHighGuard] at g
 simp [sampleHighNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem selectFastPreserves (q : State) (h : Safe q) (g : selectFastGuard q) : Safe (selectFastNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [selectFastGuard] at g
 simp [selectFastNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem selectHelperPreserves (q : State) (h : Safe q) (g : selectHelperGuard q) : Safe (selectHelperNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [selectHelperGuard] at g
 simp [selectHelperNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem attestFastTailPreserves (q : State) (h : Safe q) (g : attestFastTailGuard q) : Safe (attestFastTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [attestFastTailGuard] at g
 simp [attestFastTailNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem writeFastLinkPreserves (q : State) (h : Safe q) (g : writeFastLinkGuard q) : Safe (writeFastLinkNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [writeFastLinkGuard] at g
 simp [writeFastLinkNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem publishFastHeadPreserves (q : State) (h : Safe q) (g : publishFastHeadGuard q) : Safe (publishFastHeadNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [publishFastHeadGuard] at g
 simp [publishFastHeadNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem incrementFastCountPreserves (q : State) (h : Safe q) (g : incrementFastCountGuard q) : Safe (incrementFastCountNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [incrementFastCountGuard] at g
 simp [incrementFastCountNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem publishFastReceiptPreserves (q : State) (h : Safe q) (g : publishFastReceiptGuard q) : Safe (publishFastReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [publishFastReceiptGuard] at g
 simp [publishFastReceiptNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem helperPushPreserves (q : State) (h : Safe q) (g : helperPushGuard q) : Safe (helperPushNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [helperPushGuard] at g
 simp [helperPushNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem helperFlush800Preserves (q : State) (h : Safe q) (g : helperFlush800Guard q) : Safe (helperFlush800Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [helperFlush800Guard] at g
 simp [helperFlush800Next,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem helperKnownReturnPreserves (q : State) (h : Safe q) (g : helperKnownReturnGuard q) : Safe (helperKnownReturnNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [helperKnownReturnGuard] at g
 simp [helperKnownReturnNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem unknownHelperPreserves (q : State) (h : Safe q) (g : unknownHelperGuard q) : Safe (unknownHelperNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [unknownHelperGuard] at g
 simp [unknownHelperNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem handoffParentPreserves (q : State) (h : Safe q) (g : handoffParentGuard q) : Safe (handoffParentNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [handoffParentGuard] at g
 simp [handoffParentNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem beginParentRestorePreserves (q : State) (h : Safe q) (g : beginParentRestoreGuard q) : Safe (beginParentRestoreNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [beginParentRestoreGuard] at g
 simp [beginParentRestoreNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem knownParentRestorePreserves (q : State) (h : Safe q) (g : knownParentRestoreGuard q) : Safe (knownParentRestoreNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 simp only [knownParentRestoreGuard] at g
 simp [knownParentRestoreNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25
 · rcases h0 with ⟨g,rfl⟩
   exact enterChildPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact childCleanupKnownPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact beginChildRestorePreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact knownChildRestorePreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact claimExtraPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact returnExtraPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact denyOwnerPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact sampleEmptyPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact sampleLowPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact sampleNearPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact sampleHighPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact selectFastPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact selectHelperPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact attestFastTailPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact writeFastLinkPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact publishFastHeadPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact incrementFastCountPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact publishFastReceiptPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact helperPushPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact helperFlush800Preserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact helperKnownReturnPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact unknownHelperPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact handoffParentPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact beginParentRestorePreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact knownParentRestorePreserves q h g
 · simpa [h25] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem headNotReceipt (q : State) (h : Safe q) (hp : q.phase=12) : q.receipt=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 omega
theorem pendingChildRetainsSlot (q : State) (h : Safe q) (hp : q.childPhase=3) : q.childSlot=1 ∧ q.parentSlot=1 ∧ q.free=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 omega
theorem pendingParentRetainsSlot (q : State) (h : Safe q) (hp : q.phase=8) : q.parentSlot=1 ∧ q.supervisor=1 ∧ q.mask=2 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 omega
theorem cacheCredits (q : State) (h : Safe q)  : q.count+q.shared=q.initialCount+q.counted := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51⟩
 omega
-- Scoped endpoint join: restoration return and independent resolver/root closure are premises.
def DoneMirror (q : State) (r : EscrowCriticalTailAst.State) : Prop := q.phase=8 → r.stage=8 ∧ r.supervisor=1 ∧ r.registered=1 ∧ r.slot=1
def RetireOthers (r : EscrowCriticalTailAst.State) : Prop := r.cancel=3 ∧ r.lock=0 ∧ r.pin=0
theorem suppliesPriorGuard (q : State) (r : EscrowCriticalTailAst.State) (g : knownParentRestoreGuard q) (hm : DoneMirror q r) (hr : RetireOthers r) : EscrowCriticalTailAst.retireSlotGuard r := by
 simp only [knownParentRestoreGuard] at g
 simp only [DoneMirror] at hm
 simp only [RetireOthers] at hr
 simp only [EscrowCriticalTailAst.retireSlotGuard]
 omega
theorem guardedPriorRetirement (q : State) (r : EscrowCriticalTailAst.State) (g : knownParentRestoreGuard q) (hm : DoneMirror q r) (hr : RetireOthers r) : EscrowCriticalTailAst.Step r (EscrowCriticalTailAst.retireSlotNext r) := by
 have h := suppliesPriorGuard q r g hm hr
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩)))))))))))))))))))))))))))
end ThreadCacheTail

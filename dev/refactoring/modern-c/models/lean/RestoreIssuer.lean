import RestoreIssuerAst
namespace RestoreIssuer
open RestoreIssuerAst
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem classifyFreshPreserves (q : State) (h : Safe q) (g : classifyFreshGuard q) : Safe (classifyFreshNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,classifyFreshGuard,classifyFreshNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem classifyNavigationPreserves (q : State) (h : Safe q) (g : classifyNavigationGuard q) : Safe (classifyNavigationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,classifyNavigationGuard,classifyNavigationNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem classifySchedulerPreserves (q : State) (h : Safe q) (g : classifySchedulerGuard q) : Safe (classifySchedulerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,classifySchedulerGuard,classifySchedulerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem classifyForeignPreserves (q : State) (h : Safe q) (g : classifyForeignGuard q) : Safe (classifyForeignNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,classifyForeignGuard,classifyForeignNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem classifyConversionPreserves (q : State) (h : Safe q) (g : classifyConversionGuard q) : Safe (classifyConversionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,classifyConversionGuard,classifyConversionNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sourceFramePreserves (q : State) (h : Safe q) (g : sourceFrameGuard q) : Safe (sourceFrameNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,sourceFrameGuard,sourceFrameNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sourceRcPreserves (q : State) (h : Safe q) (g : sourceRcGuard q) : Safe (sourceRcNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,sourceRcGuard,sourceRcNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sourceRawPreserves (q : State) (h : Safe q) (g : sourceRawGuard q) : Safe (sourceRawNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,sourceRawGuard,sourceRawNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem pinSourcePreserves (q : State) (h : Safe q) (g : pinSourceGuard q) : Safe (pinSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,pinSourceGuard,pinSourceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishCarrierPreserves (q : State) (h : Safe q) (g : publishCarrierGuard q) : Safe (publishCarrierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,publishCarrierGuard,publishCarrierNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem gcSourceOnlyPreserves (q : State) (h : Safe q) (g : gcSourceOnlyGuard q) : Safe (gcSourceOnlyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,gcSourceOnlyGuard,gcSourceOnlyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem gcPublishedPreserves (q : State) (h : Safe q) (g : gcPublishedGuard q) : Safe (gcPublishedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,gcPublishedGuard,gcPublishedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveGuardPreserves (q : State) (h : Safe q) (g : reserveGuardGuard q) : Safe (reserveGuardNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,reserveGuardGuard,reserveGuardNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem guardAllocationFailsPreserves (q : State) (h : Safe q) (g : guardAllocationFailsGuard q) : Safe (guardAllocationFailsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,guardAllocationFailsGuard,guardAllocationFailsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishGuardPreserves (q : State) (h : Safe q) (g : publishGuardGuard q) : Safe (publishGuardNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,publishGuardGuard,publishGuardNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem releaseSourcePreserves (q : State) (h : Safe q) (g : releaseSourceGuard q) : Safe (releaseSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,releaseSourceGuard,releaseSourceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem allocateMarkerPreserves (q : State) (h : Safe q) (g : allocateMarkerGuard q) : Safe (allocateMarkerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,allocateMarkerGuard,allocateMarkerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enterPreserves (q : State) (h : Safe q) (g : enterGuard q) : Safe (enterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,enterGuard,enterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem exceptionToOwnerPreserves (q : State) (h : Safe q) (g : exceptionToOwnerGuard q) : Safe (exceptionToOwnerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 have hg : q.guard=1 ∨ q.guard=2 ∨ q.guard=3 := by simp only [exceptionToOwnerGuard] at g; omega
 rcases hg with hg | hg | hg <;> simp_all [Safe,exceptionToOwnerGuard,exceptionToOwnerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeOuterPreserves (q : State) (h : Safe q) (g : observeOuterGuard q) : Safe (observeOuterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,observeOuterGuard,observeOuterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem killMarkerPreserves (q : State) (h : Safe q) (g : killMarkerGuard q) : Safe (killMarkerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,killMarkerGuard,killMarkerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem completePreserves (q : State) (h : Safe q) (g : completeGuard q) : Safe (completeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,completeGuard,completeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reuseExistingPreserves (q : State) (h : Safe q) (g : reuseExistingGuard q) : Safe (reuseExistingNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,reuseExistingGuard,reuseExistingNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectRawPreserves (q : State) (h : Safe q) (g : rejectRawGuard q) : Safe (rejectRawNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,rejectRawGuard,rejectRawNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem recoverPreAdmissionPreserves (q : State) (h : Safe q) (g : recoverPreAdmissionGuard q) : Safe (recoverPreAdmissionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 simp_all [Safe,recoverPreAdmissionGuard,recoverPreAdmissionNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25
 · rcases h0 with ⟨g,e⟩; rw [e]; exact classifyFreshPreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact classifyNavigationPreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact classifySchedulerPreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact classifyForeignPreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact classifyConversionPreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact sourceFramePreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact sourceRcPreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact sourceRawPreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact pinSourcePreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact publishCarrierPreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact gcSourceOnlyPreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact gcPublishedPreserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact reserveGuardPreserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact guardAllocationFailsPreserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact publishGuardPreserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact releaseSourcePreserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact allocateMarkerPreserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact enterPreserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact exceptionToOwnerPreserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact observeOuterPreserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact killMarkerPreserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact completePreserves q h g
 · rcases h22 with ⟨g,e⟩; rw [e]; exact reuseExistingPreserves q h g
 · rcases h23 with ⟨g,e⟩; rw [e]; exact rejectRawPreserves q h g
 · rcases h24 with ⟨g,e⟩; rw [e]; exact recoverPreAdmissionPreserves q h g
 · rw [h25]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem reservationNeedsCarrier (q : State) (g : reserveGuardGuard q) : q.carrier=1 := by simp_all [reserveGuardGuard]
theorem publishedCarrierTracksGc (q : State) (h : Safe q) (c : q.carrier=1) : q.copiedVersion=q.version := by simp_all [Safe]
theorem rawCannotReserve (q : State) (h : Safe q) (raw : q.source=3) : ¬reserveGuardGuard q := by simp_all [Safe,reserveGuardGuard]
theorem reusedEntryDoesNotIssue (q : State) : (reuseExistingNext q).issued=q.issued ∧ (reuseExistingNext q).allocations=q.allocations := by constructor <;> rfl
theorem unknownRetainsCarrier (q : State) (h : Safe q) (u : q.guard=4) : q.carrier=1 ∧ q.issued=1 := by simp_all [Safe]
theorem sourceReleaseNeedsPublication (q : State) (g : releaseSourceGuard q) : q.guard≥2 := by simp_all [releaseSourceGuard]
theorem completedMarkerClosed (q : State) (h : Safe q) (done : q.guard=5) : q.marker=0 ∧ q.outer=1 := by simp_all [Safe]
end RestoreIssuer

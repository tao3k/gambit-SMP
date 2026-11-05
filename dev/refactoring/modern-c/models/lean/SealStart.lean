import SealStartAst
namespace SealStart
open SealStartAst
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem capturePreserves (q : State) (h : Safe q) (g : captureGuard q) : Safe (captureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,captureGuard,captureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resumeLivePreserves (q : State) (h : Safe q) (g : resumeLiveGuard q) : Safe (resumeLiveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,resumeLiveGuard,resumeLiveNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resumeDeniedPreserves (q : State) (h : Safe q) (g : resumeDeniedGuard q) : Safe (resumeDeniedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,resumeDeniedGuard,resumeDeniedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeWritersPreserves (q : State) (h : Safe q) (g : closeWritersGuard q) : Safe (closeWritersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,closeWritersGuard,closeWritersNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem opaqueEscapePreserves (q : State) (h : Safe q) (g : opaqueEscapeGuard q) : Safe (opaqueEscapeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,opaqueEscapeGuard,opaqueEscapeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealPreserves (q : State) (h : Safe q) (g : sealGuard q) : Safe (sealNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,sealGuard,sealNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortCandidatePreserves (q : State) (h : Safe q) (g : abortCandidateGuard q) : Safe (abortCandidateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,abortCandidateGuard,abortCandidateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observePreserves (q : State) (h : Safe q) (g : observeGuard q) : Safe (observeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,observeGuard,observeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem revokePreserves (q : State) (h : Safe q) (g : revokeGuard q) : Safe (revokeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,revokeGuard,revokeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem casStartPreserves (q : State) (h : Safe q) (g : casStartGuard q) : Safe (casStartNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,casStartGuard,casStartNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem casFailedPreserves (q : State) (h : Safe q) (g : casFailedGuard q) : Safe (casFailedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,casFailedGuard,casFailedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem revokeTooLatePreserves (q : State) (h : Safe q) (g : revokeTooLateGuard q) : Safe (revokeTooLateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,revokeTooLateGuard,revokeTooLateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishCopyPreserves (q : State) (h : Safe q) (g : finishCopyGuard q) : Safe (finishCopyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,finishCopyGuard,finishCopyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem nativeBorrowPreserves (q : State) (h : Safe q) (g : nativeBorrowGuard q) : Safe (nativeBorrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,nativeBorrowGuard,nativeBorrowNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem nativeReturnPreserves (q : State) (h : Safe q) (g : nativeReturnGuard q) : Safe (nativeReturnNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,nativeReturnGuard,nativeReturnNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem nativeUnknownPreserves (q : State) (h : Safe q) (g : nativeUnknownGuard q) : Safe (nativeUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,nativeUnknownGuard,nativeUnknownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeAdmissionPreserves (q : State) (h : Safe q) (g : closeAdmissionGuard q) : Safe (closeAdmissionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,closeAdmissionGuard,closeAdmissionNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem dropFramePreserves (q : State) (h : Safe q) (g : dropFrameGuard q) : Safe (dropFrameNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,dropFrameGuard,dropFrameNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem dropRootPreserves (q : State) (h : Safe q) (g : dropRootGuard q) : Safe (dropRootNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,dropRootGuard,dropRootNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginMaintenancePreserves (q : State) (h : Safe q) (g : beginMaintenanceGuard q) : Safe (beginMaintenanceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,beginMaintenanceGuard,beginMaintenanceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem endMaintenancePreserves (q : State) (h : Safe q) (g : endMaintenanceGuard q) : Safe (endMaintenanceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,endMaintenanceGuard,endMaintenanceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reclaimPreserves (q : State) (h : Safe q) (g : reclaimGuard q) : Safe (reclaimNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,reclaimGuard,reclaimNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem denyLateBorrowPreserves (q : State) (h : Safe q) (g : denyLateBorrowGuard q) : Safe (denyLateBorrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all [Safe,denyLateBorrowGuard,denyLateBorrowNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18 | a19 | a20 | a21 | a22 | a23 | a24
 · rcases a0 with ⟨g,rfl⟩; exact capturePreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact resumeLivePreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact resumeDeniedPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact closeWritersPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact opaqueEscapePreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact sealPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact abortCandidatePreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact issuePreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact observePreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact revokePreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact casStartPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact casFailedPreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact revokeTooLatePreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact finishCopyPreserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact nativeBorrowPreserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact nativeReturnPreserves q h g
 · rcases a16 with ⟨g,rfl⟩; exact nativeUnknownPreserves q h g
 · rcases a17 with ⟨g,rfl⟩; exact closeAdmissionPreserves q h g
 · rcases a18 with ⟨g,rfl⟩; exact dropFramePreserves q h g
 · rcases a19 with ⟨g,rfl⟩; exact dropRootPreserves q h g
 · rcases a20 with ⟨g,rfl⟩; exact beginMaintenancePreserves q h g
 · rcases a21 with ⟨g,rfl⟩; exact endMaintenancePreserves q h g
 · rcases a22 with ⟨g,rfl⟩; exact reclaimPreserves q h g
 · rcases a23 with ⟨g,rfl⟩; exact denyLateBorrowPreserves q h g
 · rw [a24]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem revokeBlocksStart (q : State) : ¬casStartGuard (revokeNext q) := by simp [casStartGuard,revokeNext]
theorem startBlocksRevoke (q : State) : ¬revokeGuard (casStartNext q) := by simp [revokeGuard,casStartNext]
theorem sealInvalidatesSavedToken (q : State) (h : q.saved≤q.generation) : (sealNext q).saved≠(sealNext q).generation := by simp [sealNext]; omega
theorem retiredHasNoUsers (q : State) (h : Safe q) (r : q.reclaimed=true) : q.nativePins=0 ∧ q.frames=0 ∧ q.roots=0 ∧ q.maintenance=0 ∧ q.observers=0 ∧ q.copyPin=false := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all <;> omega
theorem copyingAlive (q : State) (h : Safe q) (copying : q.phase=2) : q.copyPin=true ∧ q.reclaimed=false := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23⟩
 simp_all <;> omega
end SealStart

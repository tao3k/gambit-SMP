import FrameSealRootAst
namespace FrameSealRoot
open FrameSealRootAst
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem ownPreserves (q : State) (h : Safe q) (g : ownGuard q) : Safe (ownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,ownGuard,ownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem mutateLivePreserves (q : State) (h : Safe q) (g : mutateLiveGuard q) : Safe (mutateLiveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,mutateLiveGuard,mutateLiveNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealPreserves (q : State) (h : Safe q) (g : sealGuard q) : Safe (sealNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,sealGuard,sealNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginRequestPreserves (q : State) (h : Safe q) (g : beginRequestGuard q) : Safe (beginRequestNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,beginRequestGuard,beginRequestNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishRequestPreserves (q : State) (h : Safe q) (g : publishRequestGuard q) : Safe (publishRequestNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,publishRequestGuard,publishRequestNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem selectRequestPreserves (q : State) (h : Safe q) (g : selectRequestGuard q) : Safe (selectRequestNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,selectRequestGuard,selectRequestNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownRequestPreserves (q : State) (h : Safe q) (g : unknownRequestGuard q) : Safe (unknownRequestNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,unknownRequestGuard,unknownRequestNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem completeRequestPreserves (q : State) (h : Safe q) (g : completeRequestGuard q) : Safe (completeRequestNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,completeRequestGuard,completeRequestNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem ackSourcePreserves (q : State) (h : Safe q) (g : ackSourceGuard q) : Safe (ackSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,ackSourceGuard,ackSourceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezePreserves (q : State) (h : Safe q) (g : freezeGuard q) : Safe (freezeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,freezeGuard,freezeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem coverSourcePreserves (q : State) (h : Safe q) (g : coverSourceGuard q) : Safe (coverSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,coverSourceGuard,coverSourceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem startPreserves (q : State) (h : Safe q) (g : startGuard q) : Safe (startNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,startGuard,startNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem relocatePreserves (q : State) (h : Safe q) (g : relocateGuard q) : Safe (relocateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,relocateGuard,relocateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem deferRootWriterPreserves (q : State) (h : Safe q) (g : deferRootWriterGuard q) : Safe (deferRootWriterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,deferRootWriterGuard,deferRootWriterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem revokeBeforeCopyPreserves (q : State) (h : Safe q) (g : revokeBeforeCopyGuard q) : Safe (revokeBeforeCopyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,revokeBeforeCopyGuard,revokeBeforeCopyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishRoundPreserves (q : State) (h : Safe q) (g : finishRoundGuard q) : Safe (finishRoundNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,finishRoundGuard,finishRoundNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeLedgerPreserves (q : State) (h : Safe q) (g : closeLedgerGuard q) : Safe (closeLedgerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,closeLedgerGuard,closeLedgerNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireModulePreserves (q : State) (h : Safe q) (g : retireModuleGuard q) : Safe (retireModuleNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,retireModuleGuard,retireModuleNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectOpaquePreserves (q : State) (h : Safe q) (g : rejectOpaqueGuard q) : Safe (rejectOpaqueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all [Safe,rejectOpaqueGuard,rejectOpaqueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18 | a19 | a20
 · rcases a0 with ⟨g,rfl⟩; exact ownPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact mutateLivePreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact sealPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact beginRequestPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact publishRequestPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact selectRequestPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact unknownRequestPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact completeRequestPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact ackSourcePreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact freezePreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact coverSourcePreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact issuePreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact startPreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact relocatePreserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact deferRootWriterPreserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact revokeBeforeCopyPreserves q h g
 · rcases a16 with ⟨g,rfl⟩; exact finishRoundPreserves q h g
 · rcases a17 with ⟨g,rfl⟩; exact closeLedgerPreserves q h g
 · rcases a18 with ⟨g,rfl⟩; exact retireModulePreserves q h g
 · rcases a19 with ⟨g,rfl⟩; exact rejectOpaquePreserves q h g
 · rw [a20]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem privateSnapshotUnaffected (q : State) : (mutateLiveNext q).snap=q.snap ∧ (mutateLiveNext q).sealedView=q.sealedView := by simp [mutateLiveNext]
theorem receiptScope (q : State) (h : Safe q) (r : q.receipt=true) : q.sealedView=true ∧ q.covered=true ∧ q.modulePinned=true ∧ q.seen=q.rootEpoch ∧ q.B≥q.Q+q.A+q.T := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all <;> omega
theorem unknownKeepsSource (q : State) : (unknownRequestNext q).request=5 ∧ (unknownRequestNext q).modulePinned=q.modulePinned := by simp [unknownRequestNext]
end FrameSealRoot

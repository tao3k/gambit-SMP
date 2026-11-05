import FrameCommitAdmission
import FrameCommitCopy
import FrameCommitDecision
import FrameCommitCollector
import FrameCommitGeneration
import FrameCommitProbe
open FrameCommitAst
namespace FrameCommit
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 unfold Step at hs
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21
 · rcases h0 with ⟨g,rfl⟩
   exact reserveSplitPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact childDonePreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact closeLocalPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact allocateRootedCopyPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact enterRuntimePreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact resolveCanonicalPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact initializeCopyPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact validateCopyPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact prepareReturnPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact commitSplitPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact abortSplitPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact grantLocalPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact grantRemotePreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact leaveRuntimePreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact enterGcPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact forwardNoCopyPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact forwardWithCopyPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact leaveGcPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact closeDomainPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact resetDomainPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact failedProbePreserves q h g
 · rcases h21 with rfl
   exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | advance {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | advance _ s ih => exact stepPreserves _ _ ih s
theorem noLocalAfterSplit (q : State) (h : Safe q) (c : q.decision=2) : q.localGrants=0 := by
 unfold Safe at h
 grind
theorem oneReturnGrant (q : State) (h : Safe q) : q.localGrants+q.remoteGrants≤1 := by
 unfold Safe at h
 omega
theorem parentAndChildRooted (q : State) (h : Safe q) : q.sourceRoot+q.destRoot≥1 ∧ q.childRoot=1 := by
 unfold Safe at h
 omega
theorem noRecopyAfterGc (q : State) (h : Reachable q) : q.copyOps≤1 := by
 have hs := reachableSafe q h
 unfold Safe at hs
 omega
theorem commitCurrent (q : State) (h : commitSplitGuard q) :
 q.gate=1 ∧ q.viewRev=q.revision ∧ q.patchRev=q.revision ∧ q.viewLease=q.lease ∧ q.patchLease=q.lease := by
 unfold commitSplitGuard at h
 omega
theorem resetHasNoActiveFrameUser (q : State) (h : resetDomainGuard q) : q.gate=0 := by
 exact h.2
theorem runtimeExcludesForwarding (q : State) (h : q.gate=1) : ¬ forwardWithCopyGuard q := by
 simp [forwardWithCopyGuard,h]
theorem relocationUpdatesPrivateCopy (q : State) :
 (forwardWithCopyNext q).copyRev=(forwardWithCopyNext q).revision := by rfl
end FrameCommit

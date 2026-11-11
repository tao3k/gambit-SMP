import LazySplitClaim
import LazySplitPublication
import LazySplitChild
import LazySplitRestore
import LazySplitCapture
import LazySplitRetirement
import LazySplitFreeze
open LazySplitAst
namespace LazySplit
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 unfold Step at hs
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28
 · rcases h0 with ⟨g,rfl⟩
   exact denyParallelProfilePreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact claimSplitPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact failedProbePreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact allocateCopyPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact initializeCopyPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact publishReadyPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact commitSplitPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact abortPrivatePreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact localChildDonePreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact localAfterAbortDonePreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact childDoneInSplitPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact dequeueParentPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact restoreParentPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact publishResultPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact runParentPrefixPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact consumeSplitResultPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact runLocalParentPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact captureAfterValuePreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact restoreAfterValuePreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact dropCapturedPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact exitParentPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact retireTaskRootsPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact retireDescriptorPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact closeGcPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact freezeRootsPreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact beginScanPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact endScanPreserves q h g
 · rcases h27 with ⟨g,rfl⟩
   exact resumeGcPreserves q h g
 · rcases h28 with rfl
   exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | advance {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | advance _ s ih => exact stepPreserves _ _ ih s
theorem parentAlwaysRooted (q : State) (h : Safe q) (p : q.phase<8) :
 q.sourceRoot+q.copyRoot+q.contextRoot≥1 := by
 have hs := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have h4 : q.phase=4 → q.copyRoot=1 := fun hk => (h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1 hk).1
 have h5 : q.phase=5 → q.copyRoot=1 := fun hk => (h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1 hk).1
 have h7 : q.phase=7 → q.contextRoot=1 := fun hk => (h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1 hk).1
 have nsourceRoot := h.2.2.2.2.2.2.2.2.2.2.2.1
 have ncopyRoot := h.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have ncontextRoot := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 omega
theorem queuePublishedInitialized (q : State) (h : Safe q) (p : q.queueRoot=1) :
 q.ready=1 ∧ q.copyRoot=1 ∧ q.placeholder=1 := by
 unfold Safe at h
 grind
theorem strictParentNeedsResult (q : State) (h : Safe q) (p : q.parentRuns≥1) (s : q.split=1) :
 q.resultPublished=1 := by
 unfold Safe at h
 grind
theorem childRunsOncePerTask (q : State) (h : Reachable q) : q.childRuns=1 := by
 have hs:=reachableSafe q h
 unfold Safe at hs
 omega
theorem restoreAfterValueKeepsChild (q : State) :
 (restoreAfterValueNext q).childRuns=q.childRuns := by rfl
theorem descriptorCoversCaptured (q : State) (h : Safe q) (c : q.captured=1) :
 q.descriptor=1 ∧ q.captureRoot=1 := by
 unfold Safe at h
 grind
theorem initializedAbortMayStillAllocate :
 (abortPrivateNext (initializeCopyNext (allocateCopyNext (claimSplitNext initial)))).materialized=1 ∧
 (abortPrivateNext (initializeCopyNext (allocateCopyNext (claimSplitNext initial)))).split=0 := by constructor <;> rfl
theorem unclaimedLocalHasNoMaterialization :
 (runLocalParentNext (localChildDoneNext initial)).materialized=0 := by rfl
theorem materializationCharge (q : State) (hr : Reachable q) :
 0≤q.split ∧ q.split≤q.materialized ∧ q.materialized≤1 := by
 have hs := reachableSafe q hr
 unfold Safe at hs
 omega
end LazySplit

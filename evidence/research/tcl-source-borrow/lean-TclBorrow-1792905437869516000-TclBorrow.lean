import TclBorrowAccess
import TclBorrowMutation
import TclBorrowPublication
import TclBorrowTransfer
import TclBorrowRetirement
import TclBorrowStorage
import TclBorrowFreeze
import TclBorrowResume
open TclBorrowAst
namespace TclBorrow
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 unfold Step at hs
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29
 · rcases h0 with ⟨g,rfl⟩
   exact selectDispatchPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact acquireBorrowPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact refuseLateDispatchPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact refuseGcClosedPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact otherBorrowOldPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact otherBorrowNewPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact releaseOtherOldPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact releaseOtherNewPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact acquireWriterPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact prepareSetterPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact commitSetterPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact abortSetterPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact releaseWriterPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact revokePreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact publishDestinationPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact loseReplyPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact acknowledgeTransferPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact dropOldVersionPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact dropRevokedRootsPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact leaveDispatchPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact freeSourcePreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact dropDestinationPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact reuseStoragePreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact selectNewTokenPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact closeGcGatePreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact freezeRootsPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact beginScanPreserves q h g
 · rcases h27 with ⟨g,rfl⟩
   exact endScanPreserves q h g
 · rcases h28 with ⟨g,rfl⟩
   exact resumeRootsPreserves q h g
 · rcases h29 with rfl
   exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | advance {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | advance h step ih => exact stepPreserves _ _ ih step
theorem borrowedOldStillRooted (q : State) (h : Safe q) (b : q.borrower=1) (v : q.selected=1) : q.storage=1 ∧ q.oldRoot=1 := by
 unfold Safe at h
 grind
theorem otherBorrowersPreventFree (q : State) (h : Safe q) (b : q.otherOld≥1) : q.storage=1 ∧ q.oldRoot=1 := by
 unfold Safe at h
 grind
theorem writerExcludesScan (q : State) (h : Safe q) (w : q.writer=1) : q.frozen=0 ∧ q.scanning=0 := by
 unfold Safe at h
 grind
theorem frozenRootViewStable (q : State) (h : Safe q) (f : q.frozen=1) : q.oldRoot=q.viewOld ∧ q.newRoot=q.viewNew ∧ q.dest=q.viewDest ∧ q.writer=0 := by
 unfold Safe at h
 grind
theorem pendingAckRetainsBorrow (q : State) (h : Safe q) (p : q.pending=1) : q.borrower=1 ∧ q.dest=1 ∧ q.acknowledged=0 := by
 unfold Safe at h
 grind
theorem sourceReleaseAtMostOnce (q : State) (h : Safe q) : q.borrower+q.borrowReleased=q.borrowCreated ∧ q.borrowReleased≤1 := by
 unfold Safe at h
 grind
theorem staleGenerationRejected (q : State) (g : q.tokenGeneration≠q.generation) : ¬ acquireBorrowGuard q := by
 unfold acquireBorrowGuard
 grind
theorem revokeDoesNotDestroyBorrow (q : State) : (revokeNext q).borrower=q.borrower ∧ (revokeNext q).oldRoot=q.oldRoot ∧ (revokeNext q).newRoot=q.newRoot := by
 exact ⟨rfl,rfl,rfl⟩
end TclBorrow

import DispatchJointAccess
import DispatchJointReserve
import DispatchJointCommit
import DispatchJointUse
import DispatchJointExit
import DispatchJointReclaim
import DispatchJointFreeze
open DispatchJointAst
namespace DispatchJoint
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 unfold Step at hs
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27
 · rcases h0 with ⟨g,rfl⟩
   exact enterNativePreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact enterOtherPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact leaveOtherPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact selectHandlePreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact deleteCommandPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact reserveRootPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact rejectBeforeReservePreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact commitJointPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact rejectReservedDeletePreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact abortPreparationPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact loseReplyPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact resolveReservedAbortPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact ackCommitPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact readSelectedPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact finishUsePreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact retireBorrowPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact deliverOutcomePreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact leaveScopePreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact leaveEmptyScopePreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact removeRootPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact freeStoragePreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact freeControlPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact closeGcPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact freezeRootsPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact beginScanPreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact endScanPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact resumeGcPreserves q h g
 · rcases h27 with rfl
   exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | advance {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | advance _ s ih => exact stepPreserves _ _ ih s
theorem borrowHasJointBacking (q : State) (h : Safe q) (b : q.borrow=1) :
 q.nativeAuth=1 ∧ q.rootAuth=1 ∧ q.root=1 ∧ q.storage=1 := by
 unfold Safe at h
 grind
theorem unknownRetainsCustody (q : State) (h : Safe q) (u : q.unknown=1) :
 q.scope=1 ∧ q.root=1 ∧ q.control=1 ∧ q.known=0 := by
 unfold Safe at h
 grind
theorem freezeNeedsWriterDrain (q : State) (h : Safe q) (f : q.frozen=1) : q.lease=0 := by
 unfold Safe at h
 grind
theorem refusalReadNothing (q : State) (h : Safe q) (r : q.refused=1) : q.dataReads=0 ∧ q.committed=0 := by
 unfold Safe at h
 grind
theorem liveScopesPreventFree (q : State) (h : Safe q) (r : q.others≥1 ∨ q.scope=1) : q.storage=1 ∧ q.control=1 := by
 unfold Safe at h
 grind
theorem releaseAtMostOnce (q : State) (h : Safe q) : q.released≤q.created ∧ q.released≤1 := by
 unfold Safe at h
 omega
end DispatchJoint

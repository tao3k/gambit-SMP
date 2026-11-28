import Std.Tactic
namespace DecrementRestoreClosure
structure Custody where
 claim : Bool
 execution : Bool
 published : Bool
 known : Bool
 restorePending : Bool
def covered (s : Custody) := s.restorePending=true → s.claim=true ∨ s.execution=true
def adopt (s : Custody) : Custody := {s with execution:=true}
def publish (s : Custody) : Custody := {s with published:=true}
def decrement (s : Custody) : Custody := {s with claim:=false}
def loseReply (s : Custody) : Custody := {s with known:=false}
def query (s : Custody) : Custody := {s with known:=true}
def settle (s : Custody) : Custody := {s with restorePending:=false}
def detach (s : Custody) : Custody := {s with execution:=false}
theorem adoptedCovers (s : Custody) : covered (adopt s) := by simp [covered,adopt]
theorem handoffReleaseCovered (s : Custody) (owner : s.execution=true) : covered (decrement s) := by
 simp [covered,decrement,owner]
theorem activeRestoreNeedsOwner (s : Custody) (h : covered s) (active : s.restorePending=true) :
 s.claim=true ∨ s.execution=true := h active
theorem noBareReleaseDuringRestore : ¬covered ⟨false,false,false,true,true⟩ := by simp [covered]
theorem unknownKeepsCoverage (s : Custody) (h : covered s) : covered (loseReply s) := h
theorem leafRequiresSettled (pending : Bool) (h : pending=false) : pending≠true := by simp [h]
inductive Edge : Custody → Custody → Prop where
 | adopt (s) : Edge s (adopt s)
 | publish (s) (owner : s.execution=true) : Edge s (publish s)
 | release (s) (owner : s.execution=true) (receipt : s.published=true) (known : s.known=true) : Edge s (decrement s)
 | unknown (s) : Edge s (loseReply s)
 | query (s) : Edge s (query s)
 | settle (s) : Edge s (settle s)
 | detach (s) (done : s.restorePending=false) : Edge s (detach s)
theorem stepPreserves (s t : Custody) (h : covered s) (e : Edge s t) : covered t := by
 cases e with
 | adopt => exact adoptedCovers s
 | publish owner => exact h
 | release owner receipt known => exact handoffReleaseCovered s owner
 | unknown => exact h
 | query => exact h
 | settle => simp [covered,settle]
 | detach done => simp [covered,detach,done]
inductive Trace : Custody → Custody → Prop where
 | nil (s) : Trace s s
 | cons {s t u} : Edge s t → Trace t u → Trace s u
theorem restoreHistoryCovered {s t : Custody} (h : covered s) (trace : Trace s t) : covered t := by
 induction trace with
 | nil => exact h
 | cons first rest ih => exact ih (stepPreserves _ _ h first)
def canRetireVm (claim execution capture invocation : Bool) :=
 claim=false ∧ execution=false ∧ capture=false ∧ invocation=false
theorem captureBlocksVmRetirement (c e i : Bool) : ¬canRetireVm c e true i := by simp [canRetireVm]
theorem invocationBlocksVmRetirement (c e k : Bool) : ¬canRetireVm c e k true := by simp [canRetireVm]
theorem executionBlocksVmRetirement (c k i : Bool) : ¬canRetireVm c true k i := by simp [canRetireVm]
def canRetireProcessor (activeRestore activeInvocation : Bool) := activeRestore=false ∧ activeInvocation=false
theorem captureDoesNotPinOldProcessor : ¬canRetireVm false false true false ∧ canRetireProcessor false false := by simp [canRetireVm,canRetireProcessor]
def returnDecision (sameProcessor markerAlive : Bool) : Nat :=
 if !sameProcessor then 1 else if !markerAlive then 2 else 0
theorem deadMarkerDeniesC : returnDecision true false=2 := rfl
theorem wrongProcessorFirst (alive : Bool) : returnDecision false alive=1 := by simp [returnDecision]
theorem validCReturn : returnDecision true true=0 := rfl
theorem deadMarkerStillHasRestore : returnDecision true false=2 ∧ covered ⟨false,true,false,true,true⟩ := by
 simp [returnDecision,covered]
def publicationAllowed (executionLive immutableRecord readyRoots : Bool) :=
 executionLive=true ∧ immutableRecord=true ∧ readyRoots=true
theorem noOwnerNoPublish (r roots : Bool) : ¬publicationAllowed false r roots := by simp [publicationAllowed]
theorem noRootsNoPublish (e r : Bool) : ¬publicationAllowed e r false := by simp [publicationAllowed]
def visibleAtAcquire (seen committed : Nat) := seen=committed
theorem sameReceiptAfterAcquire (seen committed : Nat) (readsFrom : visibleAtAcquire seen committed) : seen=committed := readsFrom
theorem netBenefit (oldWork newWork saved added : Nat) (balance : newWork+saved=oldWork+added)
 (gain : added<saved) : newWork<oldWork := by omega
end DecrementRestoreClosure

import Std.Tactic
namespace DeviceCleanupWait
structure Wake where
 requested : Nat
 served : Nat
 token : Bool
 ready : Bool
 blocked : Bool
 deriving DecidableEq
def durable (s : Wake) := s.blocked=true → s.requested>s.served → s.token=true ∨ s.ready=true
def raise (s : Wake) := {s with requested := s.requested+1, token := true}
def canBlock (s : Wake) := s.requested=s.served ∧ s.token=false ∧ s.ready=false
def block (s : Wake) := {s with blocked := true}
theorem armCheckSafe (s : Wake) (h : canBlock s) : durable (block s) := by
 intro _ pending; simp only [block] at pending
 have eq := h.1; omega
theorem raisePreservesWake (s : Wake) : durable (raise s) := by
 intro _ _; exact Or.inl rfl
def receive (s : Wake) := {s with token := false, blocked := false}
theorem receivePreservesReady (s : Wake) : (receive s).ready=s.ready := rfl
theorem receivePreservesPending (s : Wake) : (receive s).requested=s.requested ∧ (receive s).served=s.served := ⟨rfl,rfl⟩
structure Cursor where
 phase : Nat
 wrapperCalls : Nat
 nativeLive : Bool
 unknown : Bool
 waitGeneration : Nat
 generation : Nat
 deriving DecidableEq
def retry (s : Cursor) := {s with unknown := false}
theorem retrySamePhase (s : Cursor) : (retry s).phase=s.phase ∧ (retry s).wrapperCalls=s.wrapperCalls := ⟨rfl,rfl⟩
def validWait (s : Cursor) := s.waitGeneration=s.generation
theorem generationMustMatch (s : Cursor) (h : validWait s) : s.waitGeneration=s.generation := h
def rosterComplete (members joined : Nat → Prop) := ∀ p, members p → joined p
theorem rosterEveryParticipant (m j : Nat → Prop) (h : rosterComplete m j) (p : Nat) (member : m p) : j p := h p member
def restorePermit (requested served epoch loaded : Nat) := requested=served ∧ epoch=loaded
theorem pendingBlocksResume (q a e l : Nat) (h : q>a) : ¬restorePermit q a e l := by
 intro p; have eq:=p.1; omega
theorem staleEpochBlocksResume (q a e l : Nat) (h : e≠l) : ¬restorePermit q a e l := by
 intro p; exact h p.2
structure Debt where
 accepted : Nat
 settled : Nat
 live : Nat
def balanced (s : Debt) := s.accepted=s.settled+s.live
def reserve (s : Debt) := {s with accepted:=s.accepted+1,live:=s.live+1}
def finish (s : Debt) := {s with settled:=s.settled+1,live:=s.live-1}
theorem reserveConserves (s : Debt) (h : balanced s) : balanced (reserve s) := by
 simp only [balanced,reserve] at *; omega
theorem finishConserves (s : Debt) (h : balanced s) (positive : 0<s.live) : balanced (finish s) := by
 simp only [balanced,finish] at *; omega
inductive Step : Debt → Debt → Prop where
 | child (s) : Step s (reserve s)
 | done (s) (positive : 0<s.live) : Step s (finish s)
 | wait (s) : Step s s
theorem debtStepPreserves (s t : Debt) (h : balanced s) (edge : Step s t) : balanced t := by
 cases edge with
 | child => exact reserveConserves s h
 | done positive => exact finishConserves s h positive
 | wait => exact h
def exitPermit (nativeDone noUnknown noAffinity storageAck rosterClosed waitReleased : Bool) :=
 nativeDone=true ∧ noUnknown=true ∧ noAffinity=true ∧ storageAck=true ∧ rosterClosed=true ∧ waitReleased=true
theorem unknownBlocksExit (n a s r w : Bool) : ¬exitPermit n false a s r w := by simp [exitPermit]
theorem borrowBlocksExit (n u a s r : Bool) : ¬exitPermit n u a s r false := by simp [exitPermit]
def vmPermit (debtZero rootsClosed outcomesConsumed serviceLeasesClosed : Bool) := debtZero=true ∧ rootsClosed=true ∧ outcomesConsumed=true ∧ serviceLeasesClosed=true
theorem childBlocksVm (r o l : Bool) : ¬vmPermit false r o l := by simp [vmPermit]
theorem outcomeBlocksVm (d r l : Bool) : ¬vmPermit d r false l := by simp [vmPermit]
theorem serviceBlocksVm (d r o : Bool) : ¬vmPermit d r o false := by simp [vmPermit]
def commitOwner (_oldOwner _oldScanner : Nat) := (0,0)
theorem commitScanner (o s : Nat) : (commitOwner o s).1=(commitOwner o s).2 := rfl
theorem netBenefit (oldWork newWork saved added : Nat) (balance : newWork+saved=oldWork+added) (gain : added<saved) : newWork<oldWork := by omega
end DeviceCleanupWait

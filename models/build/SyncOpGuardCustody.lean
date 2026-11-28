import Std.Tactic
namespace SyncOpGuardCustody
structure Participant where
 rootReady : Bool
 mutatorStopped : Bool
 dispatchAvailable : Bool
 returned : Bool
def participate (p : Participant) := p.rootReady=true ∧ p.mutatorStopped=true ∧ p.dispatchAvailable=true
theorem readinessNotReturn : ∃ p : Participant, participate p ∧ p.returned=false := by
 exact ⟨⟨true,true,true,false⟩, by simp [participate]⟩
theorem sleepingDoesNotParticipate : ¬participate ⟨true,true,false,false⟩ := by simp [participate]
def loopReturn (gcReturned reset requestCleared finalNoop : Bool) := gcReturned=true ∧ reset=true ∧ requestCleared=true ∧ finalNoop=true
theorem gcReturnAloneInsufficient : ¬loopReturn true true true false := by simp [loopReturn]
theorem loopReturnRequiresReset (g r c n : Bool) (h : loopReturn g r c n) : r=true := h.2.1
structure ErrorRecord where
 value : Nat
 destination : Nat
 secondary : Bool
def addSecondary (e : ErrorRecord) := {e with secondary := true}
theorem cleanupPreservesOriginal (e : ErrorRecord) : (addSecondary e).value=e.value ∧ (addSecondary e).destination=e.destination := ⟨rfl,rfl⟩
def guardPermit (terminal catcher marker outcomeRoot : Bool) := terminal=true ∧ catcher=true ∧ marker=true ∧ outcomeRoot=true
theorem rethrowNeedsOutcomeRoot (t c m o : Bool) (h : guardPermit t c m o) : o=true := h.2.2.2
def collectiveThrowPermit (loopClosed guardAccepted : Bool) := loopClosed=true ∧ guardAccepted=true
theorem collectiveUnwindMustWait : ¬collectiveThrowPermit false true := by simp [collectiveThrowPermit]
def canLeaveLoop (pendingGc cleared : Bool) := pendingGc=false ∧ cleared=true
theorem internalGcCannotConsumeRequest : ¬canLeaveLoop true true := by simp [canLeaveLoop]
def exitPermit (loop guard rootWithdrawal storageAck foreignClosed unknown : Bool) := loop=true ∧ guard=true ∧ rootWithdrawal=true ∧ storageAck=true ∧ foreignClosed=true ∧ unknown=false
theorem rootsAloneCannotExit : ¬exitPermit false false true false false false := by simp [exitPermit]
theorem unknownStorageBlocks (l g r f : Bool) : ¬exitPermit l g r false f true := by simp [exitPermit]
theorem exitNeedsGuard (l g r s f u : Bool) (h : exitPermit l g r s f u) : g=true := h.2.1
def withdrawSafe (pin reader unknown : Bool) := pin=false ∧ reader=false ∧ unknown=false
theorem pinBlocksWithdrawal (r u : Bool) : ¬withdrawSafe true r u := by simp [withdrawSafe]
def votesComplete (roster votes : Nat → Prop) := ∀ w, roster w → votes w
theorem nonzeroVoteRequired (r v : Nat → Prop) (h : votesComplete r v) (one : r 1) : v 1 := h 1 one
def tailsClosed (required done : Nat → Prop) := ∀ w, required w → done w
theorem tailReceiptRequiresEverySender (r d : Nat → Prop) (h : tailsClosed r d) (w : Nat) (member : r w) : d w := h w member
def vmTeardownPermit (rootsClosed foreignClosed noReaders noFutureGc : Bool) := rootsClosed=true ∧ foreignClosed=true ∧ noReaders=true ∧ noFutureGc=true
theorem vmCannotCloseWhileOutcomeRoot : ¬vmTeardownPermit false true true true := by simp [vmTeardownPermit]
def reusePermit (joined unknown : Bool) := joined=true ∧ unknown=false
theorem joinUnknownCannotReuse : ¬reusePermit false true := by simp [reusePermit]
theorem netBenefit (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end SyncOpGuardCustody

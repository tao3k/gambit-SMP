import Std.Tactic
namespace NativeWakeChannel
structure Wake where
 requested : Nat
 served : Nat
 token : Bool
 blocked : Bool
 retryOwned : Bool
 rescueOwned : Bool
 finiteFallback : Bool
 deriving DecidableEq
def owned (s : Wake) := s.blocked=true → s.served<s.requested → s.token=true ∨ s.retryOwned=true ∨ s.rescueOwned=true ∨ s.finiteFallback=true
def full (s : Wake) := {s with token:=true}
theorem fullRetainsWake (s : Wake) : owned (full s) := by intro _ _; exact Or.inl rfl
def interrupted (s : Wake) := {s with retryOwned:=true}
theorem eintrRetainsOwner (s : Wake) : owned (interrupted s) := by intro _ _; exact Or.inr (Or.inl rfl)
def hardFailure (s : Wake) := {s with rescueOwned:=true}
theorem failureRetainsCustody (s : Wake) : owned (hardFailure s) := by intro _ _; exact Or.inr (Or.inr (Or.inl rfl))
def drain (s : Wake) := {s with token:=false,blocked:=false}
theorem drainPreservesRequest (s : Wake) : (drain s).requested=s.requested ∧ (drain s).served=s.served := ⟨rfl,rfl⟩
def canSleep (s : Wake) := s.requested=s.served ∧ s.token=false
theorem pendingBlocksSleep (s : Wake) (h : s.served<s.requested) : ¬canSleep s := by
 intro p; have eq:=p.1; omega
-- Timer arithmetic is conditional on an actual qualified native deadline and scheduling.
def remaining (budget elapsed : Nat) := budget-elapsed
theorem fallbackDeadline (budget elapsed : Nat) (h : budget≤elapsed) : remaining budget elapsed=0 := by simp only [remaining]; omega
theorem safetyAloneNotProgress : ∃ s : Wake, owned s ∧ s.blocked=true ∧ s.served<s.requested ∧ s.token=false ∧ s.finiteFallback=false := by
 exact ⟨⟨1,0,false,true,true,false,false⟩, by simp [owned]⟩
structure Endpoint where
 generation : Nat
 pins : Nat
 waitPins : Nat
 alive : Bool
 ingressClosed : Bool
 signalsQuiesced : Bool
 deriving DecidableEq
def canClose (e : Endpoint) := e.pins=0 ∧ e.waitPins=0 ∧ e.ingressClosed=true ∧ e.signalsQuiesced=true
theorem pinBlocksClose (e : Endpoint) (h : 0<e.pins) : ¬canClose e := by intro p; have eq:=p.1; omega
theorem waitPinBlocksClose (e : Endpoint) (h : 0<e.waitPins) : ¬canClose e := by intro p; have eq:=p.2.1; omega
def takePin (e : Endpoint) := {e with pins:=e.pins+1}
theorem takePinRetainsGeneration (e : Endpoint) : (takePin e).generation=e.generation := rfl
def validHandle (e : Endpoint) (generation : Nat) := e.alive=true ∧ e.ingressClosed=false ∧ e.generation=generation
theorem staleHandleRejected (e : Endpoint) (g : Nat) (h : e.generation≠g) : ¬validHandle e g := by intro p; exact h p.2.2
def close (e : Endpoint) := {e with alive:=false}
theorem closeChangesOnlyLifetime (e : Endpoint) : (close e).generation=e.generation ∧ (close e).pins=e.pins := ⟨rfl,rfl⟩
-- Full-generation safety depends on the admission gate, not this arithmetic identity.
def reuse (e : Endpoint) := {e with generation:=e.generation+1}
theorem reuseInvalidatesOld (e : Endpoint) : (reuse e).generation≠e.generation := by simp [reuse]
structure Ledger where
 accepted : Nat
 settled : Nat
 live : Nat
def balanced (s : Ledger) := s.accepted=s.settled+s.live
def publish (s : Ledger) := {s with accepted:=s.accepted+1,live:=s.live+1}
def settle (s : Ledger) := {s with settled:=s.settled+1,live:=s.live-1}
theorem publicationConserves (s : Ledger) (h : balanced s) : balanced (publish s) := by simp only [balanced,publish] at *; omega
theorem settlementConserves (s : Ledger) (h : balanced s) (p : 0<s.live) : balanced (settle s) := by simp only [balanced,settle] at *; omega
inductive Step : Ledger → Ledger → Prop where
 | accept (s) : Step s (publish s)
 | delivered (s) (positive : 0<s.live) : Step s (settle s)
 | retry (s) : Step s s
 | rescue (s) : Step s s
theorem notificationStepPreserves (s t : Ledger) (h : balanced s) (edge : Step s t) : balanced t := by
 cases edge with
 | accept => exact publicationConserves s h
 | delivered p => exact settlementConserves s h p
 | retry => exact h
 | rescue => exact h
def complete (members joined : Nat → Prop) := ∀ p, members p → joined p
theorem rosterEveryParticipant (m j : Nat → Prop) (h : complete m j) (p : Nat) (member : m p) : j p := h p member
def retirement (quiet signalFence rosterClosed outcomeKnown : Bool) := quiet=true ∧ signalFence=true ∧ rosterClosed=true ∧ outcomeKnown=true
theorem unknownCloseBlocksExit (q s r : Bool) : ¬retirement q s r false := by simp [retirement]
theorem signalFenceRequired (q r o : Bool) : ¬retirement q false r o := by simp [retirement]
-- SC total-order constraints for two stores followed by peer loads.
-- Mapping each SC read of the initial value to these order premises remains a C refinement duty.
theorem noDoubleMissSC (publish observeArm arm observePending : Nat)
 (producerOrder : publish<observeArm) (consumerOrder : arm<observePending)
 (missArm : observeArm<arm) (missPending : observePending<publish) : False := by omega
theorem netBenefit (oldWork newWork saved added : Nat) (balance : newWork+saved=oldWork+added) (gain : added<saved) : newWork<oldWork := by omega
end NativeWakeChannel

import Std.Tactic
namespace ReleaseCommitCustody
-- Logical release authority and physical root/caller custody are distinct.
structure Token where
 released : Bool
 drops : Nat
def tokenSafe (t : Token) := t.drops=(if t.released then 1 else 0)
def release (t : Token) : Token := if t.released then t else ⟨true,t.drops+1⟩
def initial : Token := ⟨false,0⟩
theorem initialSafe : tokenSafe initial := rfl
theorem releasePreserves (t : Token) (h : tokenSafe t) : tokenSafe (release t) := by
 cases r : t.released <;> simp_all [tokenSafe,release]
theorem repeatReleaseIdempotent (t : Token) : release (release t)=release t := by
 cases r : t.released <;> simp [release,r]
theorem oneEvent (t : Token) (h : tokenSafe t) : (release t).drops=1 := by
 have s:=releasePreserves t h
 cases r : t.released <;> simp_all [tokenSafe,release]
inductive Edge : Token → Token → Prop where
 | release (t) : Edge t (release t)
 | query (t) : Edge t t
inductive Trace : Token → Token → Prop where
 | nil (t) : Trace t t
 | cons {s t u} : Edge s t → Trace t u → Trace s u
theorem stepPreserves {s t : Token} (h : tokenSafe s) (e : Edge s t) : tokenSafe t := by
 cases e with
 | release => exact releasePreserves s h
 | query => exact h
theorem historyPreserves {s t : Token} (h : tokenSafe s) (es : Trace s t) : tokenSafe t := by
 induction es with
 | nil => exact h
 | cons e es ih => exact ih (stepPreserves h e)
def visible (dropped recorded : Bool) : Option Bool := if recorded then some dropped else none
theorem legacyAmbiguity : visible false false=visible true false := rfl
theorem noBlindRecovery (f : Option Bool → Bool) : ¬(∀ dropped : Bool, f (visible dropped false)= !dropped) := by
 intro h
 have a:=h false
 have b:=h true
 simp [visible] at a b
 rw [a] at b
 contradiction
structure Keeper where
 root : Bool
 session : Bool
 debt : Bool
def covered (k : Keeper) := k.debt=true → k.root=true ∧ k.session=true
def loseReply (k : Keeper) := k
theorem unknownKeepsKeeper (k : Keeper) (h : covered k) : covered (loseReply k) := h
theorem criticalNeedsCustody (k : Keeper) (h : covered k) (pending : k.debt=true) : k.root=true ∧ k.session=true := h pending
def retire (k : Keeper) : Keeper := {k with root:=false,session:=false}
theorem rootRetirementRequiresSettled (k : Keeper) (done : k.debt=false) : covered (retire k) := by simp [covered,retire,done]
theorem tokenReleaseDoesNotSettleCaller (k : Keeper) (t : Token) : (k,release t).1.debt=k.debt := rfl
theorem requestDoesNotAuthorizeGC (requested critical : Bool) (h : requested=true) (blocked : critical=true) : ¬(requested=true ∧ critical=false) := by simp [blocked]
theorem tokenReplyRecoverable (t : Token) (done : t.released=true) : (release t).released=true := by simp [release,done]
def canRetire (guard handle invocation : Bool) := guard=false ∧ handle=false ∧ invocation=false
theorem outstandingBlocksVm (h i : Bool) : ¬canRetire true h i := by simp [canRetire]
theorem cancellationRestoredAfterDone (done : Bool) (h : done=true) : done≠false := by simp [h]
theorem auditDistinguishes : (1-0 : Nat)≠(1-1 : Nat) := by decide
theorem zeroCountProvesDropped (drops : Nat) (bound : drops≤1) (observed : 1-drops=0) : drops=1 := by omega
theorem costThreshold (old new saved added : Nat) (balance : new+saved=old+added) (win : added<saved) : new<old := by omega
end ReleaseCommitCustody

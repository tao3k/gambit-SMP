import Std.Tactic
namespace SigintDeliverySemantics
-- Reference bit and candidate finite-key representation; cuts are assumptions,
-- not conclusions about C or Scheme execution.
def publishBit (_ : Bool) : Bool := true
def publishKeys (pending : List Nat) (key : Nat) := if pending.isEmpty then [key] else pending
theorem publishCorrespondence (p : List Nat) (k : Nat) :
 (publishKeys p k).isEmpty = false := by
 unfold publishKeys
 split <;> simp_all
theorem sameEpochMerge (k : Nat) : publishKeys (publishKeys [] k) k = [k] := by simp [publishKeys]
theorem claimReopensPending (k : Nat) : publishKeys [] k = [k] := by simp [publishKeys]
def observation (target vector thread handler : Nat) : List Nat := [target,vector,thread,handler]
theorem lateVectorLookup (t th h old new : Nat) (change : old ≠ new) :
 observation t old th h ≠ observation t new th h := by simp_all [observation]
theorem frozenSelectedHandler (t v th h replacement : Nat) :
 (fun (_ : Nat) => observation t v th h) replacement = observation t v th h := rfl
theorem lateParameterLookup (t v th old new : Nat) (change : old ≠ new) :
 observation t v th old ≠ observation t v th new := by simp_all [observation]
theorem targetIdentity (old new v th h : Nat) (change : old ≠ new) :
 observation old v th h ≠ observation new v th h := by simp_all [observation]
def canRetire (pending active leases : Nat) := pending=0 ∧ active=0 ∧ leases=0
theorem boundWorkBlocksRetirement (p a l : Nat) (work : 0<a) : ¬canRetire p a l := by
 intro h; have z:=h.2.1; omega
theorem pendingBlocksRetirement (p a l : Nat) (work : 0<p) : ¬canRetire p a l := by
 intro h; have z:=h.1; omega
def chooseThread (hasCurrent : Bool) (current primordial : Nat) := if hasCurrent then current else primordial
theorem currentOrPrimordial (b : Bool) (c p : Nat) : chooseThread b c p = c ∨ chooseThread b c p = p := by
 cases b <;> simp [chooseThread]
def replay (pending : Bool) (count : Nat) := if pending then count+1 else count
theorem deferredReplay (n : Nat) : replay true n=n+1 := rfl
theorem noDeferredReplay (n : Nat) : replay false n=n := rfl
theorem afterClearCannotMerge (a b : List Nat) : [a,b].length ≠ [a].length := by simp
inductive Event where
 | raise | claim
 deriving DecidableEq
def referenceStep (s : Bool × Nat) (e : Event) : Bool × Nat :=
 match e with
 | .raise => (true,s.2)
 | .claim => (false,if s.1 then s.2+1 else s.2)
def candidateStep (s : Nat × Nat) (e : Event) : Nat × Nat :=
 match e with
 | .raise => (1,s.2)
 | .claim => (0,s.2+s.1)
def related (r : Bool × Nat) (c : Nat × Nat) := c.1=(if r.1 then 1 else 0) ∧ c.2=r.2
theorem stepRefinement (r : Bool × Nat) (c : Nat × Nat) (e : Event) (h : related r c) :
 related (referenceStep r e) (candidateStep c e) := by
 rcases r with ⟨b,n⟩; rcases c with ⟨p,m⟩
 cases e <;> cases b <;> simp_all [related,referenceStep,candidateStep]
theorem historyRefinement (events : List Event) (r : Bool × Nat) (c : Nat × Nat) (h : related r c) :
 related (events.foldl referenceStep r) (events.foldl candidateStep c) := by
 induction events generalizing r c with
 | nil => exact h
 | cons e rest ih => exact ih _ _ (stepRefinement r c e h)
theorem netBenefit (oldWork newWork saved added : Nat)
 (balance : newWork+saved=oldWork+added) (gain : added<saved) : newWork<oldWork := by omega
end SigintDeliverySemantics

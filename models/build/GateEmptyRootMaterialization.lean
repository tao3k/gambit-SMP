import Std.Tactic
namespace GateEmptyRootMaterialization
def closedZero (isOpen : Bool) (count : Nat) := isOpen=false ∧ count=0
theorem closedZeroQualified (b : Bool) (n : Nat) (h : closedZero b n) : b=false ∧ n=0 := h
theorem openZeroNotQuiescent : ¬closedZero true 0 := by simp [closedZero]
def mayAdmit (isOpen : Bool) (count capacity : Nat) := isOpen=true ∧ count<capacity
theorem closedGateDenies (n cap : Nat) : ¬mayAdmit false n cap := by simp [mayAdmit]
theorem fullGateDenies (n cap : Nat) (h : cap≤n) : ¬mayAdmit true n cap := by
 intro x; have y:=x.2; omega
theorem lastDecrement (n : Nat) (last : n=1) : n-1=0 := by omega
theorem otherOwnersRemain (n : Nat) (notLast : 1<n) : 0<n-1 := by omega
-- RMW carrier induction is conditional on preserving the previous frontier.
def carry (prior emitted : List Nat) := prior++emitted
theorem rmwPreservesPrior (prior emitted : List Nat) (i : Nat) (h : i∈prior) : i∈carry prior emitted := by
 simp [carry,h]
theorem rmwPublishesOwn (prior emitted : List Nat) (i : Nat) (h : i∈emitted) : i∈carry prior emitted := by
 simp [carry,h]
def historyFrontier (initial : List Nat) (steps : List (List Nat)) := steps.foldl carry initial
theorem rmwHistoryPreserves (steps : List (List Nat)) (initial : List Nat) (i : Nat) (h : i∈initial) :
 i∈historyFrontier initial steps := by
 induction steps generalizing initial with
 | nil => exact h
 | cons emitted rest ih => exact ih (carry initial emitted) (rmwPreservesPrior initial emitted i h)
theorem acquireSeesFrontier (frontier seen : List Nat) (i : Nat) (readFrom : seen=frontier)
 (published : i∈frontier) : i∈seen := by simpa [readFrom] using published
theorem lastContributorAloneInsufficient : (0 : Nat)∉([1] : List Nat) := by simp
-- Distinct from C gate instruction proofs: exchange requires an existing owner.
def mayExchange (reserved : Bool) := reserved=true
theorem reservationBeforeExchange (b : Bool) (h : mayExchange b) : b=true := h
theorem unreservedCannotExchange : ¬mayExchange false := by simp [mayExchange]
def emptyReceipt (po co : Bool) (p c pending active : Nat) (exclusive : Bool) :=
 closedZero po p ∧ closedZero co c ∧ pending=0 ∧ active=0 ∧ exclusive=true
theorem finalNeedsBothGates (po co : Bool) (p c q a : Nat) (x : Bool) (h : emptyReceipt po co p c q a x) :
 closedZero po p ∧ closedZero co c := ⟨h.1,h.2.1⟩
theorem activeClaimBlocksFinal (po co : Bool) (p c q a : Nat) (x : Bool) (active : 0<a) :
 ¬emptyReceipt po co p c q a x := by
 intro h; have z:=h.2.2.2.1; omega
theorem pendingBlocksFinal (po co : Bool) (p c q a : Nat) (x : Bool) (pending : 0<q) :
 ¬emptyReceipt po co p c q a x := by
 intro h; have z:=h.2.2.1; omega
structure RootState where
 cached : Nat
 slot : Nat
 identity : Nat
 epoch : Nat
def spillRoot (s : RootState) : RootState := {s with slot:=s.cached}
def moveRoot (s : RootState) (next : Nat) : RootState := {s with slot:=s.identity+next,epoch:=next}
def reloadRoot (s : RootState) : RootState := {s with cached:=s.slot}
def rooted (s : RootState) := s.slot=s.identity+s.epoch
def fresh (s : RootState) := s.cached=s.slot
theorem spillMaterializes (s : RootState) (noMove : s.cached=s.identity+s.epoch) : rooted (spillRoot s) := noMove
theorem relocationPreservesRoot (s : RootState) (next : Nat) : rooted (moveRoot s next) := rfl
theorem reloadFresh (s : RootState) : fresh (reloadRoot s) := rfl
theorem reloadKeepsRoot (s : RootState) (h : rooted s) : rooted (reloadRoot s) := h
theorem staleLocalAfterMove (id old next : Nat) (changed : old≠next) :
 ¬fresh (moveRoot ⟨id+old,id+old,id,old⟩ next) := by
 simp [fresh,moveRoot]; omega
inductive Carrier where
 | r1 | self
 deriving DecidableEq
def moveSelf (value : Nat) (_carrier : Carrier) : Nat × Carrier := (value,.self)
theorem selfTransferPreservesValue (v : Nat) (c : Carrier) : (moveSelf v c).1=v := rfl
theorem netBenefit (oldWork newWork saved added : Nat) (balance : newWork+saved=oldWork+added)
 (gain : added<saved) : newWork<oldWork := by omega
end GateEmptyRootMaterialization

import Std.Tactic
namespace OrderedRegistryDelivery
structure Journal where
 events : List Nat
 entries : List Nat
 generation : Nat
 deriving DecidableEq
def commit (id : Nat) (s : Journal) : Journal :=
 if id ∈ s.events then s else ⟨s.events ++ [id],7::s.entries,s.generation+1⟩
theorem commitIdempotent (id : Nat) (s : Journal) : commit id (commit id s)=commit id s := by
 by_cases h : id ∈ s.events
 · simp [commit,h]
 · simp [commit,h]
theorem commitOrder (id : Nat) (s : Journal) (h : id ∉ s.events) : (commit id s).events=s.events++[id] := by simp [commit,h]
def empty : Journal := ⟨[],[],0⟩
theorem equalPayloadDistinct : (commit 1 (commit 0 empty)).entries=[7,7] := by decide
def parseGenerationOf (boundary : Nat) : Nat := boundary
theorem parseGeneration (boundary : Nat) : parseGenerationOf boundary=boundary := rfl
def receiptGenerationOf (id : Nat) (ledger : Nat → Option Nat) := ledger id
theorem receiptGeneration (id generation : Nat) (ledger : Nat → Option Nat) (h : ledger id=some generation) : receiptGenerationOf id ledger=some generation := h
def failure (s : Journal) : Journal := s
theorem failureRetainsPrefix (s : Journal) : (failure s).events=s.events ∧ (failure s).entries=s.entries := by simp [failure]
def canDrain (pending unknown saved : Bool) := !pending && !unknown && !saved
theorem holdersBlockDrain (pending unknown saved : Bool) (h : pending=true ∨ unknown=true ∨ saved=true) : canDrain pending unknown saved=false := by
 rcases h with h|h|h <;> simp [canDrain,h]
theorem costPositive (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end OrderedRegistryDelivery

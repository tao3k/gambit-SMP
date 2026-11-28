import PrimitiveBindingAlgebra
namespace BindingWriterClosure
open PrimitiveBindingAlgebra
def canonical (r : Resource) : Prop := r.demanders=[""]
inductive NamedStep : Resource → Resource → Prop where
 | useFalse (r) : NamedStep r (demand r)
 | useTrue (r) : NamedStep r (supply r)
inductive NamedHistory : Resource → Resource → Prop where
 | start (r) : NamedHistory r r
 | next {a b c} : NamedHistory a b → NamedStep b c → NamedHistory a c
theorem demandCanonical (r : Resource) : canonical (demand r) := by rfl
theorem supplyKeepsCanonical (r : Resource) (h : canonical r) : canonical (supply r) := h
theorem stepKeepsCanonical {r s : Resource} (h : canonical r) (edge : NamedStep r s) : canonical s := by
 cases edge with
 | useFalse => exact demandCanonical _
 | useTrue => exact supplyKeepsCanonical _ h
theorem historyKeepsCanonical {a b : Resource} (h : canonical a) (steps : NamedHistory a b) : canonical b := by
 induction steps with
 | start => exact h
 | next _ edge ih => exact stepKeepsCanonical ih edge
theorem secondAfterNamedHistory {a b : Resource} (h : canonical a) (steps : NamedHistory a b) : demand b=b :=
 (exactDemandUnchanged b).2 (historyKeepsCanonical h steps)
theorem firstObservable : (demand ⟨"p",[],[""]⟩).demanders ≠ ([] : List String) := by decide
theorem rawWriterBreaks : demand ⟨"p",["changed"],[""]⟩ ≠ ⟨"p",["changed"],[""]⟩ := by decide
theorem namesDoNotReplaceIdentity (a b : Nat) (h : a≠b) : (a,"p")≠(b,"p") := by
 intro e; exact h (congrArg Prod.fst e)
-- These are structural laws, not a theorem about every runtime callback or setter event.
end BindingWriterClosure

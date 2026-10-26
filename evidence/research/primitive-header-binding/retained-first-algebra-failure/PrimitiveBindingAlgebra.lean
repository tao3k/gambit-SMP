import Std
namespace PrimitiveBindingAlgebra
structure Resource where
 name : String
 demanders : List String
 suppliers : List String
 deriving DecidableEq
def demand (r : Resource) : Resource := {r with demanders := [""]}
def supply (r : Resource) : Resource := {r with suppliers := [""]}
def demanded (r : Resource) : Prop := r.demanders ≠ []
theorem demandIdempotent (r : Resource) : demand (demand r)=demand r := by rfl
theorem supplyIdempotent (r : Resource) : supply (supply r)=supply r := by rfl
theorem exactDemandUnchanged (r : Resource) : demand r=r ↔ r.demanders=[""] := by
 constructor
 · intro h; have z := congrArg Resource.demanders h; simpa [demand] using z.symm
 · intro h; cases r; simp_all [demand]
theorem classificationUnchanged (r : Resource) : (demanded (demand r) ↔ demanded r) ↔ r.demanders ≠ [] := by simp [demanded,demand]
theorem supplierPreserved (r : Resource) : (demand r).suppliers=r.suppliers := by rfl
theorem suppliedOnlyChangesHeader : ¬ demanded ⟨"p",[],[""]⟩ ∧ demanded (demand ⟨"p",[],[""]⟩) := by decide
theorem noncanonicalChangesPayload : demand ⟨"p",["caller"],[""]⟩ ≠ ⟨"p",["caller"],[""]⟩ := by decide
structure Span where
 start : Nat
 stop : Nat
 deriving DecidableEq
def valid (bytes : List UInt8) (s : Span) : Prop := s.start ≤ s.stop ∧ s.stop ≤ bytes.length
def slice (bytes : List UInt8) (s : Span) := (bytes.drop s.start).take (s.stop-s.start)
structure Binding where
 slot : Nat
 label : Nat
 prm : Span
 glo : Span
 deriving DecidableEq
def corresponds (bytes : List UInt8) (b : Binding) (prm glo : List UInt8) : Prop :=
 valid bytes b.prm ∧ valid bytes b.glo ∧ b.prm.stop ≤ b.glo.start ∧ slice bytes b.prm=prm ∧ slice bytes b.glo=glo
theorem correspondenceRequiresBoth (bytes : List UInt8) (b : Binding) (p g : List UInt8)
 (h : corresponds bytes b p g) : slice bytes b.prm=p ∧ slice bytes b.glo=g := by exact ⟨h.2.2.2.1,h.2.2.2.2⟩
theorem equalWidthsInsufficient : ([65] : List UInt8).length=([66] : List UInt8).length ∧ ([65] : List UInt8)≠[66] := by decide
-- This theorem does not connect the Python byte reader or macro expansion to Lean.
end PrimitiveBindingAlgebra

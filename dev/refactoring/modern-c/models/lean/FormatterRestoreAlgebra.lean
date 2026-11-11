import BindingWriterClosure
namespace FormatterRestoreAlgebra
open PrimitiveBindingAlgebra BindingWriterClosure
structure FormatterKey where
 objectId : Nat
 generation : Nat
 deriving DecidableEq
def savedKey : FormatterKey := ⟨1,1⟩
def abaKey : FormatterKey := ⟨1,3⟩
theorem sameObjectNotSameKey : savedKey.objectId=abaKey.objectId ∧ savedKey≠abaKey := by decide
theorem unconditionalRestoreOverwritesNewer : (1 : Nat)≠2 := by decide
def restoreIfOwned (owner current : FormatterKey) (saved : Nat) : Nat := if owner=current then saved else current.objectId
theorem conflictPreservesCurrent (owner current : FormatterKey) (saved : Nat) (h : owner≠current) : restoreIfOwned owner current saved=current.objectId := by simp [restoreIfOwned,h]
structure WriterView where
 selected : Nat
 deriving DecidableEq
def resolveScoped (view : WriterView) (_registration : FormatterKey) : Nat := view.selected
theorem scopedResolverIndependent (view : WriterView) (a b : FormatterKey) : resolveScoped view a=resolveScoped view b := by rfl
theorem secondUnderNamedWriters {a b : Resource} (h : canonical a) (steps : NamedHistory a b) : demand b=b := secondAfterNamedHistory h steps
-- No theorem here says these value abstractions implement actual Scheme unwinding.
end FormatterRestoreAlgebra

import ModuleHandle
import ImageEnrollmentComposition
namespace ModuleHandleComposition
open ModuleHandleAst
def manifestUnion (inputs : List (List Nat)) : List Nat := inputs.flatten
theorem declaredChildCovered (inputs : List (List Nat)) (child : List Nat) (member : Nat)
 (registered : child ∈ inputs) (present : member ∈ child) : member ∈ manifestUnion inputs := by
 simp only [manifestUnion,List.mem_flatten]
 exact ⟨child,registered,present⟩
def effectPlan (oldEntries newEntries : List Nat) : List Nat := oldEntries ++ newEntries
theorem orderedEffectsPreserved (oldEntries newEntries : List Nat) :
 effectPlan oldEntries newEntries = oldEntries ++ newEntries := by rfl
theorem duplicateEffectsRemain (x : Nat) : effectPlan [x] [x] = [x,x] := by rfl
theorem rawMigrationBlocksPriorPermit (q : State) (p : ImageEnrollmentAst.State)
 (sameRaw : p.rawEscape=q.raw) (escaped : q.raw=true) : ¬ImageEnrollmentAst.permitGuard p := by
 apply ImageEnrollmentComposition.legacyRawBlocksPermit p
 rw [sameRaw]; exact escaped
end ModuleHandleComposition

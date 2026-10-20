import WorkAccounting

namespace GambitSMP.Experimental.RetirementHandoff

-- Logical owner availability, not physical GC or cross-VM value transfer.
def Rooted (payload vm source destination : Bool) : Prop :=
  payload = true → vm = true ∧ (source = true ∨ destination = true)

theorem tracedHandoffPermitsOwnerExit (payload vm source destination : Bool)
    (before : Rooted payload vm source destination)
    (published : destination = true) : Rooted payload vm false destination := by
  intro needed
  exact ⟨(before needed).1, Or.inr published⟩

theorem exitWithoutHandoffLosesRoot : ¬ Rooted true true false false := by
  simp [Rooted]

theorem sameVmRootDoesNotSurviveDestruction (destination : Bool) :
    ¬ Rooted true false false destination := by
  simp [Rooted]

structure Obligations where
  borrower : Bool
  publisher : Bool
  payload : Bool
  oldHandler : Bool

def Drained (o : Obligations) : Prop :=
  o.borrower = false ∧ o.publisher = false ∧
  o.payload = false ∧ o.oldHandler = false

theorem borrowerDrainIsNotPayloadDischarge :
    ¬ Drained ⟨false, false, true, false⟩ := by
  simp [Drained]

theorem registryDrainIsNotHandlerQuiet :
    ¬ Drained ⟨false, false, false, true⟩ := by
  simp [Drained]

-- The source supplies this complete inventory; the theorem cannot discover
-- omitted borrowers, producers, roots or pre-admission OS deliveries.
theorem retirementDischargesEachOwner (o : Obligations) (drained : Drained o) :
    o.payload = false ∧ o.oldHandler = false ∧
    o.borrower = false ∧ o.publisher = false := by
  exact ⟨drained.2.2.1, drained.2.2.2, drained.1, drained.2.1⟩

theorem balancedExceptionalEntries
    (a1 a2 r1 r2 : Nat) (original1 original2 delivered1 delivered2 : Int)
    (first : WorkAccounting.EntryBalanced a1 r1 original1 delivered1)
    (second : WorkAccounting.EntryBalanced a2 r2 original2 delivered2) :
    a1 + a2 = r1 + r2 ∧ original1 = delivered1 ∧ original2 = delivered2 :=
  WorkAccounting.balancedNestedExitsCompose
    a1 a2 r1 r2 original1 original2 delivered1 delivered2 first second

#print axioms tracedHandoffPermitsOwnerExit
#print axioms exitWithoutHandoffLosesRoot
#print axioms sameVmRootDoesNotSurviveDestruction
#print axioms borrowerDrainIsNotPayloadDischarge
#print axioms registryDrainIsNotHandlerQuiet
#print axioms retirementDischargesEachOwner
#print axioms balancedExceptionalEntries

end GambitSMP.Experimental.RetirementHandoff

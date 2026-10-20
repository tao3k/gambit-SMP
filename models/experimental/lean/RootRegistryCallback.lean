import WorkAccounting

namespace GambitSMP.RootRegistryCallback

-- This narrow delete permission is not general callback or insertion authority.
def ScannerDelete (owner caller depth : Nat) (deleting : Bool) : Prop :=
  owner = caller ∧ 0 < depth ∧ deleting = true

theorem ownerMayDelete (owner depth : Nat) (nested : 0 < depth) :
    ScannerDelete owner owner depth true := ⟨rfl, nested, rfl⟩

theorem foreignOwnerCannotBorrowDepth (owner caller depth : Nat)
    (different : owner ≠ caller) : ¬ ScannerDelete owner caller depth true := by
  intro permission
  exact different permission.1

theorem deletionDoesNotAuthorizeInsertion (owner depth : Nat) :
    ¬ ScannerDelete owner owner depth false := by
  simp [ScannerDelete]

def SlotSafe (reader storage : Bool) : Prop := reader = true → storage = true

theorem unlinkedRegistryDoesNotDischargeReader :
    ∃ linked reader storage : Bool,
      linked = false ∧ ¬ SlotSafe reader storage := by
  exact ⟨false, true, false, rfl, by simp [SlotSafe]⟩

theorem rootAvailabilityDoesNotAuthorizeMutation (published : Bool) :
    ¬ GambitSMP.WorkAccounting.InactiveRootsReady published true :=
  GambitSMP.WorkAccounting.rootsDoNotPermitConcurrentMutation published

def MutatorReleased (globalDone : Bool) (localDone : Bool) : Prop :=
  globalDone = true ∧ localDone = true

theorem localRootsDoNotReleaseGlobalScan :
    ¬ MutatorReleased false true := by
  simp [MutatorReleased]

-- Distinct domain entry locks do not imply a process-global writer guard.
theorem domainOwnershipDoesNotSerializeGlobalWriters :
    ∃ ownsFirst ownsSecond globalExclusive : Bool,
      ownsFirst = true ∧ ownsSecond = true ∧ globalExclusive = false := by
  exact ⟨true, true, false, rfl, rfl, rfl⟩

theorem releasedMutatorHasGlobalCompletion (globalDone localDone : Bool)
    (released : MutatorReleased globalDone localDone) : globalDone = true :=
  released.1

#print axioms ownerMayDelete
#print axioms foreignOwnerCannotBorrowDepth
#print axioms deletionDoesNotAuthorizeInsertion
#print axioms unlinkedRegistryDoesNotDischargeReader
#print axioms rootAvailabilityDoesNotAuthorizeMutation
#print axioms localRootsDoNotReleaseGlobalScan
#print axioms domainOwnershipDoesNotSerializeGlobalWriters
#print axioms releasedMutatorHasGlobalCompletion

end GambitSMP.RootRegistryCallback

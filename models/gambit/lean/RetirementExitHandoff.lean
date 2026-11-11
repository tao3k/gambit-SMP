import WorkAccounting

namespace GambitSMP.RetirementExitHandoff

def OriginDischarged (marker tail : Bool) : Prop := marker = false ∧ tail = false

theorem invalidMarkerCanRetainTail : ¬ OriginDischarged false true := by
  simp [OriginDischarged]

def ReclaimReady (joined roots donorWorkEmpty remoteTailLeft releaseTailLeft fresh : Bool) : Prop :=
  joined = true ∧ roots = true ∧ donorWorkEmpty = true ∧
  remoteTailLeft = true ∧ releaseTailLeft = true ∧ fresh = true

theorem joinDoesNotDischargeRemoteTail :
    ¬ ReclaimReady true true true false true true := by simp [ReclaimReady]

theorem invokedReleaseIsNotReturned :
    ¬ ReclaimReady true true true true false true := by simp [ReclaimReady]

theorem publicQueuesDoNotExcludePrivateWork :
    WorkAccounting.activeCount [WorkAccounting.uncountedProducer] = 0 ∧
    WorkAccounting.QueuesEmpty [WorkAccounting.uncountedProducer] ∧
    WorkAccounting.uncountedProducer.privateWork = true ∧
    ¬ WorkAccounting.ProducerLifetimeSafe [WorkAccounting.uncountedProducer] :=
  WorkAccounting.missingLifetimeCounterexample

theorem destinationCoveragePermitsDonorRelease {Slot : Type}
    (live source destination : Slot → Prop)
    (covered : ∀ slot, live slot → source slot ∨ destination slot)
    (transferred : ∀ slot, live slot → source slot → destination slot) :
    ∀ slot, live slot → destination slot := by
  intro slot active
  rcases covered slot active with old | new
  · exact transferred slot active old
  · exact new

-- Recipient-owned work need not be empty. The premise covers only work that
-- can still access the donor; this is not a serialized whole-collector proof.
theorem unfinishedRecipientWorkCanSurviveDonor :
    ∃ donorBorrow recipientOwned : Nat → Prop,
      (∀ work, ¬ donorBorrow work) ∧ (∃ work, recipientOwned work) := by
  exact ⟨(fun _ => False), (fun work => work = 0), (by simp), 0, rfl⟩

def ReleaseBudget (calls : Nat) (callable : Bool) : Prop :=
  calls + (if callable then 1 else 0) ≤ 1

theorem oneInvocationConsumesBudget (calls : Nat)
    (before : ReleaseBudget calls true) : ReleaseBudget (calls + 1) false := by
  simpa [ReleaseBudget] using before

theorem releasedFunctionCannotBeRetried : ¬ ReleaseBudget 2 false := by
  simp [ReleaseBudget]

-- This is the identity contract of the Scheme evidence relation, not proof
-- that a declared source-to-model mapping is a native refinement proof.
structure Binding where
  scope : String
  edge : String
  property : String
  modelSha : String
  observedSources : String × String
  refinementSha : String
  deriving DecidableEq

def Matches (request receipt : Binding) : Prop := request = receipt

theorem changedScopeRevokesBinding (request receipt : Binding)
    (different : request.scope ≠ receipt.scope) : ¬ Matches request receipt := by
  intro same
  exact different (congrArg Binding.scope same)

theorem changedModelRevokesBinding (request receipt : Binding)
    (different : request.modelSha ≠ receipt.modelSha) : ¬ Matches request receipt := by
  intro same
  exact different (congrArg Binding.modelSha same)

theorem unrelatedPropertyDoesNotCoverEdge (request receipt : Binding)
    (different : request.property ≠ receipt.property) : ¬ Matches request receipt := by
  intro same
  exact different (congrArg Binding.property same)

theorem changedSourcesRevokeBinding (request receipt : Binding)
    (different : request.observedSources ≠ receipt.observedSources) : ¬ Matches request receipt := by
  intro same
  exact different (congrArg Binding.observedSources same)

theorem changedRefinementRevokesBinding (request receipt : Binding)
    (different : request.refinementSha ≠ receipt.refinementSha) : ¬ Matches request receipt := by
  intro same
  exact different (congrArg Binding.refinementSha same)

theorem oneCheckedInterfaceDoesNotCoverBundle :
    ¬ ([true, false].all id = true) := by decide

#print axioms invalidMarkerCanRetainTail
#print axioms joinDoesNotDischargeRemoteTail
#print axioms invokedReleaseIsNotReturned
#print axioms publicQueuesDoNotExcludePrivateWork
#print axioms destinationCoveragePermitsDonorRelease
#print axioms unfinishedRecipientWorkCanSurviveDonor
#print axioms oneInvocationConsumesBudget
#print axioms releasedFunctionCannotBeRetried
#print axioms changedScopeRevokesBinding
#print axioms changedModelRevokesBinding
#print axioms unrelatedPropertyDoesNotCoverEdge
#print axioms changedSourcesRevokeBinding
#print axioms changedRefinementRevokesBinding
#print axioms oneCheckedInterfaceDoesNotCoverBundle

end GambitSMP.RetirementExitHandoff

import WorkAccounting

namespace GambitSMP.HostRootSourceCensus

-- Source classes may be absent, transferred, or retained by a live owner.
-- The actual source must establish these predicates for every live slot.
theorem partitionedCoverage {Slot : Type}
    (live transferred visibleReceiver retainedOwner : Slot → Prop)
    (moved : ∀ slot, live slot → transferred slot → visibleReceiver slot)
    (rest : ∀ slot, live slot → ¬ transferred slot → retainedOwner slot) :
    ∀ slot, live slot → visibleReceiver slot ∨ retainedOwner slot := by
  intro slot needed
  by_cases inTransfer : transferred slot
  · exact Or.inl (moved slot needed inTransfer)
  · exact Or.inr (rest slot needed inTransfer)

inductive RootClass where
  | rc | still | activation
  deriving DecidableEq

def ListTransferred (root : RootClass) : Prop := root = .rc ∨ root = .still

-- A real list-transfer implementation is not a complete physical census.
theorem listSpliceDoesNotDischargeActivation :
    ListTransferred .rc ∧ ListTransferred .still ∧ ¬ ListTransferred .activation := by
  simp [ListTransferred]

-- A non-live field needs no transfer. The premise is an absence witness,
-- not a zero-value test or an assumption that a retired executor has no roots.
theorem absentSlotsPermitRestrictedTransfer {Slot : Type}
    (live transferClass visibleReceiver : Slot → Prop)
    (absent : ∀ slot, ¬ transferClass slot → ¬ live slot)
    (moved : ∀ slot, live slot → transferClass slot → visibleReceiver slot) :
    ∀ slot, live slot → visibleReceiver slot := by
  intro slot needed
  by_cases selected : transferClass slot
  · exact moved slot needed selected
  · exact False.elim (absent slot selected needed)

-- Reuse the existing private-producer counterexample. A queue observation
-- cannot replace the lifetime premise of the current root/work census.
theorem emptyPublicQueuesStillNeedProducerLifetime :
    WorkAccounting.activeCount [WorkAccounting.uncountedProducer] = 0 ∧
    WorkAccounting.QueuesEmpty [WorkAccounting.uncountedProducer] ∧
    WorkAccounting.uncountedProducer.privateWork = true ∧
    ¬ WorkAccounting.ProducerLifetimeSafe [WorkAccounting.uncountedProducer] :=
  WorkAccounting.missingLifetimeCounterexample

#print axioms partitionedCoverage
#print axioms listSpliceDoesNotDischargeActivation
#print axioms absentSlotsPermitRestrictedTransfer
#print axioms emptyPublicQueuesStillNeedProducerLifetime

end GambitSMP.HostRootSourceCensus

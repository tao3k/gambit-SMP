import WorkAccounting

namespace GambitSMP.HostRootParticipation

theorem recordPublicationIsNotParticipation :
    ¬ GambitSMP.WorkAccounting.ServiceReady true false :=
  GambitSMP.WorkAccounting.announcementWithoutAcknowledgementIsNotReady

-- A complete slot inventory still needs a snapshot of the final root values.
-- The source must establish the frozen handoff and scanner observation edges.
theorem frozenHandoffComposesRelocation {Slot Value : Type}
    (live : Slot → Prop) (source handed observed : Slot → Value)
    (relocate : Value → Value)
    (frozen : ∀ slot, live slot → handed slot = source slot)
    (scanned : ∀ slot, live slot → observed slot = relocate (handed slot)) :
    ∀ slot, live slot → observed slot = relocate (source slot) := by
  intro slot needed
  rw [scanned slot needed, frozen slot needed]

theorem earlyObservationCanMissLastStore :
    ∃ observed handed : Nat, observed = 0 ∧ handed = 1 ∧ observed ≠ handed := by
  exact ⟨0, 1, rfl, rfl, by decide⟩

-- Matching the current root value by accident is not an acquire contract.
theorem equalValueDoesNotSupplyAcknowledgement :
    ∃ observed handed : Nat, observed = handed ∧
      ¬ GambitSMP.WorkAccounting.ServiceReady true false := by
  exact ⟨0, 0, rfl, recordPublicationIsNotParticipation⟩

theorem inactivePublicationStillExcludesMutation (published : Bool) :
    ¬ GambitSMP.WorkAccounting.InactiveRootsReady published true :=
  GambitSMP.WorkAccounting.rootsDoNotPermitConcurrentMutation published

#print axioms recordPublicationIsNotParticipation
#print axioms frozenHandoffComposesRelocation
#print axioms earlyObservationCanMissLastStore
#print axioms equalValueDoesNotSupplyAcknowledgement
#print axioms inactivePublicationStillExcludesMutation

end GambitSMP.HostRootParticipation

import WorkAccounting

namespace GambitSMP.HostRootPublicationLifetime

-- The source must enumerate both populations. An execution-active list alone
-- cannot instantiate this union when a blocked host still owns a live C tail.
theorem allLiveConsumersHaveVisibleRoots {Consumer Slot : Type}
    (host scanner : Consumer → Prop) (needs : Consumer → Slot → Prop)
    (saved visible : Slot → Prop)
    (hostCensus : ∀ c s, host c → needs c s → saved s)
    (scannerCensus : ∀ c s, scanner c → needs c s → saved s)
    (publication : ∀ s, saved s → visible s) :
    ∀ c s, host c ∨ scanner c → needs c s → visible s := by
  intro c s live needed
  apply publication s
  rcases live with returning | scanning
  · exact hostCensus c s returning needed
  · exact scannerCensus c s scanning needed

-- Reclamation needs the last use of each consumer, not just GC traversal.
theorem reclaimedStorageExcludesEveryConsumer {Consumer Slot : Type}
    (host scanner : Consumer → Prop) (needs : Consumer → Slot → Prop)
    (alive : Slot → Prop)
    (retained : ∀ c s, (host c ∨ scanner c) → needs c s → alive s)
    (slot : Slot) (reclaimed : ¬ alive slot) :
    ∀ c, (host c ∨ scanner c) → ¬ needs c slot := by
  intro c live needed
  exact reclaimed (retained c slot live needed)

theorem collectorDoneCanLeaveHostConsumer :
    ∃ host scanner : Nat → Prop,
      (∀ c, ¬ scanner c) ∧ (∃ c, host c) := by
  exact ⟨(fun c => c = 0), (fun _ => False), (by simp), 0, rfl⟩

theorem publishedStorageCanAlreadyBeDead :
    ∃ visible alive : Bool, visible = true ∧ alive = false := by
  exact ⟨true, false, rfl, rfl⟩

theorem inactiveRootsDoNotGrantMutation (published : Bool) :
    ¬ GambitSMP.WorkAccounting.InactiveRootsReady published true :=
  GambitSMP.WorkAccounting.rootsDoNotPermitConcurrentMutation published

#print axioms allLiveConsumersHaveVisibleRoots
#print axioms reclaimedStorageExcludesEveryConsumer
#print axioms collectorDoneCanLeaveHostConsumer
#print axioms publishedStorageCanAlreadyBeDead
#print axioms inactiveRootsDoNotGrantMutation

end GambitSMP.HostRootPublicationLifetime

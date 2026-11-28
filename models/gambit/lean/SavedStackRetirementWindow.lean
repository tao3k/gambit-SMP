import WorkAccounting

namespace GambitSMP.SavedStackRetirementWindow

-- An empty value is legal. Its persistence requires no new producer in the
-- declared window, not merely the absence of an unrelated foreign C frame.
theorem emptyWitnessNeedsStableWindow {Item : Type}
    (before after : Item → Prop)
    (noArrival : ∀ item, after item → before item)
    (emptyBefore : ∀ item, ¬ before item) : ∀ item, ¬ after item := by
  intro item arrived
  exact emptyBefore item (noArrival item arrived)

theorem foreignFrameClosureDoesNotEmptySchemeQueue :
    ∃ foreign scheme : Unit → Prop,
      (∀ item, ¬ foreign item) ∧ scheme () := by
  exact ⟨(fun _ => False), (fun _ => True), (fun _ h => h), True.intro⟩

-- Ordinary Gambit graft/return reads but does not consume the captured
-- continuation's origin; thread-restore's destructive slot move is separate.
theorem nonConsumingUsePreservesRawOrigin {Origin : Type}
    (before after raw : Origin → Prop)
    (preserved : ∀ origin, before origin → after origin)
    (pending : ∃ origin, before origin ∧ raw origin) :
    ∃ origin, after origin ∧ raw origin := by
  obtain ⟨origin, saved, stillRaw⟩ := pending
  exact ⟨origin, preserved origin saved, stillRaw⟩

theorem phaseCompletionOrdersReuse {Event : Type}
    (precedes : Event → Event → Prop)
    (transitive : ∀ a b c, precedes a b → precedes b c → precedes a c)
    (strong weak cleanup reuse : Event)
    (strongToWeak : precedes strong weak)
    (weakToCleanup : precedes weak cleanup)
    (cleanupToReuse : precedes cleanup reuse) : precedes strong reuse := by
  exact transitive strong cleanup reuse
    (transitive strong weak cleanup strongToWeak weakToCleanup) cleanupToReuse

-- Resolving every supplied origin closes old backing access only if every
-- actual raw origin is represented. Missing-origin absence is not inferred.
theorem completeOriginsBoundLastRawAccess {Origin : Type}
    (actual declared resolved : Origin → Prop)
    (complete : ∀ o, actual o → declared o)
    (closed : ∀ o, declared o → resolved o) :
    ¬ (∃ o, actual o ∧ ¬ resolved o) := by
  intro pending
  obtain ⟨origin, present, unresolved⟩ := pending
  exact unresolved (closed origin (complete origin present))

-- resize_heap applies its configured maximum after the assignment floor.
-- These arithmetic lemmas assume valid, non-overflowing section counts; they
-- do not establish that the incompatible cap is reachable in a real GC.
theorem configuredCapCanOverrideAssignedFloor (proposed floor cap : Nat)
    (tooSmall : cap < floor) : min (max proposed floor) cap < floor := by
  exact Nat.lt_of_le_of_lt (Nat.min_le_right _ _) tooSmall

theorem compatibleCapPreservesAssignedFloor (proposed floor cap : Nat)
    (fits : floor ≤ cap) : floor ≤ min (max proposed floor) cap := by
  exact Nat.le_min.mpr ⟨Nat.le_max_right _ _, fits⟩

#print axioms emptyWitnessNeedsStableWindow
#print axioms foreignFrameClosureDoesNotEmptySchemeQueue
#print axioms nonConsumingUsePreservesRawOrigin
#print axioms phaseCompletionOrdersReuse
#print axioms completeOriginsBoundLastRawAccess
#print axioms configuredCapCanOverrideAssignedFloor
#print axioms compatibleCapPreservesAssignedFloor

end GambitSMP.SavedStackRetirementWindow

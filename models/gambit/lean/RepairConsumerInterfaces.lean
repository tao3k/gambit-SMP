import WorkAccounting

namespace GambitSMP.RepairConsumerInterfaces

-- Delivery is not first-C-entry. These predicates refer to the complete actual
-- invocation population; no C counter or source implementation is assumed.
def Outstanding {Consumer : Type} (delivered returned : Consumer → Prop) (c : Consumer) : Prop :=
  delivered c ∧ ¬ returned c

def Drained {Consumer : Type} (delivered returned : Consumer → Prop) : Prop :=
  ∀ c, ¬ Outstanding delivered returned c

theorem unfinishedInvocationBlocksDrain {Consumer : Type}
    (delivered returned : Consumer → Prop) (c : Consumer)
    (pending : Outstanding delivered returned c) : ¬ Drained delivered returned := by
  intro drained
  exact drained c pending

-- A zero first-instruction census is compatible with an OS-delivered invocation.
theorem emptyEntryCensusDoesNotProveDrain :
    ∃ delivered entered returned : Unit → Prop,
      (∀ c, ¬ entered c) ∧ ¬ Drained delivered returned := by
  refine ⟨fun _ => True, fun _ => False, fun _ => False, ?_, ?_⟩
  · intro _ h; exact h
  · intro drained
    exact drained () ⟨True.intro, fun h => h⟩

-- Compose the declared-root census with the separately identified in-flight
-- consumer interval. Neither source enumeration nor discharge is manufactured.
theorem declaredAndPrivateConsumersCompose {Consumer : Type}
    (actual declared inFlight finished : Consumer → Prop)
    (coverage : ∀ c, actual c → declared c ∨ inFlight c)
    (publicDone : ∀ c, declared c → finished c)
    (privateDone : ∀ c, inFlight c → finished c) :
    ∀ c, actual c → finished c := by
  intro c present
  rcases coverage c present with listed | hidden
  · exact publicDone c listed
  · exact privateDone c hidden

theorem omittedPrivateConsumerDefeatsPublicCompletion {Consumer : Type}
    (actual finished : Consumer → Prop) (c : Consumer)
    (present : actual c) (pending : ¬ finished c) :
    ¬ (∀ x, actual x → finished x) := by
  intro done
  exact pending (done c present)

theorem newEntryEpochDoesNotRestoreDeliveryEpoch (old current : Nat)
    (same : WorkAccounting.SameGeneration old current) :
    ¬ WorkAccounting.SameGeneration old (current + 1) :=
  WorkAccounting.reuseRevokesOldIdentity old current same

-- Even a nonempty actual-use census can finish before its C invocation returns.
-- A source proof must identify that last access; this witness does not supply it.
theorem lastResourceAccessCanPrecedeInvocationReturn :
    ∃ uses completed returned : Unit → Prop,
      uses () ∧ (∀ c, uses c → completed c) ∧ ¬ returned () := by
  refine ⟨fun _ => True, fun _ => True, fun _ => False, True.intro, ?_, ?_⟩
  · intro _ _; exact True.intro
  · intro impossible; exact impossible

#print axioms unfinishedInvocationBlocksDrain
#print axioms emptyEntryCensusDoesNotProveDrain
#print axioms declaredAndPrivateConsumersCompose
#print axioms omittedPrivateConsumerDefeatsPublicCompletion
#print axioms newEntryEpochDoesNotRestoreDeliveryEpoch
#print axioms lastResourceAccessCanPrecedeInvocationReturn

end GambitSMP.RepairConsumerInterfaces

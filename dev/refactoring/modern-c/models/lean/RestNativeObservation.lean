import Std

-- Receipt and coordinate correspondence only. C pointer validity, atomic
-- publication, complete lowering and actual event origins remain premises.
namespace Gambit.RestNativeObservation

structure Scope where
  image : Nat
  command : Nat
  spelling : Nat
  caseId : Nat
  owner : Nat
  activation : Nat
  attempt : Nat
  generation : Nat
  deriving DecidableEq

def sameAttempt (a b : Scope) : Prop := a = b

theorem ownerCannotBeReplaced (a b : Scope) (different : a.owner ≠ b.owner) :
    ¬ sameAttempt a b := by
  intro same
  exact different (congrArg Scope.owner same)

-- A root revision is not a new ownership generation or a new command.
theorem rootRevisionDoesNotAuthorizeAnotherScope (a b : Scope) (revision : Nat)
    (different : a ≠ b) : (a, revision) ≠ (b, revision) := by
  intro same
  exact different (congrArg Prod.fst same)

theorem actualStoreAfterAdjustments (returned middle written a b : Int)
    (first : middle = returned-a) (second : written = middle-b) :
    written = returned-(a+b) := by omega

theorem savedHandlerIsNotUnwoundCaller (saved returned displacement : Int)
    (unwind : returned = saved+displacement) (positive : 0 < displacement) :
    saved ≠ returned := by omega

theorem oneWordShortCannotAuthorize (available demand : Nat)
    (short : available+1 = demand) : ¬ demand ≤ available := by omega

-- Real C tickets are lock-free, bounded and uniquely issued. This lemma only
-- proves the record-slot geometry once those native premises hold.
theorem distinctRecorderSlots (a b : Nat) (ordered : a < b) :
    8+16*a+16 ≤ 8+16*b := by omega

-- These premises are supplied by different runtime owners. A reservation is
-- not evidence of the writer, the root view or the delivery phase.
structure DeliveryView where
  pin : Prop
  roots : Prop
  writer : Prop
  installedOrReady : Prop
  undelivered : Prop

def DeliveryView.CanFinish (v : DeliveryView) : Prop :=
  v.pin ∧ v.roots ∧ v.writer ∧ v.installedOrReady ∧ v.undelivered

theorem grantDoesNotDischargeLostWriter (demand room : Nat) (v : DeliveryView)
    (_grant : demand ≤ room) (lost : ¬ v.writer) : ¬ v.CanFinish := by
  intro finish
  exact lost finish.2.2.1

theorem deliveryNeedsPreservation (before after : DeliveryView)
    (ready : before.CanFinish) (pin : before.pin → after.pin)
    (roots : before.roots → after.roots) (writer : before.writer → after.writer)
    (phase : before.installedOrReady → after.installedOrReady)
    (once : before.undelivered → after.undelivered) : after.CanFinish := by
  obtain ⟨p, r, w, h, d⟩ := ready
  exact ⟨pin p, roots r, writer w, phase h, once d⟩

inductive SourceResult where
  | invalid | prefix | successor
  deriving DecidableEq

def mayRequestSection (source : SourceResult) (room demand : Nat) : Prop :=
  source ≠ .invalid ∧ room < demand

theorem invalidSourceCannotRequest (room demand : Nat) :
    ¬ mayRequestSection .invalid room demand := fun h => h.1 rfl

theorem completePrefixDoesNotSupplyShortage (room demand : Nat)
    (enough : demand ≤ room) : ¬ mayRequestSection .prefix room demand := by
  intro h
  have short := h.2
  omega

-- For a positive full demand and one validated C interval, these are the
-- two comparisons before the fresh-section lock in ___rest_extend_interval.
theorem currentTailFitsIff (tail guard demand : Nat) (positive : 0 < demand) :
    (guard < tail ∧ demand ≤ tail - guard) ↔ guard + demand ≤ tail := by omega

theorem softShortageDoesNotImplyPhysicalShortage
    (soft tail guard demand : Nat) (positive : 0 < demand)
    (softShort : soft < demand) (tailFits : guard + demand ≤ tail) :
    soft < demand ∧ (guard < tail ∧ demand ≤ tail - guard) :=
  ⟨softShort, (currentTailFitsIff tail guard demand positive).2 tailFits⟩

-- A last old read may precede acquisition of the successor. Both uses
-- must be covered by one old pin, without requiring another old read.
theorem pinCoversBothUses (pin lastRead successor unpin : Nat)
    (readAcquired : pin ≤ lastRead) (successorAcquired : pin ≤ successor)
    (releaseAfterBoth : max lastRead successor < unpin) :
    (pin ≤ lastRead ∧ lastRead < unpin) ∧
      (pin ≤ successor ∧ successor < unpin) := by omega

-- Arithmetic interface between prediction under lock and actual publication.
-- C must supply the stable geometry and prove pointers belong to one object.
theorem predictedRoomSurvivesPublication (demand predicted hard guard : Nat)
    (admitted : demand ≤ predicted) (preserved : predicted + guard ≤ hard) :
    demand ≤ min predicted (hard - guard) := by omega

theorem capacityCannotTransferClaim (claimed published : Scope) (demand room : Nat)
    (_fits : demand ≤ room) (different : claimed.owner ≠ published.owner) :
    ¬ sameAttempt claimed published := ownerCannotBeReplaced _ _ different

theorem sourceProofCannotReplaceLinkedObservation (proved observed : Scope)
    (changed : proved.image ≠ observed.image) : ¬ sameAttempt proved observed := by
  intro same
  exact changed (congrArg Scope.image same)

end Gambit.RestNativeObservation

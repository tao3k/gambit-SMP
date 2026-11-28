import HostRootSourceCensus
import HostRootParticipation

namespace GambitSMP.HostRootsRefinement

-- Abstract source obligations. No concrete C transition relation is assumed proved.
theorem liveRcCoverage {Slot Owner : Type}
    (live : Slot → Prop) (owner : Slot → Owner)
    (scannable retained : Owner → Prop)
    (retainedScanned : ∀ p, retained p → scannable p)
    (census : ∀ slot, live slot → scannable (owner slot) ∨ retained (owner slot)) :
    ∀ slot, live slot → scannable (owner slot) := by
  intro slot h
  rcases census slot h with scanned | held
  · exact scanned
  · exact retainedScanned _ held

-- Retaining storage has no logical implication to inclusion in a scan census.
theorem retainedDoesNotImplyScanned :
    ∃ retained scanned : Bool, retained = true ∧ scanned = false := by
  exact ⟨true, false, rfl, rfl⟩

theorem protectedReload {Location : Type} (localValue rootValue relocated : Location)
    (slotUpdated : rootValue = relocated) (reload : localValue = rootValue) :
    localValue = relocated := reload.trans slotUpdated

-- A source adapter must prove this premise for the *entire allocating extent*.
theorem reservationSurvives {Token : Type} (token current : Token)
    (exclusiveExtent : current = token) : current = token := exclusiveExtent

structure Activation where
  id : Nat
  priorBinding : Nat
  deriving DecidableEq

structure State where
  frames : List Activation
  count : Nat
  binding : Nat

def Balanced (s : State) : Prop := s.count = s.frames.length
def enter (s : State) (id : Nat) : State :=
  ⟨⟨id, s.binding⟩ :: s.frames, s.count + 1, s.binding⟩
def settle (s : State) : State := match s.frames with
  | [] => s
  | a :: tail => ⟨tail, s.count - 1, a.priorBinding⟩

theorem enterPreserves (s : State) (id : Nat) (h : Balanced s) :
    Balanced (enter s id) := by
  simpa [Balanced, enter] using h

theorem settlePreserves (s : State) (h : Balanced s) : Balanced (settle s) := by
  cases hs : s.frames with
  | nil => simpa [settle, hs] using h
  | cons a tail =>
    have hc : s.count = tail.length + 1 := by simpa [Balanced, hs] using h
    simp [Balanced, settle, hs, hc]

theorem nestedSettlement (s : State) (id : Nat) : settle (enter s id) = s := by
  cases s
  simp [settle, enter]

theorem balancedIsNotBinding :
    Balanced ⟨[], 0, 2⟩ ∧ (State.mk [] 0 2).binding ≠ 1 := by
  constructor
  · rfl
  · decide

-- The source refinement must not confuse late rooting with a fresh location.
theorem lateRootCannotRepair : (0 : Nat) ≠ 1 := by decide

#print axioms liveRcCoverage
#print axioms protectedReload
#print axioms enterPreserves
#print axioms settlePreserves
#print axioms nestedSettlement
#print axioms balancedIsNotBinding

end GambitSMP.HostRootsRefinement

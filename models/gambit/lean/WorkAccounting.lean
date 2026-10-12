import LeanPoo.Functional.TransformationResources

namespace GambitSMP.WorkAccounting

-- A projection obligation, not a model of the C runtime or all GC phases.
structure Worker where
  counted : Bool
  privateWork : Bool
  queued : Bool
  deriving DecidableEq

def activeCount : List Worker → Nat
  | [] => 0
  | w :: ws => (if w.counted then 1 else 0) + activeCount ws

def ProducerLifetimeSafe (ws : List Worker) : Prop :=
  ∀ w ∈ ws, w.privateWork = true → w.counted = true

def QueuesEmpty (ws : List Worker) : Prop :=
  ∀ w ∈ ws, w.queued = false

theorem zeroCountExcludesActive (ws : List Worker) (h : activeCount ws = 0) :
    ∀ w ∈ ws, w.counted = false := by
  induction ws with
  | nil => simp
  | cons head tail ih =>
    cases hc : head.counted with
    | false =>
      simp [activeCount, hc] at h
      intro w hw
      simp only [List.mem_cons] at hw
      rcases hw with rfl | ht
      · exact hc
      · exact ih h w ht
    | true => simp [activeCount, hc] at h

theorem zeroCountAndEmptyQueuesExcludeHiddenWork (ws : List Worker)
    (countZero : activeCount ws = 0)
    (lifetime : ProducerLifetimeSafe ws)
    (queues : QueuesEmpty ws) :
    ∀ w ∈ ws, w.counted = false ∧ w.privateWork = false ∧ w.queued = false := by
  intro w hw
  have inactive := zeroCountExcludesActive ws countZero w hw
  have noPrivate : w.privateWork = false := by
    cases hp : w.privateWork with
    | false => exact hp
    | true =>
      have active := lifetime w hw hp
      rw [inactive] at active
      contradiction
  exact ⟨inactive, noPrivate, queues w hw⟩

-- Without producer lifetime accounting, zero count and empty queues are unsafe.
def uncountedProducer : Worker := ⟨false, true, false⟩

theorem missingLifetimeCounterexample :
    activeCount [uncountedProducer] = 0 ∧
    QueuesEmpty [uncountedProducer] ∧
    uncountedProducer.privateWork = true ∧
    ¬ ProducerLifetimeSafe [uncountedProducer] := by
  simp [activeCount, QueuesEmpty, ProducerLifetimeSafe, uncountedProducer]

-- Bounds must be established for actual stage work before composing them.
theorem stageCostsStayWithinComposedBudget
    (first second : LeanPoo.Functional.Transformation.ResourceContract)
    (size firstCost secondCost : Nat)
    (firstBound : firstCost ≤ first.cost.apply size)
    (secondBound : secondCost ≤ second.cost.apply (first.size.apply size)) :
    firstCost + secondCost ≤ (first.compose second).cost.apply size := by
  rw [LeanPoo.Functional.Transformation.resource_compose_cost]
  exact Nat.add_le_add firstBound secondBound

#print axioms zeroCountExcludesActive
#print axioms zeroCountAndEmptyQueuesExcludeHiddenWork
#print axioms missingLifetimeCounterexample
#print axioms stageCostsStayWithinComposedBudget

end GambitSMP.WorkAccounting

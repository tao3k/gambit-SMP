-- Value obligations only. Existing QNT owns native publication and invalidation.
-- Python/expander extraction fidelity and macro effects are not proved here.
namespace Gambit.CompilerBuildBatch

def Closed (deps : Nat → List Nat) (done : List Nat) : Prop :=
  ∀ node, node ∈ done → ∀ dep, dep ∈ deps node → dep ∈ done

theorem empty_closed (deps : Nat → List Nat) : Closed deps [] := by
  intro node h
  simp at h

theorem ready_extension_closed (deps : Nat → List Nat) (done fresh : List Nat)
    (closed : Closed deps done)
    (ready : ∀ node, node ∈ fresh → ∀ dep, dep ∈ deps node → dep ∈ done) :
    Closed deps (done ++ fresh) := by
  intro node member dep dependency
  rcases List.mem_append.mp member with old | new
  · exact List.mem_append.mpr (Or.inl (closed node old dep dependency))
  · exact List.mem_append.mpr (Or.inl (ready node new dep dependency))

theorem membership_preserves_closure (deps : Nat → List Nat) (a b : List Nat)
    (closed : Closed deps a) (same : ∀ node, node ∈ a ↔ node ∈ b) :
    Closed deps b := by
  intro node member dep dependency
  exact (same dep).mp (closed node ((same node).mpr member) dep dependency)

-- Ordering is a value-level obligation, separate from QNT's publication history.
-- Instantiation still requires a faithful native metadata decoder/linker.
theorem ordered_metadata_congr {α : Type} (order : List Nat) (a b : Nat → α)
    (same : ∀ n, n ∈ order → a n = b n) : order.map a = order.map b := by
  induction order with
  | nil => rfl
  | cons n rest ih =>
    simp only [List.map_cons]
    rw [same n (by simp), ih (fun k h => same k (by simp [h]))]

theorem ordered_link_congr {α β : Type} (link : List α → β)
    (order : List Nat) (a b : Nat → α)
    (same : ∀ n, n ∈ order → a n = b n) :
    link (order.map a) = link (order.map b) :=
  congrArg link (ordered_metadata_congr order a b same)

theorem same_membership_does_not_prove_same_order :
    (∀ n : Nat, n ∈ [0,1] ↔ n ∈ [1,0]) ∧ ([0,1] : List Nat) ≠ [1,0] := by
  constructor
  · intro n
    simp only [List.mem_cons, List.not_mem_nil, or_false]
    exact or_comm
  · decide

end Gambit.CompilerBuildBatch

namespace Gambit.CompilerResources

-- Point-in-time value bounds only; no claim about sampling gaps or native RSS.
theorem joint_budget_bounds_parts (driver left right budget : Nat)
    (joint : driver + (left + right) ≤ budget) :
    left ≤ budget ∧ right ≤ budget := by
  have sumBound : left + right ≤ budget :=
    Nat.le_trans (Nat.le_add_left (left + right) driver) joint
  exact ⟨Nat.le_trans (Nat.le_add_right left right) sumBound,
         Nat.le_trans (Nat.le_add_left right left) sumBound⟩

theorem per_group_limits_do_not_bound_total :
    (4 ≤ 6 ∧ 4 ≤ 6) ∧ ¬ (4 + 4 ≤ 6) := by decide

theorem sampled_limit_does_not_bound_later_value :
    (2 ≤ 6) ∧ ¬ (8 ≤ 6) := by decide

end Gambit.CompilerResources

namespace Gambit.CompilerStageProducts

-- A source-generation cohort includes payload identity, not just clock seconds.
structure Generation where
  timestamp : Nat
  bindings : List Nat
  requiredBytes : List Nat
  deriving DecidableEq

theorem equal_timestamp_is_not_equal_generation :
    (Generation.mk 42 [1] [10]).timestamp = (Generation.mk 42 [2] [10]).timestamp ∧
    Generation.mk 42 [1] [10] ≠ Generation.mk 42 [2] [10] := by decide

theorem whole_bundle_preserves_binding_and_payload (a b : Generation) (same : a = b) :
    a.timestamp = b.timestamp ∧ a.bindings = b.bindings ∧ a.requiredBytes = b.requiredBytes := by
  cases same
  exact ⟨rfl, rfl, rfl⟩

-- Reservation is useful only with a separately justified actual-use bound.
theorem reserved_children_fit (parent actualA actualB reserveA reserveB budget : Nat)
    (a : actualA ≤ reserveA) (b : actualB ≤ reserveB)
    (reserved : parent + (reserveA + reserveB) ≤ budget) :
    parent + (actualA + actualB) ≤ budget :=
  Nat.le_trans (Nat.add_le_add_left (Nat.add_le_add a b) parent) reserved

end Gambit.CompilerStageProducts

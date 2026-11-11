import Std

namespace Gambit.BootstrapCohort

-- Coverage-class membership is not a witness for every native filename.
-- These laws require a complete required-name predicate and universal coverage
-- within each class. They do not establish compiler semantics or C lifetimes.
def Complete (required emitted : Nat → Prop) : Prop :=
  ∀ n, required n → emitted n

def ClassComplete (required emitted : Nat → Prop) (kind : Nat → Nat)
    (k : Nat) : Prop :=
  ∀ n, required n → kind n = k → emitted n

theorem completeProjects (required emitted : Nat → Prop) (kind : Nat → Nat)
    (h : Complete required emitted) : ∀ k, ClassComplete required emitted kind k := by
  intro k n hr _
  exact h n hr

theorem universalClassesReflect (required emitted : Nat → Prop) (kind : Nat → Nat)
    (h : ∀ k, ClassComplete required emitted kind k) : Complete required emitted := by
  intro n hr
  exact h (kind n) n hr rfl

theorem twoClassesReflect (required emitted : Nat → Prop) (kind : Nat → Nat)
    (domain : ∀ n, required n → kind n = 0 ∨ kind n = 1)
    (scheme : ClassComplete required emitted kind 0)
    (linker : ClassComplete required emitted kind 1) : Complete required emitted := by
  intro n hr
  rcases domain n hr with hk | hk
  · exact scheme n hr hk
  · exact linker n hr hk

theorem emissionPreserves (required before after : Nat → Prop)
    (complete : Complete required before)
    (monotone : ∀ n, before n → after n) : Complete required after := by
  intro n hr
  exact monotone n (complete n hr)

-- One observed representative in each class cannot close native coverage.
theorem representativesInsufficient :
    (∃ n, n ≤ 2 ∧ n = 0) ∧ (∃ n, n ≤ 2 ∧ n = 1) ∧
    ¬ Complete (fun n => n ≤ 2) (fun n => n = 0 ∨ n = 1) := by
  refine ⟨⟨0, by decide, rfl⟩, ⟨1, by decide, rfl⟩, ?_⟩
  intro complete
  have missing := complete 2 (by decide)
  simp at missing

-- A target-source pass is a distinct event. Equality of a host output alone
-- supplies neither this event nor a semantic result.
theorem semanticRequiresSelf (target self semantic : Prop)
    (selfNeedsTarget : self → target) (semanticNeedsSelf : semantic → self)
    (h : semantic) : target ∧ self := by
  exact ⟨selfNeedsTarget (semanticNeedsSelf h), semanticNeedsSelf h⟩

end Gambit.BootstrapCohort

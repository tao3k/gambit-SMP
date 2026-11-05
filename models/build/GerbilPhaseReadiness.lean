import Std.Tactic

namespace GerbilModuleBuild

-- Mathematical readiness/publication kernel. This is not a proof that the
-- Scheme source or the QNT implementation refines these definitions.
abbrev Graph := Nat → Nat → Prop

structure State where
  published : Nat → Prop
  running : Nat → Prop
  staged : Nat → Prop
  used : Nat

def Ready (g : Graph) (s : State) (n : Nat) : Prop :=
  ∀ d, g n d → s.published d

def Safe (g : Graph) (limit : Nat) (s : State) : Prop :=
  (∀ n, s.published n → Ready g s n) ∧
  (∀ n, s.running n → Ready g s n) ∧
  (∀ n, s.staged n → Ready g s n) ∧ s.used ≤ limit

def start (s : State) (n : Nat) : State :=
  ⟨s.published, fun k => k = n ∨ s.running k, s.staged, s.used + 1⟩

def finish (s : State) (n : Nat) : State :=
  ⟨s.published, fun k => s.running k ∧ k ≠ n,
    fun k => k = n ∨ s.staged k, s.used - 1⟩

def publish (s : State) (n : Nat) : State :=
  ⟨fun k => k = n ∨ s.published k, s.running,
    fun k => s.staged k ∧ k ≠ n, s.used⟩

theorem startPreserves {g : Graph} {limit n : Nat} {s : State}
    (h : Safe g limit s) (ready : Ready g s n) (budget : s.used + 1 ≤ limit) :
    Safe g limit (start s n) := by
  rcases h with ⟨hp, hr, hs, _⟩
  refine ⟨hp, ?_, hs, budget⟩
  intro k hk
  rcases hk with rfl | hk
  · exact ready
  · exact hr k hk

theorem finishPreserves {g : Graph} {limit n : Nat} {s : State}
    (h : Safe g limit s) (active : s.running n) : Safe g limit (finish s n) := by
  rcases h with ⟨hp, hr, hs, hb⟩
  refine ⟨hp, ?_, ?_, Nat.le_trans (Nat.sub_le _ _) hb⟩
  · intro k hk
    exact hr k hk.1
  · intro k hk
    rcases hk with rfl | hk
    · exact hr k active
    · exact hs k hk

theorem publishPreserves {g : Graph} {limit n : Nat} {s : State}
    (h : Safe g limit s) (complete : s.staged n) : Safe g limit (publish s n) := by
  rcases h with ⟨hp, hr, hs, hb⟩
  refine ⟨?_, ?_, ?_, hb⟩
  · intro k hk d edge
    rcases hk with rfl | hk
    · exact Or.inr (hs k complete d edge)
    · exact Or.inr (hp k hk d edge)
  · intro k hk d edge
    exact Or.inr (hr k hk d edge)
  · intro k hk d edge
    exact Or.inr (hs k hk.1 d edge)

inductive Step (g : Graph) (limit : Nat) : State → State → Prop where
  | start (s n) : Ready g s n → s.used + 1 ≤ limit →
      ¬s.running n → ¬s.published n → Step g limit s (GerbilModuleBuild.start s n)
  | finish (s n) : s.running n → Step g limit s (GerbilModuleBuild.finish s n)
  | publish (s n) : s.staged n → Step g limit s (GerbilModuleBuild.publish s n)
  | cancelRequest (s) : Step g limit s s

theorem stepPreserves {g : Graph} {limit : Nat} {a b : State}
    (safe : Safe g limit a) (step : Step g limit a b) : Safe g limit b := by
  cases step with
  | start _ ready budget _ _ => exact startPreserves safe ready budget
  | finish _ active => exact finishPreserves safe active
  | publish _ active => exact publishPreserves safe active
  | cancelRequest => exact safe

inductive Trace (g : Graph) (limit : Nat) : State → State → Prop where
  | refl (s) : Trace g limit s s
  | next {a b c} : Trace g limit a b → Step g limit b c → Trace g limit a c

theorem tracePreserves {g : Graph} {limit : Nat} {a b : State}
    (safe : Safe g limit a) (trace : Trace g limit a b) : Safe g limit b := by
  induction trace with
  | refl => exact safe
  | next _ step ih => exact stepPreserves ih step

-- Both consumers can be enabled after a common phase closure. Actual Scheme
-- side-effect isolation and fresh lexical instances are separate source duties.
theorem concurrentEnabled {g : Graph} {s : State} {a b : Nat}
    (rb : Ready g s b) : Ready g (start s a) b := rb

theorem coherentEpoch {Epoch : Type} {manifest support session : Epoch}
    (h1 : manifest = support) (h2 : support = session) : manifest = session :=
  h1.trans h2

theorem reusePreserves {Input Output View : Type}
    (key : Input → View) (produce : Input → Output)
    (complete : ∀ a b, key a = key b → produce a = produce b)
    {old current : Input} {cached : Output}
    (origin : cached = produce old) (same : key old = key current) :
    cached = produce current := origin.trans (complete old current same)

theorem positiveWork {mandatory removed overhead : Nat} (h : overhead < removed) :
    mandatory + overhead < mandatory + removed := Nat.add_lt_add_left h mandatory

-- Cancel is not physical exit: no credit is refunded in the cancelRequest rule.
theorem cancellationKeepsCredit (s : State) :
    (show State from s).used = s.used := rfl

end GerbilModuleBuild

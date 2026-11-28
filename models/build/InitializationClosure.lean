import Std.Tactic

namespace InitializationClosure

inductive Walk {A : Type} (edge : A → A → Prop) : A → A → Prop where
  | refl (a : A) : Walk edge a a
  | next {a b c : A} : Walk edge a b → edge b c → Walk edge a c

theorem closureCoversWalk {A : Type} {edge : A → A → Prop} {cut : A → Prop}
    (closed : ∀ a b, cut a → edge a b → cut b) {start finish : A}
    (root : cut start) (walk : Walk edge start finish) : cut finish := by
  induction walk with
  | refl => exact root
  | next prior hop ih => exact closed _ _ ih hop

structure State where
  identity : Nat
  successful : Bool
  gatesComplete : Bool
  accepting : Bool
  pins : List Nat
  history : List Nat
  deriving DecidableEq

def ready (s : State) : Prop := s.successful = true ∧ s.gatesComplete = true
def effect (s : State) (ticket : Nat) : State := { s with history := s.history ++ [ticket] }
def revoke (s : State) : State := { s with accepting := false }
def reclaimable (s : State) : Prop := s.accepting = false ∧ s.pins = []

theorem readyRequiresSuccess (s : State) (h : ready s) : s.successful = true := h.1
theorem effectPreservesInstance (s : State) (ticket : Nat) :
    (effect s ticket).identity = s.identity := rfl
theorem effectExtendsHistory (s : State) (ticket : Nat) :
    (effect s ticket).history = s.history ++ [ticket] := rfl
theorem revokePreservesBorrowers (s : State) : (revoke s).pins = s.pins := rfl
theorem drainedReclaim (s : State) (drained : s.pins = []) : reclaimable (revoke s) :=
  ⟨rfl, drained⟩
theorem workThreshold (required avoided map owner validation pins : Nat)
    (positive : map + owner + validation + pins < avoided) :
    required + (map + owner + validation + pins) < required + avoided :=
  Nat.add_lt_add_left positive required

-- These kernels do not prove source initialization, capability completeness,
-- QNT-to-Lean simulation, C memory ordering, continuation transfer, or liveness.
end InitializationClosure

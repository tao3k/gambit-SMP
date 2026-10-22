import Std.Tactic

namespace SpanStorageHandoff

structure Storage where
  raw : List Nat
  exposed : List Nat
  exposedId : Nat
def mutate (s : Storage) (text : List Nat) : Storage := { s with exposed := text }
theorem mutationIsolation (s : Storage) (text : List Nat) : (mutate s text).raw = s.raw := rfl
theorem exposedIdentity (s : Storage) (text : List Nat) :
    (mutate s text).exposedId = s.exposedId := rfl

-- Resumption count is not a reclamation reference count.
theorem resumeEffects (done more : Nat) : done + more ≥ done := Nat.le_add_right _ _
def readCount (beforeRead : Bool) (resumptions : Nat) : Nat :=
  if beforeRead then 1 + resumptions else 1
theorem readAfterCut (n : Nat) : readCount false n = 1 := rfl

structure Custody where
  original : Bool
  replacement : Bool
def commit (c : Custody) : Custody := { c with original := false }
theorem rootTransfer (c : Custody) (prepared : c.replacement = true) :
    (commit c).replacement = true := prepared
def prepareFailure (c : Custody) : Custody := c
theorem failureKeepsCustody (c : Custody) (held : c.original = true) :
    (prepareFailure c).original = true := held

def streamFreeable (control trace active borrows pending : Nat) : Prop :=
  control = 0 ∧ trace = 0 ∧ active = 0 ∧ borrows = 0 ∧ pending = 0
theorem streamDrain (control trace active borrows pending : Nat)
    (witness : streamFreeable control trace active borrows pending) :
    control = 0 ∧ trace = 0 ∧ pending = 0 := ⟨witness.1, witness.2.1, witness.2.2.2.2⟩
theorem netWork (base avoided isolation views roots adapter : Nat)
    (positive : isolation + views + roots + adapter < avoided) :
    base + (isolation + views + roots + adapter) < base + avoided :=
  Nat.add_lt_add_left positive base

-- Immutable Lean values model storage separation; real backing-store aliases,
-- GC reachability witnesses, multi-shot simulation and native memory order are premises.
end SpanStorageHandoff

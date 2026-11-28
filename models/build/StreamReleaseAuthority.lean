import Std.Tactic

namespace StreamReleaseAuthority

def mayReserve (admissionOpen : Bool) (current observed : Nat) : Prop := admissionOpen = true ∧ current = observed
theorem closedRejects (current observed : Nat) : ¬ mayReserve false current observed := by
  simp [mayReserve]
theorem staleEpochRejects (current observed : Nat) (stale : current ≠ observed) :
    ¬ mayReserve true current observed := by simp [mayReserve, stale]

-- Arbitrary graph predicates: strong paths from native roots cannot be
-- reclassified weak merely because the last user reference disappeared.
theorem pinKeepsCapture (pin capture stream : Prop)
    (root : pin) (pc : pin → capture) (cs : capture → stream) : stream := cs (pc root)
theorem actionBackedge (action testator : Prop) (strongAction : action)
    (backedge : action → testator) : testator := backedge strongAction

structure Outcome where
  pending : Nat
  managedRoots : Nat
def releasedUnknown : Outcome := ⟨1, 0⟩
theorem rootlessAck : releasedUnknown.pending = 1 ∧ releasedUnknown.managedRoots = 0 := by decide

def permit (closed covered privateNotice sameEpoch : Bool) (reserved borrowed pending : Nat) : Prop :=
  closed = true ∧ covered = true ∧ privateNotice = true ∧ sameEpoch = true ∧
  reserved = 0 ∧ borrowed = 0 ∧ pending = 0
theorem permitNeedsDrain (c v n e : Bool) (r b p : Nat) (valid : permit c v n e r b p) :
    r = 0 ∧ b = 0 ∧ p = 0 := valid.2.2.2.2
theorem pendingBlocks (c v n e : Bool) (r b p : Nat) (positive : p > 0) :
    ¬ permit c v n e r b p := by
  intro h
  have zero := (permitNeedsDrain c v n e r b p h).2.2
  omega

def consumable (consumed : Bool) : Prop := consumed = false
theorem oneConsume : ¬ consumable true := by simp [consumable]

-- The graph edges, rootless representation, complete admission closure and
-- native consume linearization must be established by source/native refinement.
end StreamReleaseAuthority

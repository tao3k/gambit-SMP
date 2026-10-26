import Std
namespace GambitRuntimeOwnership
-- Parametric semantic kernels for the proposed contract. No native or QNT extraction theorem.
inductive Slot where
 | root (value : Nat)
 | raw (bits : Nat)
 | returnPoint (point : Nat)
 deriving DecidableEq, Repr

def rewriteSlot (move : Nat → Nat) : Slot → Slot
 | .root v => .root (move v)
 | .raw b => .raw b
 | .returnPoint p => .returnPoint p

def rootValues : List Slot → List Nat
 | [] => []
 | .root v :: xs => v :: rootValues xs
 | _ :: xs => rootValues xs

theorem rewriteCoversEveryDeclaredRoot (move : Nat → Nat) (xs : List Slot) :
 rootValues (xs.map (rewriteSlot move)) = (rootValues xs).map move := by
 induction xs with
 | nil => rfl
 | cons x xs ih => cases x <;> simp_all [rewriteSlot, rootValues]

theorem nonRootBitsPreserved (move : Nat → Nat) (bits : Nat) :
 rewriteSlot move (.raw bits) = .raw bits := rfl

theorem returnIdentityPreserved (move : Nat → Nat) (point : Nat) :
 rewriteSlot move (.returnPoint point) = .returnPoint point := rfl

theorem relocationComposition (first second : Nat → Nat) (slot : Slot) :
 rewriteSlot second (rewriteSlot first slot) = rewriteSlot (second ∘ first) slot := by
 cases slot <;> rfl

structure Frame where
 origin : Nat
 storage : Nat
 layout : Nat
 slots : List Slot
 deriving Repr

def scan (move : Nat → Nat) (frame : Frame) : Frame :=
 {frame with slots := frame.slots.map (rewriteSlot move)}

structure Activation where
 identity : Nat
 layout : Nat
 slots : List Slot
 deriving Repr

def restore (frame : Frame) (fresh : Nat) : Activation :=
 {identity := fresh, layout := frame.layout, slots := frame.slots}

def decode (frame : Frame) (expected fresh : Nat) : Option Activation :=
 if expected = frame.layout then some (restore frame fresh) else none

theorem scanPreservesFrameIdentity (move : Nat → Nat) (frame : Frame) :
 (scan move frame).origin = frame.origin ∧ (scan move frame).storage = frame.storage ∧
 (scan move frame).layout = frame.layout := ⟨rfl,rfl,rfl⟩

theorem restoreUsesRelocatedRoots (move : Nat → Nat) (frame : Frame) (fresh : Nat) :
 rootValues (restore (scan move frame) fresh).slots = (rootValues frame.slots).map move :=
 rewriteCoversEveryDeclaredRoot move frame.slots

theorem multiShotHasFreshActivations (frame : Frame) (a b : Nat) (different : a ≠ b) :
 (restore frame a).identity ≠ (restore frame b).identity ∧
 (restore frame a).slots = (restore frame b).slots ∧
 (restore frame a).layout = (restore frame b).layout := ⟨different,rfl,rfl⟩

theorem decodeRejectsWrongLayout (frame : Frame) (expected fresh : Nat)
 (wrong : expected ≠ frame.layout) : decode frame expected fresh = none := by
 simp [decode,wrong]

-- C23 synchronization is an explicit premise, not inferred from fences or model steps.
theorem publicationReadOrdered (hb rf : Nat → Nat → Prop)
 (trans : ∀ a b c, hb a b → hb b c → hb a c)
 (sync : ∀ a b, rf a b → hb a b) (w pub acq rd : Nat)
 (before : hb w pub) (observes : rf pub acq) (after : hb acq rd) : hb w rd :=
 trans w acq rd (trans w pub acq before (sync pub acq observes)) after
end GambitRuntimeOwnership

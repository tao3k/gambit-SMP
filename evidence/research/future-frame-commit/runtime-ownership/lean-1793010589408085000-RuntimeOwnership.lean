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

-- A subordinate refinement kernel: aliases name cells, never values.
structure SlotKey where
 storage : Nat
 generation : Nat
 offset : Nat
 deriving DecidableEq

def readAlias {Alias : Type} (key : Alias → SlotKey) (heap : SlotKey → Nat) (a : Alias) : Nat := heap (key a)

def relocateCells (selected : SlotKey → Prop) [DecidablePred selected]
 (move : Nat → Nat) (heap : SlotKey → Nat) (k : SlotKey) : Nat :=
 if selected k then move (heap k) else heap k

theorem canonicalAliasesShareUpdatedCell {Alias : Type} (key : Alias → SlotKey)
 (heap : SlotKey → Nat) (selected : SlotKey → Prop) [DecidablePred selected]
 (move : Nat → Nat) (a b : Alias) (same : key a = key b) :
 readAlias key (relocateCells selected move heap) a =
 readAlias key (relocateCells selected move heap) b := by simp [readAlias,same]

theorem completeKeySelectionUpdatesEveryAlias {Alias : Type} (key : Alias → SlotKey)
 (heap : SlotKey → Nat) (selected : SlotKey → Prop) [DecidablePred selected]
 (move : Nat → Nat) (covered : ∀ a, selected (key a)) (a : Alias) :
 readAlias key (relocateCells selected move heap) a = move (readAlias key heap a) := by
 simp [readAlias,relocateCells,covered a]

theorem equalValuesDoNotReplaceCellCoverage :
 ∃ (heap : Nat → Nat) (selected : Nat → Bool), heap 0 = heap 1 ∧
 (if selected 0 then heap 0 + 100 else heap 0) ≠
 (if selected 1 then heap 1 + 100 else heap 1) := by
 refine ⟨fun _ => 7, fun k => k == 0, ?_⟩
 decide

theorem recycledAddressIsDifferentKey (storage offset g h : Nat) (different : g ≠ h) :
 (SlotKey.mk storage g offset) ≠ (SlotKey.mk storage h offset) := by
 intro same
 have gh := congrArg SlotKey.generation same
 exact different gh

theorem retainedBackingSufficesAfterLogicalExit {Alias : Type}
 (key : Alias → SlotKey) (live : SlotKey → Prop) (registered : Alias → Prop)
 (coverage : ∀ a, registered a → live (key a)) (a : Alias) (ha : registered a) :
 live (key a) := coverage a ha
end GambitRuntimeOwnership

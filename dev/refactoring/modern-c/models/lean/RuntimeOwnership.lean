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

-- Connect a domain-level scan claim to concrete keyed cells under explicit coverage.
def DomainFresh {Alias : Type} (key : Alias → SlotKey)
 (registered : Alias → Prop) (epoch : SlotKey → Nat) (round : Nat) : Prop :=
 ∀ a, registered a → epoch (key a) = round

theorem completeCellUpdatesReflectDomainFresh {Alias : Type}
 (key : Alias → SlotKey) (registered : Alias → Prop)
 (selected : SlotKey → Prop) [DecidablePred selected]
 (before : SlotKey → Nat) (round : Nat)
 (coverage : ∀ a, registered a → selected (key a)) :
 DomainFresh key registered (fun k => if selected k then round else before k) round := by
 intro a ha
 simp [coverage a ha]

theorem domainFreshRead {Alias : Type} (key : Alias → SlotKey)
 (registered : Alias → Prop) (epoch : SlotKey → Nat) (round : Nat)
 (fresh : DomainFresh key registered epoch round) (a : Alias) (ha : registered a) :
 epoch (key a) = round := fresh a ha

-- Root-slot pinning is storage lifetime, not permission for active raw access during GC.
structure RootLease where
 pin : Bool
 backing : Bool
 access : Bool
 rawUsable : Bool
 cached : Nat
 slot : Nat
 deriving DecidableEq

def LeaseSafe (r : RootLease) : Prop :=
 (r.pin = true → r.backing = true) ∧
 (r.rawUsable = true → r.pin = true ∧ r.backing = true ∧ r.cached = r.slot)

def parkLease (r : RootLease) : RootLease := {r with access := false, rawUsable := false}

def movePinnedSlot (r : RootLease) (move : Nat → Nat) : RootLease := {r with slot := move r.slot}

def reloadLease (r : RootLease) : RootLease := {r with rawUsable := true, cached := r.slot}

theorem parkingKeepsStoragePin (r : RootLease) :
 (parkLease r).pin = r.pin ∧ (parkLease r).rawUsable = false ∧ (parkLease r).access = false := ⟨rfl,rfl,rfl⟩

theorem collectionCanPreservePinnedLease (r : RootLease) (move : Nat → Nat) (h : LeaseSafe r) :
 LeaseSafe (movePinnedSlot (parkLease r) move) := by
 rcases h with ⟨hp,_⟩
 simp_all [LeaseSafe,movePinnedSlot,parkLease]

theorem reloadRestoresValueAgreement (r : RootLease) (pin : r.pin = true) (live : r.backing = true) :
 LeaseSafe (reloadLease r) := by simp [LeaseSafe,reloadLease,pin,live]

theorem freeingPinnedBackingViolatesLease (r : RootLease) (pin : r.pin = true) :
 ¬ LeaseSafe {r with backing := false} := by simp [LeaseSafe,pin]

theorem storagePinIsNotAccessClosure :
 ∃ r : RootLease, LeaseSafe r ∧ r.pin = true ∧ r.access = true ∧ r.rawUsable = true := by
 exact ⟨⟨true,true,true,true,7,7⟩,by simp [LeaseSafe],rfl,rfl,rfl⟩

-- Enumeration programs compose declared families; they do not discover undeclared writers.
inductive RootOp where
 | fixed | frame | dynamic | control
 deriving DecidableEq

def emits (fixed frame dynamic control : SlotKey → Prop) : RootOp → SlotKey → Prop
 | .fixed => fixed
 | .frame => frame
 | .dynamic => dynamic
 | .control => control

def ProgramCovers (ops : List RootOp) (f h d c : SlotKey → Prop) (k : SlotKey) : Prop :=
 ∃ op ∈ ops, emits f h d c op k

theorem completeProgramCoversDeclaredFamilies (f h d c : SlotKey → Prop) (k : SlotKey)
 (live : f k ∨ h k ∨ d k ∨ c k) : ProgramCovers [.fixed,.frame,.dynamic,.control] f h d c k := by
 rcases live with hf | hh | hd | hc
 · exact ⟨.fixed,by simp,hf⟩
 · exact ⟨.frame,by simp,hh⟩
 · exact ⟨.dynamic,by simp,hd⟩
 · exact ⟨.control,by simp,hc⟩

theorem ordinaryExclusionRequiresControlCoverage (ordinary live control handled : SlotKey → Prop)
 (ordinaryCoverage : ∀ k, live k → ¬ control k → ordinary k)
 (controlCoverage : ∀ k, control k → live k → handled k) (k : SlotKey) (hk : live k) :
 ordinary k ∨ handled k := by
 by_cases hc : control k
 · exact Or.inr (controlCoverage k hc hk)
 · exact Or.inl (ordinaryCoverage k hk hc)

theorem declaredFamiliesNeedConcreteCoverage (actual declared emitted : SlotKey → Prop)
 (inventory : ∀ k, actual k → declared k)
 (program : ∀ k, declared k → emitted k) : ∀ k, actual k → emitted k := by
 intro k hk
 exact program k (inventory k hk)

theorem layoutEqualityIsNotDynamicMembership :
 ∃ (abi recipe : Nat) (before after : List Nat), abi = recipe ∧ before ≠ after := by
 exact ⟨1,1,[],[2],rfl,by decide⟩
namespace Contracts

-- Parametric interface laws. Actual C transitions, alias/frame preservation
-- and environment interference require source correspondence at each edge.
structure Contract (State : Type) where
 requires : State → Prop
 ensures : State → State → Prop

def Realizes {State : Type} (contract : Contract State)
 (step : State → State → Prop) : Prop :=
 ∀ before after, contract.requires before → step before after → contract.ensures before after

def Sequence {State : Type} (first second : State → State → Prop)
 (before after : State) : Prop := ∃ middle, first before middle ∧ second middle after

theorem sequentialComposition {State : Type} (first second : Contract State)
 (firstStep secondStep : State → State → Prop)
 (firstCorrect : Realizes first firstStep) (secondCorrect : Realizes second secondStep)
 (handoff : ∀ before middle, first.requires before → first.ensures before middle → second.requires middle) :
 Realizes { requires := first.requires,
            ensures := fun before after => ∃ middle, first.ensures before middle ∧ second.ensures middle after }
          (Sequence firstStep secondStep) := by
 intro before after ready steps
 rcases steps with ⟨middle, left, right⟩
 have produced := firstCorrect before middle ready left
 exact ⟨middle, produced, secondCorrect middle after (handoff before middle ready produced) right⟩

-- A replacement must admit callers satisfying the original precondition.
theorem substitutionPreservesCallers {State : Type} (original replacement : Contract State)
 (step : State → State → Prop)
 (admits : ∀ state, original.requires state → replacement.requires state)
 (guarantee : ∀ before after, original.requires before → replacement.ensures before after → original.ensures before after)
 (correct : Realizes replacement step) : Realizes original step := by
 intro before after ready transition
 exact guarantee before after ready (correct before after (admits before ready) transition)

theorem frameWithExplicitPreservation {State : Type} (contract : Contract State)
 (step : State → State → Prop) (frame : State → Prop)
 (correct : Realizes contract step)
 (preserves : ∀ before after, step before after → frame before → frame after) :
 Realizes { requires := fun state => contract.requires state ∧ frame state,
            ensures := fun before after => contract.ensures before after ∧ frame after } step := by
 intro before after ready transition
 exact ⟨correct before after ready.1 transition, preserves before after transition ready.2⟩

inductive History {State : Type} (step : State → State → Prop) (initial : State) : State → Prop where
 | start : History step initial initial
 | next {before after} : History step initial before → step before after → History step initial after

theorem interferenceClosure {State : Type} (localStep peerStep : State → State → Prop)
 (invariant : State → Prop) (initial : State) (initialized : invariant initial)
 (localPreserves : ∀ before after, invariant before → localStep before after → invariant after)
 (peerPreserves : ∀ before after, invariant before → peerStep before after → invariant after) :
 ∀ after, History (fun before after => localStep before after ∨ peerStep before after) initial after → invariant after := by
 intro after history
 induction history with
 | start => exact initialized
 | next _ edge ih =>
   cases edge with
   | inl ownStep => exact localPreserves _ _ ih ownStep
   | inr peer => exact peerPreserves _ _ ih peer

end Contracts
end GambitRuntimeOwnership

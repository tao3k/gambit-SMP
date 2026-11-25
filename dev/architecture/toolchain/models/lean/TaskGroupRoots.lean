import Std
namespace Gambit.TaskGroupRoots
-- Exact formulas mirror the companion QNT observation, not native pointers.
structure RootView where
 epoch : Nat
 roots : List Nat
 slot : Nat → Nat

def slotCurrent (v : RootView) : Prop := ∀ i ∈ v.roots, v.slot i = 10*(i+1)+v.epoch

def relocate (v : RootView) : RootView :=
 {v with epoch := v.epoch+1, slot := fun i => if i ∈ v.roots then 10*(i+1)+v.epoch+1 else v.slot i}

theorem relocationUpdatesEveryDeclaredSlot (v : RootView) : slotCurrent (relocate v) := by
 intro i h
 simp [relocate] at h ⊢
 simp [h, Nat.add_assoc]

theorem relocationLeavesUndeclaredSlots (v : RootView) (i : Nat) (h : i ∉ v.roots) : (relocate v).slot i=v.slot i := by simp [relocate,h]

theorem stalePayloadWordAfterRelocation (v : RootView) (h : 0 ∈ v.roots) : (relocate v).slot 0 ≠ 10+v.epoch := by
 simp [relocate,h]

structure Lifetime where
 generation : Nat
 observerOpen : Bool
 pins : List Nat
 schemeDone : Bool
 process : Nat -- 0 no process, 1 unresolved, 2 terminal/reaped
 effectsClosed : Bool
 resultKnown : Bool
 queueRefs : Nat
 sourceHeld : Bool
 frozen : Bool
 retired : Bool

def canPin (s : Lifetime) (g : Nat) : Prop := s.generation=g ∧ s.observerOpen=true ∧ s.retired=false

def canRetire (s : Lifetime) : Prop := s.retired=false ∧ s.observerOpen=false ∧ s.pins=[] ∧ s.schemeDone=true ∧ s.process≠1 ∧ s.effectsClosed=true ∧ s.resultKnown=true ∧ s.queueRefs=0 ∧ s.sourceHeld=false ∧ s.frozen=false

def closeObservers (s : Lifetime) : Lifetime := {s with observerOpen:=false}
def retire (s : Lifetime) : Lifetime := {s with retired:=true}
def retirementSafe (s : Lifetime) : Prop := s.retired=true → s.observerOpen=false ∧ s.pins=[] ∧ s.schemeDone=true ∧ s.process≠1 ∧ s.effectsClosed=true ∧ s.resultKnown=true ∧ s.queueRefs=0 ∧ s.sourceHeld=false ∧ s.frozen=false

theorem closeRefusesNewPin (s : Lifetime) (g : Nat) : ¬canPin (closeObservers s) g := by simp [canPin,closeObservers]

theorem wrongGenerationRefusesPin (s : Lifetime) (g : Nat) (h : s.generation≠g) : ¬canPin s g := fun p=>h p.1

theorem unknownProcessBlocksRetirement (s : Lifetime) (h : s.process=1) : ¬canRetire s := by
 intro p
 exact p.2.2.2.2.1 h

theorem pinnedObserverBlocksRetirement (s : Lifetime) (h : s.pins≠[]) : ¬canRetire s := fun p=>h p.2.2.1

theorem frozenManifestBlocksRetirement (s : Lifetime) (h : s.frozen=true) : ¬canRetire s := by
 intro p
 have no:=p.2.2.2.2.2.2.2.2.2
 rw [h] at no
 contradiction

theorem missingResultBlocksRetirement (s : Lifetime) (h : s.resultKnown=false) : ¬canRetire s := by
 intro p
 have known:=p.2.2.2.2.2.2.1
 rw [h] at known
 contradiction

theorem guardedRetirementPreservesSafety (s : Lifetime) (h : canRetire s) : retirementSafe (retire s) := by
 intro _
 exact h.2

def releasePin (pins : List Nat) (p : Nat) : List Nat := pins.filter (· != p)

theorem retiredPinCannotReturnTwice (pins : List Nat) (p : Nat) : p ∉ releasePin pins p := by simp [releasePin]

-- An abstract native completion observation must establish BOTH predicates.
-- Scheme end/result publication alone is not a process/effects witness.
theorem terminalAloneIsInsufficient (s : Lifetime) (h : s.effectsClosed=false) : ¬canRetire {s with process:=2} := by
 intro p
 have closed:=p.2.2.2.2.2.1
 simp at closed
 rw [h] at closed
 contradiction
def localKnown (s : Lifetime) : Prop := s.resultKnown=true ∧ s.process≠1 ∧ s.effectsClosed=true

def ledgerBridge (ledgerKnown : Bool) (s : Lifetime) : Prop := ledgerKnown=true → localKnown s

theorem guardedLedgerCommitPreservesBridge (s : Lifetime) (h : localKnown s) : ledgerBridge true s := fun _=>h

theorem unknownCannotBeKnownLedgerResult (s : Lifetime) (h : s.process=1) : ¬ledgerBridge true s := by
 intro b
 exact (b rfl).2.1 h
end Gambit.TaskGroupRoots

import Std
import LeanPoo.Functional.Transformation

namespace Gambit.SharedHeapRelocation

-- This is a data-observation law, not a second GC state machine. The concrete
-- adapter must establish complete authoritative-slot rewriting and an injective
-- forwarding map for the admitted live addresses. Epoch/permit ordering belongs
-- to Quint; root/young reachability remains the existing GenerationalRootAdmission.
def RewrittenOn {Slot Addr : Type} (admitted : Slot → Prop)
    (before after : Slot → Addr) (forward : Addr → Addr) : Prop :=
  ∀ slot, admitted slot → after slot = forward (before slot)

def SameTarget {Slot Addr : Type} (slots : Slot → Addr) (a b : Slot) : Prop :=
  slots a = slots b

-- A single logical cell shared by globals, captured frames or native handles
-- remains shared. No assumptions about scheduling or number of restore calls.
theorem aliasesRemainAliases {Slot Addr : Type}
    (admitted : Slot → Prop) (before after : Slot → Addr) (forward : Addr → Addr)
    (rewritten : RewrittenOn admitted before after forward)
    (a b : Slot) (ha : admitted a) (hb : admitted b)
    (same : SameTarget before a b) : SameTarget after a b := by
  unfold SameTarget at *
  rw [rewritten a ha, rewritten b hb, same]

-- Injectivity prevents two distinct live Scheme objects from being merged.
-- Injectivity is restricted to the targets of admitted authoritative slots;
-- no injectivity hypothesis is imposed on dead objects or arbitrary raw words.
theorem equalityObservationPreserved {Slot Addr : Type}
    (admitted : Slot → Prop) (before after : Slot → Addr) (forward : Addr → Addr)
    (rewritten : RewrittenOn admitted before after forward)
    (injective : ∀ a b, admitted a → admitted b →
      forward (before a) = forward (before b) → before a = before b)
    (a b : Slot) (ha : admitted a) (hb : admitted b) :
    SameTarget after a b ↔ SameTarget before a b := by
  unfold SameTarget
  rw [rewritten a ha, rewritten b hb]
  exact ⟨fun h => injective a b ha hb h, fun h => congrArg forward h⟩

-- Witnesses for why both data premises matter. Reaching the target through one
-- root does not repair another source slot, and noninjective copying is wrong.
theorem missedSourceSlotBreaksAlias :
    ∃ before after : Bool → Nat,
      SameTarget before true false ∧ ¬ SameTarget after true false := by
  refine ⟨fun _ => 7, fun b => if b then 8 else 7, rfl, ?_⟩
  simp [SameTarget]

theorem collapsedAddressesBreakIdentity :
    ∃ before after : Bool → Nat,
      ¬ SameTarget before true false ∧ SameTarget after true false := by
  refine ⟨fun b => if b then 1 else 0, fun _ => 0, ?_, rfl⟩
  simp [SameTarget]

-- Reuse the release library's typed refinement interface. This does not supply
-- a C adapter: a concrete adapter must return the slot-premise correctness proof.
structure RelocationView (Slot Addr : Type) where
  admitted : Slot → Prop
  before : Slot → Addr
  after : Slot → Addr
  forward : Addr → Addr

def slotPremises {Slot Addr : Type} (v : RelocationView Slot Addr) : Prop :=
  RewrittenOn v.admitted v.before v.after v.forward ∧
  (∀ a b, v.admitted a → v.admitted b →
    v.forward (v.before a) = v.forward (v.before b) → v.before a = v.before b)

def aliasObservations {Slot Addr : Type} (v : RelocationView Slot Addr) : Prop :=
  ∀ a b, v.admitted a → v.admitted b →
    (SameTarget v.after a b ↔ SameTarget v.before a b)

def aliasProblem (Slot Addr : Type) : LeanPoo.Functional.Transformation.Problem where
  Input := RelocationView Slot Addr
  Result := fun _ => Unit
  Valid := fun _ => True
  Correct := fun v _ => aliasObservations v

def slotProblem (Slot Addr : Type) : LeanPoo.Functional.Transformation.Problem where
  Input := RelocationView Slot Addr
  Result := fun _ => Unit
  Valid := fun _ => True
  Correct := fun v _ => slotPremises v

def aliasObservationRefinement (Slot Addr : Type) :
    LeanPoo.Functional.Transformation.CertifiedTransformation
      (aliasProblem Slot Addr) (slotProblem Slot Addr) where
  forward := id
  preserves := fun _ valid => valid
  extract := fun _ result => result
  sound := by
    intro v _ _ premises a b ha hb
    exact equalityObservationPreserved v.admitted v.before v.after v.forward
      premises.1 premises.2 a b ha hb

-- No default/identity C adapter is supplied. The missing source refinement is
-- an explicit argument, so importing the library cannot close SH-ALIAS-S.
def withSourceAdapter (Slot Addr : Type)
    (nativeProblem : LeanPoo.Functional.Transformation.Problem)
    (adapter : LeanPoo.Functional.Transformation.CertifiedTransformation
      (slotProblem Slot Addr) nativeProblem) :=
  LeanPoo.Functional.Transformation.compose
    (aliasObservationRefinement Slot Addr) adapter

-- A completed canonical-cell store denotes this update only after the C
-- adapter establishes its target as forward(before slot). It is not a model
-- of scheduling, allocation, or reading a partly initialized destination.
def rewriteBatch {Slot Addr : Type} [DecidableEq Slot]
    (before : Slot → Addr) (forward : Addr → Addr) :
    List Slot → (Slot → Addr) → Slot → Addr
  | [], current => current
  | target :: rest, current => rewriteBatch before forward rest
      (fun slot => if slot = target then forward (before slot) else current slot)

theorem rewriteBatchAt {Slot Addr : Type} [DecidableEq Slot]
    (before current : Slot → Addr) (forward : Addr → Addr)
    (todo : List Slot) (slot : Slot) :
    rewriteBatch before forward todo current slot =
      if slot ∈ todo then forward (before slot) else current slot := by
  induction todo generalizing current with
  | nil => simp [rewriteBatch]
  | cons target rest ih =>
    rw [rewriteBatch, ih]
    by_cases member : slot ∈ rest
    · simp [member]
    · by_cases same : slot = target
      · simp [member, same]
      · simp [member, same]

theorem batchCoverageProducesRewrittenOn {Slot Addr : Type} [DecidableEq Slot]
    (admitted : Slot → Prop) (before current : Slot → Addr)
    (forward : Addr → Addr) (todo : List Slot)
    (coverage : ∀ slot, admitted slot → slot ∈ todo) :
    RewrittenOn admitted before (rewriteBatch before forward todo current) forward := by
  intro slot needed
  rw [rewriteBatchAt]
  simp [coverage slot needed]

theorem repeatedCanonicalSlotIsIdempotent {Slot Addr : Type} [DecidableEq Slot]
    (before current : Slot → Addr) (forward : Addr → Addr)
    (target : Slot) (rest : List Slot) :
    rewriteBatch before forward (target :: target :: rest) current =
      rewriteBatch before forward (target :: rest) current := by
  funext slot
  by_cases same : slot = target
  · simp [rewriteBatchAt, same]
  · simp [rewriteBatchAt, same]

#print axioms aliasesRemainAliases
#print axioms equalityObservationPreserved
#print axioms missedSourceSlotBreaksAlias
#print axioms collapsedAddressesBreakIdentity
#print axioms aliasObservationRefinement
#print axioms withSourceAdapter
#print axioms rewriteBatchAt
#print axioms batchCoverageProducesRewrittenOn
#print axioms repeatedCanonicalSlotIsIdempotent
end Gambit.SharedHeapRelocation

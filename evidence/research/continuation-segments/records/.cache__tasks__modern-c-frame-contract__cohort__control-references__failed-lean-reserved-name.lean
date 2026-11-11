import Std
namespace Gambit.ContinuationSegments
-- One unbounded algebraic obligation, not a second copy of the Quint scheduler.
-- The C publication/writer adapter must separately refine ImageHistory.
structure Image where
  slots : Nat → Nat
  version : Nat
  denv : Nat
structure View where
  slots : Nat → Nat
  version : Nat
  denv : Nat
  sharedHeap : Nat → Nat
def prepare (image : Image) (heap : Nat → Nat) : View :=
  ⟨image.slots,image.version,image.denv,heap⟩
def replaceImage (image : Image) (slots : Nat → Nat) (denv : Nat) : Image :=
  ⟨slots,image.version+1,denv⟩
def Coherent (image : Image) (view : View) : Prop :=
  view.version=image.version ∧ view.slots=image.slots ∧ view.denv=image.denv
inductive ImageHistory : Image → Image → Prop
  | refl (image : Image) : ImageHistory image image
  | update {first current : Image} (prior : ImageHistory first current)
      (slots : Nat → Nat) (denv : Nat) :
      ImageHistory first (replaceImage current slots denv)
theorem historyVersionMonotone {first current : Image} (h : ImageHistory first current) :
    first.version ≤ current.version := by
  induction h with
  | refl => exact Nat.le_refl _
  | update _ slots denv ih => simp only [replaceImage]; omega
theorem unchangedVersionPreservesImage {first current : Image}
    (h : ImageHistory first current) (same : current.version=first.version) :
    current=first := by
  cases h with
  | refl => rfl
  | update prior slots denv =>
      have order := historyVersionMonotone prior
      simp only [replaceImage] at same
      omega
theorem issuedViewRemainsCoherent {issued current : Image} {view : View}
    (issuance : Coherent issued view) (history : ImageHistory issued current)
    (matches : view.version=current.version) : Coherent current view := by
  have eqv : current.version=issued.version := matches.symm.trans issuance.1
  have same := unchangedVersionPreservesImage history eqv
  simpa [same] using issuance
theorem newlyPreparedViewIsCoherent (image : Image) (heap : Nat → Nat) :
    Coherent image (prepare image heap) := ⟨rfl,rfl,rfl⟩
theorem preparationPreservesSharedHeapIdentity (image : Image) (heap : Nat → Nat) :
    (prepare image heap).sharedHeap=heap := rfl
-- Same version alone is insufficient without authentic issuance and a complete
-- writer history. In particular, raw frame/denv setters cannot be ignored.
theorem sameVersionAloneDoesNotCertifySlots :
    ∃ image : Image, ∃ view : View,
      view.version=image.version ∧ ¬ Coherent image view := by
  refine ⟨⟨fun _ => 1,0,0⟩,⟨fun _ => 0,0,0,fun _ => 0⟩,rfl,?_⟩
  intro h
  have bad := congrFun h.2.1 0
  simp at bad
end Gambit.ContinuationSegments

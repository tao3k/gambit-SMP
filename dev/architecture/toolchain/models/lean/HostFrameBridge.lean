import HostResourceSemantics
import FrameRoots
import FrameContract

-- Source schema is targ-make-frame-spec in _t-c-3.scm. No howto-specific
-- descriptor row is supplied by this file. Physical aliasing is separate.
namespace Gambit.HostFrameBridge
open HostResourceSemantics
structure FrameSpec where
 kind : Nat
 storedFs : Nat
 actualFs : Nat
 link : Nat
 bitmap : Nat

def Valid (f : FrameSpec) : Prop :=
 (f.kind=1 ∨ f.kind=2 ∨ f.kind=3) ∧ f.storedFs<16384 ∧
 f.link<16384 ∧ f.link<f.actualFs ∧ f.bitmap<2^f.actualFs

-- Physical frame slots are one-based; the structural link is not an ordinary root.
def ordinarySlots (f : FrameSpec) : List Nat :=
 (List.range (f.actualFs+1)).filter (fun slot =>
   decide (0<slot) && f.bitmap.testBit (slot-1) && decide (slot≠f.link+1))

theorem ordinarySlotMeaning (f : FrameSpec) (slot : Nat) :
 slot ∈ ordinarySlots f ↔
 0<slot ∧ slot≤f.actualFs ∧ f.bitmap.testBit (slot-1)=true ∧ slot≠f.link+1 := by
 simp [ordinarySlots,Nat.lt_succ_iff,and_assoc,and_left_comm,and_comm]

theorem zeroIsNotOrdinary (f : FrameSpec) : 0 ∉ ordinarySlots f := by
 simp [ordinarySlotMeaning]

theorem linkIsNotOrdinary (f : FrameSpec) : f.link+1 ∉ ordinarySlots f := by
 simp [ordinarySlotMeaning]

-- Injective physical slot -> logical Store-cell map, not slot-1 assumed to be a GVM register.
def rootCells (f : FrameSpec) (place : Nat → Nat) : List Nat :=
 (ordinarySlots f).map place

theorem rootCellMeaning (f : FrameSpec) (place : Nat → Nat) (cell : Nat) :
 cell ∈ rootCells f place ↔ ∃ slot, 0<slot ∧ slot≤f.actualFs ∧
 f.bitmap.testBit (slot-1)=true ∧ slot≠f.link+1 ∧ place slot=cell := by
 simp only [rootCells,List.mem_map,ordinarySlotMeaning]
 constructor
 · rintro ⟨slot,⟨positive,bounded,live,ordinary⟩,same⟩
   exact ⟨slot,positive,bounded,live,ordinary,same⟩
 · rintro ⟨slot,positive,bounded,live,ordinary,same⟩
   exact ⟨slot,⟨positive,bounded,live,ordinary⟩,same⟩

theorem linkCellExcluded (f : FrameSpec) (place : Nat → Nat)
 (injective : Function.Injective place) : place (f.link+1) ∉ rootCells f place := by
 intro present
 obtain ⟨slot,member,equal⟩ := List.mem_map.mp present
 have same : slot=f.link+1 := injective equal
 exact linkIsNotOrdinary f (same ▸ member)

def pollFrame (keep : Keep) (f : FrameSpec) (place move : Nat → Nat) (h : Host) : Host :=
 boundaryStep keep (poll (rootCells f place) move) h

theorem framePollSimulation (keep : Keep) (f : FrameSpec) (place move : Nat → Nat) (h : Host) :
 observe keep (pollFrame keep f place move h)=poll (rootCells f place) move (observe keep h) :=
 pollSimulation keep h (rootCells f place) move

theorem ordinaryRootUpdated (keep : Keep) (f : FrameSpec) (place move : Nat → Nat)
 (h : Host) (slot : Nat) (ordinary : slot ∈ ordinarySlots f) :
 (observe keep (pollFrame keep f place move h)).regs (place slot)=
 move ((observe keep h).regs (place slot)) := by
 apply polledRootValue keep h (rootCells f place) move (place slot)
 have member : place slot ∈ rootCells f place := List.mem_map.mpr ⟨slot,ordinary,rfl⟩
 simpa using member

theorem structuralLinkNotMovedAsOrdinary (keep : Keep) (f : FrameSpec)
 (place move : Nat → Nat) (h : Host) (injective : Function.Injective place) :
 (observe keep (pollFrame keep f place move h)).regs (place (f.link+1))=
 (observe keep h).regs (place (f.link+1)) := by
 rw [framePollSimulation]
 have excluded := linkCellExcluded f place injective
 simp [poll,moveRoots,excluded]

-- Reuse existing descriptor/coordinate proofs; do not restate their algorithms.
theorem inlineRootMapCorrespondence (kind fs link bitmap : Nat)
 (hk : kind<4) (hf : fs<32) (hl : link<32) (hb : bitmap<1048576) :
 (FrameContract.inlineWord kind fs link bitmap /4096)%1048576=bitmap :=
 FrameContract.inlineRoots kind fs link bitmap hk hf hl hb

theorem physicalSlotCoordinate (slot width : Nat) (positive : 0<slot) :
 ((slot-1)%width)+width*((slot-1)/width)+1=slot :=
 FrameRoots.coordinate slot width positive
end Gambit.HostFrameBridge

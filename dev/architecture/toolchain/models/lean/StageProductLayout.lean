import FrameContract
namespace Gambit.StageProductLayout
structure LayoutABI where
 wordBytes : Nat
 byteOrder : Nat
 characterBytes : Nat
 gvmRegisters : Nat
 frameAlignment : Nat
 frameReserve : Nat
 descriptorEncoding : Nat
 deriving DecidableEq
structure FrameSpec where
 label : Nat
 kind : Nat
 storedFs : Nat
 actualFs : Nat
 link : Nat
 roots : Nat
 deriving DecidableEq
structure ModulePlan where
 semanticKey : Nat
 abi : LayoutABI
 frames : List FrameSpec
 initPlan : List Nat
 defaultFlags : Nat
structure ModuleInstance where
 plan : ModulePlan
 vm : Nat
 flags : Nat
 nativeHandle : Option Nat
def instantiate (p : ModulePlan) (vm : Nat) (flags handle : Option Nat) : ModuleInstance :=
 ⟨p,vm,flags.getD p.defaultFlags,handle⟩
structure LayoutKey where
 semanticKey : Nat
 abi : LayoutABI
 frames : List FrameSpec
 initPlan : List Nat
 defaultFlags : Nat
 deriving DecidableEq
def layoutKey (p : ModulePlan) : LayoutKey := ⟨p.semanticKey,p.abi,p.frames,p.initPlan,p.defaultFlags⟩
def overrideFlags (i : ModuleInstance) (flags : Nat) : ModuleInstance := {i with flags:=flags}

theorem instanceUsesSameFrameTable (p : ModulePlan) (vm : Nat) (flags handle : Option Nat) :
 (instantiate p vm flags handle).plan.frames=p.frames := rfl
theorem setupFlagsDoNotChangePlan (i : ModuleInstance) (flags : Nat) :
 (overrideFlags i flags).plan=i.plan := rfl
theorem nativeHandleDoesNotEnterLayoutKey (p : ModulePlan) (vm : Nat) (flags a b : Option Nat) :
 layoutKey (instantiate p vm flags a).plan=layoutKey (instantiate p vm flags b).plan := rfl
theorem abiChangeInvalidatesLayout (a b : ModulePlan) (different : a.abi≠b.abi) :
 layoutKey a≠layoutKey b := fun h => different (congrArg LayoutKey.abi h)
theorem frameChangeInvalidatesLayout (a b : ModulePlan) (different : a.frames≠b.frames) :
 layoutKey a≠layoutKey b := fun h => different (congrArg LayoutKey.frames h)
theorem defaultFlagsChangeInvalidatesLayout (a b : ModulePlan) (different : a.defaultFlags≠b.defaultFlags) :
 layoutKey a≠layoutKey b := fun h => different (congrArg LayoutKey.defaultFlags h)
theorem initOrderPreserved (p : ModulePlan) (vm : Nat) (flags handle : Option Nat) :
 (instantiate p vm flags handle).plan.initPlan=p.initPlan := rfl

-- Reuse existing bitfield algebra. This is a bounded inline representation
-- slice, not native pointer validity, RETI decoding or all-ABI/OFD coverage.
def inlineBounds (f : FrameSpec) : Prop :=
 f.kind<4 ∧ f.storedFs<32 ∧ f.link<32 ∧ f.roots<1048576
def emitInline (f : FrameSpec) : Nat :=
 Gambit.FrameContract.inlineWord f.kind f.storedFs f.link f.roots
def decodeInline (word : Nat) : Nat × Nat × Nat × Nat :=
 (word%4,(word/4)%32,(word/128)%32,(word/4096)%1048576)
def inlineValues (f : FrameSpec) : Nat × Nat × Nat × Nat :=
 (f.kind,f.storedFs,f.link,f.roots)
theorem inlineFieldProjection (f : FrameSpec) (h : inlineBounds f) :
 decodeInline (emitInline f)=inlineValues f := by
 rcases h with ⟨hk,hs,hl,hr⟩
 simp only [decodeInline,emitInline,inlineValues]
 rw [Gambit.FrameContract.inlineKind _ _ _ _ hk,
     Gambit.FrameContract.inlineSize _ _ _ _ hk hs,
     Gambit.FrameContract.inlineLink _ _ _ _ hk hs hl,
     Gambit.FrameContract.inlineRoots _ _ _ _ hk hs hl hr]
theorem frameTableProjection (frames : List FrameSpec)
 (h : ∀ f ∈ frames, inlineBounds f) :
 (frames.map emitInline).map decodeInline=frames.map inlineValues := by
 induction frames with
 | nil => rfl
 | cons f fs ih =>
   have head := inlineFieldProjection f (h f (List.mem_cons_self))
   have tail := ih (fun x hx => h x (List.mem_cons_of_mem f hx))
   simpa only [List.map_cons,head,tail]
end Gambit.StageProductLayout

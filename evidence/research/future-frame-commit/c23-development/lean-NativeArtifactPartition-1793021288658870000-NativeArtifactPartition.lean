import Std
namespace Gambit.NativeArtifactPartition
structure HeaderKey where
 abi : Nat
 inlinePolicy : Nat
 deriving DecidableEq
structure ObjectKey where
 moduleId : Nat
 header : HeaderKey
 tool : Nat
 source : Nat
 descriptor : Nat
 deriving DecidableEq
structure Inputs where
 abi : Nat
 inlinePolicy : Nat
 tool : Nat
 source : Nat → Nat
 count : Nat → Nat

def header (x : Inputs) : HeaderKey := ⟨x.abi,x.inlinePolicy⟩
def objectKey (x : Inputs) (m : Nat) : ObjectKey := ⟨m,header x,x.tool,x.source m,x.count m⟩
def editCount (x : Inputs) (m value : Nat) : Inputs := {x with count:=fun n=>if n=m then value else x.count n}

theorem countDoesNotChangeHeader (x : Inputs) (m value : Nat) : header (editCount x m value)=header x := rfl

theorem countIsLocal (x : Inputs) (m n value : Nat) (different : n≠m) : objectKey (editCount x m value) n=objectKey x n := by
 simp [objectKey,header,editCount,different]

theorem changedCountInvalidates (x : Inputs) (m value : Nat) (changed : value≠x.count m) : objectKey (editCount x m value) m≠objectKey x m := by
 intro equal
 have fields:=congrArg ObjectKey.descriptor equal
 simp [objectKey,editCount] at fields
 exact changed fields

theorem moduleIdentityIsNativeInput (x : Inputs) (m n : Nat) (different : m≠n) : objectKey x m≠objectKey x n := by
 intro equal
 exact different (congrArg ObjectKey.moduleId equal)

theorem toolDoesNotChangeHeader (x : Inputs) (tool : Nat) : header {x with tool:=tool}=header x := rfl

theorem abiIsNativeInput (x : Inputs) (m abi : Nat) (changed : abi≠x.abi) : objectKey {x with abi:=abi} m≠objectKey x m := by
 intro equal
 have fields:=congrArg (fun k:ObjectKey=>k.header.abi) equal
 exact changed fields

structure Publication where
 snapshot : ObjectKey
 current : ObjectKey
 dependencyClosed : Bool
 success : Bool
 groupComplete : Bool

def admitted (p : Publication) : Prop := p.snapshot=p.current ∧ p.dependencyClosed=true ∧ p.success=true ∧ p.groupComplete=true

theorem staleSnapshotRefuses (p : Publication) (stale : p.snapshot≠p.current) : ¬admitted p := by
 intro accepted;exact stale accepted.1

theorem successNotWholeClosure (p : Publication) (accepted : admitted p) : p.dependencyClosed=true ∧ p.groupComplete=true := ⟨accepted.2.1,accepted.2.2.2⟩
-- These are projection laws. Concrete C dependencies, collision resistance,
-- actual atomic publication and QNT-to-Lean extraction remain separate duties.
end Gambit.NativeArtifactPartition

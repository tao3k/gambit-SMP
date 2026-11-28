import Std
namespace Gambit.LinkProductContract
structure Plan where
 members : List Nat
 metadata : List Nat
 abi : Nat
 tool : Nat
 deriving DecidableEq
structure Publication where
 snapshot : Plan
 current : Plan
 closed : Bool
 success : Bool
 generated : Bool
 object : Bool
 linkInfo : Bool
 deriving DecidableEq

def admitted (p : Publication) : Prop :=
 p.snapshot=p.current ∧ p.closed=true ∧ p.success=true ∧
 p.generated=true ∧ p.object=true ∧ p.linkInfo=true

theorem exactPlan (p : Publication) (h : admitted p) : p.snapshot=p.current := h.1

theorem orderedMembers (p : Publication) (h : admitted p) : p.snapshot.members=p.current.members := congrArg Plan.members h.1

theorem orderedMetadata (p : Publication) (h : admitted p) : p.snapshot.metadata=p.current.metadata := congrArg Plan.metadata h.1

theorem partialGroupRefuses (p : Publication) (missing : p.object=false) : ¬admitted p := by
 intro h
 have hh := h.2.2.2.2.1
 rw [missing] at hh
 contradiction

theorem stalePlanRefuses (p : Publication) (stale : p.snapshot≠p.current) : ¬admitted p := fun h=>stale h.1

theorem opaqueEffectRefuses (p : Publication) (untracked : p.closed=false) : ¬admitted p := by
 intro h
 have hh := h.2.1
 rw [untracked] at hh
 contradiction

-- Acknowledgement loss does not mutate the committed product. This does not
-- establish filesystem atomicity, crash recovery, or exactly-once execution.
theorem lostReplyPreserves (p : Publication) (h : admitted p) : admitted p := h

theorem multipleConsumers (p : Publication) (h : admitted p) : admitted p ∧ admitted p := ⟨h,h⟩
end Gambit.LinkProductContract

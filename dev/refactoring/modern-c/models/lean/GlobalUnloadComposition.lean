import GlobalUnload
import SealStartComposition
namespace GlobalUnloadComposition
-- Owner identifiers must encode module/image generation and VM incarnation in the adapter.
def AllDetached (owners : List Nat) (accepted : Nat → Bool) : Prop :=
 ∀ owner, owner∈owners → accepted owner=true
theorem allDetachedUnion (left right : List Nat) (accepted : Nat → Bool) :
 AllDetached (left++right) accepted ↔ AllDetached left accepted ∧ AllDetached right accepted := by
 simp [AllDetached,List.mem_append]; constructor
 · intro h; exact ⟨fun o hm => h o (Or.inl hm),fun o hm => h o (Or.inr hm)⟩
 · rintro ⟨hl,hr⟩ o (hm|hm)
   · exact hl o hm
   · exact hr o hm
theorem duplicateOwnerDoesNotSupplyAnotherReceipt (owner : Nat) (owners : List Nat) (accepted : Nat → Bool) :
 AllDetached (owner::owner::owners) accepted ↔ AllDetached (owner::owners) accepted := by
 simp [AllDetached]
theorem permitRefinesPriorGlobalReadiness (q : GlobalUnloadAst.State)
 (h : GlobalUnloadAst.Safe q) (permitted : q.phase=2) :
 SealStartComposition.GlobalRetireReady q.receipt0
   (q.users1+q.nativeUsers+q.tasks+q.observers) q.closed1 ∧
 SealStartComposition.GlobalRetireReady q.receipt1
   (q.users0+q.nativeUsers+q.tasks+q.observers) q.closed0 := by
 have ready := GlobalUnload.permitNeedsAllReceipts q h permitted
 have owners :=  GlobalUnload.permitOwnersQuiescent q h permitted
 rcases ready with ⟨r0,r1,s0,s1,hn,ht,ho⟩
 rcases owners with ⟨u0,u1,c0,c1⟩
 exact ⟨⟨r0,by omega,c1⟩,⟨r1,by omega,c0⟩⟩
-- Pair is a representative quotient; the source adapter must prove owner-manifest completeness.
theorem pairCoverage (owners : List Nat) (accepted : Nat → Bool) (a b : Nat)
 (complete : ∀ o, o∈owners → o=a ∨ o=b) (ha : accepted a=true) (hb : accepted b=true) :
 AllDetached owners accepted := by
 intro o member
 rcases complete o member with h | h
 · simpa [h] using ha
 · simpa [h] using hb
end GlobalUnloadComposition

import ImageEnrollment
import GlobalUnloadComposition
namespace ImageEnrollmentComposition
open ImageEnrollmentAst
def requiredOwners (q : State) : List Nat := if q.expected1 then [0,1] else [0]
def accepted (q : State) (owner : Nat) : Bool := if owner=0 then q.receipt0 else q.receipt1
theorem permitCoversRequiredOwners (q : State) (h : Safe q) (p : q.phase=2) :
 GlobalUnloadComposition.AllDetached (requiredOwners q) (accepted q) := by
 have own := ImageEnrollment.permitOwnerReceipts q h p
 cases e : q.expected1 with
 | false => simp [requiredOwners,accepted,GlobalUnloadComposition.AllDetached,e,own.1]
 | true =>
   have other := own.2.1 e
   simp [requiredOwners,accepted,GlobalUnloadComposition.AllDetached,e,own.1,other]
theorem actualOwnerCoverage (q : State) (h : Safe q) (p : q.phase=2)
 (actual : List Nat) (slot : Nat → Nat)
 (coverage : ∀ o, o∈actual → slot o∈requiredOwners q) :
 GlobalUnloadComposition.AllDetached actual (fun owner => accepted q (slot owner)) := by
 have known := permitCoversRequiredOwners q h p
 intro owner member
 exact known (slot owner) (coverage owner member)
theorem legacyRawBlocksPermit (q : State) (raw : q.rawEscape=true) : ¬permitGuard q := by
 simp [permitGuard,raw]
end ImageEnrollmentComposition

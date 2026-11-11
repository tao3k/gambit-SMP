import PinRosterDetachment
namespace FfiScopeRootAdmission
structure PinFlat where
 borrow : Bool
 incoming : Bool
 sourceSlot : Int
 guardLive : Bool
 scope : Bool
 root : Bool
 allocated : Bool
 marker : Bool
 active : Bool
 done : Bool
 unknown : Bool
 scanner : Bool
 closed : Bool
 retired : Bool
 epoch : Int
 slot : Int
 «local» : Int
 markerVersion : Int
 deriving DecidableEq
def qRegisterGuard (q : PinFlat) : Prop := q.borrow=true ∧ q.incoming=true ∧ ¬q.guardLive=true ∧ ¬q.closed=true ∧ ¬q.retired=true
def qRegisterNext (q : PinFlat) := {q with guardLive:=true}
def qRootsGuard (q : PinFlat) : Prop := q.guardLive=true ∧ q.scope=true ∧ q.incoming=true ∧ ¬q.done=true ∧ ¬q.root=true
def qRootsNext (q : PinFlat) := {q with root:=true,slot:=q.sourceSlot,incoming:=false}
def qReleaseGuard (q : PinFlat) : Prop := q.guardLive=true ∧ q.scope=true ∧ q.done=true ∧ ¬q.active=true ∧ ¬q.marker=true ∧ ¬q.unknown=true
def qReleaseNext (q : PinFlat) := {q with scope:=false}
theorem noBorrowRejectsGuard (q : PinFlat) (h : q.borrow=false) : ¬qRegisterGuard q := by simp [qRegisterGuard,h]
theorem unrootedIngressRejectsGuard (q : PinFlat) (h : q.incoming=false) : ¬qRegisterGuard q := by simp [qRegisterGuard,h]
theorem noGuardRejectsRoots (q : PinFlat) (h : q.guardLive=false) : ¬qRootsGuard q := by simp [qRootsGuard,h]
theorem markerBlocksRelease (q : PinFlat) (h : q.marker=true) : ¬qReleaseGuard q := by simp [qReleaseGuard,h]
theorem unknownBlocksRelease (q : PinFlat) (h : q.unknown=true) : ¬qReleaseGuard q := by simp [qReleaseGuard,h]
theorem activeBlocksRelease (q : PinFlat) (h : q.active=true) : ¬qReleaseGuard q := by simp [qReleaseGuard,h]
theorem rootPublicationValue (q : PinFlat) : (qRootsNext q).slot=q.sourceSlot := rfl
theorem reloadAfterMove (old current : Int) (m : old≠current) : ¬old=current := m
-- Event numbers stand for a supplied HB/SC embedding, not the C11 relation itself.
theorem publicationBeforeRead (init release acquire read : Nat)
 (a : init<release) (b : release<acquire) (c : acquire<read) : init<read := by omega
theorem finalUseBeforeWithdrawal (use clear withdraw : Nat)
 (a : use<clear) (b : clear<withdraw) : use<withdraw := by omega
theorem closeCannotGrantLateAdmission (accept close : Nat) (a : close<accept) (g : accept<close) : False := by omega
structure Evidence where
 semantic : Bool
 foreign : Bool
 resident : Bool
 task : Int
 expected : Int
 deriving DecidableEq
def issuable (e : Evidence) : Prop := e.semantic=true ∧ e.foreign=true ∧ e.resident=true ∧ e.task=e.expected
theorem incompleteEndorsementRejects (e : Evidence) (h : e.semantic=false) : ¬issuable e := by simp [issuable,h]
theorem wrongTaskRejects (e : Evidence) (h : e.task≠e.expected) : ¬issuable e := by simp [issuable,h]
open DerivationReceiptEnvironment
theorem environmentNoFabrication (rows : List (Nat × Nat)) (k d : Nat)
 (h : buildEnv rows k=some d) : (k,d)∈rows := PinRosterDetachment.environmentNoFabrication rows k d h
theorem environmentExactDomain (rows : List (Nat × Nat)) (valid : tableCheck rows=true) (k d : Nat) :
 buildEnv rows k=some d ↔ (k,d)∈rows := PinRosterDetachment.environmentExactDomain rows valid k d
end FfiScopeRootAdmission

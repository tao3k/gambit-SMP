/- Conditional view/ownership laws. No complete Quint induction, C execution or native proof. -/
namespace GambitSMP.ResizeBootstrapAdmission
structure View where
  complete : Bool
  frozen : Bool
  sourceRoot : Bool
  descriptorRoot : Bool
  epoch : Nat
  loaded : Nat
  pending : Bool
  deriving DecidableEq
def Covered (s : View) := s.sourceRoot=true ∨ s.descriptorRoot=true
def ViewSafe (s : View) := Covered s ∧ (s.pending=true → s.complete=true ∧ s.frozen=true ∧ s.sourceRoot=true)
def defer (s : View) := {s with pending:=true}
def register (s : View) := {s with descriptorRoot:=true,pending:=false}
theorem frozenViewCovers (s : View) (h : s.sourceRoot=true) : Covered s := Or.inl h
theorem registrationCovers (s : View) : Covered (register s) := by simp [Covered,register]
theorem deferPreservesCoverage (s : View) (c : s.complete=true) (f : s.frozen=true) (r : s.sourceRoot=true) : ViewSafe (defer s) := by simp [ViewSafe,Covered,defer,c,f,r]
def FreshOrigin (s : View) := s.loaded=s.epoch
def move (s : View) := {s with epoch:=s.epoch+1}
theorem staleOriginRejected (s : View) (h : FreshOrigin s) : ¬ FreshOrigin (move s) := by simp_all [FreshOrigin,move]
structure Child where
  prepared : Bool
  succeeded : Bool
  bound : Bool
  unknown : Bool
  failed : Bool
  stopped : Bool
  member : Bool
  reclaimed : Bool
  root : Bool
  deriving DecidableEq
def ChildSafe (s : Child) := (s.member=true → s.prepared=true ∧ s.succeeded=true ∧ s.bound=true ∧ s.reclaimed=false) ∧
 (s.unknown=true → s.root=true ∧ s.reclaimed=false) ∧
 (s.reclaimed=true → s.failed=true ∨ s.stopped=true)
def commit (s : Child) := {s with member:=true}
theorem readyMemberRequiresBound (s : Child) (h : ChildSafe s) (m : s.member=true) : s.bound=true := (h.1 m).2.2.1
theorem commitPreservesMembership (s : Child) (h : ChildSafe s) (p : s.prepared=true) (g : s.succeeded=true) (b : s.bound=true) (r : s.reclaimed=false) : ChildSafe (commit s) := by simp_all [ChildSafe,commit]
theorem unknownPreventsReclaim (s : Child) (h : ChildSafe s) (u : s.unknown=true) : s.root=true ∧ s.reclaimed=false := h.2.1 u
theorem reclaimGuardIsNecessary (s : Child) (h : ChildSafe s) (r : s.reclaimed=true) : s.failed=true ∨ s.stopped=true := h.2.2 r
structure Pair where
  first : Child
  second : Child
  deriving DecidableEq
def failSecond (s : Pair) := {s with second:={s.second with failed:=true}}
theorem siblingFailureRetainsCustody (s : Pair) : (failSecond s).first=s.first := rfl
structure Ledger where
  total : Nat
  good : Nat
  failed : Nat
  unknown : Nat
  never : Nat
  pending : Nat
  deriving DecidableEq
def Balanced (s : Ledger) := s.total=s.good+s.failed+s.unknown+s.never+s.pending
def settleGood (s : Ledger) := {s with good:=s.good+1,unknown:=s.unknown-1}
theorem unknownSettlementConserves (s : Ledger) (h : Balanced s) (u : 0<s.unknown) : Balanced (settleGood s) := by simp_all [Balanced,settleGood]; omega
theorem settledPartition (s : Ledger) (h : Balanced s) (p : s.pending=0) : s.total=s.good+s.failed+s.unknown+s.never := by simp_all [Balanced]
def reuseBytes (copies word : Nat) := copies*word-word
theorem eightCarrierSlotSaving : reuseBytes 8 8=56 := by decide
theorem noSingleCarrierSaving (word : Nat) : reuseBytes 1 word=0 := by simp [reuseBytes]
theorem positiveSupportThreshold (copies word extra : Nat) (h : word+extra<copies*word) : extra<reuseBytes copies word := by simp [reuseBytes]; omega
def requestedWords (processors : Nat) := processors*2*131072
theorem oneRequestedCapacityWords : requestedWords 1=262144 := by decide
theorem twoRequestedCapacityBytesAt8 : requestedWords 2*8=4194304 := by decide
end GambitSMP.ResizeBootstrapAdmission

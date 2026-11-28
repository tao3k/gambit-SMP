/- Conditional abstract journal/router laws, not a complete QNT or Gambit/C simulation. -/
import Std
namespace GambitSMP.ActivationVmRouting
structure Handle where
  session : Nat
  vmSlot : Nat
  vmGeneration : Nat
  activationSlot : Nat
  lease : Nat
  deriving DecidableEq
structure Origin where
  serial : Nat
  bound : Option Handle
  observed : Bool
  deriving DecidableEq
-- Binding writes the canonical locator, independently of the ordinary C return.
def bind (o : Origin) (h : Handle) : Origin := {o with bound:=some h,observed:=false}
def loseReturn (o : Origin) : Origin := {o with observed:=false}
def recover (o : Origin) : Option Handle := o.bound
def retry (o : Origin) (h : Handle) : Origin := match o.bound with | some _ => o | none => bind o h
theorem lostReturnKeepsLocator (o : Origin) : recover (loseReturn o)=recover o := rfl
theorem bindRecover (o : Origin) (h : Handle) : recover (bind o h)=some h := rfl
theorem retryBoundNeverCreates (o : Origin) (h old : Handle) (b : o.bound=some old) : retry o h=o := by simp [retry,b]
theorem sameOriginSameCanonicalHandle (o : Origin) (a b : Handle) (x : recover o=some a) (y : recover o=some b) : a=b := by
  have z : some a=some b := x.symm.trans y
  exact Option.some.inj z
theorem identityExcludesObservation (o : Origin) : (loseReturn o).serial=o.serial := rfl
structure Router where
  epoch : Nat
  vmGeneration : Nat
  phase : Nat
  data : Bool
  readers : Nat
  adminDebt : Bool
  active : Nat
  deriving DecidableEq
def KeyMatches (r : Router) (h : Handle) := h.session=r.epoch ∧ h.vmGeneration=r.vmGeneration
def UserAdmit (r : Router) := r.phase=2 ∧ r.data=true
def StatusAdmit (r : Router) := (r.phase=2 ∨ r.phase=3) ∧ r.data=true
def close (r : Router) : Router := {r with phase:=3}
def gstateCleanup (r : Router) : Router := {r with data:=false}
def start (r : Router) : Router := {r with epoch:=r.epoch+1,vmGeneration:=r.vmGeneration+1,phase:=1,data:=false}
theorem closeBlocksUser (r : Router) : ¬ UserAdmit (close r) := by simp [UserAdmit,close]
theorem closeKeepsStatus (r : Router) (h : r.data=true) : StatusAdmit (close r) := by simp [StatusAdmit,close,h]
theorem cleanupKeepsResidentEpoch (r : Router) : (gstateCleanup r).epoch=r.epoch := rfl
theorem newSetupHasFreshEpoch (r : Router) : (start r).epoch>r.epoch := by simp [start]
theorem oldSessionRejects (r : Router) (h : Handle) (same : h.session=r.epoch) : ¬ KeyMatches (start r) h := by
  simp only [KeyMatches,start]
  omega
def CanStart (r : Router) (limit : Nat) := r.phase=0 ∧ r.data=false ∧ r.readers=0 ∧ r.epoch<limit
theorem liveSetupRejected (r : Router) (limit : Nat) (live : r.phase≠0) : ¬ CanStart r limit := by simp [CanStart,live]
theorem checkedStartBound (r : Router) (limit : Nat) (h : CanStart r limit) : (start r).epoch≤limit := by simp only [CanStart] at h; simp only [start]; omega
def CanDetach (r : Router) := r.phase=3 ∧ r.active=0 ∧ r.adminDebt=false
def CanFree (r : Router) := r.phase=4 ∧ r.readers=0 ∧ r.active=0 ∧ r.adminDebt=false
theorem readerPreventsFree (r : Router) (h : r.readers>0) : ¬ CanFree r := by simp only [CanFree]; omega
theorem activationPreventsDetach (r : Router) (h : r.active>0) : ¬ CanDetach r := by simp only [CanDetach]; omega
theorem unknownAdminPreventsDetach (r : Router) (h : r.adminDebt=true) : ¬ CanDetach r := by simp [CanDetach,h]
-- A cleanup lane does not require the ordinary user gate to be open.
def AdminAdmit (r : Router) := r.phase=3 ∧ r.data=true ∧ r.adminDebt=true
theorem closedDomainMayRunAdmin (r : Router) (d : r.data=true) (a : r.adminDebt=true) : AdminAdmit (close r) := by simp [AdminAdmit,close,d,a]
structure BindingState where
  bound : Bool
  slot : Nat
  sourceHeld : Bool
  descriptor : Bool
  needed : Bool
  children : Nat
  resultAck : Bool
  deriving DecidableEq
def Covered (b : BindingState) := b.needed=true → b.sourceHeld=true ∨ b.descriptor=true
def BindingSafe (b : BindingState) := b.bound=true → Covered b
def PreserveOnUnknown (b : BindingState) := b
theorem unknownKeepsBindingCoverage (b : BindingState) (h : BindingSafe b) : BindingSafe (PreserveOnUnknown b) := h
def SlotReusable (b : BindingState) := b.children=0 ∧ b.resultAck=true ∧ b.needed=false
theorem childKeepsParentJournal (b : BindingState) (h : b.children>0) : ¬ SlotReusable b := by simp only [SlotReusable]; omega
theorem unacceptedResultKeepsSlot (b : BindingState) (h : b.resultAck=false) : ¬ SlotReusable b := by simp [SlotReusable,h]
def fixedControl (r origins cells routerBytes originBytes cellBytes adminBytes : Nat) :=
  r*routerBytes + origins*originBytes + cells*cellBytes + r*adminBytes
theorem budgetIndependentOfHistoricalCalls (r origins cells routerBytes originBytes cellBytes adminBytes historicalCalls : Nat) :
 fixedControl r origins cells routerBytes originBytes cellBytes adminBytes + 0*historicalCalls = fixedControl r origins cells routerBytes originBytes cellBytes adminBytes := by simp
end GambitSMP.ActivationVmRouting

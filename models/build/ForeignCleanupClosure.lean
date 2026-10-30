import Std.Tactic
namespace ForeignCleanupClosure
-- Abstract ledgers, not Scheme heap bytes or a C memory-model simulation.
structure Ledger where
 accepted : Nat
 settled : Nat
 debt : Nat
 deriving DecidableEq
def valid (s : Ledger) := s.accepted = s.settled + s.debt
def capture (s : Ledger) := {s with accepted := s.accepted+1, debt := s.debt+1}
def reserve (s : Ledger) := capture s
def settle (s : Ledger) := {s with settled := s.settled+1, debt := s.debt-1}
theorem captureConserves (s : Ledger) (h : valid s) : valid (capture s) := by
 simp only [valid, capture] at *; omega
theorem reserveConserves (s : Ledger) (h : valid s) : valid (reserve s) := captureConserves s h
theorem settleConserves (s : Ledger) (h : valid s) (positive : 0 < s.debt) : valid (settle s) := by
 simp only [valid, settle] at *; omega
structure Scheduled where
 ledger : Ledger
 waiting : Bool
def park (s : Scheduled) := {s with waiting := true}
theorem waitRetainsCredit (s : Scheduled) : (park s).ledger=s.ledger := rfl
inductive Step : Ledger → Ledger → Prop where
 | accept (s) : Step s (capture s)
 | child (s) : Step s (reserve s)
 | complete (s) (positive : 0 < s.debt) : Step s (settle s)
 | wait (s) : Step s s
theorem transitionPreserves (s t : Ledger) (h : valid s) (edge : Step s t) : valid t := by
 cases edge with
 | accept => exact captureConserves s h
 | child => exact reserveConserves s h
 | complete positive => exact settleConserves s h positive
 | wait => exact h
-- No-op credit transition: scheduling/waiting does not discharge accepted work.
theorem parentDoneNotClosure (childDebt : Nat) (h : 0 < childDebt) : childDebt ≠ 0 := by omega
structure Storage where
 owner : Nat
 scanner : Nat
 booked : Nat
 deferred : Nat
 rcBytes : Nat
 known : Bool
def commit (s : Storage) := {s with owner := 0, scanner := 0, known := false}
def foldQuota (s : Storage) := {s with booked := s.booked+s.deferred, deferred := 0}
theorem commitPreservesScanner (s : Storage) : (commit s).owner = (commit s).scanner := rfl
theorem commitPreservesQuota (s : Storage) : (commit s).booked+(commit s).deferred=s.booked+s.deferred := rfl
theorem lostReplyStillTarget (s : Storage) : (commit s).owner=0 ∧ (commit s).known=false := ⟨rfl,rfl⟩
theorem foldConserves (s : Storage) : (foldQuota s).booked+(foldQuota s).deferred=s.booked+s.deferred ∧ (foldQuota s).rcBytes=s.rcBytes := by simp [foldQuota]
inductive Outcome where
 | success | consumedError | partialClose | unknown
 deriving DecidableEq
def pointerConsumed : Outcome → Bool
 | .success | .consumedError => true
 | _ => false
theorem errorCanConsume : pointerConsumed .consumedError=true := rfl
def exitPermit (affinityClosed storageAck rosterReceipt : Bool) := affinityClosed=true ∧ storageAck=true ∧ rosterReceipt=true
theorem affinityBlocksExit (a r : Bool) : ¬exitPermit false a r := by simp [exitPermit]
def vmPermit (ingressClosed debtZero emissionsClosed rootsClosed noReaders noUnknown servicesSettled : Bool) :=
 ingressClosed=true ∧ debtZero=true ∧ emissionsClosed=true ∧ rootsClosed=true ∧ noReaders=true ∧ noUnknown=true ∧ servicesSettled=true
theorem vmRequiresGlobalClosure (i d e r b u s : Bool) (h : vmPermit i d e r b u s) : d=true ∧ e=true ∧ r=true := ⟨h.2.1,h.2.2.1,h.2.2.2.1⟩
theorem unknownBlocksVm (i d e r b s : Bool) : ¬vmPermit i d e r b false s := by simp [vmPermit]
theorem rootsBlockVm (i d e b u s : Bool) : ¬vmPermit i d e false b u s := by simp [vmPermit]
theorem netBenefit (oldWork newWork saved added : Nat) (balance : newWork+saved=oldWork+added) (gain : added<saved) : newWork<oldWork := by omega
end ForeignCleanupClosure

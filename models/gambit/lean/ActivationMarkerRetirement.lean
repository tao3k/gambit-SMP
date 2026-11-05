namespace GambitSMP.ActivationMarkerRetirement
structure Activation where
  state : Nat
  currentReturn : Nat
  originalOwner : Bool
def CanCommit (a : Activation) := a.state=0 ∧ a.currentReturn=0 ∧ a.originalOwner=true
def CanClose (a : Activation) := a.state=0 ∧ a.currentReturn=0 ∧ a.originalOwner=true
def commitReturn (a : Activation) := {a with state:=1,currentReturn:=1}
def closeAdmissions (a : Activation) := {a with state:=2}
theorem committedReturnRejectsClose (a : Activation) : ¬ CanClose (commitReturn a) := by simp [CanClose,commitReturn]
theorem closedAdmissionRejectsCommit (a : Activation) : ¬ CanCommit (closeAdmissions a) := by simp [CanCommit,closeAdmissions]
theorem wrongOwnerRejectsCommit (a : Activation) (h : a.originalOwner=false) : ¬ CanCommit a := by simp [CanCommit,h]
structure PinLedger where
  held : Nat
  released : Nat
def total (s : PinLedger) := s.held + s.released
def release (s : PinLedger) := {s with held:=s.held-1,released:=s.released+1}
def CanRelease (s : PinLedger) := s.held=1 ∧ s.released=0
theorem releaseConserves (s : PinLedger) (h : 0<s.held) : total (release s)=total s := by simp [total,release]; omega
theorem releasedOnceRejectsRetry (s : PinLedger) (h : CanRelease s) : ¬ CanRelease (release s) := by simp_all [CanRelease,release]
inductive Step : PinLedger → PinLedger → Prop
  | release (s : PinLedger) (h : CanRelease s) : Step s (ActivationMarkerRetirement.release s)
  | query (s : PinLedger) : Step s s
theorem stepConserves {a b : PinLedger} (h : Step a b) : total b=total a := by
  cases h with
  | release h => apply releaseConserves; simp only [CanRelease] at h; omega
  | query => rfl
inductive Trace : PinLedger → PinLedger → Prop
  | nil (s : PinLedger) : Trace s s
  | cons {a b c : PinLedger} : Step a b → Trace b c → Trace a c
theorem traceConserves {a b : PinLedger} (h : Trace a b) : total b=total a := by
  induction h with
  | nil => rfl
  | cons h _ ih => exact ih.trans (stepConserves h)
structure WriteGate where
  rootHeld : Bool
  originalOwnerOrDelegate : Bool
  stopped : Bool
  permit : Bool
  publishedView : Nat
  borrowers : Nat
def CanWrite (g : WriteGate) := g.rootHeld=true ∧ g.originalOwnerOrDelegate=true ∧
  g.stopped=true ∧ g.permit=true ∧ g.publishedView=0 ∧ g.borrowers=0
theorem unclaimedViewRejectsWrite (g : WriteGate) (h : 0<g.publishedView) : ¬ CanWrite g := by simp [CanWrite]; omega
theorem unknownWriterRejectsWrite (g : WriteGate) (h : g.stopped=false) : ¬ CanWrite g := by simp [CanWrite,h]
theorem borrowerRejectsWrite (g : WriteGate) (h : 0<g.borrowers) : ¬ CanWrite g := by simp [CanWrite]; omega
theorem unrootedWriteRejected (g : WriteGate) (h : g.rootHeld=false) : ¬ CanWrite g := by simp [CanWrite,h]
structure LegacyObservation where
  counter : Nat
  outcomeUnknown : Bool
  deriving DecidableEq
structure LegacyHistory where
  observation : LegacyObservation
  applied : Nat
  otherPins : Nat
def before : LegacyHistory := { observation:={counter:=1,outcomeUnknown:=true},applied:=0,otherPins:=0 }
def after : LegacyHistory := { observation:={counter:=1,outcomeUnknown:=true},applied:=1,otherPins:=1 }
theorem legacyObservationsEqual : before.observation=after.observation := rfl
theorem legacyOutcomesDiffer : before.applied≠after.applied := by decide
theorem noTotalOutcomeDecoder (decode : LegacyObservation→Nat) :
  ¬ (decode before.observation=before.applied ∧ decode after.observation=after.applied) := by
  simp [before,after]; omega
def clearField (_old : Bool) : Bool := false
theorem clearIsIdempotent (old : Bool) : clearField (clearField old)=clearField old := rfl
structure Retirement where
  cleanupKnown : Bool
  rootHeld : Bool
  recordReaders : Nat
  view : Nat
def CanRetire (r : Retirement) := r.cleanupKnown=true ∧ r.rootHeld=false ∧ r.recordReaders=0 ∧ r.view=0
theorem unknownDebitRejectsRetirement (r : Retirement) (h : r.cleanupKnown=false) : ¬ CanRetire r := by simp [CanRetire,h]
theorem readerRejectsRetirement (r : Retirement) (h : 0<r.recordReaders) : ¬ CanRetire r := by simp [CanRetire]; omega
def setReceipt (receipts : Nat→Nat) (id status : Nat) := fun k => if k=id then status else receipts k
theorem freshTransportUnaffected (receipts : Nat→Nat) (old fresh status : Nat) (h : fresh≠old) : setReceipt receipts old status fresh=receipts fresh := by simp [setReceipt,h]
end GambitSMP.ActivationMarkerRetirement

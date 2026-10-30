/- Source/ABI, queue exclusion and participant root freezing are separate premises. -/
namespace GambitSMP.FutureEpochReentryGate
structure Gate where
  entryOpen : Bool
  producerClosed : Bool
  reservations : Nat
  activeWriters : Nat
  publications : Nat
def Closed (g : Gate) := g.entryOpen=false ∧ g.producerClosed=true ∧ g.reservations=0 ∧ g.activeWriters=0 ∧ g.publications=0
def closeEntry (g : Gate) := {g with entryOpen:=false}
theorem closeDoesNotRevokeReservation (g : Gate) : (closeEntry g).reservations=g.reservations := rfl
theorem closeDoesNotDrainWriter (g : Gate) : (closeEntry g).activeWriters=g.activeWriters := rfl
theorem claimedBlocksSeal (g : Gate) (h : 0<g.reservations) : ¬ Closed g := by simp [Closed]; omega
theorem writerBlocksSeal (g : Gate) (h : 0<g.activeWriters) : ¬ Closed g := by simp [Closed]; omega
theorem publicationBlocksSeal (g : Gate) (h : 0<g.publications) : ¬ Closed g := by simp [Closed]; omega
structure TaskInput where
  started : Bool
  issuedInvocation : Bool
  asyncContract : Bool
  vmCustody : Bool
  roots : Bool
  resources : Bool
  code : Bool
def CanDefer (g : Gate) (t : TaskInput) := Closed g ∧ t.started=false ∧ t.issuedInvocation=false ∧
  t.asyncContract=true ∧ t.vmCustody=true ∧ t.roots=true ∧ t.resources=true ∧ t.code=true
theorem startedCannotDefer (g : Gate) (t : TaskInput) (h : t.started=true) : ¬ CanDefer g t := by simp [CanDefer,h]
theorem issuedCannotDefer (g : Gate) (t : TaskInput) (h : t.issuedInvocation=true) : ¬ CanDefer g t := by simp [CanDefer,h]
theorem synchronousCannotDefer (g : Gate) (t : TaskInput) (h : t.asyncContract=false) : ¬ CanDefer g t := by simp [CanDefer,h]
theorem deferredKeepsRoots (g : Gate) (t : TaskInput) (h : CanDefer g t) : t.roots=true := h.2.2.2.2.2.1
theorem deferredKeepsResources (g : Gate) (t : TaskInput) (h : CanDefer g t) : t.resources=true := h.2.2.2.2.2.2.1
structure Resume where
  epoch : Nat
  contextEpoch : Nat
  rootVersion : Nat
  reloadedVersion : Nat
  entryOpen : Bool
  roundComplete : Bool
  ownerBound : Bool
def Authorized (r : Resume) (expected : Nat) := r.epoch=expected ∧ r.contextEpoch=r.epoch ∧ r.reloadedVersion=r.rootVersion ∧
  r.entryOpen=true ∧ r.roundComplete=true ∧ r.ownerBound=true
theorem staleEpochRejected (r : Resume) (e : Nat) (h : r.epoch≠e) : ¬ Authorized r e := by simp [Authorized,h]
theorem staleRootRejected (r : Resume) (e : Nat) (h : r.reloadedVersion≠r.rootVersion) : ¬ Authorized r e := by simp [Authorized,h]
theorem unpreparedContextRejected (r : Resume) (e : Nat) (h : r.contextEpoch≠r.epoch) : ¬ Authorized r e := by simp [Authorized,h]
theorem missingBindingRejected (r : Resume) (e : Nat) (h : r.ownerBound=false) : ¬ Authorized r e := by simp [Authorized,h]
theorem notificationAloneInsufficient (r : Resume) (e : Nat) (h : r.roundComplete=false) : ¬ Authorized r e := by simp [Authorized,h]
structure Task where
  future : Bool
  active : Bool
  parked : Bool
  roots : Bool
  resources : Bool
  starts : Nat
  epoch : Nat
  deriving DecidableEq
def Safe (s : Task) := s.starts≤1 ∧ ((s.future=true ∨ s.active=true ∨ s.parked=true) → s.roots=true ∧ s.resources=true)
def claim (s : Task) (e : Nat) := {s with future:=false,active:=true,starts:=s.starts+1,epoch:=e}
def park (s : Task) := {s with active:=false,parked:=true}
def resume (s : Task) (e : Nat) := {s with active:=true,parked:=false,epoch:=e}
def finish (s : Task) := {s with active:=false,parked:=false}
theorem claimPreserves (s : Task) (h : Safe s) (f : s.future=true) (n : s.starts=0) (p : s.parked=false) (e : Nat) : Safe (claim s e) := by
  simp_all [Safe,claim]
theorem parkPreserves (s : Task) (h : Safe s) (a : s.active=true) : Safe (park s) := by
  simp_all [Safe,park]
theorem resumePreserves (s : Task) (h : Safe s) (p : s.parked=true) (e : Nat) : Safe (resume s e) := by
  simp_all [Safe,resume]
theorem finishPreserves (s : Task) (h : Safe s) : Safe (finish s) := by
  simp_all [Safe,finish]
theorem resumeDoesNotReinvoke (s : Task) (e : Nat) : (resume s e).starts=s.starts := rfl
theorem claimUsesFreshEpoch (s : Task) (e : Nat) : (claim s e).epoch=e := rfl
inductive Step : Task → Task → Prop
  | claim (s : Task) (r : Resume) (a : Authorized r r.epoch) (f : s.future=true) (n : s.starts=0) (p : s.parked=false) : Step s (FutureEpochReentryGate.claim s r.epoch)
  | park (s : Task) (a : s.active=true) : Step s (FutureEpochReentryGate.park s)
  | resume (s : Task) (r : Resume) (a : Authorized r r.epoch) (p : s.parked=true) : Step s (FutureEpochReentryGate.resume s r.epoch)
  | finish (s : Task) : Step s (FutureEpochReentryGate.finish s)
  | query (s : Task) : Step s s
theorem stepPreserves {a b : Task} (h : Step a b) (s : Safe a) : Safe b := by
  cases h with
  | claim r _ f n p => exact claimPreserves _ s f n p r.epoch
  | park a => exact parkPreserves _ s a
  | resume r _ p => exact resumePreserves _ s p r.epoch
  | finish => exact finishPreserves _ s
  | query => exact s
inductive Trace : Task → Task → Prop
  | nil (s : Task) : Trace s s
  | cons {a b c : Task} : Step a b → Trace b c → Trace a c
theorem tracePreserves {a b : Task} (h : Trace a b) (s : Safe a) : Safe b := by
  induction h with
  | nil => exact s
  | cons h _ ih => exact ih (stepPreserves h s)
theorem completedCannotClaimAgain (s : Task) (h : s.starts=1) : ¬ s.starts=0 := by omega
end GambitSMP.FutureEpochReentryGate

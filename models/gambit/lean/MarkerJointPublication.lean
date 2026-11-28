namespace GambitSMP.MarkerJointPublication
-- One transaction projection of the two-operation QNT model, not a C execution.
structure Pub where
  phase : Nat
  stage : Nat
  permit : Bool
  initialized : Bool
  linked : Bool
  root : Bool
  committed : Bool
  input : Bool
  alive : Bool
  stopped : Bool

def Inv (s : Pub) :=
  (s.linked=true → s.initialized=true) ∧
  (s.root=true → s.linked=true) ∧
  (s.committed=true → s.root=true) ∧
  (s.phase=2 → s.permit=false) ∧
  (s.permit=false → s.linked=s.root ∧ s.root=s.committed) ∧
  (s.permit=true → s.input=true)
def Writer (s : Pub) := s.alive=true ∨ s.stopped=true
def GrantGuard (s : Pub) := s.phase=0 ∧ s.stage=2 ∧ s.permit=false ∧ s.input=true ∧
  s.linked=false ∧ s.root=false ∧ s.committed=false
def grant (s : Pub) := {s with stage:=3,permit:=true}
def fill (s : Pub) := {s with stage:=4,initialized:=true}
def link (s : Pub) := {s with stage:=5,linked:=true}
def install (s : Pub) := {s with stage:=6,root:=true}
def commit (s : Pub) := {s with stage:=7,committed:=true}
def release (s : Pub) := {s with stage:=8,permit:=false,input:=false}
def close (s : Pub) := {s with phase:=1}
def freeze (s : Pub) := {s with phase:=2}

theorem grantPreserves (s : Pub) (h : Inv s) (g : GrantGuard s) : Inv (grant s) := by
  simp_all [Inv,GrantGuard,grant]
theorem fillPreserves (s : Pub) (h : Inv s) (p : s.permit=true) : Inv (fill s) := by
  simp_all [Inv,fill]
theorem linkPreserves (s : Pub) (h : Inv s) (p : s.permit=true) (i : s.initialized=true) : Inv (link s) := by
  simp_all [Inv,link]
theorem installPreserves (s : Pub) (h : Inv s) (p : s.permit=true) (l : s.linked=true) : Inv (install s) := by
  simp_all [Inv,install]
theorem commitPreserves (s : Pub) (h : Inv s) (p : s.permit=true) (r : s.root=true) : Inv (commit s) := by
  simp_all [Inv,commit]
theorem releasePreserves (s : Pub) (h : Inv s) (c : s.committed=true) : Inv (release s) := by
  simp_all [Inv,release]
theorem closePreserves (s : Pub) (h : Inv s) : Inv (close s) := by simp_all [Inv,close]
theorem freezePreserves (s : Pub) (h : Inv s) (p : s.permit=false) : Inv (freeze s) := by simp_all [Inv,freeze]

inductive Step : Pub → Pub → Prop
  | grant (s : Pub) (g : GrantGuard s) : Step s (MarkerJointPublication.grant s)
  | fill (s : Pub) (p : s.permit=true) (w : Writer s) : Step s (MarkerJointPublication.fill s)
  | link (s : Pub) (p : s.permit=true) (i : s.initialized=true) (w : Writer s) : Step s (MarkerJointPublication.link s)
  | install (s : Pub) (p : s.permit=true) (l : s.linked=true) (w : Writer s) : Step s (MarkerJointPublication.install s)
  | commit (s : Pub) (p : s.permit=true) (r : s.root=true) (w : Writer s) : Step s (MarkerJointPublication.commit s)
  | release (s : Pub) (c : s.committed=true) (w : Writer s) : Step s (MarkerJointPublication.release s)
  | close (s : Pub) (p : s.phase=0) : Step s (MarkerJointPublication.close s)
  | freeze (s : Pub) (p : s.permit=false) (c : s.phase=1) : Step s (MarkerJointPublication.freeze s)
  | query (s : Pub) : Step s s

theorem stepPreserves {a b : Pub} (h : Step a b) (i : Inv a) : Inv b := by
  cases h with
  | grant g => exact grantPreserves _ i g
  | fill p _ => exact fillPreserves _ i p
  | link p x _ => exact linkPreserves _ i p x
  | install p l _ => exact installPreserves _ i p l
  | commit p r _ => exact commitPreserves _ i p r
  | release c _ => exact releasePreserves _ i c
  | close _ => exact closePreserves _ i
  | freeze p _ => exact freezePreserves _ i p
  | query => exact i
inductive Trace : Pub → Pub → Prop
  | nil (s : Pub) : Trace s s
  | cons {a b c : Pub} : Step a b → Trace b c → Trace a c

theorem tracePreserves {a b : Pub} (h : Trace a b) (i : Inv a) : Inv b := by
  induction h with
  | nil => exact i
  | cons h _ ih => exact ih (stepPreserves h i)
theorem frozenHasPairedMembership (s : Pub) (h : Inv s) (f : s.phase=2) :
    s.linked=s.root ∧ s.root=s.committed := by
  rcases h with ⟨_,_,_,hf,hp,_⟩
  exact hp (hf f)
theorem partialLinkBlocksFreeze (s : Pub) (h : Inv s) (l : s.linked=true) (r : s.root=false) :
    s.phase≠2 := by
  intro f
  have pair := frozenHasPairedMembership s h f
  simp_all

theorem unknownWriterCannotWrite (s : Pub) (a : s.alive=false) (t : s.stopped=false) : ¬ Writer s := by
  simp [Writer,a,t]
theorem closingRejectsGrant (s : Pub) (h : s.phase=1) : ¬ GrantGuard s := by simp [GrantGuard,h]

structure Credit where
  reserved : Nat
  live : Nat
  returned : Nat
  quarantine : Nat
def total (s : Credit) := s.reserved+s.live+s.returned+s.quarantine
def commitCredit (s : Credit) := {s with reserved:=s.reserved-1,live:=s.live+1}
def quarantineCredit (s : Credit) := {s with reserved:=s.reserved-1,quarantine:=s.quarantine+1}
theorem commitCreditConserves (s : Credit) (h : 0<s.reserved) : total (commitCredit s)=total s := by
  simp [total,commitCredit]; omega
theorem unknownCreditConserves (s : Credit) (h : 0<s.reserved) : total (quarantineCredit s)=total s := by
  simp [total,quarantineCredit]; omega
structure Debt where
  outcomeUnknown : Bool
  rootHeld : Bool
  charged : Bool
def DebtSafe (s : Debt) := s.outcomeUnknown=true → s.rootHeld=true ∧ s.charged=true
def queryDebt (s : Debt) := s
theorem queryNeverRefunds (s : Debt) : queryDebt s=s := rfl
theorem unknownDebtKeepsRoot (s : Debt) (h : DebtSafe s) (u : s.outcomeUnknown=true) : s.rootHeld=true := (h u).1
theorem unknownDebtKeepsCharge (s : Debt) (h : DebtSafe s) (u : s.outcomeUnknown=true) : s.charged=true := (h u).2
structure InputView where
  published : Bool
  held : Bool
  retired : Bool
def InputSafe (v : InputView) := v.published=true → v.held=true ∧ v.retired=false
def CanWithdrawInput (v : InputView) := v.published=false
theorem publishedInputRejectsWithdrawal (v : InputView) (h : v.published=true) : ¬ CanWithdrawInput v := by simp [CanWithdrawInput,h]
theorem frozenInputRemainsRooted (v : InputView) (h : InputSafe v) (p : v.published=true) : v.held=true := (h p).1
end GambitSMP.MarkerJointPublication


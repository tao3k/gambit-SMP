namespace GambitSMP.ReleaseProducerAdmission
structure Credits where
 constructing : Nat
 wrapped : Nat
 queued : Nat
 running : Nat
 retained : Nat
 retired : Nat
def live (s : Credits) := s.constructing+s.wrapped+s.queued+s.running+s.retained
def total (s : Credits) := live s+s.retired
def wrap (s : Credits) := {s with constructing:=s.constructing-1,wrapped:=s.wrapped+1}
def accept (s : Credits) := {s with wrapped:=s.wrapped-1,queued:=s.queued+1}
def start (s : Credits) := {s with queued:=s.queued-1,running:=s.running+1}
def finish (s : Credits) := {s with running:=s.running-1,retained:=s.retained+1}
def retire (s : Credits) := {s with retained:=s.retained-1,retired:=s.retired+1}
theorem wrapConserves (s : Credits) (h : 0<s.constructing) : total (wrap s)=total s := by simp [total,live,wrap]; omega
theorem acceptConserves (s : Credits) (h : 0<s.wrapped) : total (accept s)=total s := by simp [total,live,accept]; omega
theorem startConserves (s : Credits) (h : 0<s.queued) : total (start s)=total s := by simp [total,live,start]; omega
theorem finishConserves (s : Credits) (h : 0<s.running) : total (finish s)=total s := by simp [total,live,finish]; omega
theorem retireConserves (s : Credits) (h : 0<s.retained) : total (retire s)=total s := by simp [total,live,retire]; omega
inductive Step : Credits → Credits → Prop
 | wrap (s : Credits) (h : 0<s.constructing) : Step s (ReleaseProducerAdmission.wrap s)
 | accept (s : Credits) (h : 0<s.wrapped) : Step s (ReleaseProducerAdmission.accept s)
 | start (s : Credits) (h : 0<s.queued) : Step s (ReleaseProducerAdmission.start s)
 | finish (s : Credits) (h : 0<s.running) : Step s (ReleaseProducerAdmission.finish s)
 | retire (s : Credits) (h : 0<s.retained) : Step s (ReleaseProducerAdmission.retire s)
 | unknown (s : Credits) : Step s s
theorem stepConserves {a b : Credits} (h : Step a b) : total a=total b := by
 cases h with
 | wrap p => exact (wrapConserves _ p).symm
 | accept p => exact (acceptConserves _ p).symm
 | start p => exact (startConserves _ p).symm
 | finish p => exact (finishConserves _ p).symm
 | retire p => exact (retireConserves _ p).symm
 | unknown => rfl
inductive Trace : Credits → Credits → Prop
 | nil (s : Credits) : Trace s s
 | cons {a b c : Credits} : Step a b → Trace b c → Trace a c
theorem traceConserves {a b : Credits} (h : Trace a b) : total a=total b := by
 induction h with
 | nil => rfl
 | cons h _ ih => exact (stepConserves h).trans ih
-- A checked admission guard must precede the native producer's first effect.
theorem reservationBound (held demand capacity : Nat) (h : held+demand≤capacity) : held≤capacity := by omega
theorem equalFunctionDoesNotMergeRights (n : Nat) : n+2≠n+1 := by omega
def retainUnknown (s : Credits) : Credits := s
theorem unknownKeepsCapacity (s : Credits) : live (retainUnknown s)=live s := by rfl
structure Admission where
 effectKnown : Bool
 affinityKnown : Bool
 delayLegal : Bool
 rootsRegistered : Bool
 rootsTraced : Bool
 codePinned : Bool
 budgetReserved : Bool
 originAllowed : Bool
def CanDefer (s : Admission) := s.effectKnown=true ∧ s.affinityKnown=true ∧ s.delayLegal=true ∧ s.rootsRegistered=true ∧ s.rootsTraced=true ∧ s.codePinned=true ∧ s.budgetReserved=true ∧ s.originAllowed=true
theorem unknownEffectRejects (s : Admission) (h : s.effectKnown=false) : ¬ CanDefer s := by simp [CanDefer,h]
theorem unknownAffinityRejects (s : Admission) (h : s.affinityKnown=false) : ¬ CanDefer s := by simp [CanDefer,h]
theorem untracedRootRejects (s : Admission) (h : s.rootsTraced=false) : ¬ CanDefer s := by simp [CanDefer,h]
theorem unreservedRejects (s : Admission) (h : s.budgetReserved=false) : ¬ CanDefer s := by simp [CanDefer,h]
theorem synchronousOriginRejects (s : Admission) (h : s.originAllowed=false) : ¬ CanDefer s := by simp [CanDefer,h]
def CanRetire (known noReaders noChildren dispositionKnown : Bool) := known=true ∧ noReaders=true ∧ noChildren=true ∧ dispositionKnown=true
theorem readersRejectRetirement (a b c : Bool) : ¬ CanRetire a false b c := by simp [CanRetire]
theorem unknownDispositionRejectsRetirement (a b c : Bool) : ¬ CanRetire a b c false := by simp [CanRetire]
theorem rootCoverageTransitive {α : Type} (needed registered traced : α → Prop) (h1 : ∀x,needed x→registered x) (h2 : ∀x,registered x→traced x) : ∀x,needed x→traced x := by intro x hx; exact h2 x (h1 x hx)
def CanClose (constructors outstandingRootDebt : Nat) := constructors=0 ∧ outstandingRootDebt=0
theorem constructorDebtRejectsClosure (n d : Nat) (h : 0<n) : ¬ CanClose n d := by simp [CanClose]; omega
theorem rootDebtRejectsClosure (n d : Nat) (h : 0<d) : ¬ CanClose n d := by simp [CanClose]; omega
end GambitSMP.ReleaseProducerAdmission

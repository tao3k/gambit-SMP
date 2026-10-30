/- Research-only conditional contracts, not source or C weak-memory refinement. -/
namespace GambitSMP.DataWriteClosureCustody
structure Cohort where
  enrollmentClosed : Bool
  completeManifest : Bool
  originalClosed : Bool
  helperClosed : Bool
  helperEnrolled : Bool
  pending : Nat
  rawEscape : Bool
  deriving DecidableEq
def Closed (c : Cohort) := c.enrollmentClosed=true ∧ c.completeManifest=true ∧
  c.originalClosed=true ∧ (c.helperEnrolled=true → c.helperClosed=true) ∧
  c.pending=0 ∧ c.rawEscape=false
theorem enrollmentMustClose (c : Cohort) (h : Closed c) : c.enrollmentClosed=true := h.1
theorem pendingRejectsCertificate (c : Cohort) (p : 0<c.pending) : ¬ Closed c := by
  simp [Closed]; omega
theorem helperMustClose (c : Cohort) (h : Closed c) (e : c.helperEnrolled=true) : c.helperClosed=true := h.2.2.2.1 e
theorem rawEscapeRejectsCertificate (c : Cohort) (h : c.rawEscape=true) : ¬ Closed c := by simp [Closed,h]
theorem incompleteManifestRejectsCertificate (c : Cohort) (h : c.completeManifest=false) : ¬ Closed c := by simp [Closed,h]
def CloseEnrollment (c : Cohort) := {c with enrollmentClosed:=true}
theorem enrollmentCloseDoesNotDrain (c : Cohort) : (CloseEnrollment c).pending=c.pending := rfl
def Register (c : Cohort) := {c with helperEnrolled:=true}
theorem registeredChildIsDebt (c : Cohort) (h : c.helperClosed=false) : ¬ Closed (Register c) := by
  simp [Closed,Register,h]
structure Custody where
  prepared : Bool
  independentBacking : Bool
  accepted : Bool
  sourceDuty : Bool
  envelope : Bool
  psPins : Nat
  originalClosed : Bool
  pendingOriginal : Nat
  joinKnown : Bool
  cleaned : Bool
  deriving DecidableEq
def Covered (s : Custody) := s.sourceDuty=true ∨ s.accepted=true
def Safe (s : Custody) := Covered s ∧ (s.accepted=true → s.prepared=true ∧ s.independentBacking=true) ∧
  (s.cleaned=true → s.accepted=true ∧ s.independentBacking=true ∧ s.psPins=0 ∧ s.originalClosed=true ∧ s.pendingOriginal=0) ∧
  (s.envelope=false → s.joinKnown=true ∧ s.cleaned=true)
def Ready (s : Custody) := s.prepared=true ∧ s.independentBacking=true
def CanCleanup (s : Custody) := s.accepted=true ∧ s.independentBacking=true ∧ s.psPins=0 ∧ s.originalClosed=true ∧ s.pendingOriginal=0
def accept (s : Custody) := {s with accepted:=true}
def dropSource (s : Custody) := {s with sourceDuty:=false}
def cleanup (s : Custody) := {s with cleaned:=true}
def joined (s : Custody) := {s with joinKnown:=true}
def retire (s : Custody) := {s with envelope:=false}
theorem acceptPreserves (s : Custody) (h : Safe s) (r : Ready s) : Safe (accept s) := by
  rcases h with ⟨cov,acc,cl,env⟩
  rcases r with ⟨prep,back⟩
  simp_all [Safe,Covered,accept]
theorem sourceDropPreserves (s : Custody) (h : Safe s) (a : s.accepted=true) : Safe (dropSource s) := by
  simpa [Safe,Covered,dropSource,a] using h
theorem cleanupPreserves (s : Custody) (h : Safe s) (r : CanCleanup s) : Safe (cleanup s) := by
  simp_all [Safe,Covered,CanCleanup,cleanup]
theorem joinPreserves (s : Custody) (h : Safe s) : Safe (joined s) := by
  simp_all [Safe,Covered,joined]
theorem retirePreserves (s : Custody) (h : Safe s) (j : s.joinKnown=true) (c : s.cleaned=true) : Safe (retire s) := by
  simp_all [Safe,Covered,retire]
theorem pointerCopyInsufficient (s : Custody) (a : s.accepted=false) : ¬ CanCleanup s := by simp [CanCleanup,a]
theorem pstateBorrowBlocksCleanup (s : Custody) (p : 0<s.psPins) : ¬ CanCleanup s := by simp [CanCleanup]; omega
theorem pendingOriginalBlocksCleanup (s : Custody) (p : 0<s.pendingOriginal) : ¬ CanCleanup s := by simp [CanCleanup]; omega
theorem failedOrUnknownJoinKeepsEnvelope (s : Custody) (h : Safe s) (j : s.joinKnown=false) : s.envelope=true := by
  cases e : s.envelope
  · have v := h.2.2.2 e
    simp_all
  · rfl
inductive Step : Custody → Custody → Prop
  | accept (s : Custody) (r : Ready s) : Step s (DataWriteClosureCustody.accept s)
  | sourceDrop (s : Custody) (a : s.accepted=true) : Step s (dropSource s)
  | cleanup (s : Custody) (r : CanCleanup s) : Step s (DataWriteClosureCustody.cleanup s)
  | joined (s : Custody) : Step s (DataWriteClosureCustody.joined s)
  | retire (s : Custody) (j : s.joinKnown=true) (c : s.cleaned=true) : Step s (DataWriteClosureCustody.retire s)
  | failedOrUnknown (s : Custody) : Step s s
  | query (s : Custody) : Step s s
theorem stepPreserves {a b : Custody} (h : Step a b) (s : Safe a) : Safe b := by
  cases h with
  | accept r => exact acceptPreserves _ s r
  | sourceDrop r => exact sourceDropPreserves _ s r
  | cleanup r => exact cleanupPreserves _ s r
  | joined => exact joinPreserves _ s
  | retire j c => exact retirePreserves _ s j c
  | failedOrUnknown => exact s
  | query => exact s
theorem joinKnowledgeMonotone {a b : Custody} (h : Step a b) (j : a.joinKnown=true) : b.joinKnown=true := by
  cases h <;> simp_all [accept,dropSource,cleanup,joined,retire]
inductive Trace :
 Custody → Custody → Prop
  | nil (s : Custody) : Trace s s
  | cons {a b c : Custody} : Step a b → Trace b c → Trace a c
theorem tracePreserves {a b : Custody} (h : Trace a b) (s : Safe a) : Safe b := by
  induction h with
  | nil => exact s
  | cons h _ ih => exact ih (stepPreserves h s)
structure Completion where
  dataClosed : Bool
  vmAccepted : Bool
  leaseReleased : Bool
  joinKnown : Bool
def CanFreeze (s : Completion) := s.dataClosed=true ∧ s.vmAccepted=true ∧ s.leaseReleased=true
theorem freezeDoesNotRequireJoin (a : Completion) (h : CanFreeze a) : CanFreeze {a with joinKnown:=false} := h
theorem successfulJoinDoesNotCloseData : ¬ CanFreeze ⟨false,true,false,true⟩ := by simp [CanFreeze]
theorem lostResponseCannotDecodeCustody (decode : Bool→Bool) : ¬ (decode false=true ∧ decode false=false) := by
  intro ⟨a,b⟩
  simp_all
end GambitSMP.DataWriteClosureCustody

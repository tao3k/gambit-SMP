namespace GambitSMP.MarkerInterruptedPublication
structure Intent where
  oldHead : Nat
  node : Nat
structure Link where
  head : Nat
  next : Nat
  ack : Bool
def Linked (i : Intent) (s : Link) := s.head=i.node ∧ s.next=i.oldHead
def Reconcilable (i : Intent) (s : Link) := s.head=i.oldHead ∨ Linked i s
def settle (i : Intent) (s : Link) := if s.head=i.oldHead then {s with head:=i.node,next:=i.oldHead} else s

theorem settleEstablishesLink (i : Intent) (s : Link) (h : Reconcilable i s) : Linked i (settle i s) := by
  by_cases e : s.head=i.oldHead
  · simp [settle,e,Linked]
  · simp only [Reconcilable] at h
    simpa [settle,e] using h.resolve_left e

theorem linkedSettlementIsIdentity (i : Intent) (s : Link) (n : i.node≠i.oldHead) (h : Linked i s) : settle i s=s := by
  simp_all [Linked,settle]
theorem settleIsIdempotent (i : Intent) (s : Link) (n : i.node≠i.oldHead) (h : Reconcilable i s) :
    settle i (settle i s)=settle i s := linkedSettlementIsIdentity i _ n (settleEstablishesLink i s h)
theorem noSelfLinkAfterSettlement (i : Intent) (s : Link) (n : i.node≠i.oldHead) (h : Reconcilable i s) :
    (settle i s).next≠i.node := by
  have v := settleEstablishesLink i s h
  simp only [Linked] at v
  omega

def beforeHead : Link := ⟨0,0,false⟩
def afterHead : Link := ⟨1,0,false⟩
theorem sameAckDifferentHead : beforeHead.ack=afterHead.ack ∧ beforeHead.head≠afterHead.head := by decide
theorem ackAloneCannotDecode (decode : Bool→Nat) :
    ¬ (decode beforeHead.ack=beforeHead.head ∧ decode afterHead.ack=afterHead.head) := by
  simp [beforeHead,afterHead]; omega
structure Writer where
  generation : Nat
  pending : Nat
def revoke (w : Writer) := {w with generation:=w.generation+1}
theorem generationDoesNotDrain (w : Writer) : (revoke w).pending=w.pending := rfl
theorem revokedPendingRemains (w : Writer) (h : 0<w.pending) : 0<(revoke w).pending := h
structure Stop where
  exactIdentity : Bool
  cooperativeClosed : Bool
  nativeTerminated : Bool
  joinSucceeded : Bool
  allWritersCovered : Bool
  pending : Nat
def StopValid (s : Stop) := s.exactIdentity=true ∧ s.allWritersCovered=true ∧ s.pending=0 ∧
  (s.cooperativeClosed=true ∨ (s.nativeTerminated=true ∧ s.joinSucceeded=true))
theorem pendingRejectsStop (s : Stop) (h : 0<s.pending) : ¬ StopValid s := by simp [StopValid]; omega
theorem wrongIdentityRejectsStop (s : Stop) (h : s.exactIdentity=false) : ¬ StopValid s := by simp [StopValid,h]
theorem omittedHelperRejectsStop (s : Stop) (h : s.allWritersCovered=false) : ¬ StopValid s := by simp [StopValid,h]
theorem failedJoinWithoutCooperationRejectsStop (s : Stop) (c : s.cooperativeClosed=false) (j : s.joinSucceeded=false) : ¬ StopValid s := by simp [StopValid,c,j]
def CanTakeOver (s : Stop) (root shape domain locks : Bool) := StopValid s ∧ root=true ∧ shape=true ∧ domain=true ∧ locks=true
theorem stoppedButUnrootedRejectsTakeover (s : Stop) (b c d : Bool) : ¬ CanTakeOver s false b c d := by simp [CanTakeOver]
theorem stoppedButInvalidShapeRejectsTakeover (s : Stop) (a c d : Bool) : ¬ CanTakeOver s a false c d := by simp [CanTakeOver]
theorem unrecoverableLockRejectsTakeover (s : Stop) (a b c : Bool) : ¬ CanTakeOver s a b c false := by simp [CanTakeOver]
structure Decision where
  published : Bool
  rooted : Bool
  prepared : Bool
  events : Nat
def DSafe (d : Decision) := d.published=true → d.rooted=true ∧ d.prepared=true ∧ d.events=1
def commit (d : Decision) := if d.published then d else {d with published:=true,events:=1}
def Ready (d : Decision) := d.rooted=true ∧ d.prepared=true
theorem commitPreserves (d : Decision) (h : DSafe d) (r : Ready d) : DSafe (commit d) := by
  cases p : d.published <;> simp_all [DSafe,Ready,commit]
theorem commitIsIdempotent (d : Decision) : commit (commit d)=commit d := by cases p : d.published <;> simp [commit,p]
def reserved (d : Decision) : Nat := if d.published then 0 else 1
def live (d : Decision) : Nat := if d.published then 1 else 0
theorem derivedCreditConserves (d : Decision) : reserved d+live d=1 := by cases p : d.published <;> simp [reserved,live,p]
inductive Step : Decision → Decision → Prop
  | commit (d : Decision) (r : Ready d) : Step d (MarkerInterruptedPublication.commit d)
  | query (d : Decision) : Step d d
theorem stepPreserves {a b : Decision} (h : Step a b) (s : DSafe a) : DSafe b := by
  cases h with
  | commit r => exact commitPreserves _ s r
  | query => exact s
inductive Trace : Decision → Decision → Prop
  | nil (d : Decision) : Trace d d
  | cons {a b c : Decision} : Step a b → Trace b c → Trace a c
theorem tracePreserves {a b : Decision} (h : Trace a b) (s : DSafe a) : DSafe b := by
  induction h with
  | nil => exact s
  | cons h _ ih => exact ih (stepPreserves h s)
def CanFreeze (d : Decision) (s : Stop) (permit : Bool) := DSafe d ∧ d.published=true ∧ StopValid s ∧ permit=false
theorem commitAloneDoesNotDrain (d : Decision) (s : Stop) (p : Bool) (h : 0<s.pending) : ¬ CanFreeze d s p := by
  intro f
  exact pendingRejectsStop s h f.2.2.1
structure CommitObservation where
  published : Bool
  deriving DecidableEq
structure CommitSnapshot where
  observation : CommitObservation
  pending : Nat
def idleNull : CommitSnapshot := ⟨⟨false⟩,0⟩
def pendingNull : CommitSnapshot := ⟨⟨false⟩,3⟩
theorem nullSnapshotsSameObservation : idleNull.observation=pendingNull.observation := rfl
theorem noCompletePendingDecoder (decode : CommitObservation→Nat) :
    ¬ (decode idleNull.observation=idleNull.pending ∧ decode pendingNull.observation=pendingNull.pending) := by
  simp [idleNull,pendingNull]; omega
end GambitSMP.MarkerInterruptedPublication


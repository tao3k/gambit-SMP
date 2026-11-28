import ControlWord
namespace ControlWord
open ControlWordAst

def encode (route ready : Int) := route + 4*ready
theorem encodingInjective (d r d' r' : Int)
 (dlo : 0≤d) (dhi : d≤3) (rlo : 0≤r) (rhi : r≤1)
 (dlo' : 0≤d') (dhi' : d'≤3) (rlo' : 0≤r') (rhi' : r'≤1)
 (equal : encode d r=encode d' r') : d=d' ∧ r=r' := by
 unfold encode at equal
 omega

theorem successfulRmwBound (q : State) (h : Safe q) :
 q.wordWins≤3 ∧ q.wordWins+q.activationWord≤5 := by
 have hc := ((safeEquivalent q).mp h).2
 unfold Invariant at hc
 omega

theorem staleCommitMustFail (q : State) (changed : q.sExpected≠q.word) :
 ¬ casCommitGuard q := by
 unfold casCommitGuard
 omega

theorem failureRetainsPreparedResult (q : State) :
 (childFailureNext q).preparedResult=q.preparedResult ∧
 (childFailureNext q).n_resultRoot=q.n_resultRoot := by exact ⟨rfl,rfl⟩

-- These are explicit external event premises. The theorem composes HB edges;
-- it does not construct a C23 execution or infer reads-from from a numeric word.
structure Handoff (Event : Type) (hb : Event → Event → Prop) where
 transitive : ∀ {a b c}, hb a b → hb b c → hb a c
 payload : Event
 commit : Event
 acquireCommit : Event
 activate : Event
 acquireActive : Event
 use : Event
 payloadBeforeCommit : hb payload commit
 commitSynchronizesAcquire : hb commit acquireCommit
 acquireBeforeActivate : hb acquireCommit activate
 activateSynchronizesWorker : hb activate acquireActive
 workerBeforeUse : hb acquireActive use

theorem releaseAcquireComposition {Event : Type} {hb : Event → Event → Prop}
 (h : Handoff Event hb) : hb h.payload h.use := by
 exact h.transitive h.payloadBeforeCommit
   (h.transitive h.commitSynchronizesAcquire
     (h.transitive h.acquireBeforeActivate
       (h.transitive h.activateSynchronizesWorker h.workerBeforeUse)))
end ControlWord

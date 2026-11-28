import Std
namespace Gambit.PreparationReuse
structure Inputs where
 production : Nat
 support : Nat
 suite : Nat
 entry : Nat
 native : Nat
 foundation : Nat
structure LayerKey where
 layer : Nat
 production : Nat
 support : Nat
 suite : Nat
 native : Nat
 foundation : Nat
 deriving DecidableEq

def layerKey (x : Inputs) (n : Nat) : LayerKey := ⟨n,x.production,if n≥1 then x.support else 0,if n=2 then x.suite else 0,x.native,x.foundation⟩

theorem entryChangeKeepsLibraryKey (x : Inputs) (e n : Nat) : layerKey {x with entry:=e} n=layerKey x n := rfl

theorem suiteChangeKeepsProduction (x : Inputs) (v : Nat) : layerKey {x with suite:=v} 0=layerKey x 0 := rfl

theorem suiteChangeKeepsSupport (x : Inputs) (v : Nat) : layerKey {x with suite:=v} 1=layerKey x 1 := rfl

theorem supportChangeKeepsProduction (x : Inputs) (v : Nat) : layerKey {x with support:=v} 0=layerKey x 0 := rfl

theorem nativeChangeInvalidates (x : Inputs) (v n : Nat) (changed : v≠x.native) : layerKey {x with native:=v} n≠layerKey x n := by
 intro same
 exact changed (congrArg LayerKey.native same)

structure Successor where
 sourceEpoch : Nat
 observedEpoch : Nat
 foundationBefore : Nat
 foundationAfter : Nat
 outputBefore : Nat
 outputAfter : Nat
 completeWriterClosure : Bool
 aliasesClosed : Bool
 successfulQuiescentProducer : Bool
 unknown : Bool
 custodyHeld : Bool

def admitted (x : Successor) : Prop :=
 x.sourceEpoch=x.observedEpoch ∧ x.foundationBefore=x.foundationAfter ∧
 x.completeWriterClosure=true ∧ x.aliasesClosed=true ∧ x.successfulQuiescentProducer=true ∧ x.unknown=false ∧ x.custodyHeld=true

theorem unknownRefusesSuccessor (x : Successor) (unknownResult : x.unknown=true) : ¬admitted x := by
 intro h
 have no:=h.2.2.2.2.2.1
 rw [unknownResult] at no
 contradiction

theorem changedFoundationRefuses (x : Successor) (changed : x.foundationBefore≠x.foundationAfter) : ¬admitted x := fun h=>changed h.2.1

theorem successorKeepsCustody (x : Successor) (h : admitted x) : x.custodyHeld=true := h.2.2.2.2.2.2

-- A read footprint is sound only after source extraction and complete effect
-- handling. This theorem never derives that premise from a source-file suffix.
def currentReadView (reads : List Nat) (cached now : Nat → Nat) : Prop := ∀ r ∈ reads, cached r=now r

def editResource (before : Nat → Nat) (changed value : Nat) : Nat → Nat := fun r=>if r=changed then value else before r

theorem outsideFootprintPreservesReadView (reads : List Nat) (before : Nat → Nat) (changed value : Nat) (outside : changed∉reads) : currentReadView reads before (editResource before changed value) := by
 intro r member
 have different : r≠changed := by intro same;subst r;exact outside member
 simp [editResource,different]

theorem consumedChangeInvalidatesReadView (reads : List Nat) (before : Nat → Nat) (changed value : Nat) (inside : changed∈reads) (different : before changed≠value) : ¬currentReadView reads before (editResource before changed value) := by
 intro h
 have same:=h changed inside
 simp [editResource] at same
 exact different same

structure GroupReceipt where
 attempt : Nat
 observedAttempt : Nat
 successfulParent : Bool
 liveWriters : Nat
 liveDescendants : Nat
 failedChildren : Bool
 outputsChecked : Bool
 declaredWriteClosure : Bool
 candidateHeld : Bool
 oldViewHeld : Bool
 unknown : Bool
 requiredOutputsComplete : Bool

def groupReady (g : GroupReceipt) : Prop :=
 g.attempt=g.observedAttempt ∧ g.successfulParent=true ∧ g.liveWriters=0 ∧
 g.liveDescendants=0 ∧ g.failedChildren=false ∧ g.outputsChecked=true ∧ g.declaredWriteClosure=true ∧
 g.candidateHeld=true ∧ g.oldViewHeld=true ∧ g.unknown=false ∧ g.requiredOutputsComplete=true

theorem parentSuccessStillNeedsDrain (g : GroupReceipt) (ready : groupReady g) : g.liveWriters=0 ∧ g.liveDescendants=0 := ⟨ready.2.2.1,ready.2.2.2.1⟩

theorem staleAttemptRefusesGroup (g : GroupReceipt) (stale : g.attempt≠g.observedAttempt) : ¬groupReady g := fun ready=>stale ready.1

theorem uncheckedOutputsRefuseGroup (g : GroupReceipt) (unchecked : g.outputsChecked=false) : ¬groupReady g := by
 intro ready
 have checked:=ready.2.2.2.2.2.1
 rw [unchecked] at checked
 contradiction

theorem readyGroupKeepsBothViews (g : GroupReceipt) (ready : groupReady g) : g.candidateHeld=true ∧ g.oldViewHeld=true := ⟨ready.2.2.2.2.2.2.2.1,ready.2.2.2.2.2.2.2.2.1⟩

theorem failedChildRefusesGroup (g : GroupReceipt) (failed : g.failedChildren=true) : ¬groupReady g := by
 intro ready
 have no:=ready.2.2.2.2.1
 rw [failed] at no
 contradiction

theorem incompleteRequiredOutputsRefuse (g : GroupReceipt) (missing : g.requiredOutputsComplete=false) : ¬groupReady g := by
 intro ready
 rcases ready with ⟨_, _, _, _, _, _, _, _, _, _, complete⟩
 rw [missing] at complete
 contradiction

def canSettleMember (attempt : Nat) (active : Nat × Nat → Prop) (token : Nat × Nat) : Prop := token.1=attempt ∧ active token

def retireMember (active : Nat × Nat → Prop) (token : Nat × Nat) : Nat × Nat → Prop := fun member=>active member ∧ member≠token

theorem staleMemberCannotSettle (attempt : Nat) (active : Nat × Nat → Prop) (token : Nat × Nat) (stale : token.1≠attempt) : ¬canSettleMember attempt active token := fun h=>stale h.1

theorem retiredMemberCannotSettleTwice (attempt : Nat) (active : Nat × Nat → Prop) (token : Nat × Nat) : ¬canSettleMember attempt (retireMember active token) token := by
 intro h
 exact h.2.2 rfl

structure MemberPublication where
 registered : Bool
 carrierRooted : Bool
 payloadInitialized : Bool
 published : Bool
 resultKnown : Bool
 attempt : Nat
 observedAttempt : Nat

def publishReady (m : MemberPublication) : Prop := m.registered=true ∧ m.carrierRooted=true ∧ m.payloadInitialized=true ∧ m.attempt=m.observedAttempt

def settleReady (m : MemberPublication) : Prop := m.registered=true ∧ m.resultKnown=true ∧ m.attempt=m.observedAttempt

theorem publicationNeedsRootedCarrier (m : MemberPublication) (h : publishReady m) : m.carrierRooted=true ∧ m.payloadInitialized=true := ⟨h.2.1,h.2.2.1⟩

theorem runningIsNotKnownResult (m : MemberPublication) (unknownResult : m.resultKnown=false) : ¬settleReady m := by
 intro h
 have known:=h.2.1
 rw [unknownResult] at known
 contradiction

theorem wrongGenerationCannotPublish (m : MemberPublication) (wrong : m.attempt≠m.observedAttempt) : ¬publishReady m := fun h=>wrong h.2.2.2

def commitResult (slot : Option Nat) (candidate : Nat) : Option Nat := match slot with | some old=>some old | none=>some candidate

theorem existingResultCannotBeOverwritten (old candidate : Nat) : commitResult (some old) candidate=some old := rfl

theorem resultCommitIdempotent (slot : Option Nat) (a b : Nat) : commitResult (commitResult slot a) b=commitResult slot a := by
 cases slot <;> rfl

-- This is conditional HB composition. C23 same-mutex or actual release/acquire
-- reads-from evidence must establish the middle edge; clock order is not HB.
theorem handoffHappensBefore (Event : Type) (hb : Event → Event → Prop)
 (transitive : ∀ a b c, hb a b → hb b c → hb a c)
 (initEvent releaseEvent acquireEvent readEvent : Event)
 (initialized : hb initEvent releaseEvent) (synchronizes : hb releaseEvent acquireEvent) (reader : hb acquireEvent readEvent) : hb initEvent readEvent :=
 transitive initEvent acquireEvent readEvent (transitive initEvent releaseEvent acquireEvent initialized synchronizes) reader

def registrationGrant (current observed : Nat) (live : Prop) : Prop := current=observed ∧ live

theorem staleGrantCannotRegister (current observed : Nat) (live : Prop) (stale : current≠observed) : ¬registrationGrant current observed live := fun h=>stale h.1

-- Conditional projections only. Producer output deltas, slot/root ownership,
-- filesystem effects and actual QNT/Lean extraction remain source obligations.
end Gambit.PreparationReuse

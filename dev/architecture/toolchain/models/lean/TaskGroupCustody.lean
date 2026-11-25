import Std
namespace Gambit.TaskGroupCustody
structure Custody where
 source : Bool
 target : Bool
 targetReady : Bool
 sourceOpen : Bool
 sourcePins : Nat
 processUnknown : Bool
 exited : Bool
 effects : Bool
 observing : Bool
 pins : Nat
 rawAlias : Bool
 rootsDropped : Bool
 releaseStage : Nat

def covered (c : Custody) : Prop := c.source=true ∨ (c.target=true ∧ c.targetReady=true)
def terminal (c : Custody) : Prop := c.exited=true ∧ c.processUnknown=false ∧ c.effects=true

def canDetach (c : Custody) : Prop := c.sourceOpen=false ∧ c.sourcePins=0 ∧ c.target=true ∧ c.targetReady=true

def detach (c : Custody) : Custody := {c with source:=false}

theorem detachPreservesRootCoverage (c : Custody) (h : canDetach c) : covered (detach c) := Or.inr ⟨h.2.2.1,h.2.2.2⟩

theorem sourcePinBlocksDetach (c : Custody) (h : c.sourcePins≠0) : ¬canDetach c := fun p=>h p.2.1

theorem openWriterBlocksDetach (c : Custody) (h : c.sourceOpen=true) : ¬canDetach c := by
 intro p
 have no:=p.1
 rw [h] at no
 contradiction

def canRetireOrigin (c : Custody) : Prop := c.source=false ∧ c.sourcePins=0 ∧ c.processUnknown=false

theorem transferredRootDoesNotRetireUnknownOrigin (c : Custody) (h : c.processUnknown=true) : ¬canRetireOrigin c := by
 intro p
 have no:=p.2.2
 rw [h] at no
 contradiction

def groupBridge {Member : Type} (known : Member → Prop) (cells : Member → Custody) : Prop := ∀ m, known m → terminal (cells m)

theorem pointwiseBridgeCoversWholeGroup {Member : Type} (known : Member → Prop) (cells : Member → Custody) (bridge : groupBridge known cells) (allKnown : ∀ m, known m) : ∀ m, terminal (cells m) := fun m=>bridge m (allKnown m)

theorem oneUnknownRefusesWholeGroup {Member : Type} (cells : Member → Custody) (m : Member) (h : (cells m).processUnknown=true) : ¬(∀ x, terminal (cells x)) := by
 intro all
 have no:=(all m).2.1
 rw [h] at no
 contradiction

-- Parametric lifting, not an assumption that every native step is local.
def replaceMember {Member : Type} [DecidableEq Member] (cells : Member → Custody) (key : Member) (value : Custody) : Member → Custody := fun m=>if m=key then value else cells m

theorem replaceMemberPreservesForAll {Member : Type} [DecidableEq Member] (P : Custody → Prop) (cells : Member → Custody) (key : Member) (value : Custody) (old : ∀ m, P (cells m)) (next : P value) : ∀ m, P (replaceMember cells key value m) := by
 intro m
 by_cases same : m=key
 · simp [replaceMember,same,next]
 · simpa [replaceMember,same] using old m

def canDropRoots (c : Custody) : Prop := terminal c ∧ c.observing=false ∧ c.pins=0 ∧ c.rawAlias=false ∧ c.sourceOpen=false ∧ c.sourcePins=0

theorem lateObserverBlocksDrop (c : Custody) (h : c.pins≠0) : ¬canDropRoots c := fun p=>h p.2.2.1

theorem rawAliasBlocksDrop (c : Custody) (h : c.rawAlias=true) : ¬canDropRoots c := by
 intro p
 have no:=p.2.2.2.1
 rw [h] at no
 contradiction

def canBeginRelease (c : Custody) : Prop := c.rootsDropped=true ∧ c.releaseStage=0

theorem unknownFreeCannotRetry (c : Custody) (h : c.releaseStage=1) : ¬canBeginRelease c := by
 intro p
 have zero:=p.2
 omega

theorem knownFreeCannotRetry (c : Custody) (h : c.releaseStage=2) : ¬canBeginRelease c := by
 intro p
 have zero:=p.2
 omega

def canObserve (c : Custody) : Prop := c.observing=true ∧ c.rootsDropped=false

theorem retiredRootsRefuseLateObservation (c : Custody) (h : c.rootsDropped=true) : ¬canObserve c := by
 intro p
 have no:=p.2
 rw [h] at no
 contradiction
end Gambit.TaskGroupCustody

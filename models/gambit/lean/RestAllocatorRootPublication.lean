/- Abstract linearizable gate and conditional happens-before chain, not a C compiler proof. -/
namespace GambitSMP.RestAllocatorRootPublication
structure S where
  closing : Bool
  roots : Bool
  published : Bool
  layoutOps : Nat
  unknown : Bool
  escrow : Bool
  ticket : Nat
  active : Bool
  full : Bool
  frozen : Bool
  layout : Nat
  stamp : Nat
  epoch : Nat
  rootEpoch : Nat
  reloaded : Bool
  deriving DecidableEq
def Safe (s : S) := (s.published=true → s.roots=true) ∧
 (s.unknown=true → 0<s.layoutOps ∧ s.escrow=true) ∧
 (s.ticket≠0 → s.stamp=s.layout ∧ s.reloaded=true ∧ s.rootEpoch=s.epoch) ∧
 (s.active=true → s.ticket=2 ∧ s.full=false ∧ s.frozen=false) ∧
 (s.full=false → s.active=true) ∧
 (s.frozen=true → s.closing=true ∧ s.full=true ∧ s.active=false ∧ s.ticket=0 ∧ s.layoutOps=0 ∧ s.unknown=false)
def publish (s : S) := {s with published:=true}
def close (s : S) := {s with closing:=true}
def freeze (s : S) := {s with frozen:=true}
def denyKnown (s : S) := {s with layoutOps:=0,escrow:=false,layout:=s.layout+1,ticket:=0}
def grant (s : S) := {s with ticket:=1,stamp:=s.layout}
def finish (s : S) := {s with ticket:=0,active:=false,full:=true}
theorem publishPreserves (s : S) (h : Safe s) (r : s.roots=true) : Safe (publish s) := by simp_all [Safe,publish]
theorem closePreserves (s : S) (h : Safe s) : Safe (close s) := by simp_all [Safe,close]
theorem freezePreserves (s : S) (h : Safe s) (c : s.closing=true) (f : s.full=true) (a : s.active=false) (t : s.ticket=0) (o : s.layoutOps=0) (u : s.unknown=false) : Safe (freeze s) := by simp_all [Safe,freeze]
theorem denyKeepsRoots (s : S) : (denyKnown s).roots=s.roots := rfl
theorem denyMayChangeLayout (s : S) : (denyKnown s).layout=s.layout+1 := rfl
theorem denyPreserves (s : S) (h : Safe s) (u : s.unknown=false) (a : s.active=false) : Safe (denyKnown s) := by simp_all [Safe,denyKnown]
theorem grantPreserves (s : S) (h : Safe s) (f : s.frozen=false) (a : s.active=false) (r : s.reloaded=true) (e : s.rootEpoch=s.epoch) : Safe (grant s) := by simp_all [Safe,grant]
theorem finishPreserves (s : S) (h : Safe s) : Safe (finish s) := by simp_all [Safe,finish]
theorem frozenExcludesLayout (s : S) (h : Safe s) (f : s.frozen=true) : s.layoutOps=0 := (h.2.2.2.2.2 f).2.2.2.2.1
theorem frozenExcludesWriter (s : S) (h : Safe s) (f : s.frozen=true) : s.active=false := (h.2.2.2.2.2 f).2.2.1
theorem unknownKeepsEscrow (s : S) (h : Safe s) (u : s.unknown=true) : 0<s.layoutOps ∧ s.escrow=true := h.2.1 u
theorem oldLayoutRejected (s : S) (h : Safe s) (t : s.ticket≠0) : s.stamp=s.layout := (h.2.2.1 t).1
-- Explicit event graph. The caller supplies actual C sequenced-before/synchronizes-with edges.
structure HBChain (E : Type) where
  hb : E → E → Prop
  trans : ∀ a b c, hb a b → hb b c → hb a c
  rootWrite : E
  rootPublish : E
  gateAcquire : E
  frameWrite : E
  parkRelease : E
  scanAcquire : E
  scan : E
  relocate : E
  resumeRelease : E
  reloadAcquire : E
  use : E
  rootEdge : hb rootWrite rootPublish
  publishEdge : hb rootPublish gateAcquire
  frameEdge : hb frameWrite parkRelease
  parkEdge : hb parkRelease scanAcquire
  scanEdge : hb scanAcquire scan
  moveEdge : hb relocate resumeRelease
  resumeEdge : hb resumeRelease reloadAcquire
  reloadEdge : hb reloadAcquire use
theorem rootsVisible {E : Type} (c : HBChain E) : c.hb c.rootWrite c.gateAcquire := c.trans _ _ _ c.rootEdge c.publishEdge
theorem frameVisible {E : Type} (c : HBChain E) : c.hb c.frameWrite c.scan := c.trans _ _ _ (c.trans _ _ _ c.frameEdge c.parkEdge) c.scanEdge
theorem movedRootsVisible {E : Type} (c : HBChain E) : c.hb c.relocate c.use := c.trans _ _ _ (c.trans _ _ _ c.moveEdge c.resumeEdge) c.reloadEdge
inductive Step : S → S → Prop
 | close (s : S) : Step s (RestAllocatorRootPublication.close s)
 | publish (s : S) (r : s.roots=true) : Step s (RestAllocatorRootPublication.publish s)
 | finish (s : S) : Step s (RestAllocatorRootPublication.finish s)
theorem stepPreserves {a b : S} (h : Safe a) (t : Step a b) : Safe b := by
 cases t with
 | close => exact closePreserves a h
 | publish r => exact publishPreserves a h r
 | finish => exact finishPreserves a h
end GambitSMP.RestAllocatorRootPublication

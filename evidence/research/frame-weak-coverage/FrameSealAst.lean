import Std
namespace FrameSealAst
set_option maxRecDepth 10000
structure State where
 managed : Bool
 chunk : Int
 cursor : Int
 initialized : Bool
 ready : Bool
 pending : Bool
 queued : Bool
 deferred : Bool
 scan : Int
 link : Int
 snapshot : Int
 fixed : Bool
 copier : Bool
 closed : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.managed=true) → ((q.chunk≥(0)) ∧ (q.chunk≤(2)) ∧ (q.cursor=(0)) ∧ (q.scan≥(0)) ∧ (q.scan≤(4)) ∧ ((q.ready=true) → (((q.initialized=true) ∧ (¬(q.pending=true))) ∧ (q.fixed=true))) ∧ (((q.pending=true) ∨ (q.deferred=true)) → (q.copier=true)) ∧ (((q.queued=true) ∨ (q.scan≥(1))) → (q.ready=true)) ∧ ((q.scan≥(2)) → (q.snapshot=(2))) ∧ ((q.fixed=true) → (((q.initialized=true) ∧ (¬(q.pending=true))) ∧ (((q.link=(1)) ∨ (q.link=(2))) ∨ (q.link=(4))))) ∧ (((q.fixed=true) ∧ (q.scan≤(1))) → (q.link=(2))) ∧ ((q.scan=(2)) → (q.link=(2))) ∧ ((q.scan=(3)) → (q.link=(1))) ∧ ((q.scan=(4)) → (q.link=(4))) ∧ ((q.closed=true) → (((((¬(q.copier=true)) ∧ (¬(q.pending=true))) ∧ (¬(q.deferred=true))) ∧ (q.scan=(4))) ∧ (q.link=(4))))))
def initial : State := {managed:=true, chunk:=(0), cursor:=(0), initialized:=false, ready:=false, pending:=false, queued:=false, deferred:=false, scan:=(0), link:=(0), snapshot:=(-(1)), fixed:=false, copier:=true, closed:=false}
def rollInitialGuard (q : State) : Prop := (q.chunk=(0))
def rollInitialNext (q : State) : State := {q with chunk:=(1)}
def copyAGuard (q : State) : Prop := (q.chunk=(1)) ∧ (¬(q.initialized=true)) ∧ (q.copier=true)
def copyANext (q : State) : State := {q with initialized:=true, pending:=true}
def readyEarlyGuard (q : State) : Prop := (¬(q.managed=true)) ∧ (q.initialized=true) ∧ (¬(q.ready=true))
def readyEarlyNext (q : State) : State := {q with ready:=true}
def publishEarlyGuard (q : State) : Prop := (¬(q.managed=true)) ∧ (q.ready=true) ∧ (q.chunk=(1)) ∧ (q.cursor≠q.chunk)
def publishEarlyNext (q : State) : State := {q with queued:=true, chunk:=(2)}
def deferChunkGuard (q : State) : Prop := (q.managed=true) ∧ (q.chunk=(1)) ∧ (q.pending=true) ∧ (¬(q.ready=true))
def deferChunkNext (q : State) : State := {q with deferred:=true, chunk:=(2)}
def fillLinkGuard (q : State) : Prop := (q.initialized=true) ∧ (q.pending=true) ∧ (q.chunk=(2)) ∧ (q.copier=true)
def fillLinkNext (q : State) : State := {q with pending:=false, fixed:=true, link:=(2)}
def sealReadyGuard (q : State) : Prop := (q.managed=true) ∧ (q.initialized=true) ∧ (¬(q.pending=true)) ∧ (q.fixed=true) ∧ (¬(q.ready=true))
def sealReadyNext (q : State) : State := {q with ready:=true}
def publishDeferredGuard (q : State) : Prop := (q.managed=true) ∧ (q.deferred=true) ∧ (q.ready=true) ∧ (¬(q.pending=true))
def publishDeferredNext (q : State) : State := {q with deferred:=false, queued:=true}
def claimGuard (q : State) : Prop := (q.queued=true) ∧ (q.ready=true) ∧ (q.scan=(0))
def claimNext (q : State) : State := {q with queued:=false, scan:=(1)}
def readLinkGuard (q : State) : Prop := (q.scan=(1))
def readLinkNext (q : State) : State := {q with scan:=(2), snapshot:=q.link}
def hideLinkGuard (q : State) : Prop := (q.scan=(2)) ∧ ((q.snapshot=(0)) ∨ (q.snapshot=(2)))
def hideLinkNext (q : State) : State := {q with scan:=(3), link:=(1)}
def restoreOldGuard (q : State) : Prop := (q.scan=(3)) ∧ (q.snapshot=(0))
def restoreOldNext (q : State) : State := {q with scan:=(4), link:=(3)}
def restoreFixedGuard (q : State) : Prop := (q.scan=(3)) ∧ (q.snapshot=(2))
def restoreFixedNext (q : State) : State := {q with scan:=(4), link:=(4)}
def releaseCopierGuard (q : State) : Prop := (q.ready=true) ∧ (¬(q.pending=true)) ∧ (¬(q.deferred=true))
def releaseCopierNext (q : State) : State := {q with copier:=false}
def closeGuard (q : State) : Prop := (¬(q.copier=true)) ∧ (q.scan=(4))
def closeNext (q : State) : State := {q with closed:=true}
def Step (q r : State) : Prop := (rollInitialGuard q ∧ r=rollInitialNext q) ∨ (copyAGuard q ∧ r=copyANext q) ∨ (readyEarlyGuard q ∧ r=readyEarlyNext q) ∨ (publishEarlyGuard q ∧ r=publishEarlyNext q) ∨ (deferChunkGuard q ∧ r=deferChunkNext q) ∨ (fillLinkGuard q ∧ r=fillLinkNext q) ∨ (sealReadyGuard q ∧ r=sealReadyNext q) ∨ (publishDeferredGuard q ∧ r=publishDeferredNext q) ∨ (claimGuard q ∧ r=claimNext q) ∨ (readLinkGuard q ∧ r=readLinkNext q) ∨ (hideLinkGuard q ∧ r=hideLinkNext q) ∨ (restoreOldGuard q ∧ r=restoreOldNext q) ∨ (restoreFixedGuard q ∧ r=restoreFixedNext q) ∨ (releaseCopierGuard q ∧ r=releaseCopierNext q) ∨ (closeGuard q ∧ r=closeNext q) ∨ r=q
end FrameSealAst

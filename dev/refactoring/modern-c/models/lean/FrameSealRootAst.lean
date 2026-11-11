import Std
namespace FrameSealRootAst
set_option maxRecDepth 10000
structure State where
 live : Int
 snap : Int
 rootEpoch : Int
 seen : Int
 request : Int
 Q : Int
 A : Int
 T : Int
 B : Int
 denied : Int
 owner : Bool
 aliases : Bool
 sealedView : Bool
 frozen : Bool
 covered : Bool
 modulePinned : Bool
 moduleClosed : Bool
 ledger : Bool
 receipt : Bool
 started : Bool
 alternative : Bool
 retained : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.live≥(1)) ∧ (q.snap≥(0)) ∧ (q.snap≤q.live) ∧ (q.rootEpoch≥(1)) ∧ (q.seen≥(0)) ∧ (q.seen≤q.rootEpoch) ∧ (q.request≥(0)) ∧ (q.request≤(5)) ∧ (q.Q≥(0)) ∧ (q.A≥(0)) ∧ (q.T≥(0)) ∧ (q.B≥(0)) ∧ (q.denied≥(0)) ∧ ((q.sealedView=true) → ((q.aliases=true) ∧ (q.snap≥(1)))) ∧ ((q.frozen=true) → ((q.request≠(1)) ∧ (q.seen=q.rootEpoch))) ∧ ((q.covered=true) → ((((q.frozen=true) ∧ (q.moduleClosed=true)) ∧ (q.modulePinned=true)) ∧ (q.B≥((q.Q+q.A)+q.T)))) ∧ ((q.receipt=true) → ((((((q.sealedView=true) ∧ (q.covered=true)) ∧ (q.frozen=true)) ∧ (q.modulePinned=true)) ∧ (q.moduleClosed=true)) ∧ (¬(q.alternative=true)))) ∧ ((q.started=true) → (q.receipt=true)) ∧ ((q.alternative=true) → (((q.retained=true) ∧ (¬(q.receipt=true))) ∧ (¬(q.started=true)))) ∧ (((q.request≥(1)) ∨ (q.ledger=true)) → (q.modulePinned=true)))
def initial : State := {live:=(1), snap:=(0), rootEpoch:=(1), seen:=(0), request:=(0), Q:=(0), A:=(0), T:=(0), B:=(0), denied:=(0), owner:=false, aliases:=false, sealedView:=false, frozen:=false, covered:=false, modulePinned:=true, moduleClosed:=true, ledger:=false, receipt:=false, started:=false, alternative:=false, retained:=false}
def ownGuard (q : State) : Prop := (¬(q.sealedView=true)) ∧ (¬(q.alternative=true))
def ownNext (q : State) : State := {q with owner:=true, aliases:=true}
def mutateLiveGuard (q : State) : Prop := (¬(q.owner=true))
def mutateLiveNext (q : State) : State := {q with live:=(q.live+(1))}
def sealGuard (q : State) : Prop := (q.owner=true) ∧ (q.aliases=true) ∧ (¬(q.sealedView=true)) ∧ (¬(q.alternative=true))
def sealNext (q : State) : State := {q with sealedView:=true, snap:=q.live, owner:=false}
def beginRequestGuard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.alternative=true)) ∧ (q.request=(0)) ∧ (q.modulePinned=true)
def beginRequestNext (q : State) : State := {q with request:=(1)}
def publishRequestGuard (q : State) : Prop := (q.request=(1)) ∧ (¬(q.frozen=true))
def publishRequestNext (q : State) : State := {q with request:=(2), rootEpoch:=(q.rootEpoch+(1))}
def selectRequestGuard (q : State) : Prop := (q.request=(2)) ∧ (¬(q.frozen=true))
def selectRequestNext (q : State) : State := {q with request:=(3), ledger:=true}
def unknownRequestGuard (q : State) : Prop := ((q.request=(2)) ∨ (q.request=(3))) ∧ (q.modulePinned=true) ∧ (¬(q.frozen=true))
def unknownRequestNext (q : State) : State := {q with request:=(5), retained:=true}
def completeRequestGuard (q : State) : Prop := (q.request=(3)) ∧ (q.ledger=true) ∧ (¬(q.frozen=true))
def completeRequestNext (q : State) : State := {q with request:=(4)}
def ackSourceGuard (q : State) : Prop := (q.request=(4)) ∧ (q.ledger=true) ∧ (¬(q.frozen=true))
def ackSourceNext (q : State) : State := {q with request:=(0), rootEpoch:=(q.rootEpoch+(1))}
def freezeGuard (q : State) : Prop := (q.request≠(1)) ∧ (¬(q.frozen=true)) ∧ (¬(q.alternative=true)) ∧ (q.modulePinned=true) ∧ (q.moduleClosed=true)
def freezeNext (q : State) : State := {q with frozen:=true, seen:=q.rootEpoch}
def coverSourceGuard (q : State) : Prop := (q.frozen=true) ∧ (¬(q.covered=true)) ∧ (q.moduleClosed=true) ∧ (q.modulePinned=true)
def coverSourceNext (q : State) : State := {q with covered:=true, Q:=(510), A:=(0), T:=(2), B:=(512)}
def issueGuard (q : State) : Prop := (q.sealedView=true) ∧ (q.covered=true) ∧ (q.frozen=true) ∧ (q.modulePinned=true) ∧ (q.moduleClosed=true) ∧ (q.seen=q.rootEpoch) ∧ (¬(q.alternative=true)) ∧ (¬(q.receipt=true))
def issueNext (q : State) : State := {q with receipt:=true}
def startGuard (q : State) : Prop := (q.receipt=true) ∧ (¬(q.started=true))
def startNext (q : State) : State := {q with started:=true}
def relocateGuard (q : State) : Prop := (q.started=true)
def relocateNext (q : State) : State := {q with denied:=(q.denied+(0))}
def deferRootWriterGuard (q : State) : Prop := (q.frozen=true)
def deferRootWriterNext (q : State) : State := {q with denied:=(q.denied+(1))}
def revokeBeforeCopyGuard (q : State) : Prop := (¬(q.started=true)) ∧ (¬(q.alternative=true))
def revokeBeforeCopyNext (q : State) : State := {q with receipt:=false, covered:=false, frozen:=false, alternative:=true, retained:=true}
def finishRoundGuard (q : State) : Prop := (q.started=true)
def finishRoundNext (q : State) : State := {q with started:=false, receipt:=false, covered:=false, frozen:=false}
def closeLedgerGuard (q : State) : Prop := (¬(q.frozen=true)) ∧ (q.request=(0)) ∧ (q.ledger=true)
def closeLedgerNext (q : State) : State := {q with ledger:=false, rootEpoch:=(q.rootEpoch+(1))}
def retireModuleGuard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.receipt=true)) ∧ (¬(q.started=true)) ∧ (q.request=(0)) ∧ (¬(q.ledger=true))
def retireModuleNext (q : State) : State := {q with modulePinned:=false}
def rejectOpaqueGuard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.started=true)) ∧ (¬(q.alternative=true))
def rejectOpaqueNext (q : State) : State := {q with moduleClosed:=false, alternative:=true, retained:=true, receipt:=false, covered:=false}
def Step (q r : State) : Prop := (ownGuard q ∧ r=ownNext q) ∨ (mutateLiveGuard q ∧ r=mutateLiveNext q) ∨ (sealGuard q ∧ r=sealNext q) ∨ (beginRequestGuard q ∧ r=beginRequestNext q) ∨ (publishRequestGuard q ∧ r=publishRequestNext q) ∨ (selectRequestGuard q ∧ r=selectRequestNext q) ∨ (unknownRequestGuard q ∧ r=unknownRequestNext q) ∨ (completeRequestGuard q ∧ r=completeRequestNext q) ∨ (ackSourceGuard q ∧ r=ackSourceNext q) ∨ (freezeGuard q ∧ r=freezeNext q) ∨ (coverSourceGuard q ∧ r=coverSourceNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (startGuard q ∧ r=startNext q) ∨ (relocateGuard q ∧ r=relocateNext q) ∨ (deferRootWriterGuard q ∧ r=deferRootWriterNext q) ∨ (revokeBeforeCopyGuard q ∧ r=revokeBeforeCopyNext q) ∨ (finishRoundGuard q ∧ r=finishRoundNext q) ∨ (closeLedgerGuard q ∧ r=closeLedgerNext q) ∨ (retireModuleGuard q ∧ r=retireModuleNext q) ∨ (rejectOpaqueGuard q ∧ r=rejectOpaqueNext q) ∨ r=q
end FrameSealRootAst

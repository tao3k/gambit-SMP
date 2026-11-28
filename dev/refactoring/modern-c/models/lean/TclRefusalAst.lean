import Std
namespace TclRefusalAst
set_option maxRecDepth 10000
structure State where
 scope : Int
 vmOpen : Int
 outerSticky : Int
 childSticky : Int
 childMerged : Int
 eventSeen : Int
 tclCode : Int
 diagnostic : Int
 done : Int
 delivered : Int
 origin : Int
 translated : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.scope≥(0)) ∧ (q.scope≤(2)) ∧ (q.vmOpen≥(0)) ∧ (q.vmOpen≤(1)) ∧ (q.outerSticky≥(0)) ∧ (q.outerSticky≤(1)) ∧ (q.childSticky≥(0)) ∧ (q.childSticky≤(1)) ∧ (q.childMerged≥(0)) ∧ (q.childMerged≤(1)) ∧ (q.eventSeen≥(0)) ∧ (q.eventSeen≤(1)) ∧ (q.tclCode≥(0)) ∧ (q.tclCode≤(1)) ∧ (q.diagnostic≥(0)) ∧ (q.diagnostic≤(1)) ∧ (q.done≥(0)) ∧ (q.done≤(1)) ∧ (q.delivered≥(0)) ∧ (q.delivered≤(1)) ∧ (q.origin≥(0)) ∧ (q.origin≤(3)) ∧ (q.translated≥(0)) ∧ (q.translated≤(1)) ∧ ((q.eventSeen=(1)) → ((q.outerSticky=(1)) ∨ ((q.scope=(2)) ∧ (q.childSticky=(1))))) ∧ ((q.outerSticky=(1)) → (q.eventSeen=(1))) ∧ ((q.childSticky=(1)) → ((q.scope=(2)) ∧ (q.eventSeen=(1)))) ∧ ((q.childMerged=(1)) → (((q.scope=(2)) ∧ (q.childSticky=(1))) ∧ (q.outerSticky=(1)))) ∧ ((q.done=(1)) → (q.scope=(1))) ∧ ((q.delivered=(1)) → (((q.scope=(1)) ∧ (q.done=(1))) ∧ (q.origin≥(1)))) ∧ ((q.delivered=(0)) → ((q.origin=(0)) ∧ (q.translated=(0)))) ∧ (((q.delivered=(1)) ∧ (q.eventSeen=(1))) → ((q.origin=(1)) ∧ (q.translated=(0)))) ∧ ((q.translated=(1)) → (((q.vmOpen=(1)) ∧ (q.eventSeen=(0))) ∧ (q.origin=(2)))) ∧ ((q.scope=(0)) → ((((q.eventSeen=(0)) ∧ (q.outerSticky=(0))) ∧ (q.childSticky=(0))) ∧ (q.done=(0)))))
def initial : State := {scope:=(0), vmOpen:=(1), outerSticky:=(0), childSticky:=(0), childMerged:=(0), eventSeen:=(0), tclCode:=(0), diagnostic:=(0), done:=(0), delivered:=(0), origin:=(0), translated:=(0)}
def beginEvalGuard (q : State) : Prop := ((q.scope=(0)) ∧ (q.delivered=(0)))
def beginEvalNext (q : State) : State := {q with scope:=(1)}
def beginNestedGuard (q : State) : Prop := (((q.scope=(1)) ∧ (q.done=(0))) ∧ (q.delivered=(0)))
def beginNestedNext (q : State) : State := {q with scope:=(2), childSticky:=(0), childMerged:=(0)}
def recordOuterRefusalGuard (q : State) : Prop := (((q.scope=(1)) ∧ (q.done=(0))) ∧ (q.delivered=(0)))
def recordOuterRefusalNext (q : State) : State := {q with outerSticky:=(1), eventSeen:=(1)}
def recordChildRefusalGuard (q : State) : Prop := ((q.scope=(2)) ∧ (q.delivered=(0)))
def recordChildRefusalNext (q : State) : State := {q with childSticky:=(1), eventSeen:=(1)}
def publishOuterDiagnosticGuard (q : State) : Prop := ((((q.scope=(1)) ∧ (q.outerSticky=(1))) ∧ (q.done=(0))) ∧ (q.delivered=(0)))
def publishOuterDiagnosticNext (q : State) : State := {q with tclCode:=(1), diagnostic:=(1)}
def publishChildDiagnosticGuard (q : State) : Prop := (((q.scope=(2)) ∧ (q.childSticky=(1))) ∧ (q.delivered=(0)))
def publishChildDiagnosticNext (q : State) : State := {q with tclCode:=(1), diagnostic:=(1)}
def catchOrResetResultGuard (q : State) : Prop := (((q.tclCode=(1)) ∧ (q.done=(0))) ∧ (q.delivered=(0)))
def catchOrResetResultNext (q : State) : State := {q with tclCode:=(0), diagnostic:=(0)}
def ordinaryTclErrorGuard (q : State) : Prop := (((q.scope≥(1)) ∧ (q.done=(0))) ∧ (q.delivered=(0)))
def ordinaryTclErrorNext (q : State) : State := {q with tclCode:=(1)}
def mergeChildRefusalGuard (q : State) : Prop := (((q.scope=(2)) ∧ (q.childSticky=(1))) ∧ (q.delivered=(0)))
def mergeChildRefusalNext (q : State) : State := {q with outerSticky:=(1), childMerged:=(1)}
def popNestedGuard (q : State) : Prop := (((q.scope=(2)) ∧ (q.delivered=(0))) ∧ ((q.childSticky=(0)) ∨ (q.childMerged=(1))))
def popNestedNext (q : State) : State := {q with scope:=(1), childSticky:=(0), childMerged:=(0)}
def finishEvalGuard (q : State) : Prop := (((q.scope=(1)) ∧ (q.done=(0))) ∧ (q.delivered=(0)))
def finishEvalNext (q : State) : State := {q with done:=(1)}
def deliverRefusalGuard (q : State) : Prop := ((((q.scope=(1)) ∧ (q.done=(1))) ∧ (q.outerSticky=(1))) ∧ (q.delivered=(0)))
def deliverRefusalNext (q : State) : State := {q with delivered:=(1), origin:=(1)}
def deliverOrdinaryNativeErrorGuard (q : State) : Prop := (((((q.scope=(1)) ∧ (q.done=(1))) ∧ (q.outerSticky=(0))) ∧ (q.tclCode=(1))) ∧ (q.delivered=(0)))
def deliverOrdinaryNativeErrorNext (q : State) : State := {q with delivered:=(1), origin:=(2)}
def translateOrdinaryErrorGuard (q : State) : Prop := ((((((q.scope=(1)) ∧ (q.done=(1))) ∧ (q.outerSticky=(0))) ∧ (q.tclCode=(1))) ∧ (q.vmOpen=(1))) ∧ (q.delivered=(0)))
def translateOrdinaryErrorNext (q : State) : State := {q with delivered:=(1), origin:=(2), translated:=(1)}
def deliverSuccessGuard (q : State) : Prop := (((((q.scope=(1)) ∧ (q.done=(1))) ∧ (q.outerSticky=(0))) ∧ (q.tclCode=(0))) ∧ (q.delivered=(0)))
def deliverSuccessNext (q : State) : State := {q with delivered:=(1), origin:=(3)}
def closeVmGuard (q : State) : Prop := ((q.vmOpen=(1)) ∧ (q.delivered=(0)))
def closeVmNext (q : State) : State := {q with vmOpen:=(0)}
def resumeVmGuard (q : State) : Prop := ((q.vmOpen=(0)) ∧ (q.delivered=(0)))
def resumeVmNext (q : State) : State := {q with vmOpen:=(1)}
def Step (q r : State) : Prop := (beginEvalGuard q ∧ r=beginEvalNext q) ∨ (beginNestedGuard q ∧ r=beginNestedNext q) ∨ (recordOuterRefusalGuard q ∧ r=recordOuterRefusalNext q) ∨ (recordChildRefusalGuard q ∧ r=recordChildRefusalNext q) ∨ (publishOuterDiagnosticGuard q ∧ r=publishOuterDiagnosticNext q) ∨ (publishChildDiagnosticGuard q ∧ r=publishChildDiagnosticNext q) ∨ (catchOrResetResultGuard q ∧ r=catchOrResetResultNext q) ∨ (ordinaryTclErrorGuard q ∧ r=ordinaryTclErrorNext q) ∨ (mergeChildRefusalGuard q ∧ r=mergeChildRefusalNext q) ∨ (popNestedGuard q ∧ r=popNestedNext q) ∨ (finishEvalGuard q ∧ r=finishEvalNext q) ∨ (deliverRefusalGuard q ∧ r=deliverRefusalNext q) ∨ (deliverOrdinaryNativeErrorGuard q ∧ r=deliverOrdinaryNativeErrorNext q) ∨ (translateOrdinaryErrorGuard q ∧ r=translateOrdinaryErrorNext q) ∨ (deliverSuccessGuard q ∧ r=deliverSuccessNext q) ∨ (closeVmGuard q ∧ r=closeVmNext q) ∨ (resumeVmGuard q ∧ r=resumeVmNext q) ∨ r=q
end TclRefusalAst

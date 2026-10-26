import Std
namespace RestoreIssuerAst
set_option maxRecDepth 10000
structure State where
 intent : Int
 source : Int
 sourceRoot : Int
 pin : Int
 carrier : Int
 version : Int
 copiedVersion : Int
 guard : Int
 issued : Int
 marker : Int
 handoff : Int
 escrow : Int
 outer : Int
 reuses : Int
 allocations : Int
 rejected : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.intent≥(0)) ∧ (q.intent≤(5)) ∧ (q.source≥(0)) ∧ (q.source≤(3)) ∧ (q.sourceRoot≥(0)) ∧ (q.sourceRoot≤(1)) ∧ (q.pin≥(0)) ∧ (q.pin≤(1)) ∧ (q.carrier≥(0)) ∧ (q.carrier≤(1)) ∧ (q.guard≥(0)) ∧ (q.guard≤(5)) ∧ (q.issued≥(0)) ∧ (q.issued≤(1)) ∧ (q.marker≥(0)) ∧ (q.marker≤(1)) ∧ (q.handoff≥(0)) ∧ (q.handoff≤(1)) ∧ (q.escrow≥(0)) ∧ (q.escrow≤(1)) ∧ (q.outer≥(0)) ∧ (q.outer≤(1)) ∧ (q.version≥(0)) ∧ (q.copiedVersion≥(0)) ∧ (q.reuses≥(0)) ∧ (q.allocations≥(0)) ∧ (q.rejected≥(0)) ∧ ((q.guard>(0)) → (((q.issued=(1)) ∧ (q.carrier=(1))) ∧ ((q.intent=(1)) ∨ (q.intent=(4))))) ∧ ((q.issued=(1)) → (q.guard>(0))) ∧ ((q.carrier=(1)) → ((((q.source=(1)) ∨ (q.source=(2))) ∧ (q.copiedVersion=q.version)) ∧ ((q.intent=(1)) ∨ (q.intent=(4))))) ∧ ((q.pin=(1)) → (((q.sourceRoot=(1)) ∧ ((q.source=(1)) ∨ (q.source=(2)))) ∧ ((q.intent=(1)) ∨ (q.intent=(4))))) ∧ ((q.source=(0)) → (((q.sourceRoot=(0)) ∧ (q.carrier=(0))) ∧ (q.pin=(0)))) ∧ ((q.source=(3)) → (((q.sourceRoot=(0)) ∧ (q.carrier=(0))) ∧ (q.pin=(0)))) ∧ ((q.marker=(1)) → ((q.intent=(4)) ∧ (q.guard≥(2)))) ∧ ((q.handoff=(1)) → ((q.guard≥(2)) ∧ (q.carrier=(1)))) ∧ ((q.escrow=(1)) → ((q.carrier=(1)) ∧ (q.guard≠(5)))) ∧ ((q.guard=(5)) → ((q.marker=(0)) ∧ (q.outer=(1)))) ∧ ((q.outer=(1)) → (q.guard≥(3))) ∧ ((q.sourceRoot=(1)) → ((q.source=(1)) ∨ (q.source=(2)))) ∧ ((q.guard=(0)) → (q.handoff=(0))))
def initial : State := {intent:=(0), source:=(0), sourceRoot:=(0), pin:=(0), carrier:=(0), version:=(0), copiedVersion:=(0), guard:=(0), issued:=(0), marker:=(0), handoff:=(0), escrow:=(0), outer:=(0), reuses:=(0), allocations:=(0), rejected:=(0)}
def classifyFreshGuard (q : State) : Prop := (q.intent=(0)) ∧ (q.guard=(0))
def classifyFreshNext (q : State) : State := {q with intent:=(1)}
def classifyNavigationGuard (q : State) : Prop := (q.intent=(0)) ∧ (q.guard=(0))
def classifyNavigationNext (q : State) : State := {q with intent:=(2)}
def classifySchedulerGuard (q : State) : Prop := (q.intent=(0)) ∧ (q.guard=(0))
def classifySchedulerNext (q : State) : State := {q with intent:=(3)}
def classifyForeignGuard (q : State) : Prop := (q.intent=(0)) ∧ (q.guard=(0))
def classifyForeignNext (q : State) : State := {q with intent:=(4)}
def classifyConversionGuard (q : State) : Prop := (q.intent=(0)) ∧ (q.guard=(0))
def classifyConversionNext (q : State) : State := {q with intent:=(5)}
def sourceFrameGuard (q : State) : Prop := (q.source=(0)) ∧ (q.guard=(0))
def sourceFrameNext (q : State) : State := {q with source:=(1), sourceRoot:=(1)}
def sourceRcGuard (q : State) : Prop := (q.source=(0)) ∧ (q.guard=(0))
def sourceRcNext (q : State) : State := {q with source:=(2), sourceRoot:=(1)}
def sourceRawGuard (q : State) : Prop := (q.source=(0)) ∧ (q.guard=(0))
def sourceRawNext (q : State) : State := {q with source:=(3), sourceRoot:=(0)}
def pinSourceGuard (q : State) : Prop := (q.guard=(0)) ∧ (q.sourceRoot=(1)) ∧ ((q.intent=(1)) ∨ (q.intent=(4)))
def pinSourceNext (q : State) : State := {q with pin:=(1)}
def publishCarrierGuard (q : State) : Prop := (q.guard=(0)) ∧ (q.pin=(1)) ∧ (q.sourceRoot=(1))
def publishCarrierNext (q : State) : State := {q with carrier:=(1), copiedVersion:=q.version}
def gcSourceOnlyGuard (q : State) : Prop := (q.sourceRoot=(1)) ∧ (q.carrier=(0))
def gcSourceOnlyNext (q : State) : State := {q with version:=(q.version+(1))}
def gcPublishedGuard (q : State) : Prop := (q.carrier=(1))
def gcPublishedNext (q : State) : State := {q with version:=(q.version+(1)), copiedVersion:=q.copiedVersion}
def reserveGuardGuard (q : State) : Prop := (q.guard=(0)) ∧ (q.carrier=(1))
def reserveGuardNext (q : State) : State := {q with guard:=(1), issued:=(1), allocations:=(q.allocations+(1))}
def guardAllocationFailsGuard (q : State) : Prop := (q.guard=(0)) ∧ (q.carrier=(1))
def guardAllocationFailsNext (q : State) : State := {q with escrow:=(1)}
def publishGuardGuard (q : State) : Prop := (q.guard=(1))
def publishGuardNext (q : State) : State := {q with guard:=(2), escrow:=(0)}
def releaseSourceGuard (q : State) : Prop := (q.guard≥(2)) ∧ (q.sourceRoot=(1))
def releaseSourceNext (q : State) : State := {q with sourceRoot:=(0), pin:=(0), handoff:=(1)}
def allocateMarkerGuard (q : State) : Prop := (q.guard=(2)) ∧ (q.intent=(4)) ∧ (q.marker=(0))
def allocateMarkerNext (q : State) : State := {q with marker:=(1), allocations:=(q.allocations+(1))}
def enterGuard (q : State) : Prop := (q.guard=(2)) ∧ ((q.intent=(1)) ∨ (q.marker=(1)))
def enterNext (q : State) : State := {q with guard:=(3)}
def exceptionToOwnerGuard (q : State) : Prop := (q.guard≥(1)) ∧ (q.guard≤(3))
def exceptionToOwnerNext (q : State) : State := {q with guard:=(4), escrow:=(1)}
def observeOuterGuard (q : State) : Prop := ((q.guard=(3)) ∨ (q.guard=(4)))
def observeOuterNext (q : State) : State := {q with outer:=(1)}
def killMarkerGuard (q : State) : Prop := (q.outer=(1)) ∧ (q.marker=(1))
def killMarkerNext (q : State) : State := {q with marker:=(0)}
def completeGuard (q : State) : Prop := ((q.guard=(3)) ∨ (q.guard=(4))) ∧ (q.outer=(1)) ∧ (q.marker=(0))
def completeNext (q : State) : State := {q with guard:=(5), escrow:=(0)}
def reuseExistingGuard (q : State) : Prop := (q.guard=(0)) ∧ (q.sourceRoot=(1)) ∧ (((q.intent=(2)) ∨ (q.intent=(3))) ∨ (q.intent=(5)))
def reuseExistingNext (q : State) : State := {q with reuses:=(q.reuses+(1))}
def rejectRawGuard (q : State) : Prop := (q.source=(3)) ∧ (q.guard=(0))
def rejectRawNext (q : State) : State := {q with rejected:=(q.rejected+(1))}
def recoverPreAdmissionGuard (q : State) : Prop := (q.guard=(0)) ∧ (q.escrow=(1)) ∧ (q.sourceRoot=(1))
def recoverPreAdmissionNext (q : State) : State := {q with carrier:=(0), escrow:=(0), copiedVersion:=(0)}
def Step (q r : State) : Prop := (classifyFreshGuard q ∧ r=classifyFreshNext q) ∨ (classifyNavigationGuard q ∧ r=classifyNavigationNext q) ∨ (classifySchedulerGuard q ∧ r=classifySchedulerNext q) ∨ (classifyForeignGuard q ∧ r=classifyForeignNext q) ∨ (classifyConversionGuard q ∧ r=classifyConversionNext q) ∨ (sourceFrameGuard q ∧ r=sourceFrameNext q) ∨ (sourceRcGuard q ∧ r=sourceRcNext q) ∨ (sourceRawGuard q ∧ r=sourceRawNext q) ∨ (pinSourceGuard q ∧ r=pinSourceNext q) ∨ (publishCarrierGuard q ∧ r=publishCarrierNext q) ∨ (gcSourceOnlyGuard q ∧ r=gcSourceOnlyNext q) ∨ (gcPublishedGuard q ∧ r=gcPublishedNext q) ∨ (reserveGuardGuard q ∧ r=reserveGuardNext q) ∨ (guardAllocationFailsGuard q ∧ r=guardAllocationFailsNext q) ∨ (publishGuardGuard q ∧ r=publishGuardNext q) ∨ (releaseSourceGuard q ∧ r=releaseSourceNext q) ∨ (allocateMarkerGuard q ∧ r=allocateMarkerNext q) ∨ (enterGuard q ∧ r=enterNext q) ∨ (exceptionToOwnerGuard q ∧ r=exceptionToOwnerNext q) ∨ (observeOuterGuard q ∧ r=observeOuterNext q) ∨ (killMarkerGuard q ∧ r=killMarkerNext q) ∨ (completeGuard q ∧ r=completeNext q) ∨ (reuseExistingGuard q ∧ r=reuseExistingNext q) ∨ (rejectRawGuard q ∧ r=rejectRawNext q) ∨ (recoverPreAdmissionGuard q ∧ r=recoverPreAdmissionNext q) ∨ r=q
end RestoreIssuerAst

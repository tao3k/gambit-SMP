import Std
namespace BindingObserverAst
set_option maxRecDepth 10000
structure State where
 stage : Int
 mode : Int
 writers : Int
 demand : Int
 epoch : Int
 planEpoch : Int
 depth : Int
 observerSafe : Bool
 first : Bool
 second : Bool
 custody : Bool
 errorSeen : Bool
 stable : Bool
 closed : Bool
 receipt : Bool
 captured : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.stage≥(0)) ∧ (q.stage≤(5)) ∧ (q.mode≥(0)) ∧ (q.mode≤(2)) ∧ (q.writers≥(0)) ∧ (q.writers≤(2)) ∧ (q.demand≥(0)) ∧ (q.demand≤(2)) ∧ (q.epoch≥(1)) ∧ (q.planEpoch≥(0)) ∧ (q.depth≥(0)) ∧ ((q.stage≥(1)) → ((q.custody=true) ∧ (q.mode≥(1)))) ∧ ((q.first=true) → ((q.stage≥(2)) ∧ (q.custody=true))) ∧ ((q.second=true) → ((q.stage≥(3)) ∧ (q.first=true))) ∧ ((q.stage=(2)) → (q.first=true)) ∧ (((q.stage=(3)) ∨ (q.stage=(4))) → (q.second=true)) ∧ ((q.closed=true) → ((q.stage≥(3)) ∧ (q.second=true))) ∧ ((q.mode=(1)) → ((q.observerSafe=true) ∧ (q.writers=(0)))) ∧ (((q.stage≥(1)) ∧ (q.stable=true)) → (q.planEpoch=q.epoch)) ∧ ((q.depth>(0)) → (q.stage=(2))) ∧ ((((q.stage=(3)) ∨ (q.stage=(4))) ∧ (q.mode=(2))) → (q.demand=(1))) ∧ ((q.captured=true) → (q.custody=true)) ∧ ((q.receipt=true) → (((((((q.stage=(4)) ∧ (q.closed=true)) ∧ (¬(q.errorSeen=true))) ∧ (q.stable=true)) ∧ (q.depth=(0))) ∧ (q.planEpoch=q.epoch)) ∧ (¬(q.captured=true)))) ∧ ((q.stage=(4)) → (q.receipt=true)))
def initial : State := {stage:=(0), mode:=(0), writers:=(0), demand:=(0), epoch:=(1), planEpoch:=(0), depth:=(0), observerSafe:=false, first:=false, second:=false, custody:=false, errorSeen:=false, stable:=true, closed:=false, receipt:=false, captured:=false}
def plainProfileGuard (q : State) : Prop := (q.stage=(0))
def plainProfileNext (q : State) : State := {q with mode:=(1), writers:=(0), observerSafe:=true}
def useOnlyProfileGuard (q : State) : Prop := (q.stage=(0))
def useOnlyProfileNext (q : State) : State := {q with mode:=(2), writers:=(1), observerSafe:=false}
def rawProfileGuard (q : State) : Prop := (q.stage=(0))
def rawProfileNext (q : State) : State := {q with mode:=(2), writers:=(2), observerSafe:=false}
def sealGuard (q : State) : Prop := (q.stage=(0)) ∧ (q.mode≥(1)) ∧ (q.mode≤(2))
def sealNext (q : State) : State := {q with stage:=(1), custody:=true, planEpoch:=q.epoch}
def firstElideGuard (q : State) : Prop := (q.stage=(1)) ∧ (q.mode=(1)) ∧ (q.observerSafe=true) ∧ (q.stable=true) ∧ (q.planEpoch=q.epoch)
def firstElideNext (q : State) : State := {q with stage:=(2), first:=true}
def firstRetainGuard (q : State) : Prop := (q.stage=(1)) ∧ (q.mode=(2)) ∧ (q.stable=true) ∧ (q.planEpoch=q.epoch)
def firstRetainNext (q : State) : State := {q with stage:=(2), first:=true, demand:=(1)}
def enterFormatterGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(0)) ∧ (q.stable=true)
def enterFormatterNext (q : State) : State := {q with depth:=(q.depth+(1))}
def enterIOHandlerGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(0)) ∧ (q.stable=true) ∧ (q.errorSeen=true)
def enterIOHandlerNext (q : State) : State := {q with depth:=(q.depth+(1))}
def enterTimeoutGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(0)) ∧ (q.stable=true)
def enterTimeoutNext (q : State) : State := {q with depth:=(q.depth+(1))}
def enterGCGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(0)) ∧ (q.stable=true)
def enterGCNext (q : State) : State := {q with depth:=(q.depth+(1))}
def readObserverGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(1)) ∧ (q.mode=(2))
def readObserverNext (q : State) : State := {q with demand:=q.demand}
def namedDemandGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(1)) ∧ (q.writers≥(1)) ∧ (q.stable=true)
def namedDemandNext (q : State) : State := {q with demand:=(1)}
def namedSupplyGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(1)) ∧ (q.writers≥(1)) ∧ (q.stable=true)
def namedSupplyNext (q : State) : State := {q with demand:=q.demand}
def rawWriteGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(1)) ∧ (q.writers=(2)) ∧ (q.stable=true)
def rawWriteNext (q : State) : State := {q with demand:=(2)}
def leaveHookGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(1)) ∧ (q.stable=true)
def leaveHookNext (q : State) : State := {q with depth:=(q.depth-(1))}
def secondReadonlyGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.mode=(2)) ∧ (q.demand=(1)) ∧ (q.depth=(0)) ∧ (q.stable=true) ∧ (q.planEpoch=q.epoch)
def secondReadonlyNext (q : State) : State := {q with stage:=(3), second:=true}
def secondUnobservedGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.mode=(1)) ∧ (q.observerSafe=true) ∧ (q.depth=(0)) ∧ (q.stable=true) ∧ (q.planEpoch=q.epoch)
def secondUnobservedNext (q : State) : State := {q with stage:=(3), second:=true}
def secondNormalizeGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.mode=(2)) ∧ (q.depth=(0)) ∧ (q.stable=true) ∧ (q.planEpoch=q.epoch)
def secondNormalizeNext (q : State) : State := {q with stage:=(3), second:=true, demand:=(1)}
def ioFailureGuard (q : State) : Prop := (q.stage≥(1)) ∧ (q.stage≤(3))
def ioFailureNext (q : State) : State := {q with errorSeen:=true}
def compilerAbortGuard (q : State) : Prop := (q.stage≥(1)) ∧ (q.stage≤(3))
def compilerAbortNext (q : State) : State := {q with stage:=(5), depth:=(0), errorSeen:=true}
def nestedCompilationGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(1))
def nestedCompilationNext (q : State) : State := {q with epoch:=(q.epoch+(1)), stable:=false}
def rejectStaleGuard (q : State) : Prop := (q.stage=(2)) ∧ (¬(q.stable=true))
def rejectStaleNext (q : State) : State := {q with stage:=(5), depth:=(0)}
def captureGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(1))
def captureNext (q : State) : State := {q with captured:=true}
def resumeCapturedGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(1)) ∧ (q.captured=true) ∧ (q.stable=true) ∧ (q.planEpoch=q.epoch)
def resumeCapturedNext (q : State) : State := {q with demand:=q.demand}
def certifyNoResumeGuard (q : State) : Prop := (q.stage=(3)) ∧ (q.captured=true)
def certifyNoResumeNext (q : State) : State := {q with captured:=false}
def closeOutputGuard (q : State) : Prop := (q.stage=(3)) ∧ (q.stable=true) ∧ (q.depth=(0)) ∧ (q.planEpoch=q.epoch)
def closeOutputNext (q : State) : State := {q with closed:=true}
def issueGuard (q : State) : Prop := (q.stage=(3)) ∧ (q.closed=true) ∧ (q.stable=true) ∧ (q.depth=(0)) ∧ (q.planEpoch=q.epoch) ∧ True ∧ (¬(q.captured=true))
def issueNext (q : State) : State := {q with stage:=(4), receipt:=true}
def unknownExitGuard (q : State) : Prop := (q.stage≥(1)) ∧ (q.stage≤(3))
def unknownExitNext (q : State) : State := {q with stage:=(5), depth:=(0)}
def debugScalarPassGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.depth≥(1))
def debugScalarPassNext (q : State) : State := {q with demand:=q.demand}
def Step (q r : State) : Prop := (plainProfileGuard q ∧ r=plainProfileNext q) ∨ (useOnlyProfileGuard q ∧ r=useOnlyProfileNext q) ∨ (rawProfileGuard q ∧ r=rawProfileNext q) ∨ (sealGuard q ∧ r=sealNext q) ∨ (firstElideGuard q ∧ r=firstElideNext q) ∨ (firstRetainGuard q ∧ r=firstRetainNext q) ∨ (enterFormatterGuard q ∧ r=enterFormatterNext q) ∨ (enterIOHandlerGuard q ∧ r=enterIOHandlerNext q) ∨ (enterTimeoutGuard q ∧ r=enterTimeoutNext q) ∨ (enterGCGuard q ∧ r=enterGCNext q) ∨ (readObserverGuard q ∧ r=readObserverNext q) ∨ (namedDemandGuard q ∧ r=namedDemandNext q) ∨ (namedSupplyGuard q ∧ r=namedSupplyNext q) ∨ (rawWriteGuard q ∧ r=rawWriteNext q) ∨ (leaveHookGuard q ∧ r=leaveHookNext q) ∨ (secondReadonlyGuard q ∧ r=secondReadonlyNext q) ∨ (secondUnobservedGuard q ∧ r=secondUnobservedNext q) ∨ (secondNormalizeGuard q ∧ r=secondNormalizeNext q) ∨ (ioFailureGuard q ∧ r=ioFailureNext q) ∨ (compilerAbortGuard q ∧ r=compilerAbortNext q) ∨ (nestedCompilationGuard q ∧ r=nestedCompilationNext q) ∨ (rejectStaleGuard q ∧ r=rejectStaleNext q) ∨ (captureGuard q ∧ r=captureNext q) ∨ (resumeCapturedGuard q ∧ r=resumeCapturedNext q) ∨ (certifyNoResumeGuard q ∧ r=certifyNoResumeNext q) ∨ (closeOutputGuard q ∧ r=closeOutputNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (unknownExitGuard q ∧ r=unknownExitNext q) ∨ (debugScalarPassGuard q ∧ r=debugScalarPassNext q) ∨ r=q
end BindingObserverAst

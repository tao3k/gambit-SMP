import Std
namespace NativeBindingPlanAst
set_option maxRecDepth 10000
structure State where
 stage : Int
 epoch : Int
 planEpoch : Int
 mode : Int
 demand : Int
 headerDemand : Int
 prmCount : Int
 gloCount : Int
 entry : Bool
 layout : Bool
 exclusive : Bool
 noObservers : Bool
 sealed : Bool
 first : Bool
 second : Bool
 prm : Bool
 glo : Bool
 paused : Bool
 revoked : Bool
 custody : Bool
 closed : Bool
 receipt : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.stage≥(0)) ∧ (q.stage≤(6)) ∧ (q.epoch≥(1)) ∧ (q.planEpoch≥(0)) ∧ (q.mode≥(0)) ∧ (q.mode≤(2)) ∧ (q.demand≥(0)) ∧ (q.demand≤(2)) ∧ (q.headerDemand≥(0)) ∧ (q.headerDemand≤(2)) ∧ (q.prmCount≥(0)) ∧ (q.prmCount≤(1)) ∧ (q.gloCount≥(0)) ∧ (q.gloCount≤(1)) ∧ ((q.sealed=true) → (((((q.stage≥(2)) ∧ (q.entry=true)) ∧ (q.layout=true)) ∧ (q.custody=true)) ∧ (q.mode≥(1)))) ∧ ((q.stage≥(2)) → (q.sealed=true)) ∧ (((q.sealed=true) ∧ (¬(q.revoked=true))) → ((q.planEpoch=q.epoch) ∧ (q.exclusive=true))) ∧ ((q.first=true) → (q.sealed=true)) ∧ ((q.second=true) → ((q.prm=true) ∧ (q.first=true))) ∧ ((q.prm=true) → ((q.first=true) ∧ (q.prmCount=(1)))) ∧ ((q.glo=true) → ((q.second=true) ∧ (q.gloCount=(1)))) ∧ ((q.prmCount=(1)) → (q.prm=true)) ∧ ((q.gloCount=(1)) → (q.glo=true)) ∧ ((q.closed=true) → (q.glo=true)) ∧ ((((q.first=true) ∧ (q.mode=(1))) ∧ (¬(q.revoked=true))) → (q.noObservers=true)) ∧ ((((q.first=true) ∧ (q.mode=(2))) ∧ (¬(q.revoked=true))) → (q.demand=(1))) ∧ ((q.receipt=true) → (((((q.stage=(5)) ∧ (q.closed=true)) ∧ (q.glo=true)) ∧ (¬(q.revoked=true))) ∧ (¬(q.paused=true)))) ∧ ((q.stage=(5)) → (q.receipt=true)) ∧ ((q.prm=true) → (q.stage≥(3))) ∧ ((q.glo=true) → (q.stage≥(4))) ∧ (((q.stage≥(3)) ∧ (q.stage≤(5))) → (q.prm=true)) ∧ (((q.stage≥(4)) ∧ (q.stage≤(5))) → (q.glo=true)))
def initial : State := {stage:=(0), epoch:=(1), planEpoch:=(0), mode:=(0), demand:=(0), headerDemand:=(0), prmCount:=(0), gloCount:=(0), entry:=false, layout:=false, exclusive:=false, noObservers:=false, sealed:=false, first:=false, second:=false, prm:=false, glo:=false, paused:=false, revoked:=false, custody:=false, closed:=false, receipt:=false}
def discoverGuard (q : State) : Prop := (q.stage=(0))
def discoverNext (q : State) : State := {q with entry:=true}
def resolveGuard (q : State) : Prop := (q.stage=(0)) ∧ (q.entry=true)
def resolveNext (q : State) : State := {q with layout:=true}
def closeWritersGuard (q : State) : Prop := (q.stage=(0))
def closeWritersNext (q : State) : State := {q with exclusive:=true}
def admitElisionGuard (q : State) : Prop := (q.stage=(0))
def admitElisionNext (q : State) : State := {q with mode:=(1), noObservers:=true}
def requireMetadataGuard (q : State) : Prop := (q.stage=(0))
def requireMetadataNext (q : State) : State := {q with mode:=(2), noObservers:=false}
def writeHeaderGuard (q : State) : Prop := (q.stage=(0)) ∧ (q.entry=true)
def writeHeaderNext (q : State) : State := {q with stage:=(1), headerDemand:=q.demand}
def sealPlanGuard (q : State) : Prop := (q.stage=(1)) ∧ (q.entry=true) ∧ (q.layout=true) ∧ (q.exclusive=true) ∧ (q.mode≥(1)) ∧ (q.mode≤(2))
def sealPlanNext (q : State) : State := {q with stage:=(2), sealed:=true, planEpoch:=q.epoch, custody:=true}
def firstElideGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.mode=(1)) ∧ (q.noObservers=true) ∧ (q.exclusive=true) ∧ (q.planEpoch=q.epoch) ∧ (¬(q.revoked=true)) ∧ (¬(q.paused=true)) ∧ (¬(q.first=true))
def firstElideNext (q : State) : State := {q with first:=true}
def firstPreserveGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.mode=(2)) ∧ (q.exclusive=true) ∧ (q.planEpoch=q.epoch) ∧ (¬(q.revoked=true)) ∧ (¬(q.paused=true)) ∧ (¬(q.first=true))
def firstPreserveNext (q : State) : State := {q with first:=true, demand:=(1)}
def emitPrmGuard (q : State) : Prop := (q.stage=(2)) ∧ (q.first=true) ∧ (q.exclusive=true) ∧ (q.planEpoch=q.epoch) ∧ (¬(q.revoked=true)) ∧ (¬(q.paused=true))
def emitPrmNext (q : State) : State := {q with stage:=(3), prm:=true, prmCount:=(q.prmCount+(1))}
def secondElideGuard (q : State) : Prop := (q.stage=(3)) ∧ (q.mode=(1)) ∧ (q.noObservers=true) ∧ (q.exclusive=true) ∧ (q.planEpoch=q.epoch) ∧ (¬(q.revoked=true)) ∧ (¬(q.paused=true))
def secondElideNext (q : State) : State := {q with second:=true}
def secondPreserveGuard (q : State) : Prop := (q.stage=(3)) ∧ (q.mode=(2)) ∧ (q.exclusive=true) ∧ (q.planEpoch=q.epoch) ∧ (¬(q.revoked=true)) ∧ (¬(q.paused=true))
def secondPreserveNext (q : State) : State := {q with second:=true, demand:=(1)}
def emitGloGuard (q : State) : Prop := (q.stage=(3)) ∧ (q.second=true) ∧ (q.exclusive=true) ∧ (q.planEpoch=q.epoch) ∧ (¬(q.revoked=true)) ∧ (¬(q.paused=true))
def emitGloNext (q : State) : State := {q with stage:=(4), glo:=true, gloCount:=(q.gloCount+(1))}
def closeOutputGuard (q : State) : Prop := (q.stage=(4)) ∧ (q.glo=true) ∧ (q.exclusive=true) ∧ (q.planEpoch=q.epoch) ∧ (¬(q.revoked=true)) ∧ (¬(q.paused=true))
def closeOutputNext (q : State) : State := {q with closed:=true}
def issueGuard (q : State) : Prop := (q.stage=(4)) ∧ True ∧ (q.exclusive=true) ∧ (q.planEpoch=q.epoch) ∧ (¬(q.revoked=true)) ∧ (¬(q.paused=true))
def issueNext (q : State) : State := {q with stage:=(5), receipt:=true}
def pauseGuard (q : State) : Prop := (q.stage≥(2)) ∧ (q.stage≤(4)) ∧ (¬(q.paused=true))
def pauseNext (q : State) : State := {q with paused:=true}
def resumeSameGuard (q : State) : Prop := (q.stage≥(2)) ∧ (q.stage≤(4)) ∧ (q.paused=true) ∧ (q.planEpoch=q.epoch) ∧ (q.exclusive=true) ∧ (¬(q.revoked=true))
def resumeSameNext (q : State) : State := {q with paused:=false}
def foreignReentryGuard (q : State) : Prop := (q.stage≥(2)) ∧ (q.stage≤(4)) ∧ (q.paused=true)
def foreignReentryNext (q : State) : State := {q with epoch:=(q.epoch+(1)), revoked:=true}
def lateWriterGuard (q : State) : Prop := (q.stage≥(2)) ∧ (q.stage≤(4))
def lateWriterNext (q : State) : State := {q with demand:=(2), exclusive:=false, revoked:=true}
def escapedObserverGuard (q : State) : Prop := (q.stage≥(2)) ∧ (q.stage≤(4))
def escapedObserverNext (q : State) : State := {q with noObservers:=false, revoked:=true}
def unknownExitGuard (q : State) : Prop := (q.stage≥(2)) ∧ (q.stage≤(4))
def unknownExitNext (q : State) : State := {q with stage:=(6), paused:=false, revoked:=true}
def rejectResumeGuard (q : State) : Prop := (q.stage≥(2)) ∧ (q.stage≤(4)) ∧ (q.paused=true) ∧ (q.revoked=true)
def rejectResumeNext (q : State) : State := {q with stage:=(6), paused:=false}
def Step (q r : State) : Prop := (discoverGuard q ∧ r=discoverNext q) ∨ (resolveGuard q ∧ r=resolveNext q) ∨ (closeWritersGuard q ∧ r=closeWritersNext q) ∨ (admitElisionGuard q ∧ r=admitElisionNext q) ∨ (requireMetadataGuard q ∧ r=requireMetadataNext q) ∨ (writeHeaderGuard q ∧ r=writeHeaderNext q) ∨ (sealPlanGuard q ∧ r=sealPlanNext q) ∨ (firstElideGuard q ∧ r=firstElideNext q) ∨ (firstPreserveGuard q ∧ r=firstPreserveNext q) ∨ (emitPrmGuard q ∧ r=emitPrmNext q) ∨ (secondElideGuard q ∧ r=secondElideNext q) ∨ (secondPreserveGuard q ∧ r=secondPreserveNext q) ∨ (emitGloGuard q ∧ r=emitGloNext q) ∨ (closeOutputGuard q ∧ r=closeOutputNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (pauseGuard q ∧ r=pauseNext q) ∨ (resumeSameGuard q ∧ r=resumeSameNext q) ∨ (foreignReentryGuard q ∧ r=foreignReentryNext q) ∨ (lateWriterGuard q ∧ r=lateWriterNext q) ∨ (escapedObserverGuard q ∧ r=escapedObserverNext q) ∨ (unknownExitGuard q ∧ r=unknownExitNext q) ∨ (rejectResumeGuard q ∧ r=rejectResumeNext q) ∨ r=q
end NativeBindingPlanAst

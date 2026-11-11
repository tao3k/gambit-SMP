import Std
namespace WillDrainAst
set_option maxRecDepth 10000
structure State where
 weak : Int
 ready : Int
 claimed : Int
 loaded : Int
 runnable : Int
 active : Int
 unknown : Int
 pins : Int
 captures : Int
 created : Int
 retired : Int
 epoch : Int
 sealedEpoch : Int
 uses : Int
 closed : Bool
 mapped : Bool
 aliases : Bool
 issued : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.weak≥(0)) ∧ (q.ready≥(0)) ∧ (q.claimed≥(0)) ∧ (q.loaded≥(0)) ∧ (q.runnable≥(0)) ∧ (q.active≥(0)) ∧ (q.unknown≥(0)) ∧ (q.pins≥(0)) ∧ (q.captures≥(0)) ∧ (q.created≥(0)) ∧ (q.retired≥(0)) ∧ (q.epoch≥(0)) ∧ (q.sealedEpoch≥(0)) ∧ (q.uses≥(0)) ∧ (q.epoch≥(1)) ∧ (q.retired≤q.created) ∧ ((q.created-q.retired)=((((((q.weak+q.ready)+q.claimed)+q.loaded)+q.runnable)+q.active)+q.unknown)) ∧ ((q.issued=true) → (((((((((((((q.closed=true) ∧ (q.mapped=true)) ∧ (q.aliases=true)) ∧ (q.sealedEpoch=q.epoch)) ∧ (q.weak=(0))) ∧ (q.ready=(0))) ∧ (q.claimed=(0))) ∧ (q.loaded=(0))) ∧ (q.runnable=(0))) ∧ (q.active=(0))) ∧ (q.unknown=(0))) ∧ (q.pins=(0))) ∧ (q.captures=(0)))))
def initial : State := {weak:=(0), ready:=(0), claimed:=(0), loaded:=(0), runnable:=(0), active:=(0), unknown:=(0), pins:=(0), captures:=(0), created:=(0), retired:=(0), epoch:=(1), sealedEpoch:=(0), uses:=(0), closed:=false, mapped:=false, aliases:=false, issued:=false}
def reserveExternalGuard (q : State) : Prop := (¬(q.closed=true))
def reserveExternalNext (q : State) : State := {q with pins:=(q.pins+(1))}
def reserveChildGuard (q : State) : Prop := (q.active>(0))
def reserveChildNext (q : State) : State := {q with pins:=(q.pins+(1))}
def commitWillGuard (q : State) : Prop := (q.pins>(0))
def commitWillNext (q : State) : State := {q with pins:=(q.pins-(1)), weak:=(q.weak+(1)), created:=(q.created+(1)), epoch:=(q.epoch+(1)), issued:=false, aliases:=false}
def abortReservationGuard (q : State) : Prop := (q.pins>(0))
def abortReservationNext (q : State) : State := {q with pins:=(q.pins-(1))}
def unknownCommitGuard (q : State) : Prop := (q.pins>(0))
def unknownCommitNext (q : State) : State := {q with pins:=(q.pins-(1)), unknown:=(q.unknown+(1)), created:=(q.created+(1)), epoch:=(q.epoch+(1)), issued:=false, aliases:=false}
def closeExternalGuard (q : State) : Prop := (¬(q.closed=true))
def closeExternalNext (q : State) : State := {q with closed:=true}
def makeExecutableGuard (q : State) : Prop := (q.weak>(0))
def makeExecutableNext (q : State) : State := {q with weak:=(q.weak-(1)), ready:=(q.ready+(1))}
def dequeueGuard (q : State) : Prop := (q.ready>(0))
def dequeueNext (q : State) : State := {q with ready:=(q.ready-(1)), claimed:=(q.claimed+(1))}
def loadOperandsGuard (q : State) : Prop := (q.claimed>(0))
def loadOperandsNext (q : State) : State := {q with claimed:=(q.claimed-(1)), loaded:=(q.loaded+(1))}
def zapWillFieldsGuard (q : State) : Prop := (q.loaded>(0))
def zapWillFieldsNext (q : State) : State := {q with loaded:=(q.loaded-(1)), runnable:=(q.runnable+(1))}
def enterActionGuard (q : State) : Prop := (q.runnable>(0))
def enterActionNext (q : State) : State := {q with runnable:=(q.runnable-(1)), active:=(q.active+(1))}
def captureGuard (q : State) : Prop := (q.active>(0))
def captureNext (q : State) : State := {q with captures:=(q.captures+(1))}
def returnActionGuard (q : State) : Prop := (q.active>(0))
def returnActionNext (q : State) : State := {q with active:=(q.active-(1)), retired:=(q.retired+(1))}
def escapeActionGuard (q : State) : Prop := (q.active>(0))
def escapeActionNext (q : State) : State := {q with active:=(q.active-(1)), unknown:=(q.unknown+(1))}
def resumeCaptureGuard (q : State) : Prop := (q.captures>(0))
def resumeCaptureNext (q : State) : State := {q with active:=(q.active+(1)), created:=(q.created+(1)), epoch:=(q.epoch+(1)), issued:=false, aliases:=false}
def retireOneCaptureGuard (q : State) : Prop := (q.captures>(0))
def retireOneCaptureNext (q : State) : State := {q with captures:=(q.captures-(1))}
def resolveUnknownDoneGuard (q : State) : Prop := (q.unknown>(0))
def resolveUnknownDoneNext (q : State) : State := {q with unknown:=(q.unknown-(1)), retired:=(q.retired+(1))}
def resolveUnknownReadyGuard (q : State) : Prop := (q.unknown>(0))
def resolveUnknownReadyNext (q : State) : State := {q with unknown:=(q.unknown-(1)), ready:=(q.ready+(1))}
def attestRootMapsGuard (q : State) : Prop := True
def attestRootMapsNext (q : State) : State := {q with mapped:=true}
def attestAliasClosureGuard (q : State) : Prop := (q.closed=true) ∧ (q.weak=(0)) ∧ (q.ready=(0)) ∧ (q.claimed=(0)) ∧ (q.loaded=(0)) ∧ (q.runnable=(0)) ∧ (q.active=(0)) ∧ (q.unknown=(0)) ∧ (q.pins=(0)) ∧ (q.captures=(0))
def attestAliasClosureNext (q : State) : State := {q with aliases:=true}
def issueGuard (q : State) : Prop := (q.closed=true) ∧ (q.mapped=true) ∧ (q.aliases=true) ∧ True ∧ (q.ready=(0)) ∧ (q.claimed=(0)) ∧ (q.loaded=(0)) ∧ (q.runnable=(0)) ∧ (q.active=(0)) ∧ (q.unknown=(0)) ∧ (q.pins=(0)) ∧ (q.captures=(0))
def issueNext (q : State) : State := {q with issued:=true, sealedEpoch:=q.epoch}
def reuseGuard (q : State) : Prop := (q.issued=true) ∧ (q.sealedEpoch=q.epoch)
def reuseNext (q : State) : State := {q with uses:=(q.uses+(1))}
def unmanagedInterferenceGuard (q : State) : Prop := True
def unmanagedInterferenceNext (q : State) : State := {q with epoch:=(q.epoch+(1)), aliases:=false, issued:=false}
def Step (q r : State) : Prop := (reserveExternalGuard q ∧ r=reserveExternalNext q) ∨ (reserveChildGuard q ∧ r=reserveChildNext q) ∨ (commitWillGuard q ∧ r=commitWillNext q) ∨ (abortReservationGuard q ∧ r=abortReservationNext q) ∨ (unknownCommitGuard q ∧ r=unknownCommitNext q) ∨ (closeExternalGuard q ∧ r=closeExternalNext q) ∨ (makeExecutableGuard q ∧ r=makeExecutableNext q) ∨ (dequeueGuard q ∧ r=dequeueNext q) ∨ (loadOperandsGuard q ∧ r=loadOperandsNext q) ∨ (zapWillFieldsGuard q ∧ r=zapWillFieldsNext q) ∨ (enterActionGuard q ∧ r=enterActionNext q) ∨ (captureGuard q ∧ r=captureNext q) ∨ (returnActionGuard q ∧ r=returnActionNext q) ∨ (escapeActionGuard q ∧ r=escapeActionNext q) ∨ (resumeCaptureGuard q ∧ r=resumeCaptureNext q) ∨ (retireOneCaptureGuard q ∧ r=retireOneCaptureNext q) ∨ (resolveUnknownDoneGuard q ∧ r=resolveUnknownDoneNext q) ∨ (resolveUnknownReadyGuard q ∧ r=resolveUnknownReadyNext q) ∨ (attestRootMapsGuard q ∧ r=attestRootMapsNext q) ∨ (attestAliasClosureGuard q ∧ r=attestAliasClosureNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (reuseGuard q ∧ r=reuseNext q) ∨ (unmanagedInterferenceGuard q ∧ r=unmanagedInterferenceNext q) ∨ r=q
end WillDrainAst

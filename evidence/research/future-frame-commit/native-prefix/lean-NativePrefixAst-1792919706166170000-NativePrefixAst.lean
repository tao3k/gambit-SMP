import Std
namespace NativePrefixAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 profile : Int
 identity : Int
 bindingEpoch : Int
 sealEpoch : Int
 fast : Int
 durable : Int
 sourceRoot : Int
 carrierRoot : Int
 intent : Int
 allocation : Int
 recorded : Int
 hook : Int
 unknown : Int
 custodian : Int
 epoch : Int
 rootEpoch : Int
 localEpoch : Int
 gate : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(9)) ∧ (q.profile≥(0)) ∧ (q.profile≤(6)) ∧ (q.custodian≥(0)) ∧ (q.custodian≤(3)) ∧ (q.epoch≥(0)) ∧ (q.rootEpoch≥(0)) ∧ (q.rootEpoch≤q.epoch) ∧ (q.localEpoch≥(0)) ∧ (q.localEpoch≤q.epoch) ∧ (q.identity≥(0)) ∧ (q.identity≤(1)) ∧ (q.bindingEpoch≥(0)) ∧ (q.bindingEpoch≤(1)) ∧ (q.sealEpoch≥(0)) ∧ (q.sealEpoch≤(1)) ∧ (q.fast≥(0)) ∧ (q.fast≤(1)) ∧ (q.durable≥(0)) ∧ (q.durable≤(1)) ∧ (q.sourceRoot≥(0)) ∧ (q.sourceRoot≤(1)) ∧ (q.carrierRoot≥(0)) ∧ (q.carrierRoot≤(1)) ∧ (q.intent≥(0)) ∧ (q.intent≤(1)) ∧ (q.allocation≥(0)) ∧ (q.allocation≤(1)) ∧ (q.recorded≥(0)) ∧ (q.recorded≤(1)) ∧ (q.hook≥(0)) ∧ (q.hook≤(1)) ∧ (q.unknown≥(0)) ∧ (q.unknown≤(1)) ∧ (q.gate≥(0)) ∧ (q.gate≤(1)) ∧ ((q.phase≤(1)) → ((q.fast=(0)) ∧ (q.durable=(0)) ∧ (q.sourceRoot=(0)) ∧ (q.carrierRoot=(0)) ∧ (q.intent=(0)) ∧ (q.allocation=(0)) ∧ (q.recorded=(0)) ∧ (q.hook=(0)) ∧ (q.unknown=(0)) ∧ (q.custodian=(0)) ∧ (q.epoch=(0)) ∧ (q.rootEpoch=(0)) ∧ (q.localEpoch=(0)))) ∧ ((q.fast=(1)) → ((q.profile=(0)) ∧ (q.phase≥(2)) ∧ (q.phase≤(5)) ∧ (q.identity=(1)) ∧ (q.intent=(1)) ∧ (q.hook=(0)) ∧ (q.sourceRoot=(0)) ∧ (q.carrierRoot=(0)) ∧ (q.localEpoch=q.epoch) ∧ (q.custodian=(1)))) ∧ ((q.durable=(1)) → ((q.profile≥(1)) ∧ (q.profile≤(3)) ∧ (q.phase≥(2)) ∧ (q.phase≤(8)) ∧ (q.sourceRoot=(1)) ∧ (q.intent=(1)))) ∧ (((q.phase≥(2)) ∧ (q.phase≤(6))) → ((q.intent=(1)) ∧ (q.identity=(1)) ∧ (q.bindingEpoch=q.sealEpoch) ∧ (q.custodian=(1)))) ∧ (((q.phase≥(2)) ∧ (q.phase≤(5))) → ((q.fast+q.durable)=(1))) ∧ (((q.phase≥(4)) ∧ (q.phase≤(6))) → (q.allocation=(1))) ∧ (((q.phase≥(5)) ∧ (q.phase≤(6))) → (q.recorded=(1))) ∧ ((q.phase=(6)) → ((q.carrierRoot=(1)) ∧ (q.fast=(0)) ∧ (q.durable=(0)) ∧ (q.hook=(0)) ∧ (q.unknown=(0)))) ∧ ((q.unknown=(1)) → ((q.phase=(8)) ∧ (q.intent=(1)) ∧ ((q.sourceRoot+q.carrierRoot)≥(1)) ∧ (q.custodian=(2)) ∧ (q.hook=(0)))) ∧ ((q.phase=(8)) → ((q.unknown=(1)) ∧ (q.profile≥(0)) ∧ (q.profile≤(3)) ∧ (q.identity=(1)) ∧ (q.bindingEpoch=q.sealEpoch))) ∧ (((q.sourceRoot+q.carrierRoot)≥(1)) → (q.rootEpoch=q.epoch)) ∧ (q.recorded≤q.allocation) ∧ ((q.hook=(1)) → ((q.profile≥(2)) ∧ (q.profile≤(3)) ∧ (q.durable=(1)) ∧ (q.phase≥(3)) ∧ (q.phase≤(4)))) ∧ ((q.carrierRoot=(1)) → ((q.fast=(0)) ∧ (q.durable=(0)) ∧ (q.recorded=(1)) ∧ (q.allocation=(1)) ∧ (q.identity=(1)))) ∧ ((q.phase=(7)) → ((q.fast=(0)) ∧ (q.durable=(0)) ∧ (q.hook=(0)) ∧ (q.unknown=(0)) ∧ (q.intent=(0)) ∧ (q.sourceRoot=(0)))) ∧ ((q.phase=(9)) → ((q.fast=(0)) ∧ (q.durable=(0)) ∧ (q.sourceRoot=(0)) ∧ (q.carrierRoot=(0)) ∧ (q.intent=(0)) ∧ (q.allocation=(0)) ∧ (q.recorded=(0)) ∧ (q.hook=(0)) ∧ (q.unknown=(0)) ∧ (q.custodian=(0)))) ∧ ((q.phase=(2)) → ((q.allocation=(0)) ∧ (q.recorded=(0)) ∧ (q.hook=(0)))) ∧ ((q.phase=(3)) → ((q.allocation=(0)) ∧ (q.recorded=(0)))) ∧ ((q.phase=(4)) → (q.recorded=(0))))
def initial : State := {phase:=(0), profile:=(0), identity:=(1), bindingEpoch:=(0), sealEpoch:=(0), fast:=(0), durable:=(0), sourceRoot:=(0), carrierRoot:=(0), intent:=(0), allocation:=(0), recorded:=(0), hook:=(0), unknown:=(0), custodian:=(0), epoch:=(0), rootEpoch:=(0), localEpoch:=(0), gate:=(1)}
def selectPlainGuard (q : State) : Prop := (q.phase=(0))
def selectPlainNext (q : State) : State := {q with phase:=(1), profile:=(0), identity:=(1)}
def selectCollectingGuard (q : State) : Prop := (q.phase=(0))
def selectCollectingNext (q : State) : State := {q with phase:=(1), profile:=(1), identity:=(1)}
def selectReentrantGuard (q : State) : Prop := (q.phase=(0))
def selectReentrantNext (q : State) : State := {q with phase:=(1), profile:=(2), identity:=(1)}
def selectAbandoningGuard (q : State) : Prop := (q.phase=(0))
def selectAbandoningNext (q : State) : State := {q with phase:=(1), profile:=(3), identity:=(1)}
def selectOpaqueGuard (q : State) : Prop := (q.phase=(0))
def selectOpaqueNext (q : State) : State := {q with phase:=(1), profile:=(4), identity:=(1)}
def selectWrongSelfGuard (q : State) : Prop := (q.phase=(0))
def selectWrongSelfNext (q : State) : State := {q with phase:=(1), profile:=(5), identity:=(0)}
def selectDebugIOGuard (q : State) : Prop := (q.phase=(0))
def selectDebugIONext (q : State) : State := {q with phase:=(1), profile:=(6), identity:=(1)}
def replaceBeforeGrantGuard (q : State) : Prop := ((q.phase=(1)) ∧ (q.bindingEpoch=(0)))
def replaceBeforeGrantNext (q : State) : State := {q with bindingEpoch:=(1)}
def grantFastGuard (q : State) : Prop := (((((q.phase=(1)) ∧ (q.profile=(0))) ∧ (q.identity=(1))) ∧ (q.bindingEpoch=q.sealEpoch)) ∧ (q.gate=(1)))
def grantFastNext (q : State) : State := {q with phase:=(2), fast:=(1), intent:=(1), custodian:=(1), localEpoch:=q.epoch}
def grantDurableGuard (q : State) : Prop := ((((((q.phase=(1)) ∧ (q.profile≥(1))) ∧ (q.profile≤(3))) ∧ (q.identity=(1))) ∧ (q.bindingEpoch=q.sealEpoch)) ∧ (q.gate=(1)))
def grantDurableNext (q : State) : State := {q with phase:=(2), durable:=(1), sourceRoot:=(1), intent:=(1), custodian:=(1), rootEpoch:=q.epoch, localEpoch:=q.epoch}
def denyProfileGuard (q : State) : Prop := ((q.phase=(1)) ∧ (((q.profile≥(4)) ∨ (q.bindingEpoch≠q.sealEpoch)) ∨ (q.gate=(0))))
def denyProfileNext (q : State) : State := {q with phase:=(9)}
def closeAdmissionGuard (q : State) : Prop := (q.gate=(1))
def closeAdmissionNext (q : State) : State := {q with gate:=(0)}
def beginAllocationGuard (q : State) : Prop := ((q.phase=(2)) ∧ (q.intent=(1)))
def beginAllocationNext (q : State) : State := {q with phase:=(3)}
def obtainNativeMemoryGuard (q : State) : Prop := ((q.phase=(3)) ∧ (q.allocation=(0)))
def obtainNativeMemoryNext (q : State) : State := {q with phase:=(4), allocation:=(1)}
def enterHookGuard (q : State) : Prop := ((((((q.phase=(3)) ∨ (q.phase=(4))) ∧ (q.profile≥(2))) ∧ (q.profile≤(3))) ∧ (q.durable=(1))) ∧ (q.hook=(0)))
def enterHookNext (q : State) : State := {q with hook:=(1)}
def returnHookGuard (q : State) : Prop := (((q.phase=(3)) ∨ (q.phase=(4))) ∧ (q.hook=(1)))
def returnHookNext (q : State) : State := {q with hook:=(0)}
def gcRoundGuard (q : State) : Prop := ((((q.phase≥(2)) ∧ (q.phase≤(8))) ∧ (q.phase≠(7))) ∧ ((q.sourceRoot+q.carrierRoot)≥(1)))
def gcRoundNext (q : State) : State := {q with epoch:=(q.epoch+(1)), rootEpoch:=(q.epoch+(1))}
def reloadRootGuard (q : State) : Prop := ((((q.phase≥(2)) ∧ (q.phase≤(6))) ∧ ((q.sourceRoot+q.carrierRoot)≥(1))) ∧ (q.hook=(0)))
def reloadRootNext (q : State) : State := {q with localEpoch:=q.rootEpoch}
def captureOutcomeGuard (q : State) : Prop := ((q.phase=(4)) ∧ (q.hook=(0)))
def captureOutcomeNext (q : State) : State := {q with phase:=(5), recorded:=(1)}
def publishInputsGuard (q : State) : Prop := (((((q.phase=(5)) ∧ (q.recorded=(1))) ∧ (q.hook=(0))) ∧ (q.localEpoch=q.epoch)) ∧ (q.identity=(1)))
def publishInputsNext (q : State) : State := {q with phase:=(6), carrierRoot:=(1), rootEpoch:=q.epoch, fast:=(0), durable:=(0)}
def abandonBeforeRecordGuard (q : State) : Prop := ((((q.phase=(3)) ∨ (q.phase=(4))) ∧ (q.profile=(3))) ∧ (q.durable=(1)))
def abandonBeforeRecordNext (q : State) : State := {q with phase:=(8), unknown:=(1), custodian:=(2), hook:=(0)}
def loseRecordedResponseGuard (q : State) : Prop := (((q.phase=(5)) ∧ (q.sourceRoot=(1))) ∨ (q.phase=(6)))
def loseRecordedResponseNext (q : State) : State := {q with phase:=(8), unknown:=(1), custodian:=(2), fast:=(0), durable:=(0)}
def recoverPrivateRecordGuard (q : State) : Prop := ((((((q.phase=(8)) ∧ (q.profile≥(1))) ∧ (q.profile≤(3))) ∧ (q.recorded=(1))) ∧ (q.carrierRoot=(0))) ∧ (q.sourceRoot=(1)))
def recoverPrivateRecordNext (q : State) : State := {q with phase:=(5), unknown:=(0), custodian:=(1), durable:=(1), localEpoch:=q.rootEpoch}
def recoverPublishedRecordGuard (q : State) : Prop := (((q.phase=(8)) ∧ (q.recorded=(1))) ∧ (q.carrierRoot=(1)))
def recoverPublishedRecordNext (q : State) : State := {q with phase:=(6), unknown:=(0), custodian:=(1), localEpoch:=q.rootEpoch}
def releaseSourceGuard (q : State) : Prop := (((q.phase=(6)) ∧ (q.carrierRoot=(1))) ∧ (q.localEpoch=q.epoch))
def releaseSourceNext (q : State) : State := {q with sourceRoot:=(0)}
def handoffBankGuard (q : State) : Prop := ((((q.phase=(6)) ∧ (q.carrierRoot=(1))) ∧ (q.recorded=(1))) ∧ (q.rootEpoch=q.epoch))
def handoffBankNext (q : State) : State := {q with phase:=(7), custodian:=(3), intent:=(0), sourceRoot:=(0)}
def rollbackPlainGuard (q : State) : Prop := ((((q.phase=(5)) ∧ (q.profile=(0))) ∧ (q.fast=(1))) ∧ (q.hook=(0)))
def rollbackPlainNext (q : State) : State := {q with phase:=(7), allocation:=(0), recorded:=(0), intent:=(0), fast:=(0), custodian:=(0)}
def Step (q r : State) : Prop := (selectPlainGuard q ∧ r=selectPlainNext q) ∨ (selectCollectingGuard q ∧ r=selectCollectingNext q) ∨ (selectReentrantGuard q ∧ r=selectReentrantNext q) ∨ (selectAbandoningGuard q ∧ r=selectAbandoningNext q) ∨ (selectOpaqueGuard q ∧ r=selectOpaqueNext q) ∨ (selectWrongSelfGuard q ∧ r=selectWrongSelfNext q) ∨ (selectDebugIOGuard q ∧ r=selectDebugIONext q) ∨ (replaceBeforeGrantGuard q ∧ r=replaceBeforeGrantNext q) ∨ (grantFastGuard q ∧ r=grantFastNext q) ∨ (grantDurableGuard q ∧ r=grantDurableNext q) ∨ (denyProfileGuard q ∧ r=denyProfileNext q) ∨ (closeAdmissionGuard q ∧ r=closeAdmissionNext q) ∨ (beginAllocationGuard q ∧ r=beginAllocationNext q) ∨ (obtainNativeMemoryGuard q ∧ r=obtainNativeMemoryNext q) ∨ (enterHookGuard q ∧ r=enterHookNext q) ∨ (returnHookGuard q ∧ r=returnHookNext q) ∨ (gcRoundGuard q ∧ r=gcRoundNext q) ∨ (reloadRootGuard q ∧ r=reloadRootNext q) ∨ (captureOutcomeGuard q ∧ r=captureOutcomeNext q) ∨ (publishInputsGuard q ∧ r=publishInputsNext q) ∨ (abandonBeforeRecordGuard q ∧ r=abandonBeforeRecordNext q) ∨ (loseRecordedResponseGuard q ∧ r=loseRecordedResponseNext q) ∨ (recoverPrivateRecordGuard q ∧ r=recoverPrivateRecordNext q) ∨ (recoverPublishedRecordGuard q ∧ r=recoverPublishedRecordNext q) ∨ (releaseSourceGuard q ∧ r=releaseSourceNext q) ∨ (handoffBankGuard q ∧ r=handoffBankNext q) ∨ (rollbackPlainGuard q ∧ r=rollbackPlainNext q) ∨ r=q
end NativePrefixAst

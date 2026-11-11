import Std
namespace ThreadCacheTailAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 count : Int
 initialCount : Int
 shared : Int
 counted : Int
 headPublished : Int
 qualified : Int
 receipt : Int
 owner : Int
 mask : Int
 supervisor : Int
 free : Int
 parentSlot : Int
 childSlot : Int
 extra : Int
 childPhase : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.count≥(0)) ∧ (q.initialCount≥(0)) ∧ (q.shared≥(0)) ∧ (q.counted≥(0)) ∧ (q.headPublished≥(0)) ∧ (q.qualified≥(0)) ∧ (q.receipt≥(0)) ∧ (q.owner≥(0)) ∧ (q.mask≥(0)) ∧ (q.supervisor≥(0)) ∧ (q.free≥(0)) ∧ (q.parentSlot≥(0)) ∧ (q.childSlot≥(0)) ∧ (q.extra≥(0)) ∧ (q.childPhase≥(0)) ∧ (q.phase≤(13)) ∧ (q.count≤(1201)) ∧ (q.initialCount≤(1200)) ∧ (q.shared≤(800)) ∧ (q.counted≤(1)) ∧ (q.headPublished≤(1)) ∧ (q.qualified≤(1)) ∧ (q.receipt≤(1)) ∧ (q.owner≤(1)) ∧ (q.mask≤(3)) ∧ (q.supervisor≤(1)) ∧ (q.free≤(2)) ∧ (q.parentSlot≤(1)) ∧ (q.childSlot≤(1)) ∧ (q.extra≤(1)) ∧ (q.childPhase≤(4)) ∧ (q.mask≥(1)) ∧ ((((q.free+q.parentSlot)+q.childSlot)+q.extra)=(2)) ∧ ((q.count+q.shared)=(q.initialCount+q.counted)) ∧ ((q.phase=(0)) → ((q.count=(0)) ∧ (q.initialCount=(0)) ∧ (q.counted=(0)) ∧ (q.headPublished=(0)) ∧ (q.receipt=(0)))) ∧ (((q.phase≥(1)) ∧ (q.phase≤(3))) → ((q.counted=(0)) ∧ (q.headPublished=(0)) ∧ (q.receipt=(0)))) ∧ ((q.phase=(11)) → ((q.counted=(0)) ∧ (q.headPublished=(0)) ∧ (q.qualified=(1)) ∧ (q.receipt=(0)))) ∧ ((q.phase=(12)) → ((q.counted=(0)) ∧ (q.headPublished=(1)) ∧ (q.qualified=(1)) ∧ (q.receipt=(0)))) ∧ ((q.phase=(13)) → ((q.counted=(1)) ∧ (q.headPublished=(1)) ∧ (q.qualified=(1)) ∧ (q.receipt=(0)) ∧ (q.count≤(1200)))) ∧ (((q.phase=(4)) ∨ (q.phase=(5))) → ((q.counted=(1)) ∧ (q.headPublished=(1)) ∧ (q.receipt=(0)))) ∧ ((q.receipt=(1)) → ((q.phase≥(6)) ∧ (q.phase≤(9)) ∧ (q.counted=(1)) ∧ (q.headPublished=(1)) ∧ (q.count≤(1200)))) ∧ (((q.phase≥(6)) ∧ (q.phase≤(9))) → (q.receipt=(1))) ∧ ((q.phase=(5)) → (q.shared=(800))) ∧ (((((((q.phase≠(5)) ∧ (q.phase≠(6))) ∧ (q.phase≠(7))) ∧ (q.phase≠(8))) ∧ (q.phase≠(9))) ∧ (q.phase≠(10))) → (q.shared=(0))) ∧ ((q.phase≠(9)) → (q.parentSlot=(1))) ∧ ((q.phase=(9)) → ((q.parentSlot=(0)) ∧ (q.mask=(3)) ∧ (q.supervisor=(0)))) ∧ (((q.phase≠(8)) ∧ (q.phase≠(9))) → (q.mask=(1))) ∧ ((q.phase=(8)) → ((q.mask=(2)) ∧ (q.supervisor=(1)) ∧ (q.parentSlot=(1)))) ∧ ((q.supervisor=(1)) → ((q.phase=(7)) ∨ (q.phase=(8)))) ∧ ((((q.childPhase=(1)) ∨ (q.childPhase=(2))) ∨ (q.childPhase=(3))) → ((q.childSlot=(1)) ∧ (q.phase=(0)) ∧ (q.mask=(1)))) ∧ (((q.childPhase=(0)) ∨ (q.childPhase=(4))) → (q.childSlot=(0))) ∧ ((((q.phase=(2)) ∨ (q.phase=(11))) ∨ (q.phase=(12))) → ((q.count≥(1)) ∧ (q.count<(1200)))))
def initial : State := {phase:=(0), count:=(0), initialCount:=(0), shared:=(0), counted:=(0), headPublished:=(0), qualified:=(0), receipt:=(0), owner:=(1), mask:=(1), supervisor:=(0), free:=(1), parentSlot:=(1), childSlot:=(0), extra:=(0), childPhase:=(0)}
def enterChildGuard (q : State) : Prop := (((q.phase=(0)) ∧ (q.childPhase=(0))) ∧ (q.free>(0)))
def enterChildNext (q : State) : State := {q with free:=(q.free-(1)), childSlot:=(1), childPhase:=(1)}
def childCleanupKnownGuard (q : State) : Prop := (q.childPhase=(1))
def childCleanupKnownNext (q : State) : State := {q with childPhase:=(2)}
def beginChildRestoreGuard (q : State) : Prop := (q.childPhase=(2))
def beginChildRestoreNext (q : State) : State := {q with childPhase:=(3)}
def knownChildRestoreGuard (q : State) : Prop := (q.childPhase=(3))
def knownChildRestoreNext (q : State) : State := {q with childPhase:=(4), childSlot:=(0), free:=(q.free+(1))}
def claimExtraGuard (q : State) : Prop := (((q.phase=(0)) ∧ (q.extra=(0))) ∧ (q.free>(0)))
def claimExtraNext (q : State) : State := {q with extra:=(1), free:=(q.free-(1))}
def returnExtraGuard (q : State) : Prop := (q.extra=(1))
def returnExtraNext (q : State) : State := {q with extra:=(0), free:=(q.free+(1))}
def denyOwnerGuard (q : State) : Prop := (q.phase=(0))
def denyOwnerNext (q : State) : State := {q with owner:=(0)}
def sampleEmptyGuard (q : State) : Prop := ((q.phase=(0)) ∧ ((q.childPhase=(0)) ∨ (q.childPhase=(4))))
def sampleEmptyNext (q : State) : State := {q with phase:=(1), count:=(0), initialCount:=(0)}
def sampleLowGuard (q : State) : Prop := ((q.phase=(0)) ∧ ((q.childPhase=(0)) ∨ (q.childPhase=(4))))
def sampleLowNext (q : State) : State := {q with phase:=(1), count:=(1), initialCount:=(1)}
def sampleNearGuard (q : State) : Prop := ((q.phase=(0)) ∧ ((q.childPhase=(0)) ∨ (q.childPhase=(4))))
def sampleNearNext (q : State) : State := {q with phase:=(1), count:=(1199), initialCount:=(1199)}
def sampleHighGuard (q : State) : Prop := ((q.phase=(0)) ∧ ((q.childPhase=(0)) ∨ (q.childPhase=(4))))
def sampleHighNext (q : State) : State := {q with phase:=(1), count:=(1200), initialCount:=(1200)}
def selectFastGuard (q : State) : Prop := ((((q.phase=(1)) ∧ (q.owner=(1))) ∧ (q.count≥(1))) ∧ (q.count<(1200)))
def selectFastNext (q : State) : State := {q with phase:=(2)}
def selectHelperGuard (q : State) : Prop := (((q.phase=(1)) ∧ (q.owner=(1))) ∧ ((q.count=(0)) ∨ (q.count≥(1200))))
def selectHelperNext (q : State) : State := {q with phase:=(3)}
def attestFastTailGuard (q : State) : Prop := ((((q.phase=(2)) ∧ (q.mask=(1))) ∧ (q.owner=(1))) ∧ (q.qualified=(0)))
def attestFastTailNext (q : State) : State := {q with qualified:=(1)}
def writeFastLinkGuard (q : State) : Prop := (((q.phase=(2)) ∧ (q.qualified=(1))) ∧ (q.mask=(1)))
def writeFastLinkNext (q : State) : State := {q with phase:=(11)}
def publishFastHeadGuard (q : State) : Prop := ((q.phase=(11)) ∧ (q.mask=(1)))
def publishFastHeadNext (q : State) : State := {q with phase:=(12), headPublished:=(1)}
def incrementFastCountGuard (q : State) : Prop := ((q.phase=(12)) ∧ (q.mask=(1)))
def incrementFastCountNext (q : State) : State := {q with phase:=(13), count:=(q.count+(1)), counted:=(1)}
def publishFastReceiptGuard (q : State) : Prop := ((q.phase=(13)) ∧ (q.mask=(1)))
def publishFastReceiptNext (q : State) : State := {q with phase:=(6), receipt:=(1)}
def helperPushGuard (q : State) : Prop := (q.phase=(3))
def helperPushNext (q : State) : State := {q with phase:=(4), count:=(q.count+(1)), counted:=(1), headPublished:=(1)}
def helperFlush800Guard (q : State) : Prop := ((q.phase=(4)) ∧ (q.count>(1200)))
def helperFlush800Next (q : State) : State := {q with phase:=(5), count:=(q.count-(800)), shared:=(800)}
def helperKnownReturnGuard (q : State) : Prop := (((q.phase=(4)) ∧ (q.count≤(1200))) ∨ (q.phase=(5)))
def helperKnownReturnNext (q : State) : State := {q with phase:=(6), receipt:=(1)}
def unknownHelperGuard (q : State) : Prop := (((q.phase=(3)) ∨ (q.phase=(4))) ∨ (q.phase=(5)))
def unknownHelperNext (q : State) : State := {q with phase:=(10)}
def handoffParentGuard (q : State) : Prop := (((((q.phase=(6)) ∧ (q.receipt=(1))) ∧ (q.mask=(1))) ∧ ((q.childPhase=(0)) ∨ (q.childPhase=(4)))) ∧ (q.childSlot=(0)))
def handoffParentNext (q : State) : State := {q with phase:=(7), supervisor:=(1)}
def beginParentRestoreGuard (q : State) : Prop := (((q.phase=(7)) ∧ (q.supervisor=(1))) ∧ (q.mask=(1)))
def beginParentRestoreNext (q : State) : State := {q with phase:=(8), mask:=(2)}
def knownParentRestoreGuard (q : State) : Prop := (((q.phase=(8)) ∧ (q.supervisor=(1))) ∧ (q.mask=(2)))
def knownParentRestoreNext (q : State) : State := {q with phase:=(9), mask:=(3), supervisor:=(0), parentSlot:=(0), free:=(q.free+(1))}
def Step (q r : State) : Prop := (enterChildGuard q ∧ r=enterChildNext q) ∨ (childCleanupKnownGuard q ∧ r=childCleanupKnownNext q) ∨ (beginChildRestoreGuard q ∧ r=beginChildRestoreNext q) ∨ (knownChildRestoreGuard q ∧ r=knownChildRestoreNext q) ∨ (claimExtraGuard q ∧ r=claimExtraNext q) ∨ (returnExtraGuard q ∧ r=returnExtraNext q) ∨ (denyOwnerGuard q ∧ r=denyOwnerNext q) ∨ (sampleEmptyGuard q ∧ r=sampleEmptyNext q) ∨ (sampleLowGuard q ∧ r=sampleLowNext q) ∨ (sampleNearGuard q ∧ r=sampleNearNext q) ∨ (sampleHighGuard q ∧ r=sampleHighNext q) ∨ (selectFastGuard q ∧ r=selectFastNext q) ∨ (selectHelperGuard q ∧ r=selectHelperNext q) ∨ (attestFastTailGuard q ∧ r=attestFastTailNext q) ∨ (writeFastLinkGuard q ∧ r=writeFastLinkNext q) ∨ (publishFastHeadGuard q ∧ r=publishFastHeadNext q) ∨ (incrementFastCountGuard q ∧ r=incrementFastCountNext q) ∨ (publishFastReceiptGuard q ∧ r=publishFastReceiptNext q) ∨ (helperPushGuard q ∧ r=helperPushNext q) ∨ (helperFlush800Guard q ∧ r=helperFlush800Next q) ∨ (helperKnownReturnGuard q ∧ r=helperKnownReturnNext q) ∨ (unknownHelperGuard q ∧ r=unknownHelperNext q) ∨ (handoffParentGuard q ∧ r=handoffParentNext q) ∨ (beginParentRestoreGuard q ∧ r=beginParentRestoreNext q) ∨ (knownParentRestoreGuard q ∧ r=knownParentRestoreNext q) ∨ r=q
end ThreadCacheTailAst

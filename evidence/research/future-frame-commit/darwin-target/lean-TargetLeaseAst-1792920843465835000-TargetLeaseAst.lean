import Std
namespace TargetLeaseAst
set_option maxRecDepth 10000
structure State where
 published : Int
 gate : Int
 current : Int
 oldLive : Int
 certificate : Int
 mayAbandon : Int
 outer : Int
 nested : Int
 maintenance : Int
 origin : Int
 allocFamily : Int
 freeFamily : Int
 operation : Int
 pointer : Int
 recorded : Int
 unknown : Int
 custodian : Int
 freeApplied : Int
 freeReceipt : Int
 retired : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.current≥(0)) ∧ (q.current≤(2)) ∧ (q.allocFamily≥(0)) ∧ (q.allocFamily≤(1)) ∧ (q.freeFamily≥(0)) ∧ (q.freeFamily≤(1)) ∧ (q.operation≥(0)) ∧ (q.operation≤(7)) ∧ (q.custodian≥(0)) ∧ (q.custodian≤(2)) ∧ (q.published≥(0)) ∧ (q.published≤(1)) ∧ (q.gate≥(0)) ∧ (q.gate≤(1)) ∧ (q.oldLive≥(0)) ∧ (q.oldLive≤(1)) ∧ (q.certificate≥(0)) ∧ (q.certificate≤(1)) ∧ (q.mayAbandon≥(0)) ∧ (q.mayAbandon≤(1)) ∧ (q.outer≥(0)) ∧ (q.outer≤(1)) ∧ (q.nested≥(0)) ∧ (q.nested≤(1)) ∧ (q.maintenance≥(0)) ∧ (q.maintenance≤(1)) ∧ (q.origin≥(0)) ∧ (q.origin≤(1)) ∧ (q.pointer≥(0)) ∧ (q.pointer≤(1)) ∧ (q.recorded≥(0)) ∧ (q.recorded≤(1)) ∧ (q.unknown≥(0)) ∧ (q.unknown≤(1)) ∧ (q.freeApplied≥(0)) ∧ (q.freeApplied≤(1)) ∧ (q.freeReceipt≥(0)) ∧ (q.freeReceipt≤(1)) ∧ (q.retired≥(0)) ∧ (q.retired≤(1)) ∧ ((q.published=(0)) → ((q.gate=(0)) ∧ (q.current=(0)) ∧ (q.oldLive=(0)) ∧ (q.certificate=(0)) ∧ (q.outer=(0)) ∧ (q.nested=(0)) ∧ (q.maintenance=(0)) ∧ (q.origin=(0)) ∧ (q.operation=(0)) ∧ (q.pointer=(0)) ∧ (q.recorded=(0)) ∧ (q.unknown=(0)) ∧ (q.retired=(0)))) ∧ ((q.gate=(1)) → ((q.published=(1)) ∧ (q.current=(1)) ∧ (q.oldLive=(1)) ∧ (q.certificate=(1)))) ∧ ((((((q.outer+q.nested)+q.maintenance)+q.origin)+q.unknown)≥(1)) → ((q.oldLive=(1)) ∧ (q.certificate=(1)) ∧ (q.published=(1)))) ∧ ((q.origin=(1)) → (q.allocFamily=(1))) ∧ (((q.operation≥(1)) ∧ (q.operation≤(6))) → (q.origin=(1))) ∧ (((q.operation≥(1)) ∧ (q.operation≤(4))) → (q.outer=(1))) ∧ ((q.operation=(1)) → ((q.pointer=(0)) ∧ (q.recorded=(0)))) ∧ ((q.operation=(2)) → ((q.pointer=(1)) ∧ (q.recorded=(0)))) ∧ ((q.operation=(3)) → ((q.pointer=(1)) ∧ (q.recorded=(1)))) ∧ ((q.operation=(4)) → (((q.recorded=(1)) → (q.pointer=(1))) ∧ (q.unknown=(1)) ∧ (q.origin=(1)) ∧ (q.outer=(1)) ∧ (q.custodian=(2)))) ∧ (((q.operation≥(5)) ∧ (q.operation≤(6))) → ((q.maintenance=(1)) ∧ (q.recorded=(1)) ∧ (q.freeFamily=q.allocFamily) ∧ (q.freeFamily=(1)))) ∧ ((q.operation=(6)) → ((q.unknown=(1)) ∧ (q.custodian=(2)))) ∧ ((q.unknown=(1)) → (((q.operation=(4)) ∨ (q.operation=(6))) ∧ (q.origin=(1)) ∧ (q.custodian=(2)))) ∧ ((q.operation=(7)) → ((q.origin=(0)) ∧ (q.pointer=(0)) ∧ (q.unknown=(0)))) ∧ ((q.freeReceipt=(1)) → ((q.freeApplied=(1)) ∧ (q.pointer=(0)) ∧ (q.recorded=(1)))) ∧ ((q.freeApplied=(1)) → ((q.freeFamily=(1)) ∧ (q.pointer=(0)))) ∧ ((q.retired=(1)) → ((q.oldLive=(0)) ∧ (q.certificate=(0)) ∧ (q.gate=(0)) ∧ (q.outer=(0)) ∧ (q.nested=(0)) ∧ (q.maintenance=(0)) ∧ (q.origin=(0)) ∧ (q.unknown=(0)))) ∧ (((q.oldLive=(0)) ∧ (q.published=(1))) → (q.retired=(1))))
def initial : State := {published:=(0), gate:=(0), current:=(0), oldLive:=(0), certificate:=(0), mayAbandon:=(0), outer:=(0), nested:=(0), maintenance:=(0), origin:=(0), allocFamily:=(0), freeFamily:=(0), operation:=(0), pointer:=(0), recorded:=(0), unknown:=(0), custodian:=(0), freeApplied:=(0), freeReceipt:=(0), retired:=(0)}
def publishPlainGuard (q : State) : Prop := (q.published=(0))
def publishPlainNext (q : State) : State := {q with published:=(1), gate:=(1), current:=(1), oldLive:=(1), certificate:=(1)}
def publishAdmittedHooksGuard (q : State) : Prop := (q.published=(0))
def publishAdmittedHooksNext (q : State) : State := {q with published:=(1), gate:=(1), current:=(1), oldLive:=(1), certificate:=(1), mayAbandon:=(1)}
def acquireOuterGuard (q : State) : Prop := (((((((q.published=(1)) ∧ (q.gate=(1))) ∧ (q.current=(1))) ∧ (q.oldLive=(1))) ∧ (q.certificate=(1))) ∧ (q.outer=(0))) ∧ (q.operation=(0)))
def acquireOuterNext (q : State) : State := {q with outer:=(1), custodian:=(1)}
def closeOrdinaryGuard (q : State) : Prop := ((q.published=(1)) ∧ (q.gate=(1)))
def closeOrdinaryNext (q : State) : State := {q with gate:=(0)}
def publishReplacementGuard (q : State) : Prop := (((q.published=(1)) ∧ (q.gate=(0))) ∧ (q.current=(1)))
def publishReplacementNext (q : State) : State := {q with current:=(2)}
def beginMallocGuard (q : State) : Prop := (((q.outer=(1)) ∧ (q.operation=(0))) ∧ (q.origin=(0)))
def beginMallocNext (q : State) : State := {q with origin:=(1), allocFamily:=(1), operation:=(1)}
def obtainPointerGuard (q : State) : Prop := (q.operation=(1))
def obtainPointerNext (q : State) : State := {q with operation:=(2), pointer:=(1)}
def recordSuccessGuard (q : State) : Prop := ((q.operation=(2)) ∧ (q.nested=(0)))
def recordSuccessNext (q : State) : State := {q with operation:=(3), recorded:=(1)}
def recordNullGuard (q : State) : Prop := ((q.operation=(1)) ∧ (q.nested=(0)))
def recordNullNext (q : State) : State := {q with operation:=(7), recorded:=(1), origin:=(0)}
def enterNestedGuard (q : State) : Prop := ((((q.oldLive=(1)) ∧ (q.mayAbandon=(1))) ∧ ((q.outer=(1)) ∨ (q.maintenance=(1)))) ∧ (q.nested=(0)))
def enterNestedNext (q : State) : State := {q with nested:=(1)}
def leaveNestedGuard (q : State) : Prop := (q.nested=(1))
def leaveNestedNext (q : State) : State := {q with nested:=(0)}
def loseBeforeCaptureGuard (q : State) : Prop := (((q.operation=(1)) ∨ (q.operation=(2))) ∧ (q.mayAbandon=(1)))
def loseBeforeCaptureNext (q : State) : State := {q with operation:=(4), unknown:=(1), custodian:=(2)}
def loseRecordedAckGuard (q : State) : Prop := (q.operation=(3))
def loseRecordedAckNext (q : State) : State := {q with operation:=(4), unknown:=(1), custodian:=(2)}
def recoverRecordedGuard (q : State) : Prop := (((q.operation=(4)) ∧ (q.recorded=(1))) ∧ (q.nested=(0)))
def recoverRecordedNext (q : State) : State := {q with operation:=(3), unknown:=(0), custodian:=(1)}
def releaseOuterGuard (q : State) : Prop := ((((q.outer=(1)) ∧ (((q.operation=(0)) ∨ (q.operation=(3))) ∨ (q.operation=(7)))) ∧ (q.unknown=(0))) ∧ (q.nested=(0)))
def releaseOuterNext (q : State) : State := {q with outer:=(0)}
def beginOriginFreeGuard (q : State) : Prop := ((((((q.operation=(3)) ∧ (q.recorded=(1))) ∧ (q.origin=(1))) ∧ (q.oldLive=(1))) ∧ (q.outer=(0))) ∧ (q.maintenance=(0)))
def beginOriginFreeNext (q : State) : State := {q with maintenance:=(1), operation:=(5), freeFamily:=q.allocFamily, custodian:=(1)}
def applyFreeGuard (q : State) : Prop := (((q.operation=(5)) ∧ (q.freeApplied=(0))) ∧ (q.nested=(0)))
def applyFreeNext (q : State) : State := {q with pointer:=(0), freeApplied:=(1)}
def recordFreeBackendGuard (q : State) : Prop := (((q.operation=(5)) ∧ (q.freeApplied=(1))) ∧ (q.nested=(0)))
def recordFreeBackendNext (q : State) : State := {q with freeReceipt:=(1)}
def loseFreeReturnGuard (q : State) : Prop := (q.operation=(5))
def loseFreeReturnNext (q : State) : State := {q with operation:=(6), unknown:=(1), custodian:=(2)}
def settleFreeGuard (q : State) : Prop := (((q.operation=(5)) ∧ (q.freeReceipt=(1))) ∧ (q.nested=(0)))
def settleFreeNext (q : State) : State := {q with operation:=(7), origin:=(0)}
def reconcileFreeGuard (q : State) : Prop := (((q.operation=(6)) ∧ (q.freeReceipt=(1))) ∧ (q.nested=(0)))
def reconcileFreeNext (q : State) : State := {q with operation:=(7), origin:=(0), unknown:=(0), custodian:=(1)}
def releaseMaintenanceGuard (q : State) : Prop := ((((q.operation=(7)) ∧ (q.maintenance=(1))) ∧ (q.unknown=(0))) ∧ (q.nested=(0)))
def releaseMaintenanceNext (q : State) : State := {q with maintenance:=(0)}
def retireOldBundleGuard (q : State) : Prop := ((((((((q.published=(1)) ∧ (q.gate=(0))) ∧ (q.outer=(0))) ∧ (q.nested=(0))) ∧ (q.maintenance=(0))) ∧ (q.origin=(0))) ∧ (q.unknown=(0))) ∧ (q.oldLive=(1)))
def retireOldBundleNext (q : State) : State := {q with oldLive:=(0), certificate:=(0), retired:=(1)}
def Step (q r : State) : Prop := (publishPlainGuard q ∧ r=publishPlainNext q) ∨ (publishAdmittedHooksGuard q ∧ r=publishAdmittedHooksNext q) ∨ (acquireOuterGuard q ∧ r=acquireOuterNext q) ∨ (closeOrdinaryGuard q ∧ r=closeOrdinaryNext q) ∨ (publishReplacementGuard q ∧ r=publishReplacementNext q) ∨ (beginMallocGuard q ∧ r=beginMallocNext q) ∨ (obtainPointerGuard q ∧ r=obtainPointerNext q) ∨ (recordSuccessGuard q ∧ r=recordSuccessNext q) ∨ (recordNullGuard q ∧ r=recordNullNext q) ∨ (enterNestedGuard q ∧ r=enterNestedNext q) ∨ (leaveNestedGuard q ∧ r=leaveNestedNext q) ∨ (loseBeforeCaptureGuard q ∧ r=loseBeforeCaptureNext q) ∨ (loseRecordedAckGuard q ∧ r=loseRecordedAckNext q) ∨ (recoverRecordedGuard q ∧ r=recoverRecordedNext q) ∨ (releaseOuterGuard q ∧ r=releaseOuterNext q) ∨ (beginOriginFreeGuard q ∧ r=beginOriginFreeNext q) ∨ (applyFreeGuard q ∧ r=applyFreeNext q) ∨ (recordFreeBackendGuard q ∧ r=recordFreeBackendNext q) ∨ (loseFreeReturnGuard q ∧ r=loseFreeReturnNext q) ∨ (settleFreeGuard q ∧ r=settleFreeNext q) ∨ (reconcileFreeGuard q ∧ r=reconcileFreeNext q) ∨ (releaseMaintenanceGuard q ∧ r=releaseMaintenanceNext q) ∨ (retireOldBundleGuard q ∧ r=retireOldBundleNext q) ∨ r=q
end TargetLeaseAst

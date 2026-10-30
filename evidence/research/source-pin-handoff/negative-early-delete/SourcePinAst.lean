import Std
namespace SourcePinAst
set_option maxRecDepth 10000
structure State where
 gate : Int
 alive : Int
 sourceRoot : Int
 epoch : Int
 gc : Int
 pin0 : Int
 pin1 : Int
 accepted0 : Int
 accepted1 : Int
 carrier0 : Int
 carrier1 : Int
 value0 : Int
 value1 : Int
 guard0 : Int
 guard1 : Int
 ack0 : Int
 ack1 : Int
 dups : Int
 rejected : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.gate≥(0)) ∧ (q.gate≤(1)) ∧ (q.alive≥(0)) ∧ (q.alive≤(1)) ∧ (q.sourceRoot≥(0)) ∧ (q.sourceRoot≤(1)) ∧ (q.gc≥(0)) ∧ (q.gc≤(1)) ∧ (q.pin0≥(0)) ∧ (q.pin0≤(1)) ∧ (q.pin1≥(0)) ∧ (q.pin1≤(1)) ∧ (q.accepted0≥(0)) ∧ (q.accepted0≤(1)) ∧ (q.accepted1≥(0)) ∧ (q.accepted1≤(1)) ∧ (q.carrier0≥(0)) ∧ (q.carrier0≤(2)) ∧ (q.carrier1≥(0)) ∧ (q.carrier1≤(2)) ∧ (q.guard0≥(0)) ∧ (q.guard0≤(4)) ∧ (q.guard1≥(0)) ∧ (q.guard1≤(4)) ∧ (q.ack0≥(0)) ∧ (q.ack0≤(1)) ∧ (q.ack1≥(0)) ∧ (q.ack1≤(1)) ∧ (q.epoch≥(0)) ∧ (q.value0≥(0)) ∧ (q.value1≥(0)) ∧ (q.dups≥(0)) ∧ (q.rejected≥(0)) ∧ (q.sourceRoot=q.alive) ∧ ((q.alive=(0)) → (((q.gate=(0)) ∧ (q.pin0=(0))) ∧ (q.pin1=(0)))) ∧ ((q.gc=(1)) → (((q.sourceRoot=(1)) ∨ (q.carrier0=(2))) ∨ (q.carrier1=(2)))) ∧ ((q.pin0=(1)) → (((q.alive=(1)) ∧ (q.sourceRoot=(1))) ∧ (q.accepted0=(1)))) ∧ ((q.carrier0=(1)) → ((q.pin0=(1)) ∧ (q.guard0=(0)))) ∧ ((q.carrier0=(2)) → (q.value0=q.epoch)) ∧ ((q.guard0>(0)) → (q.accepted0=(1))) ∧ ((((q.guard0=(1)) ∨ (q.guard0=(2))) ∨ (q.guard0=(3))) → (q.carrier0=(2))) ∧ ((q.ack0=(1)) → ((q.guard0=(2)) ∨ (q.guard0=(4)))) ∧ ((q.carrier0>(0)) → (q.accepted0=(1))) ∧ ((q.guard0=(0)) → (q.ack0=(0))) ∧ ((q.guard0=(3)) → (q.pin0=(1))) ∧ ((q.pin1=(1)) → (((q.alive=(1)) ∧ (q.sourceRoot=(1))) ∧ (q.accepted1=(1)))) ∧ ((q.carrier1=(1)) → ((q.pin1=(1)) ∧ (q.guard1=(0)))) ∧ ((q.carrier1=(2)) → (q.value1=q.epoch)) ∧ ((q.guard1>(0)) → (q.accepted1=(1))) ∧ ((((q.guard1=(1)) ∨ (q.guard1=(2))) ∨ (q.guard1=(3))) → (q.carrier1=(2))) ∧ ((q.ack1=(1)) → ((q.guard1=(2)) ∨ (q.guard1=(4)))) ∧ ((q.carrier1>(0)) → (q.accepted1=(1))) ∧ ((q.guard1=(0)) → (q.ack1=(0))) ∧ ((q.guard1=(3)) → (q.pin1=(1))) ∧ (((q.guard0=(1)) ∨ (q.guard0=(3))) → (q.pin0=(1))) ∧ (((q.guard1=(1)) ∨ (q.guard1=(3))) → (q.pin1=(1))) ∧ (((q.carrier0>(0)) ∧ (q.guard0=(0))) → (q.pin0=(1))) ∧ (((q.carrier1>(0)) ∧ (q.guard1=(0))) → (q.pin1=(1))))
def initial : State := {gate:=(1), alive:=(1), sourceRoot:=(1), epoch:=(0), gc:=(0), pin0:=(0), pin1:=(0), accepted0:=(0), accepted1:=(0), carrier0:=(0), carrier1:=(0), value0:=(0), value1:=(0), guard0:=(0), guard1:=(0), ack0:=(0), ack1:=(0), dups:=(0), rejected:=(0)}
def pinOuterGuard (q : State) : Prop := (q.gate=(1)) ∧ (q.alive=(1)) ∧ (q.accepted0=(0)) ∧ (q.gc=(0))
def pinOuterNext (q : State) : State := {q with pin0:=(1), accepted0:=(1)}
def pinNestedGuard (q : State) : Prop := (q.gate=(1)) ∧ (q.alive=(1)) ∧ (q.accepted1=(0)) ∧ (q.guard0=(2)) ∧ (q.gc=(0))
def pinNestedNext (q : State) : State := {q with pin1:=(1), accepted1:=(1)}
def closeSourceGuard (q : State) : Prop := (q.gate=(1))
def closeSourceNext (q : State) : State := {q with gate:=(0)}
def rejectLatePinGuard (q : State) : Prop := (q.gate=(0))
def rejectLatePinNext (q : State) : State := {q with rejected:=(q.rejected+(1))}
def copy0Guard (q : State) : Prop := (q.guard0=(0)) ∧ (q.pin0=(1)) ∧ (q.carrier0=(0)) ∧ (q.gc=(0))
def copy0Next (q : State) : State := {q with carrier0:=(1), value0:=q.epoch}
def refresh0Guard (q : State) : Prop := (q.pin0=(1)) ∧ (q.carrier0=(1)) ∧ (q.gc=(0))
def refresh0Next (q : State) : State := {q with value0:=q.epoch}
def enroll0Guard (q : State) : Prop := (q.pin0=(1)) ∧ (q.carrier0=(1)) ∧ (q.value0=q.epoch) ∧ (q.gc=(0))
def enroll0Next (q : State) : State := {q with carrier0:=(2)}
def reserveGuard0Guard (q : State) : Prop := (q.carrier0=(2)) ∧ (q.guard0=(0)) ∧ (q.gc=(0))
def reserveGuard0Next (q : State) : State := {q with guard0:=(1)}
def commitGuard0Guard (q : State) : Prop := (q.guard0=(1))
def commitGuard0Next (q : State) : State := {q with guard0:=(2)}
def lostReservation0Guard (q : State) : Prop := (q.guard0=(1))
def lostReservation0Next (q : State) : State := {q with guard0:=(3)}
def resolveCommitted0Guard (q : State) : Prop := (q.guard0=(3))
def resolveCommitted0Next (q : State) : State := {q with guard0:=(2)}
def resolveFailed0Guard (q : State) : Prop := (q.guard0=(3))
def resolveFailed0Next (q : State) : State := {q with guard0:=(4)}
def queryAck0Guard (q : State) : Prop := ((q.guard0=(2)) ∨ (q.guard0=(4)))
def queryAck0Next (q : State) : State := {q with ack0:=(1)}
def returnPin0Guard (q : State) : Prop := (q.pin0=(1)) ∧ (q.carrier0=(2)) ∧ (q.ack0=(1)) ∧ ((q.guard0=(2)) ∨ (q.guard0=(4)))
def returnPin0Next (q : State) : State := {q with pin0:=(0)}
def repeatReturn0Guard (q : State) : Prop := (q.pin0=(0)) ∧ (q.accepted0=(1))
def repeatReturn0Next (q : State) : State := {q with dups:=(q.dups+(1))}
def abortBeforeGuard0Guard (q : State) : Prop := (q.pin0=(1)) ∧ (q.guard0=(0)) ∧ (q.gc=(0))
def abortBeforeGuard0Next (q : State) : State := {q with pin0:=(0), carrier0:=(0)}
def outerExit0Guard (q : State) : Prop := (q.guard0=(2))
def outerExit0Next (q : State) : State := {q with guard0:=(4)}
def retireCarrier0Guard (q : State) : Prop := (q.pin0=(0)) ∧ (q.guard0=(4)) ∧ (q.ack0=(1)) ∧ (q.gc=(0))
def retireCarrier0Next (q : State) : State := {q with carrier0:=(0)}
def copy1Guard (q : State) : Prop := (q.guard1=(0)) ∧ (q.pin1=(1)) ∧ (q.carrier1=(0)) ∧ (q.gc=(0))
def copy1Next (q : State) : State := {q with carrier1:=(1), value1:=q.epoch}
def refresh1Guard (q : State) : Prop := (q.pin1=(1)) ∧ (q.carrier1=(1)) ∧ (q.gc=(0))
def refresh1Next (q : State) : State := {q with value1:=q.epoch}
def enroll1Guard (q : State) : Prop := (q.pin1=(1)) ∧ (q.carrier1=(1)) ∧ (q.value1=q.epoch) ∧ (q.gc=(0))
def enroll1Next (q : State) : State := {q with carrier1:=(2)}
def reserveGuard1Guard (q : State) : Prop := (q.carrier1=(2)) ∧ (q.guard1=(0)) ∧ (q.gc=(0))
def reserveGuard1Next (q : State) : State := {q with guard1:=(1)}
def commitGuard1Guard (q : State) : Prop := (q.guard1=(1))
def commitGuard1Next (q : State) : State := {q with guard1:=(2)}
def lostReservation1Guard (q : State) : Prop := (q.guard1=(1))
def lostReservation1Next (q : State) : State := {q with guard1:=(3)}
def resolveCommitted1Guard (q : State) : Prop := (q.guard1=(3))
def resolveCommitted1Next (q : State) : State := {q with guard1:=(2)}
def resolveFailed1Guard (q : State) : Prop := (q.guard1=(3))
def resolveFailed1Next (q : State) : State := {q with guard1:=(4)}
def queryAck1Guard (q : State) : Prop := ((q.guard1=(2)) ∨ (q.guard1=(4)))
def queryAck1Next (q : State) : State := {q with ack1:=(1)}
def returnPin1Guard (q : State) : Prop := (q.pin1=(1)) ∧ (q.carrier1=(2)) ∧ (q.ack1=(1)) ∧ ((q.guard1=(2)) ∨ (q.guard1=(4)))
def returnPin1Next (q : State) : State := {q with pin1:=(0)}
def repeatReturn1Guard (q : State) : Prop := (q.pin1=(0)) ∧ (q.accepted1=(1))
def repeatReturn1Next (q : State) : State := {q with dups:=(q.dups+(1))}
def abortBeforeGuard1Guard (q : State) : Prop := (q.pin1=(1)) ∧ (q.guard1=(0)) ∧ (q.gc=(0))
def abortBeforeGuard1Next (q : State) : State := {q with pin1:=(0), carrier1:=(0)}
def outerExit1Guard (q : State) : Prop := (q.guard1=(2))
def outerExit1Next (q : State) : State := {q with guard1:=(4)}
def retireCarrier1Guard (q : State) : Prop := (q.pin1=(0)) ∧ (q.guard1=(4)) ∧ (q.ack1=(1)) ∧ (q.gc=(0))
def retireCarrier1Next (q : State) : State := {q with carrier1:=(0)}
def retireSourceGuard (q : State) : Prop := (q.gate=(0)) ∧ (q.alive=(1)) ∧ True ∧ (q.pin1=(0)) ∧ (q.gc=(0))
def retireSourceNext (q : State) : State := {q with alive:=(0), sourceRoot:=(0)}
def freezeGcGuard (q : State) : Prop := (q.gc=(0)) ∧ (((q.sourceRoot=(1)) ∨ (q.carrier0=(2))) ∨ (q.carrier1=(2)))
def freezeGcNext (q : State) : State := {q with gc:=(1)}
def finishGcNoneGuard (q : State) : Prop := (q.gc=(1)) ∧ (q.carrier0≠(2)) ∧ (q.carrier1≠(2))
def finishGcNoneNext (q : State) : State := {q with gc:=(0), epoch:=(q.epoch+(1))}
def finishGcOuterGuard (q : State) : Prop := (q.gc=(1)) ∧ (q.carrier0=(2)) ∧ (q.carrier1≠(2))
def finishGcOuterNext (q : State) : State := {q with gc:=(0), epoch:=(q.epoch+(1)), value0:=(q.value0+(1))}
def finishGcNestedGuard (q : State) : Prop := (q.gc=(1)) ∧ (q.carrier0≠(2)) ∧ (q.carrier1=(2))
def finishGcNestedNext (q : State) : State := {q with gc:=(0), epoch:=(q.epoch+(1)), value1:=(q.value1+(1))}
def finishGcBothGuard (q : State) : Prop := (q.gc=(1)) ∧ (q.carrier0=(2)) ∧ (q.carrier1=(2))
def finishGcBothNext (q : State) : State := {q with gc:=(0), epoch:=(q.epoch+(1)), value0:=(q.value0+(1)), value1:=(q.value1+(1))}
def Step (q r : State) : Prop := (pinOuterGuard q ∧ r=pinOuterNext q) ∨ (pinNestedGuard q ∧ r=pinNestedNext q) ∨ (closeSourceGuard q ∧ r=closeSourceNext q) ∨ (rejectLatePinGuard q ∧ r=rejectLatePinNext q) ∨ (copy0Guard q ∧ r=copy0Next q) ∨ (refresh0Guard q ∧ r=refresh0Next q) ∨ (enroll0Guard q ∧ r=enroll0Next q) ∨ (reserveGuard0Guard q ∧ r=reserveGuard0Next q) ∨ (commitGuard0Guard q ∧ r=commitGuard0Next q) ∨ (lostReservation0Guard q ∧ r=lostReservation0Next q) ∨ (resolveCommitted0Guard q ∧ r=resolveCommitted0Next q) ∨ (resolveFailed0Guard q ∧ r=resolveFailed0Next q) ∨ (queryAck0Guard q ∧ r=queryAck0Next q) ∨ (returnPin0Guard q ∧ r=returnPin0Next q) ∨ (repeatReturn0Guard q ∧ r=repeatReturn0Next q) ∨ (abortBeforeGuard0Guard q ∧ r=abortBeforeGuard0Next q) ∨ (outerExit0Guard q ∧ r=outerExit0Next q) ∨ (retireCarrier0Guard q ∧ r=retireCarrier0Next q) ∨ (copy1Guard q ∧ r=copy1Next q) ∨ (refresh1Guard q ∧ r=refresh1Next q) ∨ (enroll1Guard q ∧ r=enroll1Next q) ∨ (reserveGuard1Guard q ∧ r=reserveGuard1Next q) ∨ (commitGuard1Guard q ∧ r=commitGuard1Next q) ∨ (lostReservation1Guard q ∧ r=lostReservation1Next q) ∨ (resolveCommitted1Guard q ∧ r=resolveCommitted1Next q) ∨ (resolveFailed1Guard q ∧ r=resolveFailed1Next q) ∨ (queryAck1Guard q ∧ r=queryAck1Next q) ∨ (returnPin1Guard q ∧ r=returnPin1Next q) ∨ (repeatReturn1Guard q ∧ r=repeatReturn1Next q) ∨ (abortBeforeGuard1Guard q ∧ r=abortBeforeGuard1Next q) ∨ (outerExit1Guard q ∧ r=outerExit1Next q) ∨ (retireCarrier1Guard q ∧ r=retireCarrier1Next q) ∨ (retireSourceGuard q ∧ r=retireSourceNext q) ∨ (freezeGcGuard q ∧ r=freezeGcNext q) ∨ (finishGcNoneGuard q ∧ r=finishGcNoneNext q) ∨ (finishGcOuterGuard q ∧ r=finishGcOuterNext q) ∨ (finishGcNestedGuard q ∧ r=finishGcNestedNext q) ∨ (finishGcBothGuard q ∧ r=finishGcBothNext q) ∨ r=q
end SourcePinAst

import Std
namespace RestoreEntryAst
set_option maxRecDepth 10000
structure State where
 t0phase : Int
 t0witness : Int
 t0issued : Int
 t0settles : Int
 t0carrier : Int
 t0guard : Bool
 t0roots : Bool
 t0restored : Bool
 t0ack : Bool
 t1phase : Int
 t1witness : Int
 t1issued : Int
 t1settles : Int
 t1carrier : Int
 t1guard : Bool
 t1roots : Bool
 t1restored : Bool
 t1ack : Bool
 current : Int
 parent1 : Int
 kind1 : Int
 presented : Int
 nonce : Int
 hops : Int
 duplicates : Int
 rejected : Int
 markerCreated1 : Bool
 markerLive1 : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.t0phase≥(0)) ∧ (q.t0phase≤(7)) ∧ (q.t0issued≥(0)) ∧ (q.t0issued≤(1)) ∧ (q.t0settles≥(0)) ∧ (q.t0settles≤(1)) ∧ (q.t0carrier≥(0)) ∧ (q.t0carrier≤(2)) ∧ ((q.t0phase>(0)) → ((q.t0guard=true) ∧ (q.t0issued=(1)))) ∧ ((q.t0phase=(0)) → (((q.t0issued=(0)) ∧ (¬(q.t0guard=true))) ∧ (q.t0settles=(0)))) ∧ ((q.t0phase=(2)) → (q.t0roots=true)) ∧ ((q.t0phase=(3)) → (q.t0roots=true)) ∧ ((q.t0phase=(6)) → (((q.t0settles=(1)) ∧ (q.t0witness=(101))) ∧ (q.t0restored=true))) ∧ ((q.t0phase≠(6)) → (q.t0settles=(0))) ∧ ((q.t0witness≠(0)) → ((((q.t0phase=(5)) ∨ (q.t0phase=(6))) ∧ (q.t0witness=(101))) ∧ (q.t0restored=true))) ∧ (q.t1phase≥(0)) ∧ (q.t1phase≤(7)) ∧ (q.t1issued≥(0)) ∧ (q.t1issued≤(1)) ∧ (q.t1settles≥(0)) ∧ (q.t1settles≤(1)) ∧ (q.t1carrier≥(0)) ∧ (q.t1carrier≤(2)) ∧ ((q.t1phase>(0)) → ((q.t1guard=true) ∧ (q.t1issued=(1)))) ∧ ((q.t1phase=(0)) → (((q.t1issued=(0)) ∧ (¬(q.t1guard=true))) ∧ (q.t1settles=(0)))) ∧ ((q.t1phase=(2)) → (q.t1roots=true)) ∧ ((q.t1phase=(3)) → (q.t1roots=true)) ∧ ((q.t1phase=(6)) → (((q.t1settles=(1)) ∧ (q.t1witness=(102))) ∧ (q.t1restored=true))) ∧ ((q.t1phase≠(6)) → (q.t1settles=(0))) ∧ ((q.t1witness≠(0)) → ((((q.t1phase=(5)) ∨ (q.t1phase=(6))) ∧ (q.t1witness=(102))) ∧ (q.t1restored=true))) ∧ (q.current≥(0)) ∧ (q.current≤(2)) ∧ ((q.parent1=(0)) ∨ (q.parent1=(1))) ∧ (q.kind1≥(0)) ∧ (q.kind1≤(2)) ∧ ((q.presented=(1)) ∨ (q.presented=(2))) ∧ ((q.nonce=(101)) ∨ (q.nonce=(102))) ∧ (q.hops≥(0)) ∧ (q.duplicates≥(0)) ∧ (q.rejected≥(0)) ∧ ((q.current=(1)) → (q.t0phase=(2))) ∧ ((q.current=(2)) → (((q.t1phase=(2)) ∨ (q.t1phase=(4))) ∨ (q.t1phase=(7)))) ∧ ((q.t0phase=(2)) → ((q.current=(1)) ∨ ((q.parent1=(1)) ∧ (((q.t1phase=(2)) ∨ (q.t1phase=(4))) ∨ (q.t1phase=(7)))))) ∧ ((q.parent1=(1)) → ((q.t0phase=(2)) ∨ (q.t1phase=(6)))) ∧ ((q.t1phase>(0)) → ((q.kind1=(1)) ∨ (q.kind1=(2)))) ∧ ((q.kind1=(2)) → (q.parent1=(1))) ∧ ((q.markerLive1=true) → (((q.markerCreated1=true) ∧ (q.kind1=(2))) ∧ (q.t1phase≠(6)))) ∧ (((q.t1phase=(5)) ∨ (q.t1phase=(6))) → (¬(q.markerLive1=true))) ∧ ((q.t1phase=(2)) → ((q.kind1=(1)) ∨ (q.markerCreated1=true))) ∧ ((q.parent1=(1)) → (q.t1phase>(0))) ∧ ((q.kind1=(1)) → (q.parent1=(0))) ∧ ((((q.t1phase=(2)) ∨ (q.t1phase=(4))) ∨ (q.t1phase=(7))) → (q.current=(2))) ∧ (((q.t0phase=(4)) ∨ (q.t0phase=(7))) → (q.t0roots=true)) ∧ (((q.t1phase=(4)) ∨ (q.t1phase=(7))) → (q.t1roots=true)))
def initial : State := {t0phase:=(0), t0witness:=(0), t0issued:=(0), t0settles:=(0), t0carrier:=(0), t0guard:=false, t0roots:=false, t0restored:=false, t0ack:=false, t1phase:=(0), t1witness:=(0), t1issued:=(0), t1settles:=(0), t1carrier:=(0), t1guard:=false, t1roots:=false, t1restored:=false, t1ack:=false, current:=(0), parent1:=(0), kind1:=(0), presented:=(1), nonce:=(101), hops:=(0), duplicates:=(0), rejected:=(0), markerCreated1:=false, markerLive1:=false}
def reserveInitial0Guard (q : State) : Prop := (q.t0phase=(0)) ∧ (q.current=(0))
def reserveInitial0Next (q : State) : State := {q with t0phase:=(1), t0guard:=true, t0issued:=(1)}
def publishRoot0Guard (q : State) : Prop := (q.t0phase=(1)) ∧ (q.t0guard=true)
def publishRoot0Next (q : State) : State := {q with t0roots:=true}
def enterInitial0Guard (q : State) : Prop := (q.t0phase=(1)) ∧ (q.t0roots=true) ∧ (q.t0guard=true) ∧ (q.current=(0))
def enterInitial0Next (q : State) : State := {q with t0phase:=(2), current:=(1), t0carrier:=(1)}
def internalGraft0Guard (q : State) : Prop := (q.t0phase=(2)) ∧ (q.current=(1))
def internalGraft0Next (q : State) : State := {q with hops:=(q.hops+(1))}
def suspend0Guard (q : State) : Prop := (q.t0phase=(2)) ∧ (q.current=(1)) ∧ ((q.t1phase=(0)) ∨ (q.t1phase=(6)))
def suspend0Next (q : State) : State := {q with t0phase:=(3), current:=(0)}
def schedulerResume0Guard (q : State) : Prop := (q.t0phase=(3)) ∧ (q.t0roots=true) ∧ (q.t0guard=true) ∧ (q.current=(0))
def schedulerResume0Next (q : State) : State := {q with t0phase:=(2), current:=(1), t0carrier:=(2)}
def bodyReturn0Guard (q : State) : Prop := (q.t0phase=(2)) ∧ (q.current=(1)) ∧ ((q.t1phase=(0)) ∨ (q.t1phase=(6)))
def bodyReturn0Next (q : State) : State := {q with t0phase:=(4), current:=(0)}
def restoreOuter0Guard (q : State) : Prop := (q.t0phase=(4))
def restoreOuter0Next (q : State) : State := {q with t0restored:=true}
def observeExit0Guard (q : State) : Prop := (q.t0phase=(4)) ∧ (q.t0restored=true)
def observeExit0Next (q : State) : State := {q with t0phase:=(5), t0witness:=(101)}
def settle0Guard (q : State) : Prop := (q.t0phase=(5)) ∧ (q.t0witness=(101)) ∧ (q.t0guard=true) ∧ (q.presented=(1)) ∧ (q.nonce=(101))
def settle0Next (q : State) : State := {q with t0phase:=(6), t0settles:=(1)}
def reserveSemantic1Guard (q : State) : Prop := (q.t0phase=(6)) ∧ (q.t1phase=(0)) ∧ (q.current=(0))
def reserveSemantic1Next (q : State) : State := {q with t1phase:=(1), t1guard:=true, t1issued:=(1), parent1:=(0), kind1:=(1)}
def reserveCrossRestore1Guard (q : State) : Prop := (q.t0phase=(2)) ∧ (q.current=(1)) ∧ (q.t1phase=(0))
def reserveCrossRestore1Next (q : State) : State := {q with t0phase:=(7), current:=(0), t1phase:=(1), t1guard:=true, t1issued:=(1), parent1:=(0), kind1:=(1)}
def reserveForeignChild1Guard (q : State) : Prop := (q.t0phase=(2)) ∧ (q.current=(1)) ∧ (q.t1phase=(0))
def reserveForeignChild1Next (q : State) : State := {q with t1phase:=(1), t1guard:=true, t1issued:=(1), parent1:=(1), kind1:=(2)}
def publishRoot1Guard (q : State) : Prop := (q.t1phase=(1)) ∧ (q.t1guard=true)
def publishRoot1Next (q : State) : State := {q with t1roots:=true}
def allocateMarker1Guard (q : State) : Prop := (q.t1phase=(1)) ∧ (q.kind1=(2)) ∧ (q.t1roots=true) ∧ (¬(q.markerCreated1=true))
def allocateMarker1Next (q : State) : State := {q with markerCreated1:=true, markerLive1:=true}
def enter1Guard (q : State) : Prop := (q.t1phase=(1)) ∧ (q.t1guard=true) ∧ (q.t1roots=true) ∧ (q.current=q.parent1) ∧ ((q.kind1=(1)) ∨ ((q.kind1=(2)) ∧ (q.markerLive1=true)))
def enter1Next (q : State) : State := {q with t1phase:=(2), current:=(2), t1carrier:=(1)}
def internalGraft1Guard (q : State) : Prop := (q.t1phase=(2)) ∧ (q.current=(2))
def internalGraft1Next (q : State) : State := {q with hops:=(q.hops+(1))}
def bodyReturn1Guard (q : State) : Prop := (q.t1phase=(2)) ∧ (q.current=(2))
def bodyReturn1Next (q : State) : State := {q with t1phase:=(4)}
def restoreOuter1Guard (q : State) : Prop := (q.t1phase=(4))
def restoreOuter1Next (q : State) : State := {q with t1restored:=true}
def invalidateMarker1Guard (q : State) : Prop := (q.t1phase=(4)) ∧ (q.t1restored=true) ∧ (q.markerLive1=true)
def invalidateMarker1Next (q : State) : State := {q with markerLive1:=false}
def observeExit1Guard (q : State) : Prop := (q.t1phase=(4)) ∧ (q.t1restored=true) ∧ True
def observeExit1Next (q : State) : State := {q with t1phase:=(5), t1witness:=(102), current:=q.parent1}
def settle1Guard (q : State) : Prop := (q.t1phase=(5)) ∧ (q.t1witness=(102)) ∧ (q.t1guard=true) ∧ (q.presented=(2)) ∧ (q.nonce=(102))
def settle1Next (q : State) : State := {q with t1phase:=(6), t1settles:=(1)}
def abortMarkerAllocation1Guard (q : State) : Prop := (q.t1phase=(1)) ∧ (q.kind1=(2)) ∧ (¬(q.markerCreated1=true))
def abortMarkerAllocation1Next (q : State) : State := {q with t1phase:=(5), t1restored:=true, t1witness:=(102)}
def unknownForeignExit1Guard (q : State) : Prop := (q.t1phase=(2)) ∧ (q.current=(2))
def unknownForeignExit1Next (q : State) : State := {q with t1phase:=(7)}
def confirmOuterCatch1Guard (q : State) : Prop := (q.t1phase=(7)) ∧ (q.current=(2))
def confirmOuterCatch1Next (q : State) : State := {q with t1phase:=(4)}
def presentOldGuard (q : State) : Prop := True
def presentOldNext (q : State) : State := {q with presented:=(1), nonce:=(101)}
def presentNewGuard (q : State) : Prop := True
def presentNewNext (q : State) : State := {q with presented:=(2), nonce:=(102)}
def presentOldAsNewGuard (q : State) : Prop := True
def presentOldAsNewNext (q : State) : State := {q with presented:=(2), nonce:=(101)}
def rejectMismatchedGuardGuard (q : State) : Prop := (q.presented=(2)) ∧ (q.nonce≠(102))
def rejectMismatchedGuardNext (q : State) : State := {q with rejected:=(q.rejected+(1))}
def repeatOldReceiptGuard (q : State) : Prop := (q.t0phase=(6)) ∧ (q.presented=(1)) ∧ (q.nonce=(101))
def repeatOldReceiptNext (q : State) : State := {q with duplicates:=(q.duplicates+(1))}
def rejectUnobservedOldExitGuard (q : State) : Prop := (q.t0phase=(7)) ∧ (q.presented=(1)) ∧ (q.nonce=(101))
def rejectUnobservedOldExitNext (q : State) : State := {q with rejected:=(q.rejected+(1))}
def loseReply0Guard (q : State) : Prop := (q.t0phase=(6))
def loseReply0Next (q : State) : State := {q with t0ack:=false}
def query0Guard (q : State) : Prop := (q.t0phase=(6)) ∧ (q.presented=(1)) ∧ (q.nonce=(101))
def query0Next (q : State) : State := {q with t0ack:=true}
def loseReply1Guard (q : State) : Prop := (q.t1phase=(6))
def loseReply1Next (q : State) : State := {q with t1ack:=false}
def query1Guard (q : State) : Prop := (q.t1phase=(6)) ∧ (q.presented=(2)) ∧ (q.nonce=(102))
def query1Next (q : State) : State := {q with t1ack:=true}
def Step (q r : State) : Prop := (reserveInitial0Guard q ∧ r=reserveInitial0Next q) ∨ (publishRoot0Guard q ∧ r=publishRoot0Next q) ∨ (enterInitial0Guard q ∧ r=enterInitial0Next q) ∨ (internalGraft0Guard q ∧ r=internalGraft0Next q) ∨ (suspend0Guard q ∧ r=suspend0Next q) ∨ (schedulerResume0Guard q ∧ r=schedulerResume0Next q) ∨ (bodyReturn0Guard q ∧ r=bodyReturn0Next q) ∨ (restoreOuter0Guard q ∧ r=restoreOuter0Next q) ∨ (observeExit0Guard q ∧ r=observeExit0Next q) ∨ (settle0Guard q ∧ r=settle0Next q) ∨ (reserveSemantic1Guard q ∧ r=reserveSemantic1Next q) ∨ (reserveCrossRestore1Guard q ∧ r=reserveCrossRestore1Next q) ∨ (reserveForeignChild1Guard q ∧ r=reserveForeignChild1Next q) ∨ (publishRoot1Guard q ∧ r=publishRoot1Next q) ∨ (allocateMarker1Guard q ∧ r=allocateMarker1Next q) ∨ (enter1Guard q ∧ r=enter1Next q) ∨ (internalGraft1Guard q ∧ r=internalGraft1Next q) ∨ (bodyReturn1Guard q ∧ r=bodyReturn1Next q) ∨ (restoreOuter1Guard q ∧ r=restoreOuter1Next q) ∨ (invalidateMarker1Guard q ∧ r=invalidateMarker1Next q) ∨ (observeExit1Guard q ∧ r=observeExit1Next q) ∨ (settle1Guard q ∧ r=settle1Next q) ∨ (abortMarkerAllocation1Guard q ∧ r=abortMarkerAllocation1Next q) ∨ (unknownForeignExit1Guard q ∧ r=unknownForeignExit1Next q) ∨ (confirmOuterCatch1Guard q ∧ r=confirmOuterCatch1Next q) ∨ (presentOldGuard q ∧ r=presentOldNext q) ∨ (presentNewGuard q ∧ r=presentNewNext q) ∨ (presentOldAsNewGuard q ∧ r=presentOldAsNewNext q) ∨ (rejectMismatchedGuardGuard q ∧ r=rejectMismatchedGuardNext q) ∨ (repeatOldReceiptGuard q ∧ r=repeatOldReceiptNext q) ∨ (rejectUnobservedOldExitGuard q ∧ r=rejectUnobservedOldExitNext q) ∨ (loseReply0Guard q ∧ r=loseReply0Next q) ∨ (query0Guard q ∧ r=query0Next q) ∨ (loseReply1Guard q ∧ r=loseReply1Next q) ∨ (query1Guard q ∧ r=query1Next q) ∨ r=q
end RestoreEntryAst

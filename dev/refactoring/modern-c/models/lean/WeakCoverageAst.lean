import Std
namespace WeakCoverageAst
set_option maxRecDepth 10000
structure State where
 mode : Int
 kind : Int
 configured : Bool
 memKey : Bool
 keyLive : Bool
 valLive : Bool
 keyTraced : Bool
 valTraced : Bool
 tableDone : Bool
 registered : Bool
 willKind : Int
 actionSeen : Bool
 testatorSeen : Bool
 willFlag : Bool
 cleaned : Bool
 deleted : Bool
 keyResolved : Bool
 valResolved : Bool
 closed : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.mode≥(0)) ∧ (q.mode≤(2)) ∧ (q.kind≥(0)) ∧ (q.kind≤(3)) ∧ (q.willKind≥(0)) ∧ (q.willKind≤(2)) ∧ ((q.keyTraced=true) → ((((q.configured=true) ∧ (q.memKey=true)) ∧ (q.keyLive=true)) ∧ ((q.kind=(0)) ∨ (q.kind=(2))))) ∧ ((q.valTraced=true) → (((q.configured=true) ∧ (q.valLive=true)) ∧ ((q.kind=(0)) ∨ (q.kind=(1))))) ∧ ((q.tableDone=true) → ((q.configured=true) ∧ (q.registered=true) ∧ ((((q.kind=(0)) ∨ (q.kind=(2))) ∧ (q.memKey=true)) → (q.keyTraced=true)) ∧ (((q.kind=(0)) ∨ (q.kind=(1))) → (q.valTraced=true)))) ∧ ((q.willKind=(0)) → (((¬(q.actionSeen=true)) ∧ (¬(q.testatorSeen=true))) ∧ (¬(q.willFlag=true)))) ∧ ((q.willKind=(1)) → ((q.actionSeen=true) ∧ ((q.willFlag=true) ∨ (q.testatorSeen=true)))) ∧ ((q.willKind=(2)) → ((q.actionSeen=true) ∧ (q.testatorSeen=true))) ∧ ((q.willFlag=true) → ((q.willKind=(1)) ∧ (¬(q.testatorSeen=true)))) ∧ ((q.mode≥(1)) → (q.tableDone=true)) ∧ ((q.mode=(2)) → ((q.actionSeen=true) ∧ (q.testatorSeen=true))) ∧ ((q.cleaned=true) → ((q.mode=(2)) ∧ (q.keyResolved=true) ∧ (q.valResolved=true) ∧ ((q.deleted=true) ↔ (((((q.kind=(1)) ∨ (q.kind=(3))) ∧ (q.memKey=true)) ∧ (¬(q.keyLive=true))) ∨ (((q.kind=(2)) ∨ (q.kind=(3))) ∧ (¬(q.valLive=true))))))) ∧ ((q.closed=true) → ((((q.mode=(2)) ∧ (q.cleaned=true)) ∧ (q.keyResolved=true)) ∧ (q.valResolved=true))))
def initial : State := {mode:=(0), kind:=(0), configured:=false, memKey:=true, keyLive:=true, valLive:=true, keyTraced:=false, valTraced:=false, tableDone:=false, registered:=false, willKind:=(0), actionSeen:=false, testatorSeen:=false, willFlag:=false, cleaned:=false, deleted:=false, keyResolved:=false, valResolved:=false, closed:=false}
def configStrongGuard (q : State) : Prop := (¬(q.configured=true))
def configStrongNext (q : State) : State := {q with configured:=true, kind:=(0)}
def configWeakKeyGuard (q : State) : Prop := (¬(q.configured=true))
def configWeakKeyNext (q : State) : State := {q with configured:=true, kind:=(1)}
def configWeakValGuard (q : State) : Prop := (¬(q.configured=true))
def configWeakValNext (q : State) : State := {q with configured:=true, kind:=(2)}
def configWeakBothGuard (q : State) : Prop := (¬(q.configured=true))
def configWeakBothNext (q : State) : State := {q with configured:=true, kind:=(3)}
def configRawKeyGuard (q : State) : Prop := (¬(q.configured=true))
def configRawKeyNext (q : State) : State := {q with configured:=true, kind:=(3), memKey:=false}
def deadKeyGuard (q : State) : Prop := (¬(q.configured=true))
def deadKeyNext (q : State) : State := {q with keyLive:=false}
def deadValGuard (q : State) : Prop := (¬(q.configured=true))
def deadValNext (q : State) : State := {q with valLive:=false}
def traceKeyGuard (q : State) : Prop := (q.configured=true) ∧ (¬(q.tableDone=true)) ∧ (q.memKey=true) ∧ ((q.kind=(0)) ∨ (q.kind=(2)))
def traceKeyNext (q : State) : State := {q with keyTraced:=true, keyLive:=true}
def traceValGuard (q : State) : Prop := (q.configured=true) ∧ (¬(q.tableDone=true)) ∧ ((q.kind=(0)) ∨ (q.kind=(1)))
def traceValNext (q : State) : State := {q with valTraced:=true, valLive:=true}
def tableScanDoneGuard (q : State) : Prop := (q.configured=true) ∧ (¬(q.tableDone=true)) ∧ ((((q.kind=(0)) ∨ (q.kind=(2))) ∧ (q.memKey=true)) → (q.keyTraced=true)) ∧ (((q.kind=(0)) ∨ (q.kind=(1))) → (q.valTraced=true))
def tableScanDoneNext (q : State) : State := {q with tableDone:=true, registered:=true}
def strongWillGuard (q : State) : Prop := (q.mode=(0)) ∧ (q.willKind=(0))
def strongWillNext (q : State) : State := {q with willKind:=(1), actionSeen:=true, willFlag:=true}
def enterWeakGuard (q : State) : Prop := (q.mode=(0)) ∧ (q.tableDone=true)
def enterWeakNext (q : State) : State := {q with mode:=(1)}
def repairWillGuard (q : State) : Prop := (q.mode=(1)) ∧ (q.willKind=(1)) ∧ (q.willFlag=true)
def repairWillNext (q : State) : State := {q with testatorSeen:=true, willFlag:=false}
def freshWeakWillGuard (q : State) : Prop := (q.mode=(1)) ∧ (q.willKind=(0))
def freshWeakWillNext (q : State) : State := {q with willKind:=(2), actionSeen:=true, testatorSeen:=true}
def skipDoneGuard (q : State) : Prop := (q.mode=(1)) ∧ ((q.willKind=(1)) ∨ (q.tableDone=true))
def skipDoneNext (q : State) : State := {q with }
def finishWeakGuard (q : State) : Prop := (q.mode=(1)) ∧ (q.actionSeen=true) ∧ (q.testatorSeen=true)
def finishWeakNext (q : State) : State := {q with mode:=(2)}
def cleanupTableGuard (q : State) : Prop := (q.mode=(2)) ∧ (q.registered=true) ∧ (¬(q.cleaned=true))
def cleanupTableNext (q : State) : State := {q with cleaned:=true, keyResolved:=true, valResolved:=true, deleted:=(decide (((((q.kind=(1)) ∨ (q.kind=(3))) ∧ (q.memKey=true)) ∧ (¬(q.keyLive=true))) ∨ (((q.kind=(2)) ∨ (q.kind=(3))) ∧ (¬(q.valLive=true)))))}
def closeGuard (q : State) : Prop := (q.mode=(2)) ∧ (q.cleaned=true) ∧ (q.keyResolved=true) ∧ (q.valResolved=true)
def closeNext (q : State) : State := {q with closed:=true}
def Step (q r : State) : Prop := (configStrongGuard q ∧ r=configStrongNext q) ∨ (configWeakKeyGuard q ∧ r=configWeakKeyNext q) ∨ (configWeakValGuard q ∧ r=configWeakValNext q) ∨ (configWeakBothGuard q ∧ r=configWeakBothNext q) ∨ (configRawKeyGuard q ∧ r=configRawKeyNext q) ∨ (deadKeyGuard q ∧ r=deadKeyNext q) ∨ (deadValGuard q ∧ r=deadValNext q) ∨ (traceKeyGuard q ∧ r=traceKeyNext q) ∨ (traceValGuard q ∧ r=traceValNext q) ∨ (tableScanDoneGuard q ∧ r=tableScanDoneNext q) ∨ (strongWillGuard q ∧ r=strongWillNext q) ∨ (enterWeakGuard q ∧ r=enterWeakNext q) ∨ (repairWillGuard q ∧ r=repairWillNext q) ∨ (freshWeakWillGuard q ∧ r=freshWeakWillNext q) ∨ (skipDoneGuard q ∧ r=skipDoneNext q) ∨ (finishWeakGuard q ∧ r=finishWeakNext q) ∨ (cleanupTableGuard q ∧ r=cleanupTableNext q) ∨ (closeGuard q ∧ r=closeNext q) ∨ r=q
end WeakCoverageAst

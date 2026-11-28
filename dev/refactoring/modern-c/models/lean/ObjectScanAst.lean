import Std
namespace ObjectScanAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 owner : Int
 t0 : Int
 t1 : Int
 payload : Bool
 forwarded : Bool
 copier : Bool
 tail : Bool
 privateChunk : Bool
 child0 : Bool
 child1 : Bool
 active0 : Bool
 active1 : Bool
 closed : Bool
 terminated : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(3)) ∧ (q.t0≥(0)) ∧ (q.t0≤(4)) ∧ (q.t1≥(0)) ∧ (q.t1≤(4)) ∧ ((q.phase≥(1)) → ((q.payload=true) ∧ (q.forwarded=true))) ∧ ((q.payload=true) → (q.forwarded=true)) ∧ ((q.copier=true) → (q.active0=true)) ∧ ((q.tail=true) → (q.copier=true)) ∧ ((q.privateChunk=true) → ((q.copier=true) ∧ (q.payload=true))) ∧ ((q.phase=(2)) → ((((q.owner=(0)) ∧ (q.t0=(3))) ∧ (q.active0=true)) ∨ (((q.owner=(1)) ∧ (q.t1=(3))) ∧ (q.active1=true)))) ∧ ((q.phase≠(2)) → (q.owner=(-(1)))) ∧ ((q.t0=(3)) → ((q.phase=(2)) ∧ (q.owner=(0)))) ∧ ((q.t1=(3)) → ((q.phase=(2)) ∧ (q.owner=(1)))) ∧ (((q.t0≥(1)) ∧ (q.t0≤(3))) → (q.active0=true)) ∧ (((q.t1≥(1)) ∧ (q.t1≤(3))) → (q.active1=true)) ∧ ((q.t0=(4)) → (q.phase≥(2))) ∧ ((q.t1=(4)) → (q.phase≥(2))) ∧ ((q.child0=true) → (q.active0=true)) ∧ ((q.child1=true) → (q.active1=true)) ∧ ((q.closed=true) → (q.t0≥(1))) ∧ ((q.terminated=true) → ((q.closed=true) ∧ (q.phase=(3)) ∧ (¬(q.active0=true)) ∧ (¬(q.active1=true)) ∧ (¬(q.copier=true)) ∧ (¬(q.tail=true)) ∧ (¬(q.privateChunk=true)) ∧ (¬(q.child0=true)) ∧ (¬(q.child1=true)) ∧ (q.t0=(4)) ∧ ((q.t1=(0)) ∨ (q.t1=(4))))))
def initial : State := {phase:=(0), owner:=(-(1)), t0:=(0), t1:=(0), payload:=false, forwarded:=false, copier:=true, tail:=false, privateChunk:=false, child0:=false, child1:=false, active0:=true, active1:=true, closed:=false, terminated:=false}
def forwardGuard (q : State) : Prop := (q.copier=true) ∧ (¬(q.forwarded=true)) ∧ (¬(q.terminated=true))
def forwardNext (q : State) : State := {q with forwarded:=true, tail:=true}
def initializeCopyGuard (q : State) : Prop := (q.copier=true) ∧ (q.forwarded=true) ∧ (¬(q.payload=true))
def initializeCopyNext (q : State) : State := {q with payload:=true, privateChunk:=true}
def publishReadyGuard (q : State) : Prop := (q.copier=true) ∧ (q.payload=true) ∧ (q.phase=(0))
def publishReadyNext (q : State) : State := {q with phase:=(1)}
def publishBatchGuard (q : State) : Prop := (q.copier=true) ∧ (q.privateChunk=true) ∧ (q.phase≥(1)) ∧ (q.t0=(0))
def publishBatchNext (q : State) : State := {q with privateChunk:=false, t0:=(1)}
def duplicateTaskGuard (q : State) : Prop := (¬(q.closed=true)) ∧ (q.t0≥(1)) ∧ (q.t1=(0)) ∧ (q.active1=true)
def duplicateTaskNext (q : State) : State := {q with t1:=(1)}
def closeInputsGuard (q : State) : Prop := (¬(q.closed=true)) ∧ (q.t0≥(1))
def closeInputsNext (q : State) : State := {q with closed:=true}
def finishTailGuard (q : State) : Prop := (q.copier=true) ∧ (q.phase≥(1)) ∧ (¬(q.privateChunk=true))
def finishTailNext (q : State) : State := {q with tail:=false, copier:=false}
def claim0Guard (q : State) : Prop := (q.active0=true) ∧ (¬(q.copier=true)) ∧ (q.t0=(1))
def claim0Next (q : State) : State := {q with t0:=(2)}
def claim1Guard (q : State) : Prop := (q.active1=true) ∧ (q.t1=(1))
def claim1Next (q : State) : State := {q with t1:=(2)}
def own0Guard (q : State) : Prop := (q.active0=true) ∧ (q.t0=(2)) ∧ (q.phase=(1))
def own0Next (q : State) : State := {q with phase:=(2), owner:=(0), t0:=(3), child0:=true}
def own1Guard (q : State) : Prop := (q.active1=true) ∧ (q.t1=(2)) ∧ (q.phase=(1))
def own1Next (q : State) : State := {q with phase:=(2), owner:=(1), t1:=(3), child1:=true}
def skip0Guard (q : State) : Prop := (q.t0=(2)) ∧ ((q.phase=(2)) ∨ (q.phase=(3))) ∧ (q.owner≠(0))
def skip0Next (q : State) : State := {q with t0:=(4)}
def skip1Guard (q : State) : Prop := (q.t1=(2)) ∧ ((q.phase=(2)) ∨ (q.phase=(3))) ∧ (q.owner≠(1))
def skip1Next (q : State) : State := {q with t1:=(4)}
def done0Guard (q : State) : Prop := (q.t0=(3)) ∧ (q.owner=(0)) ∧ (q.phase=(2))
def done0Next (q : State) : State := {q with phase:=(3), owner:=(-(1)), t0:=(4)}
def done1Guard (q : State) : Prop := (q.t1=(3)) ∧ (q.owner=(1)) ∧ (q.phase=(2))
def done1Next (q : State) : State := {q with phase:=(3), owner:=(-(1)), t1:=(4)}
def drain0Guard (q : State) : Prop := (q.active0=true) ∧ (q.t0=(4)) ∧ (q.child0=true)
def drain0Next (q : State) : State := {q with child0:=false}
def drain1Guard (q : State) : Prop := (q.active1=true) ∧ (q.t1=(4)) ∧ (q.child1=true)
def drain1Next (q : State) : State := {q with child1:=false}
def idle0Guard (q : State) : Prop := (q.closed=true) ∧ (¬(q.copier=true)) ∧ (q.t0=(4)) ∧ (q.owner≠(0)) ∧ (¬(q.child0=true))
def idle0Next (q : State) : State := {q with active0:=false}
def idle1Guard (q : State) : Prop := (q.closed=true) ∧ ((q.t1=(0)) ∨ (q.t1=(4))) ∧ (q.owner≠(1)) ∧ (¬(q.child1=true))
def idle1Next (q : State) : State := {q with active1:=false}
def terminateGuard (q : State) : Prop := (q.closed=true) ∧ (¬(q.active0=true)) ∧ (¬(q.active1=true))
def terminateNext (q : State) : State := {q with terminated:=true}
def Step (q r : State) : Prop := (forwardGuard q ∧ r=forwardNext q) ∨ (initializeCopyGuard q ∧ r=initializeCopyNext q) ∨ (publishReadyGuard q ∧ r=publishReadyNext q) ∨ (publishBatchGuard q ∧ r=publishBatchNext q) ∨ (duplicateTaskGuard q ∧ r=duplicateTaskNext q) ∨ (closeInputsGuard q ∧ r=closeInputsNext q) ∨ (finishTailGuard q ∧ r=finishTailNext q) ∨ (claim0Guard q ∧ r=claim0Next q) ∨ (claim1Guard q ∧ r=claim1Next q) ∨ (own0Guard q ∧ r=own0Next q) ∨ (own1Guard q ∧ r=own1Next q) ∨ (skip0Guard q ∧ r=skip0Next q) ∨ (skip1Guard q ∧ r=skip1Next q) ∨ (done0Guard q ∧ r=done0Next q) ∨ (done1Guard q ∧ r=done1Next q) ∨ (drain0Guard q ∧ r=drain0Next q) ∨ (drain1Guard q ∧ r=drain1Next q) ∨ (idle0Guard q ∧ r=idle0Next q) ∨ (idle1Guard q ∧ r=idle1Next q) ∨ (terminateGuard q ∧ r=terminateNext q) ∨ r=q
end ObjectScanAst

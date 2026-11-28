import Std
namespace MarkerTransportAst
set_option maxRecDepth 10000
structure State where
 mode : Int
 reader : Int
 writer : Int
 link : Int
 exposed : Bool
 alive : Bool
 atomicStorage : Bool
 tagged : Bool
 gate : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.mode≥(1)) → ((q.mode≤(2)) ∧ (q.reader≥(0)) ∧ (q.reader≤(2)) ∧ (q.writer≥(0)) ∧ (q.writer≤(2)) ∧ ((q.mode=(1)) → (q.atomicStorage=true)) ∧ (((q.mode=(1)) ∧ (q.reader>(0))) → (q.reader=(2))) ∧ (((q.mode=(1)) ∧ (q.writer>(0))) → (q.writer=(2))) ∧ (((q.reader>(0)) ∨ (q.writer>(0))) → ((q.alive=true) ∧ (q.exposed=true))) ∧ ((q.writer>(0)) → (q.gate=true)) ∧ (q.tagged=true)))
def initial : State := {mode:=(0), reader:=(0), writer:=(0), link:=(0), exposed:=false, alive:=true, atomicStorage:=false, tagged:=true, gate:=false}
def chooseAtomicGuard (q : State) : Prop := (¬(q.exposed=true)) ∧ (q.alive=true) ∧ (q.reader=(0)) ∧ (q.writer=(0)) ∧ (¬(q.gate=true)) ∧ (q.tagged=true)
def chooseAtomicNext (q : State) : State := {q with mode:=(1), atomicStorage:=true}
def chooseSplitGuard (q : State) : Prop := (¬(q.exposed=true)) ∧ (q.alive=true) ∧ (q.reader=(0)) ∧ (q.writer=(0)) ∧ (¬(q.gate=true)) ∧ (q.tagged=true)
def chooseSplitNext (q : State) : State := {q with mode:=(2)}
def exposeGuard (q : State) : Prop := (q.alive=true)
def exposeNext (q : State) : State := {q with exposed:=true}
def plainReadGuard (q : State) : Prop := (q.mode≠(1)) ∧ (q.alive=true) ∧ (q.exposed=true) ∧ (q.reader=(0))
def plainReadNext (q : State) : State := {q with reader:=(1)}
def atomicReadGuard (q : State) : Prop := (q.mode=(1)) ∧ (q.atomicStorage=true) ∧ (q.alive=true) ∧ (q.exposed=true) ∧ (q.reader=(0))
def atomicReadNext (q : State) : State := {q with reader:=(2)}
def acquireGateGuard (q : State) : Prop := (¬(q.gate=true)) ∧ (q.alive=true)
def acquireGateNext (q : State) : State := {q with gate:=true}
def plainWriteGuard (q : State) : Prop := (q.mode≠(1)) ∧ (q.alive=true) ∧ (q.exposed=true) ∧ (q.gate=true) ∧ (q.writer=(0))
def plainWriteNext (q : State) : State := {q with writer:=(1), link:=(1)}
def atomicWriteGuard (q : State) : Prop := (q.mode=(1)) ∧ (q.atomicStorage=true) ∧ (q.alive=true) ∧ (q.exposed=true) ∧ (q.gate=true) ∧ (q.writer=(0))
def atomicWriteNext (q : State) : State := {q with writer:=(2), link:=(1)}
def finishReadGuard (q : State) : Prop := (q.reader>(0))
def finishReadNext (q : State) : State := {q with reader:=(0)}
def finishWriteGuard (q : State) : Prop := (q.writer>(0))
def finishWriteNext (q : State) : State := {q with writer:=(0)}
def releaseGateGuard (q : State) : Prop := (q.gate=true) ∧ (q.writer=(0))
def releaseGateNext (q : State) : State := {q with gate:=false}
def retireStorageGuard (q : State) : Prop := (q.alive=true) ∧ (q.reader=(0)) ∧ (q.writer=(0)) ∧ (¬(q.gate=true))
def retireStorageNext (q : State) : State := {q with alive:=false}
def Step (q r : State) : Prop := (chooseAtomicGuard q ∧ r=chooseAtomicNext q) ∨ (chooseSplitGuard q ∧ r=chooseSplitNext q) ∨ (exposeGuard q ∧ r=exposeNext q) ∨ (plainReadGuard q ∧ r=plainReadNext q) ∨ (atomicReadGuard q ∧ r=atomicReadNext q) ∨ (acquireGateGuard q ∧ r=acquireGateNext q) ∨ (plainWriteGuard q ∧ r=plainWriteNext q) ∨ (atomicWriteGuard q ∧ r=atomicWriteNext q) ∨ (finishReadGuard q ∧ r=finishReadNext q) ∨ (finishWriteGuard q ∧ r=finishWriteNext q) ∨ (releaseGateGuard q ∧ r=releaseGateNext q) ∨ (retireStorageGuard q ∧ r=retireStorageNext q) ∨ r=q
end MarkerTransportAst

import Std
namespace FormatterLegalAst
set_option maxRecDepth 10000
structure State where
 pc : Int
 writer : Int
 savedWriter : Int
 generation : Int
 capacity : Int
 produced : Int
 consumed : Int
 callbacks : Int
 resumes : Int
 epoch : Int
 planEpoch : Int
 lastWriteEpoch : Int
 writes : Int
 demand : Int
 certGen : Int
 certEpoch : Int
 attempts : Int
 validVar : Bool
 pipe : Bool
 handler : Bool
 captured : Bool
 custody : Bool
 newer : Bool
 clobbered : Bool
 closed : Bool
 fault : Bool
 equivalent : Bool
 certificate : Bool
 alive : Bool
 raw : Bool
 locked : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.pc≥(0)) ∧ (q.pc≤(8)) ∧ (q.writer≥(0)) ∧ (q.writer≤(2)) ∧ (q.savedWriter≥(0)) ∧ (q.savedWriter≤(2)) ∧ (q.generation≥(1)) ∧ (q.capacity=(1)) ∧ (q.produced≥(0)) ∧ (q.produced≤(64)) ∧ (q.consumed≥(0)) ∧ (q.consumed≤q.produced) ∧ (q.callbacks≥(0)) ∧ (q.callbacks≤(1)) ∧ (q.resumes≥(0)) ∧ (q.epoch≥(1)) ∧ (q.planEpoch≥(1)) ∧ (q.lastWriteEpoch≥(0)) ∧ (q.lastWriteEpoch≤q.epoch) ∧ (q.writes≥(0)) ∧ (q.demand≥(0)) ∧ (q.demand≤(2)) ∧ (q.certGen≥(0)) ∧ (q.certEpoch≥(0)) ∧ (q.attempts≥(0)) ∧ ((q.captured=true) → (q.custody=true)) ∧ ((q.pc≥(2)) → (q.custody=true)) ∧ ((((q.pc=(3)) ∨ (q.pc=(5))) ∨ (q.pc=(6))) → (q.callbacks=(1))) ∧ ((((q.pc=(4)) ∨ (q.pc=(7))) ∨ (q.pc=(8))) → (q.callbacks=(0))) ∧ ((q.locked=true) → (q.pc=(8))) ∧ ((q.pc=(8)) → (q.locked=true)) ∧ ((q.certificate=true) → (((((((((((((q.pc=(7)) ∧ (q.closed=true)) ∧ (¬(q.captured=true))) ∧ (q.callbacks=(0))) ∧ (q.alive=true)) ∧ (q.epoch=q.planEpoch)) ∧ (q.demand=(1))) ∧ (¬(q.raw=true))) ∧ (¬(q.clobbered=true))) ∧ (q.writer=q.savedWriter)) ∧ (q.generation=q.certGen)) ∧ (q.epoch=q.certEpoch)) ∧ (q.equivalent=true))))
def initial : State := {pc:=(0), writer:=(1), savedWriter:=(1), generation:=(1), capacity:=(1), produced:=(0), consumed:=(0), callbacks:=(0), resumes:=(0), epoch:=(1), planEpoch:=(1), lastWriteEpoch:=(0), writes:=(0), demand:=(1), certGen:=(0), certEpoch:=(0), attempts:=(0), validVar:=false, pipe:=false, handler:=false, captured:=false, custody:=false, newer:=false, clobbered:=false, closed:=false, fault:=false, equivalent:=false, certificate:=false, alive:=true, raw:=false, locked:=false}
def prepareGuard (q : State) : Prop := (q.pc=(0))
def prepareNext (q : State) : State := {q with pc:=(1), validVar:=true, pipe:=true, handler:=true}
def enterGuard (q : State) : Prop := (q.pc=(1)) ∧ (q.validVar=true) ∧ (q.pipe=true) ∧ (q.handler=true)
def enterNext (q : State) : State := {q with pc:=(2), writer:=(0), savedWriter:=q.writer, generation:=(q.generation+(1)), custody:=true, planEpoch:=q.epoch}
def fillGuard (q : State) : Prop := (q.pc=(2)) ∧ (q.produced=(0))
def fillNext (q : State) : State := {q with produced:=(64)}
def timeoutGuard (q : State) : Prop := (q.pc=(2)) ∧ ((q.produced-q.consumed)>((32)+q.capacity))
def timeoutNext (q : State) : State := {q with pc:=(3), callbacks:=(1), fault:=true}
def captureEscapeGuard (q : State) : Prop := (q.pc=(3))
def captureEscapeNext (q : State) : State := {q with pc:=(4), captured:=true, callbacks:=(0)}
def publishGuard (q : State) : Prop := ((q.pc=(4)) ∨ (q.pc=(7)))
def publishNext (q : State) : State := {q with writer:=(2), generation:=(q.generation+(1)), newer:=true, certificate:=false, equivalent:=false}
def drainGuard (q : State) : Prop := ((q.pc=(4)) ∨ (q.pc=(7)))
def drainNext (q : State) : State := {q with consumed:=q.produced}
def resumeGuard (q : State) : Prop := ((q.pc=(4)) ∨ (q.pc=(7))) ∧ (q.captured=true) ∧ (q.consumed=q.produced)
def resumeNext (q : State) : State := {q with pc:=(5), callbacks:=(1), resumes:=(q.resumes+(1)), equivalent:=false, certificate:=false}
def returnHandlerGuard (q : State) : Prop := (q.pc=(3))
def returnHandlerNext (q : State) : State := {q with pc:=(5)}
def namedTailGuard (q : State) : Prop := (q.pc=(5)) ∧ (q.alive=true)
def namedTailNext (q : State) : State := {q with pc:=(6), writes:=(q.writes+(1)), lastWriteEpoch:=q.epoch, demand:=(1)}
def rawTailGuard (q : State) : Prop := (q.pc=(5)) ∧ (q.alive=true)
def rawTailNext (q : State) : State := {q with pc:=(6), writes:=(q.writes+(1)), lastWriteEpoch:=q.epoch, demand:=(2), raw:=true}
def rejectDeadGuard (q : State) : Prop := (q.pc=(5)) ∧ (¬(q.alive=true))
def rejectDeadNext (q : State) : State := {q with pc:=(4), callbacks:=(0), captured:=true, equivalent:=false, certificate:=false}
def resetRegistryGuard (q : State) : Prop := ((q.pc=(4)) ∨ (q.pc=(7)))
def resetRegistryNext (q : State) : State := {q with epoch:=(q.epoch+(1)), demand:=(0), alive:=true, certificate:=false, equivalent:=false}
def endRegistryGuard (q : State) : Prop := ((q.pc=(4)) ∨ (q.pc=(7)))
def endRegistryNext (q : State) : State := {q with alive:=false, certificate:=false, equivalent:=false}
def callbackReturnsGuard (q : State) : Prop := (q.pc=(6))
def callbackReturnsNext (q : State) : State := {q with pc:=(8), callbacks:=(0), locked:=true}
def finishGuard (q : State) : Prop := (q.pc=(8))
def finishNext (q : State) : State := {q with pc:=(7), writer:=q.savedWriter, generation:=(q.generation+(1)), locked:=false, clobbered:=(decide ((q.clobbered=true) ∨ ((q.newer=true) ∧ (q.writer=(2)))))}
def closeAdmissionGuard (q : State) : Prop := ((q.pc=(4)) ∨ (q.pc=(7)))
def closeAdmissionNext (q : State) : State := {q with closed:=true}
def detachGuard (q : State) : Prop := (q.pc=(7)) ∧ (q.captured=true)
def detachNext (q : State) : State := {q with captured:=false}
def attestGuard (q : State) : Prop := (q.pc=(7)) ∧ (q.closed=true) ∧ (¬(q.captured=true)) ∧ (q.callbacks=(0)) ∧ (q.alive=true) ∧ (q.epoch=q.planEpoch) ∧ (q.demand=(1)) ∧ (¬(q.raw=true)) ∧ (¬(q.clobbered=true)) ∧ (q.writer=q.savedWriter)
def attestNext (q : State) : State := {q with equivalent:=true}
def issueGuard (q : State) : Prop := (q.pc=(7)) ∧ (q.closed=true) ∧ True ∧ (q.callbacks=(0)) ∧ (q.alive=true) ∧ (q.epoch=q.planEpoch) ∧ (q.demand=(1)) ∧ (¬(q.raw=true)) ∧ (¬(q.clobbered=true)) ∧ (q.writer=q.savedWriter) ∧ (q.equivalent=true)
def issueNext (q : State) : State := {q with certificate:=true, certGen:=q.generation, certEpoch:=q.epoch}
def attemptStaleGuard (q : State) : Prop := ((q.pc=(4)) ∨ (q.pc=(7))) ∧ (q.captured=true)
def attemptStaleNext (q : State) : State := {q with attempts:=(q.attempts+(1))}
def Step (q r : State) : Prop := (prepareGuard q ∧ r=prepareNext q) ∨ (enterGuard q ∧ r=enterNext q) ∨ (fillGuard q ∧ r=fillNext q) ∨ (timeoutGuard q ∧ r=timeoutNext q) ∨ (captureEscapeGuard q ∧ r=captureEscapeNext q) ∨ (publishGuard q ∧ r=publishNext q) ∨ (drainGuard q ∧ r=drainNext q) ∨ (resumeGuard q ∧ r=resumeNext q) ∨ (returnHandlerGuard q ∧ r=returnHandlerNext q) ∨ (namedTailGuard q ∧ r=namedTailNext q) ∨ (rawTailGuard q ∧ r=rawTailNext q) ∨ (rejectDeadGuard q ∧ r=rejectDeadNext q) ∨ (resetRegistryGuard q ∧ r=resetRegistryNext q) ∨ (endRegistryGuard q ∧ r=endRegistryNext q) ∨ (callbackReturnsGuard q ∧ r=callbackReturnsNext q) ∨ (finishGuard q ∧ r=finishNext q) ∨ (closeAdmissionGuard q ∧ r=closeAdmissionNext q) ∨ (detachGuard q ∧ r=detachNext q) ∨ (attestGuard q ∧ r=attestNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (attemptStaleGuard q ∧ r=attemptStaleNext q) ∨ r=q
end FormatterLegalAst

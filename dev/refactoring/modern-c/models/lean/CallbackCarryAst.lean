import Std
namespace CallbackCarryAst
set_option maxRecDepth 10000
structure State where
 pc : Int
 wlo : Int
 whi : Int
 rlo : Int
 rhi : Int
 carry : Int
 physical : Int
 bias : Int
 roots : Int
 active : Int
 epoch : Int
 sealedEpoch : Int
 closed : Bool
 mapped : Bool
 released : Bool
 permit : Bool
 unknown : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.pc≥(0)) ∧ (q.pc≤(6)) ∧ (q.wlo≥(0)) ∧ (q.whi≥(0)) ∧ (q.rlo≥(0)) ∧ (q.rhi≥(0)) ∧ (q.roots≥(0)) ∧ (q.active≥(0)) ∧ (q.epoch≥(1)) ∧ (q.sealedEpoch≥(0)) ∧ ((q.carry=(0)) ∨ (q.carry=(4))) ∧ ((q.pc=(1)) → (((((q.wlo=(32)) ∧ (q.whi=(8))) ∧ (q.rhi=(32))) ∧ (q.rlo=((32)-q.carry))) ∧ (q.physical=((8)+q.carry)))) ∧ ((((q.pc=(2)) ∨ (q.pc=(3))) ∨ (q.pc=(6))) → ((((q.wlo=q.carry) ∧ (q.whi=(8))) ∧ (q.rlo=((32)-q.carry))) ∧ (q.physical=((8)+q.carry)))) ∧ (((q.pc=(4)) ∨ (q.pc=(5))) → (((((q.wlo=q.carry) ∧ (q.whi=((8)+q.carry))) ∧ (q.rlo=(0))) ∧ (q.bias=q.carry)) ∧ (q.physical=(((q.wlo+q.whi)-q.rlo)-q.bias)))) ∧ ((q.released=true) → ((((q.closed=true) ∧ (q.mapped=true)) ∧ (q.roots=(0))) ∧ (q.active=(0)))) ∧ ((q.closed=true) → (((q.mapped=true) ∧ (q.roots=(0))) ∧ (q.active=(0)))) ∧ ((q.permit=true) → ((q.sealedEpoch=q.epoch) ∧ (¬(q.unknown=true)))))
def initial : State := {pc:=(0), wlo:=(0), whi:=(0), rlo:=(0), rhi:=(0), carry:=(0), physical:=(0), bias:=(0), roots:=(0), active:=(0), epoch:=(1), sealedEpoch:=(0), closed:=false, mapped:=false, released:=false, permit:=false, unknown:=false}
def beginLegalGuard (q : State) : Prop := (q.pc=(0)) ∧ (¬(q.released=true))
def beginLegalNext (q : State) : State := {q with pc:=(1), wlo:=(32), whi:=(8), rlo:=(32), rhi:=(32), carry:=(0), physical:=(8)}
def beginInternalCarryGuard (q : State) : Prop := (q.pc=(0)) ∧ (¬(q.released=true))
def beginInternalCarryNext (q : State) : State := {q with pc:=(1), wlo:=(32), whi:=(8), rlo:=(28), rhi:=(32), carry:=(4), physical:=(12)}
def advanceFifoGuard (q : State) : Prop := (q.pc=(1))
def advanceFifoNext (q : State) : State := {q with pc:=(2), wlo:=(q.wlo-q.rlo)}
def allocateCandidateGuard (q : State) : Prop := (q.pc=(2))
def allocateCandidateNext (q : State) : State := {q with pc:=(3)}
def installSharedGuard (q : State) : Prop := (q.pc=(3))
def installSharedNext (q : State) : State := {q with pc:=(4), whi:=(q.whi+q.carry), rlo:=(0), rhi:=(0), bias:=q.carry}
def exposeGuard (q : State) : Prop := (q.pc=(4))
def exposeNext (q : State) : State := {q with pc:=(5), rhi:=q.whi}
def allocationFailureGuard (q : State) : Prop := (q.pc=(2))
def allocationFailureNext (q : State) : State := {q with pc:=(6)}
def captureGuard (q : State) : Prop := (q.pc≥(1)) ∧ (¬(q.closed=true)) ∧ (¬(q.released=true))
def captureNext (q : State) : State := {q with roots:=(q.roots+(1))}
def resumeGuard (q : State) : Prop := (q.roots>(0)) ∧ (¬(q.closed=true)) ∧ (¬(q.released=true))
def resumeNext (q : State) : State := {q with active:=(q.active+(1))}
def returnActivationGuard (q : State) : Prop := (q.active>(0))
def returnActivationNext (q : State) : State := {q with active:=(q.active-(1))}
def attestRootRetirementGuard (q : State) : Prop := (q.active=(0))
def attestRootRetirementNext (q : State) : State := {q with closed:=true, mapped:=true, roots:=(0)}
def releaseGuard (q : State) : Prop := (q.closed=true) ∧ (q.mapped=true) ∧ (q.roots=(0)) ∧ (q.active=(0))
def releaseNext (q : State) : State := {q with released:=true}
def changeRegistrationGuard (q : State) : Prop := (¬(q.closed=true))
def changeRegistrationNext (q : State) : State := {q with epoch:=(q.epoch+(1)), permit:=false}
def unknownCallbackGuard (q : State) : Prop := (¬(q.closed=true))
def unknownCallbackNext (q : State) : State := {q with unknown:=true, permit:=false}
def attestEffectsGuard (q : State) : Prop := (¬(q.unknown=true))
def attestEffectsNext (q : State) : State := {q with sealedEpoch:=q.epoch, permit:=true}
def Step (q r : State) : Prop := (beginLegalGuard q ∧ r=beginLegalNext q) ∨ (beginInternalCarryGuard q ∧ r=beginInternalCarryNext q) ∨ (advanceFifoGuard q ∧ r=advanceFifoNext q) ∨ (allocateCandidateGuard q ∧ r=allocateCandidateNext q) ∨ (installSharedGuard q ∧ r=installSharedNext q) ∨ (exposeGuard q ∧ r=exposeNext q) ∨ (allocationFailureGuard q ∧ r=allocationFailureNext q) ∨ (captureGuard q ∧ r=captureNext q) ∨ (resumeGuard q ∧ r=resumeNext q) ∨ (returnActivationGuard q ∧ r=returnActivationNext q) ∨ (attestRootRetirementGuard q ∧ r=attestRootRetirementNext q) ∨ (releaseGuard q ∧ r=releaseNext q) ∨ (changeRegistrationGuard q ∧ r=changeRegistrationNext q) ∨ (unknownCallbackGuard q ∧ r=unknownCallbackNext q) ∨ (attestEffectsGuard q ∧ r=attestEffectsNext q) ∨ r=q
end CallbackCarryAst

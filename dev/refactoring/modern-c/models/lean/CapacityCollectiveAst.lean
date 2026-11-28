import Std
namespace CapacityCollectiveAst
set_option maxRecDepth 10000
structure State where
 generation : Int
 decision : Int
 vote0 : Int
 vote1 : Int
 seen0 : Int
 seen1 : Int
 result0 : Int
 result1 : Int
 published : Bool
 poolReady : Bool
 ack0 : Bool
 ack1 : Bool
 reader0 : Bool
 reader1 : Bool
 released : Bool
 flip0 : Bool
 flip1 : Bool
 retained : Bool
 freed : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.generation=(7)) ∧ (q.decision≥(0)) ∧ (q.decision≤(2)) ∧ (q.vote0≥(0)) ∧ (q.vote0≤(2)) ∧ (q.vote1≥(0)) ∧ (q.vote1≤(2)) ∧ (q.result0≥(0)) ∧ (q.result0≤(2)) ∧ (q.result1≥(0)) ∧ (q.result1≤(2)) ∧ ((q.vote0>(0)) → ((q.published=true) ∧ (q.seen0=q.generation))) ∧ ((q.vote1>(0)) → ((q.published=true) ∧ (q.seen1=q.generation))) ∧ ((q.vote0=(1)) → (q.poolReady=true)) ∧ ((q.vote1=(1)) → (q.poolReady=true)) ∧ ((q.vote0=(0)) → (q.seen0=(-(1)))) ∧ ((q.vote1=(0)) → (q.seen1=(-(1)))) ∧ ((q.decision>(0)) → ((q.vote0>(0)) ∧ (q.vote1>(0)))) ∧ ((q.decision=(1)) → (((q.poolReady=true) ∧ (q.vote0=(1))) ∧ (q.vote1=(1)))) ∧ ((q.decision=(2)) → ((q.vote0=(2)) ∨ (q.vote1=(2)))) ∧ ((q.ack0=true) → ((q.decision>(0)) ∧ (¬(q.reader0=true)))) ∧ ((q.ack1=true) → ((q.decision>(0)) ∧ (¬(q.reader1=true)))) ∧ ((q.reader0=true) → ((q.vote0>(0)) ∧ (¬(q.ack0=true)))) ∧ ((q.reader1=true) → ((q.vote1>(0)) ∧ (¬(q.ack1=true)))) ∧ ((q.released=true) → ((q.ack0=true) ∧ (q.ack1=true))) ∧ (((q.flip0=true) ∨ (q.flip1=true)) → (((q.released=true) ∧ (q.decision=(1))) ∧ (¬(q.freed=true)))) ∧ ((q.result0>(0)) → ((q.released=true) ∧ (q.result0=q.decision))) ∧ ((q.result1>(0)) → ((q.released=true) ∧ (q.result1=q.decision))) ∧ ((q.freed=true) → ((((((q.released=true) ∧ (q.decision=(2))) ∧ (q.result0=(2))) ∧ (q.result1=(2))) ∧ (¬(q.reader0=true))) ∧ (¬(q.reader1=true)))))
def initial : State := {generation:=(7), decision:=(0), vote0:=(0), vote1:=(0), seen0:=(-(1)), seen1:=(-(1)), result0:=(0), result1:=(0), published:=false, poolReady:=false, ack0:=false, ack1:=false, reader0:=false, reader1:=false, released:=false, flip0:=false, flip1:=false, retained:=false, freed:=false}
def publishReadyGuard (q : State) : Prop := (¬(q.published=true))
def publishReadyNext (q : State) : State := {q with published:=true, poolReady:=true}
def publishFailureGuard (q : State) : Prop := (¬(q.published=true))
def publishFailureNext (q : State) : State := {q with published:=true, poolReady:=false}
def accept0Guard (q : State) : Prop := (q.published=true) ∧ (q.poolReady=true) ∧ (q.vote0=(0))
def accept0Next (q : State) : State := {q with vote0:=(1), seen0:=q.generation, reader0:=true}
def accept1Guard (q : State) : Prop := (q.published=true) ∧ (q.poolReady=true) ∧ (q.vote1=(0))
def accept1Next (q : State) : State := {q with vote1:=(1), seen1:=q.generation, reader1:=true}
def reject0Guard (q : State) : Prop := (q.published=true) ∧ (q.vote0=(0))
def reject0Next (q : State) : State := {q with vote0:=(2), seen0:=q.generation, reader0:=true}
def reject1Guard (q : State) : Prop := (q.published=true) ∧ (q.vote1=(0))
def reject1Next (q : State) : State := {q with vote1:=(2), seen1:=q.generation, reader1:=true}
def decideAcceptGuard (q : State) : Prop := (q.decision=(0)) ∧ (q.vote0=(1)) ∧ (q.vote1=(1))
def decideAcceptNext (q : State) : State := {q with decision:=(1)}
def decideRejectGuard (q : State) : Prop := (q.decision=(0)) ∧ (q.vote0>(0)) ∧ (q.vote1>(0)) ∧ ((q.vote0=(2)) ∨ (q.vote1=(2)))
def decideRejectNext (q : State) : State := {q with decision:=(2)}
def acknowledge0Guard (q : State) : Prop := (q.decision>(0)) ∧ (¬(q.ack0=true))
def acknowledge0Next (q : State) : State := {q with ack0:=true, reader0:=false}
def acknowledge1Guard (q : State) : Prop := (q.decision>(0)) ∧ (¬(q.ack1=true))
def acknowledge1Next (q : State) : State := {q with ack1:=true, reader1:=false}
def releaseGuard (q : State) : Prop := (q.decision>(0)) ∧ (q.ack0=true) ∧ (q.ack1=true)
def releaseNext (q : State) : State := {q with released:=true}
def flip0Guard (q : State) : Prop := (q.released=true) ∧ (q.decision=(1)) ∧ (¬(q.flip0=true))
def flip0Next (q : State) : State := {q with flip0:=true}
def flip1Guard (q : State) : Prop := (q.released=true) ∧ (q.decision=(1)) ∧ (¬(q.flip1=true))
def flip1Next (q : State) : State := {q with flip1:=true}
def deliver0Guard (q : State) : Prop := (q.released=true) ∧ (q.decision>(0)) ∧ (q.result0=(0))
def deliver0Next (q : State) : State := {q with result0:=q.decision}
def deliver1Guard (q : State) : Prop := (q.released=true) ∧ (q.decision>(0)) ∧ (q.result1=(0))
def deliver1Next (q : State) : State := {q with result1:=q.decision}
def retainUnknownGuard (q : State) : Prop := (q.published=true) ∧ (¬((q.ack0=true) ∧ (q.ack1=true)))
def retainUnknownNext (q : State) : State := {q with retained:=true}
def retainSetupUnknownGuard (q : State) : Prop := (q.released=true) ∧ (q.decision=(1)) ∧ (¬((q.flip0=true) ∧ (q.flip1=true)))
def retainSetupUnknownNext (q : State) : State := {q with retained:=true}
def freeRejectedGuard (q : State) : Prop := (¬(q.freed=true)) ∧ (q.released=true) ∧ (q.decision=(2)) ∧ (q.result0=(2)) ∧ (q.result1=(2)) ∧ (¬(q.reader0=true)) ∧ (¬(q.reader1=true))
def freeRejectedNext (q : State) : State := {q with freed:=true}
def Step (q r : State) : Prop := (publishReadyGuard q ∧ r=publishReadyNext q) ∨ (publishFailureGuard q ∧ r=publishFailureNext q) ∨ (accept0Guard q ∧ r=accept0Next q) ∨ (accept1Guard q ∧ r=accept1Next q) ∨ (reject0Guard q ∧ r=reject0Next q) ∨ (reject1Guard q ∧ r=reject1Next q) ∨ (decideAcceptGuard q ∧ r=decideAcceptNext q) ∨ (decideRejectGuard q ∧ r=decideRejectNext q) ∨ (acknowledge0Guard q ∧ r=acknowledge0Next q) ∨ (acknowledge1Guard q ∧ r=acknowledge1Next q) ∨ (releaseGuard q ∧ r=releaseNext q) ∨ (flip0Guard q ∧ r=flip0Next q) ∨ (flip1Guard q ∧ r=flip1Next q) ∨ (deliver0Guard q ∧ r=deliver0Next q) ∨ (deliver1Guard q ∧ r=deliver1Next q) ∨ (retainUnknownGuard q ∧ r=retainUnknownNext q) ∨ (retainSetupUnknownGuard q ∧ r=retainSetupUnknownNext q) ∨ (freeRejectedGuard q ∧ r=freeRejectedNext q) ∨ r=q
end CapacityCollectiveAst

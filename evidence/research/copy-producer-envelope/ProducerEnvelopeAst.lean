import Std
namespace ProducerEnvelopeAst
set_option maxRecDepth 10000
structure State where
 epoch : Int
 seenEpoch : Int
 objectMax : Int
 frameFs : Int
 cap : Int
 q : Int
 u : Int
 align : Int
 threshold : Int
 budget : Int
 spent : Int
 phase : Int
 denied : Int
 objects : Bool
 frames : Bool
 abi : Bool
 oldPinned : Bool
 sourceWitness : Bool
 source : Bool
 frozen : Bool
 sealed : Bool
 started : Bool
 alternative : Bool
 retained : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := (((¬(q.started=true)) → (q.spent=(0))) ∧ (q.epoch≥(1)) ∧ (q.epoch≤(2)) ∧ (q.objectMax=(300)) ∧ (q.frameFs=(37)) ∧ (q.q=(510)) ∧ (q.cap≥(0)) ∧ (q.spent≥(0)) ∧ (q.spent≤q.u) ∧ (q.denied≥(0)) ∧ (q.phase≥(0)) ∧ (q.phase≤(1)) ∧ (q.u≥(0)) ∧ (q.align≥(0)) ∧ (q.align≤q.q) ∧ (q.u≤(q.q+q.align)) ∧ (q.threshold≥(0)) ∧ (q.budget≥(q.u+q.threshold)) ∧ (q.seenEpoch≥(0)) ∧ (q.seenEpoch≤q.epoch) ∧ ((q.frozen=true) → (((q.objects=true) ∧ (q.frames=true)) ∧ (q.sourceWitness=true))) ∧ ((q.source=true) → (q.frozen=true)) ∧ ((q.alternative=true) → (((q.retained=true) ∧ (¬(q.sealed=true))) ∧ (¬(q.started=true)))) ∧ ((q.sealed=true) → (((((((((((q.objects=true) ∧ (q.frames=true)) ∧ (q.abi=true)) ∧ (q.oldPinned=true)) ∧ (q.source=true)) ∧ (q.frozen=true)) ∧ (q.sourceWitness=true)) ∧ (¬(q.alternative=true))) ∧ (q.seenEpoch=q.epoch)) ∧ (q.cap≥q.objectMax)) ∧ (q.cap≥(q.frameFs+(2))))) ∧ ((q.started=true) → (q.sealed=true)) ∧ ((q.phase=(1)) → (q.started=true)))
def initial : State := {epoch:=(1), seenEpoch:=(0), objectMax:=(300), frameFs:=(37), cap:=(0), q:=(510), u:=(0), align:=(0), threshold:=(0), budget:=(0), spent:=(0), phase:=(0), denied:=(0), objects:=false, frames:=false, abi:=true, oldPinned:=true, sourceWitness:=true, source:=false, frozen:=false, sealed:=false, started:=false, alternative:=false, retained:=false}
def coverObjectsGuard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.alternative=true))
def coverObjectsNext (q : State) : State := {q with objects:=true}
def coverFramesGuard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.alternative=true))
def coverFramesNext (q : State) : State := {q with frames:=true}
def chooseCapGuard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.alternative=true))
def chooseCapNext (q : State) : State := {q with cap:=(300)}
def abiMismatchGuard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.alternative=true))
def abiMismatchNext (q : State) : State := {q with abi:=false, alternative:=true, retained:=true}
def opaqueProducerGuard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.alternative=true))
def opaqueProducerNext (q : State) : State := {q with objects:=false, alternative:=true, retained:=true}
def missingOldModuleGuard (q : State) : Prop := (¬(q.started=true)) ∧ (¬(q.alternative=true))
def missingOldModuleNext (q : State) : State := {q with oldPinned:=false, sealed:=false, alternative:=true, retained:=true}
def missingSourceWitnessGuard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.alternative=true))
def missingSourceWitnessNext (q : State) : State := {q with sourceWitness:=false, alternative:=true, retained:=true}
def freeze64Guard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.alternative=true)) ∧ (q.objects=true) ∧ (q.frames=true) ∧ (q.sourceWitness=true)
def freeze64Next (q : State) : State := {q with frozen:=true, source:=true, seenEpoch:=q.epoch, u:=(510), align:=(0), threshold:=(2), budget:=(512)}
def freeze32Guard (q : State) : Prop := (¬(q.frozen=true)) ∧ (¬(q.alternative=true)) ∧ (q.objects=true) ∧ (q.frames=true) ∧ (q.sourceWitness=true)
def freeze32Next (q : State) : State := {q with frozen:=true, source:=true, seenEpoch:=q.epoch, u:=(1020), align:=(510), threshold:=(4), budget:=(1024)}
def issueGuard (q : State) : Prop := (q.frozen=true) ∧ (q.objects=true) ∧ (q.frames=true) ∧ (q.abi=true) ∧ (q.oldPinned=true) ∧ (q.source=true) ∧ (q.sourceWitness=true) ∧ (¬(q.alternative=true)) ∧ (¬(q.sealed=true)) ∧ (q.seenEpoch=q.epoch) ∧ (q.cap≥q.objectMax) ∧ (q.cap≥(q.frameFs+(2))) ∧ (q.budget≥(q.u+q.threshold))
def issueNext (q : State) : State := {q with sealed:=true}
def startGuard (q : State) : Prop := (q.sealed=true) ∧ (¬(q.started=true)) ∧ (¬(q.alternative=true))
def startNext (q : State) : State := {q with started:=true}
def consumeGuard (q : State) : Prop := (q.started=true) ∧ ((q.spent+(1))≤q.u)
def consumeNext (q : State) : State := {q with spent:=(q.spent+(1))}
def weakCutGuard (q : State) : Prop := (q.started=true) ∧ (q.phase=(0))
def weakCutNext (q : State) : State := {q with phase:=(1)}
def deferLateModuleGuard (q : State) : Prop := (q.started=true)
def deferLateModuleNext (q : State) : State := {q with denied:=(q.denied+(1))}
def replaceBeforeStartGuard (q : State) : Prop := (¬(q.started=true)) ∧ (¬(q.alternative=true))
def replaceBeforeStartNext (q : State) : State := {q with epoch:=(2), sealed:=false, alternative:=true, retained:=true}
def Step (q r : State) : Prop := (coverObjectsGuard q ∧ r=coverObjectsNext q) ∨ (coverFramesGuard q ∧ r=coverFramesNext q) ∨ (chooseCapGuard q ∧ r=chooseCapNext q) ∨ (abiMismatchGuard q ∧ r=abiMismatchNext q) ∨ (opaqueProducerGuard q ∧ r=opaqueProducerNext q) ∨ (missingOldModuleGuard q ∧ r=missingOldModuleNext q) ∨ (missingSourceWitnessGuard q ∧ r=missingSourceWitnessNext q) ∨ (freeze64Guard q ∧ r=freeze64Next q) ∨ (freeze32Guard q ∧ r=freeze32Next q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (startGuard q ∧ r=startNext q) ∨ (consumeGuard q ∧ r=consumeNext q) ∨ (weakCutGuard q ∧ r=weakCutNext q) ∨ (deferLateModuleGuard q ∧ r=deferLateModuleNext q) ∨ (replaceBeforeStartGuard q ∧ r=replaceBeforeStartNext q) ∨ r=q
end ProducerEnvelopeAst

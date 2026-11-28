import Std
namespace ContinuationRestoreAst
set_option maxRecDepth 10000
structure State where
 r0 : Int
 r1 : Int
 mode0 : Int
 mode1 : Int
 cap0 : Int
 cap1 : Int
 outcome : Int
 denied : Int
 frozen : Bool
 retained : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.r0≥(0)) ∧ (q.r1≥(0)) ∧ (q.mode0≥(0)) ∧ (q.mode0≤(3)) ∧ (q.mode1≥(0)) ∧ (q.mode1≤(3)) ∧ (q.outcome≥(0)) ∧ (q.outcome≤(2)) ∧ (q.denied≥(0)) ∧ ((((q.mode0>(0)) ∨ (q.mode1>(0))) ∨ (q.outcome>(0))) → (q.frozen=true)) ∧ ((¬(q.frozen=true)) → (((((q.r0=(0)) ∧ (q.r1=(0))) ∧ (q.mode0=(0))) ∧ (q.mode1=(0))) ∧ (q.outcome=(0)))) ∧ ((q.frozen=true) → ((q.r0≥(4)) ∧ (q.r1≥(4)))) ∧ ((q.mode0=(0)) → (q.cap0=(0))) ∧ ((q.mode1=(0)) → (q.cap1=(0))) ∧ ((q.mode0=(1)) → ((q.cap0=(20)) ∧ ((q.r0+(8))≤q.cap0))) ∧ ((q.mode1=(1)) → ((q.cap1=(20)) ∧ ((q.r1+(8))≤q.cap1))) ∧ ((q.mode0=(2)) → ((q.cap0=(64)) ∧ ((q.r0+(8))≤q.cap0))) ∧ ((q.mode1=(2)) → ((q.cap1=(64)) ∧ ((q.r1+(8))≤q.cap1))) ∧ ((q.mode0=(3)) → ((q.cap0=(0)) ∧ ((q.r0+(8))>(64)))) ∧ ((q.mode1=(3)) → ((q.cap1=(0)) ∧ ((q.r1+(8))>(64)))) ∧ ((q.outcome=(1)) → ((((q.mode0>(0)) ∧ (q.mode0<(3))) ∧ (q.mode1>(0))) ∧ (q.mode1<(3)))))
def initial : State := {r0:=(0), r1:=(0), mode0:=(0), mode1:=(0), cap0:=(0), cap1:=(0), outcome:=(0), denied:=(0), frozen:=false, retained:=false}
def freezeSmallGuard (q : State) : Prop := (¬(q.frozen=true))
def freezeSmallNext (q : State) : State := {q with r0:=(8), r1:=(12), frozen:=true}
def freezeLargeGuard (q : State) : Prop := (¬(q.frozen=true))
def freezeLargeNext (q : State) : State := {q with r0:=(8), r1:=(24), frozen:=true}
def freezeOversizeGuard (q : State) : Prop := (¬(q.frozen=true))
def freezeOversizeNext (q : State) : State := {q with r0:=(8), r1:=(68), frozen:=true}
def share0Guard (q : State) : Prop := (q.frozen=true) ∧ (q.outcome=(0)) ∧ (q.mode0=(0)) ∧ ((q.r0+(8))≤(20))
def share0Next (q : State) : State := {q with mode0:=(1), cap0:=(20)}
def share1Guard (q : State) : Prop := (q.frozen=true) ∧ (q.outcome=(0)) ∧ (q.mode1=(0)) ∧ ((q.r1+(8))≤(20))
def share1Next (q : State) : State := {q with mode1:=(1), cap1:=(20)}
def dedicate0Guard (q : State) : Prop := (q.frozen=true) ∧ (q.outcome=(0)) ∧ (q.mode0=(0)) ∧ ((q.r0+(8))≤(64))
def dedicate0Next (q : State) : State := {q with mode0:=(2), cap0:=(64)}
def dedicate1Guard (q : State) : Prop := (q.frozen=true) ∧ (q.outcome=(0)) ∧ (q.mode1=(0)) ∧ ((q.r1+(8))≤(64))
def dedicate1Next (q : State) : State := {q with mode1:=(2), cap1:=(64)}
def reject0Guard (q : State) : Prop := (q.frozen=true) ∧ (q.outcome=(0)) ∧ (q.mode0=(0)) ∧ ((q.r0+(8))>(64))
def reject0Next (q : State) : State := {q with mode0:=(3)}
def reject1Guard (q : State) : Prop := (q.frozen=true) ∧ (q.outcome=(0)) ∧ (q.mode1=(0)) ∧ ((q.r1+(8))>(64))
def reject1Next (q : State) : State := {q with mode1:=(3)}
def sealAcceptGuard (q : State) : Prop := (q.frozen=true) ∧ (q.outcome=(0)) ∧ (q.mode0>(0)) ∧ (q.mode0<(3)) ∧ (q.mode1>(0)) ∧ (q.mode1<(3))
def sealAcceptNext (q : State) : State := {q with outcome:=(1)}
def sealRejectGuard (q : State) : Prop := (q.frozen=true) ∧ (q.outcome=(0)) ∧ (q.mode0>(0)) ∧ (q.mode1>(0)) ∧ ((q.mode0=(3)) ∨ (q.mode1=(3)))
def sealRejectNext (q : State) : State := {q with outcome:=(2)}
def allocationFailureGuard (q : State) : Prop := (q.frozen=true) ∧ (q.outcome=(0))
def allocationFailureNext (q : State) : State := {q with outcome:=(2)}
def denyMutationGuard (q : State) : Prop := (q.frozen=true)
def denyMutationNext (q : State) : State := {q with denied:=(q.denied+(1))}
def retainUnknownGuard (q : State) : Prop := (q.frozen=true)
def retainUnknownNext (q : State) : State := {q with retained:=true}
def Step (q r : State) : Prop := (freezeSmallGuard q ∧ r=freezeSmallNext q) ∨ (freezeLargeGuard q ∧ r=freezeLargeNext q) ∨ (freezeOversizeGuard q ∧ r=freezeOversizeNext q) ∨ (share0Guard q ∧ r=share0Next q) ∨ (share1Guard q ∧ r=share1Next q) ∨ (dedicate0Guard q ∧ r=dedicate0Next q) ∨ (dedicate1Guard q ∧ r=dedicate1Next q) ∨ (reject0Guard q ∧ r=reject0Next q) ∨ (reject1Guard q ∧ r=reject1Next q) ∨ (sealAcceptGuard q ∧ r=sealAcceptNext q) ∨ (sealRejectGuard q ∧ r=sealRejectNext q) ∨ (allocationFailureGuard q ∧ r=allocationFailureNext q) ∨ (denyMutationGuard q ∧ r=denyMutationNext q) ∨ (retainUnknownGuard q ∧ r=retainUnknownNext q) ∨ r=q
end ContinuationRestoreAst

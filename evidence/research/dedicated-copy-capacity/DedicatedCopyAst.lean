import Std
namespace DedicatedCopyAst
set_option maxRecDepth 10000
structure State where
 sourceN : Int
 actual : Int
 target : Int
 extra : Int
 strategy : Int
 outcome : Int
 retired : Int
 charged : Int
 frozen : Bool
 attempted : Bool
 unknown : Bool
 retained : Bool
 sealed : Bool
 collecting : Bool
 cleaned : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.sourceN=(4)) ∧ (q.target=(6)) ∧ (q.actual≥(4)) ∧ (q.actual≤(6)) ∧ (q.actual=((4)+q.extra)) ∧ ((q.strategy=(0)) ∨ (q.strategy=(2))) ∧ (q.outcome≥(0)) ∧ (q.outcome≤(2)) ∧ (q.charged≥(0)) ∧ (q.charged≤(14)) ∧ (q.retired≥(0)) ∧ (((9)*q.retired)≤q.charged) ∧ ((q.strategy=(2)) → (q.frozen=true)) ∧ ((q.attempted=true) → (q.frozen=true)) ∧ ((q.unknown=true) → ((((q.attempted=true) ∧ (q.retained=true)) ∧ (¬(q.sealed=true))) ∧ (¬(q.cleaned=true)))) ∧ ((q.sealed=true) → ((((((q.frozen=true) ∧ (q.strategy=(2))) ∧ (q.outcome=(1))) ∧ (¬(q.unknown=true))) ∧ (q.actual≥q.target)) ∧ (¬(q.cleaned=true)))) ∧ ((q.outcome=(1)) → (q.sealed=true)) ∧ ((q.outcome=(2)) → ((((q.attempted=true) ∧ (¬(q.sealed=true))) ∧ (¬(q.unknown=true))) ∧ (q.retained=true))) ∧ ((q.collecting=true) → (q.sealed=true)) ∧ ((q.cleaned=true) → ((((q.outcome=(2)) ∧ (q.actual=(4))) ∧ (q.extra=(0))) ∧ (¬(q.unknown=true)))))
def initial : State := {sourceN:=(4), actual:=(4), target:=(6), extra:=(0), strategy:=(0), outcome:=(0), retired:=(0), charged:=(0), frozen:=false, attempted:=false, unknown:=false, retained:=false, sealed:=false, collecting:=false, cleaned:=false}
def freezeGuard (q : State) : Prop := (¬(q.frozen=true))
def freezeNext (q : State) : State := {q with frozen:=true}
def sharedUnsuitableGuard (q : State) : Prop := (q.frozen=true) ∧ (¬(q.sealed=true)) ∧ (q.strategy=(0))
def sharedUnsuitableNext (q : State) : State := {q with strategy:=(2)}
def growFullGuard (q : State) : Prop := (q.frozen=true) ∧ (q.strategy=(2)) ∧ (¬(q.sealed=true)) ∧ (¬(q.attempted=true)) ∧ (¬(q.unknown=true)) ∧ (¬(q.cleaned=true))
def growFullNext (q : State) : State := {q with actual:=(6), extra:=(2), attempted:=true}
def growPartialGuard (q : State) : Prop := (q.frozen=true) ∧ (q.strategy=(2)) ∧ (¬(q.sealed=true)) ∧ (¬(q.attempted=true)) ∧ (¬(q.unknown=true)) ∧ (¬(q.cleaned=true)) ∧ (q.actual≤(5))
def growPartialNext (q : State) : State := {q with actual:=(5), extra:=(1), attempted:=true}
def growFailedGuard (q : State) : Prop := (q.frozen=true) ∧ (q.strategy=(2)) ∧ (¬(q.sealed=true)) ∧ (¬(q.attempted=true)) ∧ (¬(q.unknown=true)) ∧ (¬(q.cleaned=true))
def growFailedNext (q : State) : State := {q with attempted:=true}
def growUnknownGuard (q : State) : Prop := (q.frozen=true) ∧ (q.strategy=(2)) ∧ (¬(q.sealed=true)) ∧ (¬(q.attempted=true)) ∧ (¬(q.unknown=true)) ∧ (¬(q.cleaned=true))
def growUnknownNext (q : State) : State := {q with attempted:=true, unknown:=true, retained:=true}
def resolveFullGuard (q : State) : Prop := (q.unknown=true) ∧ (¬(q.sealed=true)) ∧ (¬(q.cleaned=true))
def resolveFullNext (q : State) : State := {q with actual:=(6), extra:=(2), unknown:=false}
def resolvePartialGuard (q : State) : Prop := (q.unknown=true) ∧ (¬(q.sealed=true)) ∧ (¬(q.cleaned=true)) ∧ (q.actual≤(5))
def resolvePartialNext (q : State) : State := {q with actual:=(5), extra:=(1), unknown:=false}
def chooseDedicatedGuard (q : State) : Prop := (q.frozen=true) ∧ (q.strategy=(2)) ∧ (¬(q.sealed=true)) ∧ (q.outcome=(0)) ∧ (q.attempted=true) ∧ (¬(q.unknown=true)) ∧ (¬(q.cleaned=true)) ∧ (q.actual≥q.target)
def chooseDedicatedNext (q : State) : State := {q with sealed:=true, outcome:=(1)}
def planUnavailableGuard (q : State) : Prop := (q.frozen=true) ∧ (q.strategy=(2)) ∧ (¬(q.sealed=true)) ∧ (q.outcome=(0)) ∧ (q.attempted=true) ∧ (¬(q.unknown=true)) ∧ (¬(q.cleaned=true)) ∧ (q.actual<q.target)
def planUnavailableNext (q : State) : State := {q with outcome:=(2), retained:=true}
def retryPlanGuard (q : State) : Prop := (q.outcome=(2)) ∧ (¬(q.sealed=true)) ∧ (¬(q.unknown=true)) ∧ (¬(q.cleaned=true))
def retryPlanNext (q : State) : State := {q with outcome:=(0), attempted:=false}
def beginCopyGuard (q : State) : Prop := (q.sealed=true) ∧ (q.outcome=(1)) ∧ (¬(q.collecting=true))
def beginCopyNext (q : State) : State := {q with collecting:=true}
def retireChargedGuard (q : State) : Prop := (q.collecting=true) ∧ ((q.charged+(9))≤(14))
def retireChargedNext (q : State) : State := {q with retired:=(q.retired+(1)), charged:=(q.charged+(9))}
def consumeOneGuard (q : State) : Prop := (q.collecting=true) ∧ ((q.charged+(1))≤(14))
def consumeOneNext (q : State) : State := {q with charged:=(q.charged+(1))}
def retainUnknownGuard (q : State) : Prop := (q.frozen=true) ∧ (¬(q.cleaned=true))
def retainUnknownNext (q : State) : State := {q with retained:=true}
def cleanupKnownBatchGuard (q : State) : Prop := (q.outcome=(2)) ∧ (¬(q.sealed=true)) ∧ (¬(q.unknown=true)) ∧ (¬(q.cleaned=true))
def cleanupKnownBatchNext (q : State) : State := {q with actual:=(4), extra:=(0), cleaned:=true}
def Step (q r : State) : Prop := (freezeGuard q ∧ r=freezeNext q) ∨ (sharedUnsuitableGuard q ∧ r=sharedUnsuitableNext q) ∨ (growFullGuard q ∧ r=growFullNext q) ∨ (growPartialGuard q ∧ r=growPartialNext q) ∨ (growFailedGuard q ∧ r=growFailedNext q) ∨ (growUnknownGuard q ∧ r=growUnknownNext q) ∨ (resolveFullGuard q ∧ r=resolveFullNext q) ∨ (resolvePartialGuard q ∧ r=resolvePartialNext q) ∨ (chooseDedicatedGuard q ∧ r=chooseDedicatedNext q) ∨ (planUnavailableGuard q ∧ r=planUnavailableNext q) ∨ (retryPlanGuard q ∧ r=retryPlanNext q) ∨ (beginCopyGuard q ∧ r=beginCopyNext q) ∨ (retireChargedGuard q ∧ r=retireChargedNext q) ∨ (consumeOneGuard q ∧ r=consumeOneNext q) ∨ (retainUnknownGuard q ∧ r=retainUnknownNext q) ∨ (cleanupKnownBatchGuard q ∧ r=cleanupKnownBatchNext q) ∨ r=q
end DedicatedCopyAst

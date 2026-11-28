import Std
namespace ChainSealAst
set_option maxRecDepth 10000
structure State where
 n : Int
 copied : Int
 sealed : Int
 published : Int
 target : Int
 ended : Int
 reserved : Bool
 initialized : Bool
 deferred : Bool
 owner : Bool
 suffixReady : Bool
 retag : Bool
 done : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.n≥(0)) ∧ (q.sealed≥(0)) ∧ (q.sealed≤q.copied) ∧ (q.copied≤q.n) ∧ (q.copied≤(q.sealed+(2))) ∧ (q.published≥(0)) ∧ (q.published≤q.sealed) ∧ ((¬(q.initialized=true)) → (q.copied≤(q.sealed+(1)))) ∧ ((q.initialized=true) → (q.reserved=true)) ∧ ((((q.reserved=true) ∨ (q.copied>q.sealed)) ∨ (q.deferred=true)) → (q.owner=true)) ∧ ((q.deferred=true) → ((q.target>(0)) ∧ (q.target≤q.copied))) ∧ (((q.ended=(1)) ∨ (q.ended=(2))) → ((q.copied=q.sealed) ∧ (¬(q.reserved=true)))) ∧ ((q.ended=(2)) → (q.suffixReady=true)) ∧ ((q.retag=true) → ((q.ended=(1)) ∨ (q.ended=(2)))) ∧ ((q.done=true) → ((((¬(q.owner=true)) ∧ (¬(q.deferred=true))) ∧ (q.retag=true)) ∧ (q.published=q.sealed))))
def initial : State := {n:=(3), copied:=(0), sealed:=(0), published:=(0), target:=(0), ended:=(0), reserved:=false, initialized:=false, deferred:=false, owner:=true, suffixReady:=false, retag:=false, done:=false}
def reserveGuard (q : State) : Prop := (q.owner=true) ∧ (q.ended=(0)) ∧ (¬(q.reserved=true)) ∧ (¬(q.initialized=true)) ∧ (q.copied<q.n)
def reserveNext (q : State) : State := {q with reserved:=true}
def initializeCopyGuard (q : State) : Prop := (q.owner=true) ∧ (q.reserved=true) ∧ (¬(q.initialized=true)) ∧ (q.ended=(0)) ∧ (q.copied<q.n)
def initializeCopyNext (q : State) : State := {q with copied:=(q.copied+(1)), initialized:=true}
def resolvePreviousGuard (q : State) : Prop := (q.initialized=true) ∧ (q.copied=(q.sealed+(2)))
def resolvePreviousNext (q : State) : State := {q with sealed:=(q.sealed+(1))}
def finishInstallGuard (q : State) : Prop := (q.initialized=true) ∧ (q.copied=(q.sealed+(1)))
def finishInstallNext (q : State) : State := {q with initialized:=false, reserved:=false}
def deferChunkGuard (q : State) : Prop := (q.owner=true) ∧ (q.ended=(0)) ∧ (¬(q.reserved=true)) ∧ (q.copied=(q.sealed+(1))) ∧ (¬(q.deferred=true))
def deferChunkNext (q : State) : State := {q with deferred:=true, target:=q.copied}
def publishDeferredGuard (q : State) : Prop := (q.deferred=true) ∧ (q.sealed≥q.target)
def publishDeferredNext (q : State) : State := {q with deferred:=false}
def publishPrefixGuard (q : State) : Prop := (q.owner=true)
def publishPrefixNext (q : State) : State := {q with published:=q.sealed}
def certifySuffixGuard (q : State) : Prop := (q.owner=true) ∧ (q.ended=(0))
def certifySuffixNext (q : State) : State := {q with suffixReady:=true}
def terminalGuard (q : State) : Prop := (q.owner=true) ∧ (q.ended=(0)) ∧ (¬(q.reserved=true)) ∧ (q.copied=q.n)
def terminalNext (q : State) : State := {q with sealed:=q.copied, ended:=(1)}
def forwardedGuard (q : State) : Prop := (q.owner=true) ∧ (q.ended=(0)) ∧ (¬(q.reserved=true)) ∧ (q.copied<q.n) ∧ (q.suffixReady=true)
def forwardedNext (q : State) : State := {q with sealed:=q.copied, ended:=(2)}
def capacityFailureGuard (q : State) : Prop := (q.owner=true) ∧ (q.ended=(0)) ∧ (¬(q.reserved=true))
def capacityFailureNext (q : State) : State := {q with ended:=(3)}
def retagRootGuard (q : State) : Prop := ((q.ended=(1)) ∨ (q.ended=(2)))
def retagRootNext (q : State) : State := {q with retag:=true}
def releaseGuard (q : State) : Prop := (q.owner=true) ∧ (q.retag=true) ∧ (¬(q.deferred=true)) ∧ (q.published=q.sealed)
def releaseNext (q : State) : State := {q with owner:=false, done:=true}
def Step (q r : State) : Prop := (reserveGuard q ∧ r=reserveNext q) ∨ (initializeCopyGuard q ∧ r=initializeCopyNext q) ∨ (resolvePreviousGuard q ∧ r=resolvePreviousNext q) ∨ (finishInstallGuard q ∧ r=finishInstallNext q) ∨ (deferChunkGuard q ∧ r=deferChunkNext q) ∨ (publishDeferredGuard q ∧ r=publishDeferredNext q) ∨ (publishPrefixGuard q ∧ r=publishPrefixNext q) ∨ (certifySuffixGuard q ∧ r=certifySuffixNext q) ∨ (terminalGuard q ∧ r=terminalNext q) ∨ (forwardedGuard q ∧ r=forwardedNext q) ∨ (capacityFailureGuard q ∧ r=capacityFailureNext q) ∨ (retagRootGuard q ∧ r=retagRootNext q) ∨ (releaseGuard q ∧ r=releaseNext q) ∨ r=q
end ChainSealAst

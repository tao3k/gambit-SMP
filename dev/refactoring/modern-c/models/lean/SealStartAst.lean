import Std
namespace SealStartAst
set_option maxRecDepth 10000
structure State where
 generation : Int
 saved : Int
 ticket : Int
 phase : Int
 nativePins : Int
 frames : Int
 roots : Int
 maintenance : Int
 observers : Int
 denied : Int
 writer : Bool
 guard : Bool
 suspended : Bool
 sealed : Bool
 opaqueExport : Bool
 admit : Bool
 copyPin : Bool
 revocationWins : Bool
 unknown : Bool
 reclaimed : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.generation≥(1)) ∧ (q.saved≥(0)) ∧ (q.saved≤q.generation) ∧ (q.ticket≥(0)) ∧ (q.ticket≤q.generation) ∧ (q.phase≥(0)) ∧ (q.phase≤(4)) ∧ (q.nativePins≥(0)) ∧ (q.nativePins≤(1)) ∧ (q.frames≥(0)) ∧ (q.frames≤(1)) ∧ (q.roots≥(0)) ∧ (q.roots≤(1)) ∧ (q.maintenance≥(0)) ∧ (q.maintenance≤(1)) ∧ (q.observers≥(0)) ∧ (q.observers≤(1)) ∧ (q.denied≥(0)) ∧ ((q.sealed=true) → ((((¬(q.writer=true)) ∧ (¬(q.guard=true))) ∧ (¬(q.suspended=true))) ∧ (¬(q.opaqueExport=true)))) ∧ ((q.phase=(1)) → ((q.sealed=true) ∧ (¬(q.reclaimed=true)))) ∧ ((q.phase=(2)) → ((((q.sealed=true) ∧ (q.copyPin=true)) ∧ (¬(q.revocationWins=true))) ∧ (¬(q.reclaimed=true)))) ∧ ((q.copyPin=true) → (q.phase=(2))) ∧ ((q.revocationWins=true) → (q.phase≠(2))) ∧ ((q.reclaimed=true) → (((((((((((((¬(q.admit=true)) ∧ (¬(q.guard=true))) ∧ (¬(q.suspended=true))) ∧ (¬(q.writer=true))) ∧ (q.phase≠(1))) ∧ (q.phase≠(2))) ∧ (¬(q.copyPin=true))) ∧ (q.nativePins=(0))) ∧ (q.frames=(0))) ∧ (q.roots=(0))) ∧ (q.maintenance=(0))) ∧ (q.observers=(0))) ∧ (¬(q.unknown=true)))))
def initial : State := {generation:=(1), saved:=(0), ticket:=(0), phase:=(0), nativePins:=(0), frames:=(1), roots:=(1), maintenance:=(0), observers:=(0), denied:=(0), writer:=true, guard:=true, suspended:=false, sealed:=false, opaqueExport:=false, admit:=true, copyPin:=false, revocationWins:=false, unknown:=false, reclaimed:=false}
def captureGuard (q : State) : Prop := (q.guard=true) ∧ (¬(q.sealed=true)) ∧ (q.phase=(0))
def captureNext (q : State) : State := {q with saved:=q.generation, suspended:=true, writer:=false, guard:=false, frames:=(1)}
def resumeLiveGuard (q : State) : Prop := (q.suspended=true) ∧ (q.saved=q.generation) ∧ (¬(q.sealed=true)) ∧ (q.phase=(0)) ∧ (¬(q.reclaimed=true))
def resumeLiveNext (q : State) : State := {q with suspended:=false, guard:=true, writer:=true}
def resumeDeniedGuard (q : State) : Prop := (((q.saved≠q.generation) ∨ (¬(q.suspended=true))) ∨ (q.sealed=true))
def resumeDeniedNext (q : State) : State := {q with denied:=(q.denied+(1))}
def closeWritersGuard (q : State) : Prop := (q.guard=true) ∧ (¬(q.suspended=true)) ∧ (q.nativePins=(0))
def closeWritersNext (q : State) : State := {q with writer:=false}
def opaqueEscapeGuard (q : State) : Prop := (q.writer=true) ∧ (¬(q.sealed=true))
def opaqueEscapeNext (q : State) : State := {q with opaqueExport:=true}
def sealGuard (q : State) : Prop := (q.guard=true) ∧ (¬(q.writer=true)) ∧ (¬(q.suspended=true)) ∧ (¬(q.opaqueExport=true)) ∧ (q.nativePins=(0)) ∧ (¬(q.reclaimed=true))
def sealNext (q : State) : State := {q with sealed:=true, guard:=false, generation:=(q.generation+(1))}
def abortCandidateGuard (q : State) : Prop := (¬(q.sealed=true)) ∧ (q.phase=(0))
def abortCandidateNext (q : State) : State := {q with writer:=false, guard:=false, suspended:=false, generation:=(q.generation+(1)), phase:=(3), revocationWins:=true}
def issueGuard (q : State) : Prop := (q.sealed=true) ∧ (q.phase=(0)) ∧ (¬(q.reclaimed=true)) ∧ (q.admit=true)
def issueNext (q : State) : State := {q with phase:=(1)}
def observeGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.admit=true) ∧ (q.observers=(0)) ∧ (¬(q.reclaimed=true))
def observeNext (q : State) : State := {q with observers:=(1), ticket:=q.generation}
def revokeGuard (q : State) : Prop := (q.phase=(1))
def revokeNext (q : State) : State := {q with phase:=(3), revocationWins:=true}
def casStartGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.observers=(1)) ∧ (q.ticket=q.generation) ∧ (¬(q.reclaimed=true)) ∧ (¬(q.revocationWins=true)) ∧ (q.sealed=true)
def casStartNext (q : State) : State := {q with phase:=(2), copyPin:=true, observers:=(0)}
def casFailedGuard (q : State) : Prop := (q.phase=(3)) ∧ (q.observers=(1))
def casFailedNext (q : State) : State := {q with observers:=(0), denied:=(q.denied+(1))}
def revokeTooLateGuard (q : State) : Prop := (q.phase=(2))
def revokeTooLateNext (q : State) : State := {q with denied:=(q.denied+(1))}
def finishCopyGuard (q : State) : Prop := (q.phase=(2))
def finishCopyNext (q : State) : State := {q with phase:=(4), copyPin:=false}
def nativeBorrowGuard (q : State) : Prop := (q.sealed=true) ∧ (q.admit=true) ∧ (¬(q.reclaimed=true)) ∧ (q.nativePins=(0))
def nativeBorrowNext (q : State) : State := {q with nativePins:=(1)}
def nativeReturnGuard (q : State) : Prop := (q.nativePins=(1)) ∧ (¬(q.unknown=true))
def nativeReturnNext (q : State) : State := {q with nativePins:=(0)}
def nativeUnknownGuard (q : State) : Prop := (q.nativePins=(1))
def nativeUnknownNext (q : State) : State := {q with unknown:=true}
def closeAdmissionGuard (q : State) : Prop := (¬(q.reclaimed=true))
def closeAdmissionNext (q : State) : State := {q with admit:=false}
def dropFrameGuard (q : State) : Prop := (q.frames=(1))
def dropFrameNext (q : State) : State := {q with frames:=(0)}
def dropRootGuard (q : State) : Prop := (q.roots=(1))
def dropRootNext (q : State) : State := {q with roots:=(0)}
def beginMaintenanceGuard (q : State) : Prop := (q.admit=true) ∧ (¬(q.reclaimed=true)) ∧ (q.maintenance=(0))
def beginMaintenanceNext (q : State) : State := {q with maintenance:=(1)}
def endMaintenanceGuard (q : State) : Prop := (q.maintenance=(1))
def endMaintenanceNext (q : State) : State := {q with maintenance:=(0)}
def reclaimGuard (q : State) : Prop := (¬(q.admit=true)) ∧ (¬(q.guard=true)) ∧ (¬(q.writer=true)) ∧ (¬(q.suspended=true)) ∧ (q.phase≠(1)) ∧ (q.phase≠(2)) ∧ (¬(q.copyPin=true)) ∧ (q.nativePins=(0)) ∧ (q.frames=(0)) ∧ (q.roots=(0)) ∧ (q.maintenance=(0)) ∧ (q.observers=(0)) ∧ (¬(q.unknown=true))
def reclaimNext (q : State) : State := {q with reclaimed:=true}
def denyLateBorrowGuard (q : State) : Prop := (¬(q.admit=true))
def denyLateBorrowNext (q : State) : State := {q with denied:=(q.denied+(1))}
def Step (q r : State) : Prop := (captureGuard q ∧ r=captureNext q) ∨ (resumeLiveGuard q ∧ r=resumeLiveNext q) ∨ (resumeDeniedGuard q ∧ r=resumeDeniedNext q) ∨ (closeWritersGuard q ∧ r=closeWritersNext q) ∨ (opaqueEscapeGuard q ∧ r=opaqueEscapeNext q) ∨ (sealGuard q ∧ r=sealNext q) ∨ (abortCandidateGuard q ∧ r=abortCandidateNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (observeGuard q ∧ r=observeNext q) ∨ (revokeGuard q ∧ r=revokeNext q) ∨ (casStartGuard q ∧ r=casStartNext q) ∨ (casFailedGuard q ∧ r=casFailedNext q) ∨ (revokeTooLateGuard q ∧ r=revokeTooLateNext q) ∨ (finishCopyGuard q ∧ r=finishCopyNext q) ∨ (nativeBorrowGuard q ∧ r=nativeBorrowNext q) ∨ (nativeReturnGuard q ∧ r=nativeReturnNext q) ∨ (nativeUnknownGuard q ∧ r=nativeUnknownNext q) ∨ (closeAdmissionGuard q ∧ r=closeAdmissionNext q) ∨ (dropFrameGuard q ∧ r=dropFrameNext q) ∨ (dropRootGuard q ∧ r=dropRootNext q) ∨ (beginMaintenanceGuard q ∧ r=beginMaintenanceNext q) ∨ (endMaintenanceGuard q ∧ r=endMaintenanceNext q) ∨ (reclaimGuard q ∧ r=reclaimNext q) ∨ (denyLateBorrowGuard q ∧ r=denyLateBorrowNext q) ∨ r=q
end SealStartAst

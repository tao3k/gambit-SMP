import Std
namespace AllocationTicketAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 ticket : Int
 owner : Int
 effect : Int
 calls : Int
 frees : Int
 reserved : Int
 sourceHold : Int
 deriving DecidableEq
def Safe (q : State) : Prop := (((q.phase=(0)) ∧ (q.ticket=(0)) ∧ (q.owner=(0)) ∧ (q.effect=(0)) ∧ (q.calls=(0)) ∧ (q.frees=(0)) ∧ (q.reserved=(0)) ∧ (q.sourceHold=(0))) ∨ ((q.phase=(1)) ∧ (q.ticket=(1)) ∧ (q.owner=(1)) ∧ (q.effect=(0)) ∧ (q.calls=(0)) ∧ (q.frees=(0)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(1))) ∨ ((q.phase=(2)) ∧ (q.ticket=(1)) ∧ (q.owner=(1)) ∧ (q.effect=(0)) ∧ (q.calls=(1)) ∧ (q.frees=(0)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(1))) ∨ ((q.phase=(3)) ∧ (q.ticket=(1)) ∧ (q.owner=(1)) ∧ (q.effect=(1)) ∧ (q.calls=(1)) ∧ (q.frees=(0)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(1))) ∨ ((q.phase=(4)) ∧ (q.ticket=(1)) ∧ (q.owner=(2)) ∧ (q.effect=(1)) ∧ (q.calls=(1)) ∧ (q.frees=(0)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(1))) ∨ ((q.phase=(5)) ∧ (q.ticket=(0)) ∧ (q.owner=(2)) ∧ (q.effect=(1)) ∧ (q.calls=(1)) ∧ (q.frees=(0)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(0))) ∨ ((q.phase=(6)) ∧ (q.ticket=(1)) ∧ (q.owner=(1)) ∧ (q.effect=(1)) ∧ (q.calls=(1)) ∧ (q.frees=(0)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(1))) ∨ ((q.phase=(7)) ∧ (q.ticket=(1)) ∧ (q.owner=(1)) ∧ (q.effect=(1)) ∧ (q.calls=(1)) ∧ (q.frees=(1)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(1))) ∨ ((q.phase=(8)) ∧ (q.ticket=(1)) ∧ (q.owner=(3)) ∧ (q.effect=(2)) ∧ (q.calls=(1)) ∧ (q.frees=(0)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(1))) ∨ ((q.phase=(9)) ∧ (q.ticket=(1)) ∧ (q.owner=(3)) ∧ (q.effect=(2)) ∧ (q.calls=(1)) ∧ (q.frees=(1)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(1))) ∨ ((q.phase=(10)) ∧ (q.ticket=(0)) ∧ (q.owner=(0)) ∧ (q.effect=(0)) ∧ (q.calls=(0)) ∧ (q.frees=(0)) ∧ (q.reserved=(0)) ∧ (q.sourceHold=(0))) ∨ ((q.phase=(11)) ∧ (q.ticket=(0)) ∧ (q.owner=(0)) ∧ (q.effect=(3)) ∧ (q.calls=(1)) ∧ (q.frees=(1)) ∧ (q.reserved=(0)) ∧ (q.sourceHold=(0))) ∨ ((q.phase=(12)) ∧ (q.ticket=(1)) ∧ (q.owner=(3)) ∧ (q.effect=(1)) ∧ (q.calls=(1)) ∧ (q.frees=(0)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(1))) ∨ ((q.phase=(13)) ∧ (q.ticket=(0)) ∧ (q.owner=(0)) ∧ (q.effect=(0)) ∧ (q.calls=(1)) ∧ (q.frees=(0)) ∧ (q.reserved=(0)) ∧ (q.sourceHold=(0))) ∨ ((q.phase=(14)) ∧ (q.ticket=(1)) ∧ (q.owner=(1)) ∧ (q.effect=(1)) ∧ (q.calls=(1)) ∧ (q.frees=(0)) ∧ (q.reserved=(1)) ∧ (q.sourceHold=(1))))
def initial : State := {phase:=(0), ticket:=(0), owner:=(0), effect:=(0), calls:=(0), frees:=(0), reserved:=(0), sourceHold:=(0)}
def issueGuard (q : State) : Prop := (q.phase=(0))
def issueNext (q : State) : State := {q with phase:=(1), ticket:=(1), owner:=(1), effect:=(0), calls:=(0), frees:=(0), reserved:=(1), sourceHold:=(1)}
def metadataExhaustedGuard (q : State) : Prop := (q.phase=(0))
def metadataExhaustedNext (q : State) : State := {q with phase:=(10), ticket:=(0), owner:=(0), effect:=(0), calls:=(0), frees:=(0), reserved:=(0), sourceHold:=(0)}
def invokeGuard (q : State) : Prop := (q.phase=(1))
def invokeNext (q : State) : State := {q with phase:=(2), ticket:=(1), owner:=(1), effect:=(0), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def cancelBeforeInvokeGuard (q : State) : Prop := (q.phase=(1))
def cancelBeforeInvokeNext (q : State) : State := {q with phase:=(10), ticket:=(0), owner:=(0), effect:=(0), calls:=(0), frees:=(0), reserved:=(0), sourceHold:=(0)}
def allocatorNullGuard (q : State) : Prop := (q.phase=(2))
def allocatorNullNext (q : State) : State := {q with phase:=(13), ticket:=(0), owner:=(0), effect:=(0), calls:=(1), frees:=(0), reserved:=(0), sourceHold:=(0)}
def allocatorReturnGuard (q : State) : Prop := (q.phase=(2))
def allocatorReturnNext (q : State) : State := {q with phase:=(14), ticket:=(1), owner:=(1), effect:=(1), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def captureReturnGuard (q : State) : Prop := (q.phase=(14))
def captureReturnNext (q : State) : State := {q with phase:=(3), ticket:=(1), owner:=(1), effect:=(1), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def interruptUnrecordedReturnGuard (q : State) : Prop := (q.phase=(14))
def interruptUnrecordedReturnNext (q : State) : State := {q with phase:=(8), ticket:=(1), owner:=(3), effect:=(2), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def allocatorOutcomeUnknownGuard (q : State) : Prop := (q.phase=(2))
def allocatorOutcomeUnknownNext (q : State) : State := {q with phase:=(8), ticket:=(1), owner:=(3), effect:=(2), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def commitGuard (q : State) : Prop := (q.phase=(3))
def commitNext (q : State) : State := {q with phase:=(4), ticket:=(1), owner:=(2), effect:=(1), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def indexOutcomeUnknownGuard (q : State) : Prop := (q.phase=(3))
def indexOutcomeUnknownNext (q : State) : State := {q with phase:=(12), ticket:=(1), owner:=(3), effect:=(1), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def resolveCommittedGuard (q : State) : Prop := (q.phase=(12))
def resolveCommittedNext (q : State) : State := {q with phase:=(4), ticket:=(1), owner:=(2), effect:=(1), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def resolveAbsentGuard (q : State) : Prop := (q.phase=(12))
def resolveAbsentNext (q : State) : State := {q with phase:=(3), ticket:=(1), owner:=(1), effect:=(1), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def observeCommitGuard (q : State) : Prop := (q.phase=(4))
def observeCommitNext (q : State) : State := {q with phase:=(5), ticket:=(0), owner:=(2), effect:=(1), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(0)}
def retryCommitQueryGuard (q : State) : Prop := (q.phase=(4))
def retryCommitQueryNext (q : State) : State := {q with phase:=(4), ticket:=(1), owner:=(2), effect:=(1), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def requestPrivateAbortGuard (q : State) : Prop := (q.phase=(3))
def requestPrivateAbortNext (q : State) : State := {q with phase:=(6), ticket:=(1), owner:=(1), effect:=(1), calls:=(1), frees:=(0), reserved:=(1), sourceHold:=(1)}
def invokePrivateFreeGuard (q : State) : Prop := (q.phase=(6))
def invokePrivateFreeNext (q : State) : State := {q with phase:=(7), ticket:=(1), owner:=(1), effect:=(1), calls:=(1), frees:=(1), reserved:=(1), sourceHold:=(1)}
def privateFreeKnownGuard (q : State) : Prop := (q.phase=(7))
def privateFreeKnownNext (q : State) : State := {q with phase:=(11), ticket:=(0), owner:=(0), effect:=(3), calls:=(1), frees:=(1), reserved:=(0), sourceHold:=(0)}
def privateFreeUnknownGuard (q : State) : Prop := (q.phase=(7))
def privateFreeUnknownNext (q : State) : State := {q with phase:=(9), ticket:=(1), owner:=(3), effect:=(2), calls:=(1), frees:=(1), reserved:=(1), sourceHold:=(1)}
def Step (q r : State) : Prop := (issueGuard q ∧ r=issueNext q) ∨ (metadataExhaustedGuard q ∧ r=metadataExhaustedNext q) ∨ (invokeGuard q ∧ r=invokeNext q) ∨ (cancelBeforeInvokeGuard q ∧ r=cancelBeforeInvokeNext q) ∨ (allocatorNullGuard q ∧ r=allocatorNullNext q) ∨ (allocatorReturnGuard q ∧ r=allocatorReturnNext q) ∨ (captureReturnGuard q ∧ r=captureReturnNext q) ∨ (interruptUnrecordedReturnGuard q ∧ r=interruptUnrecordedReturnNext q) ∨ (allocatorOutcomeUnknownGuard q ∧ r=allocatorOutcomeUnknownNext q) ∨ (commitGuard q ∧ r=commitNext q) ∨ (indexOutcomeUnknownGuard q ∧ r=indexOutcomeUnknownNext q) ∨ (resolveCommittedGuard q ∧ r=resolveCommittedNext q) ∨ (resolveAbsentGuard q ∧ r=resolveAbsentNext q) ∨ (observeCommitGuard q ∧ r=observeCommitNext q) ∨ (retryCommitQueryGuard q ∧ r=retryCommitQueryNext q) ∨ (requestPrivateAbortGuard q ∧ r=requestPrivateAbortNext q) ∨ (invokePrivateFreeGuard q ∧ r=invokePrivateFreeNext q) ∨ (privateFreeKnownGuard q ∧ r=privateFreeKnownNext q) ∨ (privateFreeUnknownGuard q ∧ r=privateFreeUnknownNext q) ∨ r=q
end AllocationTicketAst

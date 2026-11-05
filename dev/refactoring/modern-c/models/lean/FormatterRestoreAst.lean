import Std
namespace FormatterRestoreAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 writer : Int
 generation : Int
 savedWriter : Int
 installGen : Int
 epoch : Int
 scopeEpoch : Int
 tickets : Int
 borrowers : Int
 captures : Int
 attempts : Int
 demand : Int
 certGen : Int
 certEpoch : Int
 legacyPc : Int
 legacyWriter : Int
 legacySaved : Int
 legacyCaptureSaved : Int
 legacyGen : Int
 legacyResumes : Int
 legacyTarget : Int
 active : Bool
 frameClosed : Bool
 registrationClosed : Bool
 custody : Bool
 errorSeen : Bool
 qualified : Bool
 certificate : Bool
 retired : Bool
 legacyCaptured : Bool
 legacyNewer : Bool
 legacyClobbered : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(5)) ∧ (q.writer≥(0)) ∧ (q.writer≤(2)) ∧ (q.savedWriter≥(0)) ∧ (q.savedWriter≤(2)) ∧ (q.generation≥(1)) ∧ (q.installGen≥(0)) ∧ (q.epoch≥(1)) ∧ (q.scopeEpoch≥(1)) ∧ (q.tickets≥(0)) ∧ (q.borrowers≥(0)) ∧ (q.captures≥(0)) ∧ (q.attempts≥(0)) ∧ (q.demand≥(0)) ∧ (q.demand≤(2)) ∧ (q.certGen≥(0)) ∧ (q.certEpoch≥(0)) ∧ ((q.active=true) → ((q.phase=(1)) ∨ (q.phase=(2)))) ∧ (((q.phase=(1)) ∨ (q.phase=(2))) → (q.active=true)) ∧ ((q.frameClosed=true) → (¬(q.active=true))) ∧ (((q.phase=(3)) ∨ (q.phase=(4))) → ((q.frameClosed=true) ∧ (q.custody=true))) ∧ ((((((q.active=true) ∨ (q.tickets>(0))) ∨ (q.borrowers>(0))) ∨ (q.captures>(0))) ∨ (q.certificate=true)) → (q.custody=true)) ∧ ((q.certificate=true) → ((((((((((((((q.phase=(3)) ∨ (q.phase=(5))) ∧ (q.registrationClosed=true)) ∧ (q.frameClosed=true)) ∧ (q.writer=q.savedWriter)) ∧ (q.generation=q.certGen)) ∧ (q.epoch=q.certEpoch)) ∧ (q.epoch=q.scopeEpoch)) ∧ (q.tickets=(0))) ∧ (q.borrowers=(0))) ∧ (q.captures=(0))) ∧ (q.demand=(1))) ∧ (¬(q.errorSeen=true))) ∧ (q.qualified=true))) ∧ ((q.retired=true) → ((q.phase=(5)) ∧ (q.certificate=true))) ∧ ((q.phase=(5)) → (q.retired=true)) ∧ (q.legacyPc≥(0)) ∧ (q.legacyPc≤(4)) ∧ (q.legacyWriter≥(0)) ∧ (q.legacyWriter≤(2)) ∧ (q.legacySaved≥(0)) ∧ (q.legacySaved≤(2)) ∧ (q.legacyCaptureSaved≥(0)) ∧ (q.legacyCaptureSaved≤(2)) ∧ (q.legacyGen≥(1)) ∧ (q.legacyResumes≥(0)) ∧ (q.legacyTarget≥(0)) ∧ (q.legacyTarget≤(2)))
def initial : State := {phase:=(0), writer:=(1), generation:=(1), savedWriter:=(1), installGen:=(0), epoch:=(1), scopeEpoch:=(1), tickets:=(0), borrowers:=(0), captures:=(0), attempts:=(0), demand:=(1), certGen:=(0), certEpoch:=(0), legacyPc:=(0), legacyWriter:=(1), legacySaved:=(1), legacyCaptureSaved:=(1), legacyGen:=(1), legacyResumes:=(0), legacyTarget:=(0), active:=false, frameClosed:=false, registrationClosed:=false, custody:=false, errorSeen:=false, qualified:=false, certificate:=false, retired:=false, legacyCaptured:=false, legacyNewer:=false, legacyClobbered:=false}
def beginScopeGuard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.registrationClosed=true))
def beginScopeNext (q : State) : State := {q with phase:=(1), active:=true, custody:=true, savedWriter:=q.writer, writer:=(0), generation:=(q.generation+(1)), installGen:=(q.generation+(1)), scopeEpoch:=q.epoch, frameClosed:=false}
def bodyReturnsGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.active=true)
def bodyReturnsNext (q : State) : State := {q with phase:=(2)}
def restoreOwnedGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.active=true) ∧ (¬(q.frameClosed=true)) ∧ (q.generation=q.installGen) ∧ (q.writer=(0)) ∧ (q.epoch=q.scopeEpoch)
def restoreOwnedNext (q : State) : State := {q with phase:=(3), writer:=q.savedWriter, generation:=(q.generation+(1)), active:=false, frameClosed:=true}
def escapeOwnedGuard (q : State) : Prop := (q.phase≥(1)) ∧ (q.phase≤(2)) ∧ (q.active=true) ∧ (q.generation=q.installGen) ∧ (q.writer=(0)) ∧ (q.epoch=q.scopeEpoch)
def escapeOwnedNext (q : State) : State := {q with phase:=(4), writer:=q.savedWriter, generation:=(q.generation+(1)), active:=false, frameClosed:=true, errorSeen:=true, certificate:=false, qualified:=false}
def publishOtherGuard (q : State) : Prop := (q.phase≤(4))
def publishOtherNext (q : State) : State := {q with writer:=(2), generation:=(q.generation+(1)), certificate:=false, qualified:=false}
def publishSameIdentityGuard (q : State) : Prop := (q.phase≤(4))
def publishSameIdentityNext (q : State) : State := {q with writer:=q.savedWriter, generation:=(q.generation+(1)), certificate:=false, qualified:=false}
def yieldConflictGuard (q : State) : Prop := (q.phase≥(1)) ∧ (q.phase≤(2)) ∧ (q.active=true) ∧ ((q.generation≠q.installGen) ∨ (q.epoch≠q.scopeEpoch))
def yieldConflictNext (q : State) : State := {q with phase:=(4), active:=false, frameClosed:=true, errorSeen:=true, certificate:=false, qualified:=false}
def changeEpochGuard (q : State) : Prop := (q.phase≤(4))
def changeEpochNext (q : State) : State := {q with epoch:=(q.epoch+(1)), certificate:=false, qualified:=false}
def acceptTicketGuard (q : State) : Prop := (q.phase≤(3)) ∧ (¬(q.registrationClosed=true))
def acceptTicketNext (q : State) : State := {q with tickets:=(q.tickets+(1)), custody:=true, certificate:=false, qualified:=false}
def startTicketGuard (q : State) : Prop := (q.phase≤(4)) ∧ (q.tickets>(0))
def startTicketNext (q : State) : State := {q with tickets:=(q.tickets-(1)), borrowers:=(q.borrowers+(1)), custody:=true, certificate:=false, qualified:=false}
def finishBorrowerGuard (q : State) : Prop := (q.phase≤(4)) ∧ (q.borrowers>(0))
def finishBorrowerNext (q : State) : State := {q with borrowers:=(q.borrowers-(1))}
def captureGuard (q : State) : Prop := (q.phase≤(4)) ∧ ((q.active=true) ∨ (q.borrowers>(0)))
def captureNext (q : State) : State := {q with captures:=(q.captures+(1)), custody:=true, certificate:=false, qualified:=false}
def rejectStalePermitGuard (q : State) : Prop := (q.phase≤(4)) ∧ (q.captures>(0))
def rejectStalePermitNext (q : State) : State := {q with attempts:=(q.attempts+(1))}
def detachCaptureGuard (q : State) : Prop := (q.phase≤(4)) ∧ (q.captures>(0))
def detachCaptureNext (q : State) : State := {q with captures:=(q.captures-(1))}
def closeRegistrationGuard (q : State) : Prop := (q.phase≤(4))
def closeRegistrationNext (q : State) : State := {q with registrationClosed:=true}
def namedDemandGuard (q : State) : Prop := (q.phase≤(4))
def namedDemandNext (q : State) : State := {q with demand:=(1)}
def namedSupplyGuard (q : State) : Prop := (q.phase≤(4))
def namedSupplyNext (q : State) : State := {q with demand:=q.demand}
def rawMetadataGuard (q : State) : Prop := (q.phase≤(4))
def rawMetadataNext (q : State) : State := {q with demand:=(2), certificate:=false, qualified:=false}
def ioFailureGuard (q : State) : Prop := (q.phase≤(4))
def ioFailureNext (q : State) : State := {q with errorSeen:=true, certificate:=false, qualified:=false}
def qualifyProfileGuard (q : State) : Prop := (q.phase=(3)) ∧ (q.registrationClosed=true) ∧ (q.tickets=(0)) ∧ (q.borrowers=(0)) ∧ (q.captures=(0)) ∧ (q.writer=q.savedWriter) ∧ (q.epoch=q.scopeEpoch) ∧ (¬(q.errorSeen=true)) ∧ (q.demand=(1))
def qualifyProfileNext (q : State) : State := {q with qualified:=true}
def issueGuard (q : State) : Prop := (q.phase=(3)) ∧ (q.registrationClosed=true) ∧ (q.tickets=(0)) ∧ (q.borrowers=(0)) ∧ (q.captures=(0)) ∧ (q.writer=q.savedWriter) ∧ (q.epoch=q.scopeEpoch) ∧ (¬(q.errorSeen=true)) ∧ (q.demand=(1)) ∧ (q.qualified=true)
def issueNext (q : State) : State := {q with certificate:=true, certGen:=q.generation, certEpoch:=q.epoch}
def consumeSecondGuard (q : State) : Prop := (q.phase=(3)) ∧ (q.certificate=true) ∧ (q.generation=q.certGen) ∧ (q.epoch=q.certEpoch)
def consumeSecondNext (q : State) : State := {q with phase:=(5), retired:=true}
def legacyEnterGuard (q : State) : Prop := (q.legacyPc=(0))
def legacyEnterNext (q : State) : State := {q with legacySaved:=q.legacyWriter, legacyWriter:=(0), legacyGen:=(q.legacyGen+(1)), legacyPc:=(1)}
def legacyCaptureGuard (q : State) : Prop := (q.legacyPc=(1)) ∧ (¬(q.legacyCaptured=true))
def legacyCaptureNext (q : State) : State := {q with legacyCaptured:=true, legacyCaptureSaved:=q.legacySaved}
def legacyEscapeGuard (q : State) : Prop := (q.legacyPc=(1))
def legacyEscapeNext (q : State) : State := {q with legacyPc:=(4)}
def legacyPublishGuard (q : State) : Prop := (q.legacyPc≥(1)) ∧ (q.legacyPc≤(4))
def legacyPublishNext (q : State) : State := {q with legacyWriter:=(2), legacyGen:=(q.legacyGen+(1)), legacyNewer:=true}
def legacyResolveGuard (q : State) : Prop := (q.legacyPc=(1))
def legacyResolveNext (q : State) : State := {q with legacyTarget:=q.legacyWriter}
def legacyReturnGuard (q : State) : Prop := (q.legacyPc=(1))
def legacyReturnNext (q : State) : State := {q with legacyPc:=(2)}
def legacyRestoreGuard (q : State) : Prop := (q.legacyPc=(2))
def legacyRestoreNext (q : State) : State := {q with legacyWriter:=q.legacySaved, legacyGen:=(q.legacyGen+(1)), legacyPc:=(3), legacyClobbered:=(decide ((q.legacyClobbered=true) ∨ ((q.legacyNewer=true) ∧ (q.legacySaved≠(2)))))}
def legacyResumeGuard (q : State) : Prop := ((q.legacyPc=(3)) ∨ (q.legacyPc=(4))) ∧ (q.legacyCaptured=true)
def legacyResumeNext (q : State) : State := {q with legacyPc:=(1), legacySaved:=q.legacyCaptureSaved, legacyResumes:=(q.legacyResumes+(1))}
def legacyLateEntryGuard (q : State) : Prop := ((q.legacyPc=(3)) ∨ (q.legacyPc=(4)))
def legacyLateEntryNext (q : State) : State := {q with legacySaved:=q.legacyWriter, legacyWriter:=(0), legacyGen:=(q.legacyGen+(1)), legacyPc:=(1)}
def Step (q r : State) : Prop := (beginScopeGuard q ∧ r=beginScopeNext q) ∨ (bodyReturnsGuard q ∧ r=bodyReturnsNext q) ∨ (restoreOwnedGuard q ∧ r=restoreOwnedNext q) ∨ (escapeOwnedGuard q ∧ r=escapeOwnedNext q) ∨ (publishOtherGuard q ∧ r=publishOtherNext q) ∨ (publishSameIdentityGuard q ∧ r=publishSameIdentityNext q) ∨ (yieldConflictGuard q ∧ r=yieldConflictNext q) ∨ (changeEpochGuard q ∧ r=changeEpochNext q) ∨ (acceptTicketGuard q ∧ r=acceptTicketNext q) ∨ (startTicketGuard q ∧ r=startTicketNext q) ∨ (finishBorrowerGuard q ∧ r=finishBorrowerNext q) ∨ (captureGuard q ∧ r=captureNext q) ∨ (rejectStalePermitGuard q ∧ r=rejectStalePermitNext q) ∨ (detachCaptureGuard q ∧ r=detachCaptureNext q) ∨ (closeRegistrationGuard q ∧ r=closeRegistrationNext q) ∨ (namedDemandGuard q ∧ r=namedDemandNext q) ∨ (namedSupplyGuard q ∧ r=namedSupplyNext q) ∨ (rawMetadataGuard q ∧ r=rawMetadataNext q) ∨ (ioFailureGuard q ∧ r=ioFailureNext q) ∨ (qualifyProfileGuard q ∧ r=qualifyProfileNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (consumeSecondGuard q ∧ r=consumeSecondNext q) ∨ (legacyEnterGuard q ∧ r=legacyEnterNext q) ∨ (legacyCaptureGuard q ∧ r=legacyCaptureNext q) ∨ (legacyEscapeGuard q ∧ r=legacyEscapeNext q) ∨ (legacyPublishGuard q ∧ r=legacyPublishNext q) ∨ (legacyResolveGuard q ∧ r=legacyResolveNext q) ∨ (legacyReturnGuard q ∧ r=legacyReturnNext q) ∨ (legacyRestoreGuard q ∧ r=legacyRestoreNext q) ∨ (legacyResumeGuard q ∧ r=legacyResumeNext q) ∨ (legacyLateEntryGuard q ∧ r=legacyLateEntryNext q) ∨ r=q
end FormatterRestoreAst

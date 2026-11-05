import Std
namespace SizeGuardAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 direction : Int
 created : Int
 hold : Int
 effects : Int
 carrier : Int
 lang : Int
 captured : Int
 guard : Int
 lease : Int
 closed : Int
 frozen : Int
 gc : Int
 scanners : Int
 scanned : Int
 exited : Int
 outcome : Int
 receiptId : Int
 reply : Int
 attempt : Int
 epoch : Int
 leaseEpoch : Int
 viewGuard : Int
 viewCarrier : Int
 viewAttempt : Int
 viewLang : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(9)) ∧ (q.direction≥(0)) ∧ (q.direction≤(1)) ∧ (q.created≥(0)) ∧ (q.created≤(1)) ∧ (q.hold≥(0)) ∧ (q.hold≤(1)) ∧ (q.effects≥(0)) ∧ (q.effects≤(1)) ∧ (q.carrier≥(0)) ∧ (q.carrier≤(1)) ∧ (q.lang≥(0)) ∧ (q.lang≤(1)) ∧ (q.captured≥(0)) ∧ (q.captured≤(1)) ∧ (q.guard≥(0)) ∧ (q.guard≤(1)) ∧ (q.lease≥(0)) ∧ (q.lease≤(2)) ∧ (q.closed≥(0)) ∧ (q.closed≤(1)) ∧ (q.frozen≥(0)) ∧ (q.frozen≤(1)) ∧ (q.gc≥(0)) ∧ (q.gc≤(1)) ∧ (q.scanners≥(0)) ∧ (q.scanners≤(1)) ∧ (q.scanned≥(0)) ∧ (q.scanned≤(1)) ∧ (q.exited≥(0)) ∧ (q.exited≤(1)) ∧ (q.outcome≥(0)) ∧ (q.outcome≤(2)) ∧ (q.reply≥(0)) ∧ (q.reply≤(1)) ∧ (q.viewGuard≥(0)) ∧ (q.viewGuard≤(1)) ∧ (q.viewCarrier≥(0)) ∧ (q.viewCarrier≤(1)) ∧ (q.viewLang≥(0)) ∧ (q.viewLang≤(1)) ∧ (q.viewAttempt≥(0)) ∧ (q.viewAttempt≤q.attempt) ∧ ((q.frozen=(1)) → ((((q.guard=q.viewGuard) ∧ (q.carrier=q.viewCarrier)) ∧ (q.attempt=q.viewAttempt)) ∧ (q.lang=q.viewLang))) ∧ (q.attempt≥(0)) ∧ (q.epoch≥(1)) ∧ (q.receiptId≥(0)) ∧ (q.receiptId≤q.attempt) ∧ (q.leaseEpoch≥(0)) ∧ (q.leaseEpoch≤q.epoch) ∧ ((q.hold+q.effects)=q.created) ∧ (q.captured≤q.lang) ∧ ((q.phase≤(2)) → ((((((q.created=(0)) ∧ (q.hold=(0))) ∧ (q.effects=(0))) ∧ (q.carrier=(0))) ∧ (q.lang=(0))) ∧ (q.captured=(0)))) ∧ ((q.phase≤(5)) → (q.effects=(0))) ∧ ((q.phase≥(6)) → ((q.hold=(0)) ∧ (q.effects=q.created))) ∧ ((q.phase≥(7)) → (q.receiptId=q.attempt)) ∧ ((q.phase≤(7)) → (q.reply=(0))) ∧ ((q.reply=(1)) → (((q.phase=(8)) ∨ (q.phase=(9))) ∧ (q.receiptId=q.attempt))) ∧ ((q.phase=(0)) → ((q.guard=(0)) ∧ (q.attempt=(0)))) ∧ ((q.phase≥(1)) → (q.attempt≥(1))) ∧ (((q.phase≥(1)) ∧ (q.phase≤(8))) → (q.guard=(1))) ∧ (((q.phase≥(3)) ∧ (q.phase≤(8))) → (q.carrier=(1))) ∧ ((q.phase=(9)) → ((q.guard=(0)) ∧ (q.carrier=(0)))) ∧ ((q.phase≤(3)) → ((q.exited=(0)) ∧ (q.outcome=(0)))) ∧ ((q.phase≥(4)) → ((q.exited=(1)) ∧ (q.outcome≥(1)))) ∧ ((q.lease=(1)) → (((q.phase=(3)) ∨ (q.phase=(8))) ∨ (q.phase=(9)))) ∧ ((q.lease=(2)) → (((q.phase=(5)) ∨ (q.phase=(6))) ∨ (q.phase=(7)))) ∧ ((((q.phase=(5)) ∨ (q.phase=(6))) ∨ (q.phase=(7))) → (q.lease=(2))) ∧ ((q.lease≥(1)) → (((q.frozen=(0)) ∧ (q.gc=(0))) ∧ (q.leaseEpoch=q.epoch))) ∧ ((q.frozen=(1)) → ((q.closed=(1)) ∧ (q.lease=(0)))) ∧ ((q.gc=(1)) → ((q.frozen=(1)) ∧ (q.scanners=(1)))) ∧ ((q.scanners=(1)) → (q.gc=(1))) ∧ ((q.scanned=(1)) → (((q.frozen=(1)) ∧ (q.gc=(0))) ∧ (q.scanners=(0)))) ∧ ((((((q.direction=(1)) ∧ (q.created=(1))) ∧ (q.outcome=(1))) ∧ (q.phase≥(4))) ∧ (q.phase≤(7))) → (q.lang=(1))))
def initial : State := {phase:=(0), direction:=(0), created:=(0), hold:=(0), effects:=(0), carrier:=(0), lang:=(0), captured:=(0), guard:=(0), lease:=(0), closed:=(0), frozen:=(0), gc:=(0), scanners:=(0), scanned:=(0), exited:=(0), outcome:=(0), receiptId:=(0), reply:=(0), attempt:=(0), epoch:=(1), leaseEpoch:=(0), viewGuard:=(0), viewCarrier:=(0), viewAttempt:=(0), viewLang:=(0)}
def reserveSfunGuard (q : State) : Prop := ((((q.phase=(0)) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def reserveSfunNext (q : State) : State := {q with phase:=(1), direction:=(0), guard:=(1), attempt:=(1)}
def reserveCfunGuard (q : State) : Prop := ((((q.phase=(0)) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def reserveCfunNext (q : State) : State := {q with phase:=(1), direction:=(1), guard:=(1), attempt:=(1)}
def beginConversionGuard (q : State) : Prop := (((((q.phase=(1)) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0))) ∧ (q.lease=(0)))
def beginConversionNext (q : State) : State := {q with phase:=(2)}
def completeBoxedGuard (q : State) : Prop := (((((q.phase=(2)) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0))) ∧ (q.lease=(0)))
def completeBoxedNext (q : State) : State := {q with phase:=(3), created:=(1), hold:=(1), carrier:=(1)}
def completeImmediateGuard (q : State) : Prop := (((((q.phase=(2)) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0))) ∧ (q.lease=(0)))
def completeImmediateNext (q : State) : State := {q with phase:=(3), carrier:=(1)}
def abortBeforeConversionGuard (q : State) : Prop := ((((((q.phase=(1)) ∨ (q.phase=(2))) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0))) ∧ (q.lease=(0)))
def abortBeforeConversionNext (q : State) : State := {q with phase:=(4), carrier:=(1), exited:=(1), outcome:=(2)}
def acquireRootUpdateGuard (q : State) : Prop := (((((((q.phase=(3)) ∨ (q.phase=(8))) ∨ (q.phase=(9))) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0))) ∧ (q.lease=(0)))
def acquireRootUpdateNext (q : State) : State := {q with lease:=(1), leaseEpoch:=q.epoch}
def publishLanguageGuard (q : State) : Prop := ((((q.phase=(3)) ∧ (q.lease=(1))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def publishLanguageNext (q : State) : State := {q with lang:=(1)}
def releaseRootUpdateGuard (q : State) : Prop := (((q.lease=(1)) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def releaseRootUpdateNext (q : State) : State := {q with lease:=(0)}
def captureArgumentGuard (q : State) : Prop := (((((((q.phase=(3)) ∧ (q.direction=(0))) ∧ (q.lang=(1))) ∧ (q.lease=(0))) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def captureArgumentNext (q : State) : State := {q with captured:=(1)}
def finishNativeGuard (q : State) : Prop := ((((((q.phase=(3)) ∧ (q.lease=(0))) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0))) ∧ (((q.direction=(0)) ∨ (q.lang=(1))) ∨ (q.created=(0))))
def finishNativeNext (q : State) : State := {q with phase:=(4), exited:=(1), outcome:=(1)}
def escapeNativeGuard (q : State) : Prop := (((((q.phase=(3)) ∧ (q.lease=(0))) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def escapeNativeNext (q : State) : State := {q with phase:=(4), exited:=(1), outcome:=(2)}
def claimDropGuard (q : State) : Prop := (((((q.phase=(4)) ∧ (q.lease=(0))) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def claimDropNext (q : State) : State := {q with phase:=(5), lease:=(2), leaseEpoch:=q.epoch}
def fuseCfunHandoffGuard (q : State) : Prop := ((((((q.phase=(3)) ∧ (q.direction=(1))) ∧ (q.lease=(0))) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def fuseCfunHandoffNext (q : State) : State := {q with phase:=(5), lang:=(1), exited:=(1), outcome:=(1), lease:=(2), leaseEpoch:=q.epoch}
def physicalDropGuard (q : State) : Prop := (((((q.phase=(5)) ∧ (q.lease=(2))) ∧ (q.leaseEpoch=q.epoch)) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def physicalDropNext (q : State) : State := {q with phase:=(6), hold:=(0), effects:=q.created}
def recordDropGuard (q : State) : Prop := (((((q.phase=(6)) ∧ (q.lease=(2))) ∧ (q.leaseEpoch=q.epoch)) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def recordDropNext (q : State) : State := {q with phase:=(7), receiptId:=q.attempt}
def releaseDropGuard (q : State) : Prop := (((((q.phase=(7)) ∧ (q.lease=(2))) ∧ (q.receiptId=q.attempt)) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def releaseDropNext (q : State) : State := {q with phase:=(8), lease:=(0), reply:=(1)}
def loseReplyGuard (q : State) : Prop := (((q.phase=(8)) ∨ (q.phase=(9))) ∧ (q.reply=(1)))
def loseReplyNext (q : State) : State := {q with reply:=(0)}
def queryReceiptGuard (q : State) : Prop := (((q.phase=(8)) ∨ (q.phase=(9))) ∧ (q.receiptId=q.attempt))
def queryReceiptNext (q : State) : State := {q with reply:=(1)}
def dropCaptureGuard (q : State) : Prop := ((((((q.phase=(8)) ∨ (q.phase=(9))) ∧ (q.closed=(0))) ∧ (q.lease=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def dropCaptureNext (q : State) : State := {q with captured:=(0)}
def clearLanguageGuard (q : State) : Prop := ((((((q.phase=(8)) ∨ (q.phase=(9))) ∧ (q.captured=(0))) ∧ (q.lease=(1))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def clearLanguageNext (q : State) : State := {q with lang:=(0)}
def retireGuardGuard (q : State) : Prop := (((((q.phase=(8)) ∧ (q.lease=(1))) ∧ (q.frozen=(0))) ∧ (q.gc=(0))) ∧ (q.scanners=(0)))
def retireGuardNext (q : State) : State := {q with phase:=(9), guard:=(0), carrier:=(0)}
def reissueSfunGuard (q : State) : Prop := (((((((q.phase=(9)) ∧ (q.lang=(0))) ∧ (q.captured=(0))) ∧ (q.lease=(0))) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def reissueSfunNext (q : State) : State := {q with phase:=(1), direction:=(0), created:=(0), hold:=(0), effects:=(0), carrier:=(0), guard:=(1), exited:=(0), outcome:=(0), reply:=(0), attempt:=(q.attempt+(1))}
def reissueCfunGuard (q : State) : Prop := (((((((q.phase=(9)) ∧ (q.lang=(0))) ∧ (q.captured=(0))) ∧ (q.lease=(0))) ∧ (q.closed=(0))) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def reissueCfunNext (q : State) : State := {q with phase:=(1), direction:=(1), created:=(0), hold:=(0), effects:=(0), carrier:=(0), guard:=(1), exited:=(0), outcome:=(0), reply:=(0), attempt:=(q.attempt+(1))}
def closeGateGuard (q : State) : Prop := (((q.closed=(0)) ∧ (q.frozen=(0))) ∧ (q.gc=(0)))
def closeGateNext (q : State) : State := {q with closed:=(1)}
def freezeOwnerGuard (q : State) : Prop := True
def freezeOwnerNext (q : State) : State := {q with frozen:=(1), viewGuard:=q.guard, viewCarrier:=q.carrier, viewAttempt:=q.attempt, viewLang:=q.lang}
def beginScanGuard (q : State) : Prop := (((q.frozen=(1)) ∧ (q.gc=(0))) ∧ (q.scanned=(0)))
def beginScanNext (q : State) : State := {q with gc:=(1), scanners:=(1)}
def endScanGuard (q : State) : Prop := ((q.gc=(1)) ∧ (q.scanners=(1)))
def endScanNext (q : State) : State := {q with gc:=(0), scanners:=(0), scanned:=(1)}
def resumeOwnerGuard (q : State) : Prop := (((((q.frozen=(1)) ∧ (q.gc=(0))) ∧ (q.scanners=(0))) ∧ (q.scanned=(1))) ∧ (q.lease=(0)))
def resumeOwnerNext (q : State) : State := {q with closed:=(0), frozen:=(0), scanned:=(0), epoch:=(q.epoch+(1))}
def Step (q r : State) : Prop := (reserveSfunGuard q ∧ r=reserveSfunNext q) ∨ (reserveCfunGuard q ∧ r=reserveCfunNext q) ∨ (beginConversionGuard q ∧ r=beginConversionNext q) ∨ (completeBoxedGuard q ∧ r=completeBoxedNext q) ∨ (completeImmediateGuard q ∧ r=completeImmediateNext q) ∨ (abortBeforeConversionGuard q ∧ r=abortBeforeConversionNext q) ∨ (acquireRootUpdateGuard q ∧ r=acquireRootUpdateNext q) ∨ (publishLanguageGuard q ∧ r=publishLanguageNext q) ∨ (releaseRootUpdateGuard q ∧ r=releaseRootUpdateNext q) ∨ (captureArgumentGuard q ∧ r=captureArgumentNext q) ∨ (finishNativeGuard q ∧ r=finishNativeNext q) ∨ (escapeNativeGuard q ∧ r=escapeNativeNext q) ∨ (claimDropGuard q ∧ r=claimDropNext q) ∨ (fuseCfunHandoffGuard q ∧ r=fuseCfunHandoffNext q) ∨ (physicalDropGuard q ∧ r=physicalDropNext q) ∨ (recordDropGuard q ∧ r=recordDropNext q) ∨ (releaseDropGuard q ∧ r=releaseDropNext q) ∨ (loseReplyGuard q ∧ r=loseReplyNext q) ∨ (queryReceiptGuard q ∧ r=queryReceiptNext q) ∨ (dropCaptureGuard q ∧ r=dropCaptureNext q) ∨ (clearLanguageGuard q ∧ r=clearLanguageNext q) ∨ (retireGuardGuard q ∧ r=retireGuardNext q) ∨ (reissueSfunGuard q ∧ r=reissueSfunNext q) ∨ (reissueCfunGuard q ∧ r=reissueCfunNext q) ∨ (closeGateGuard q ∧ r=closeGateNext q) ∨ (freezeOwnerGuard q ∧ r=freezeOwnerNext q) ∨ (beginScanGuard q ∧ r=beginScanNext q) ∨ (endScanGuard q ∧ r=endScanNext q) ∨ (resumeOwnerGuard q ∧ r=resumeOwnerNext q) ∨ r=q
end SizeGuardAst

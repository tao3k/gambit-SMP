module result_mutex_abort_responsibility_tests {
 import result_mutex_abort_responsibility.* from "./result_mutex_abort_responsibility"
 action deliver=attemptWrite.then(drain).then(acceptWriteOutcome).then(serviceReady).then(finish)
 run eagainHandsOffToReceiverBeforeWriterReturns=initEagainDrainRace.then(publish)
 .then(attemptWrite).then(drain).then(acceptWriteOutcome).then(serviceReady).then(finish)
 .expect(done and safe and s.outcome==2 and not(s.pipe))
 run interruptedWriteRetainsIssuerThenRetries=initEintrRetry.then(publish)
 .then(attemptWrite).expect(safe and s.issuer and not(s.returned) and not(s.pipe))
 .then(retryEintr).then(drain).then(acceptWriteOutcome).then(serviceReady).then(finish)
 .expect(done and safe and s.retried)
 run permanentFailureIsRetainedNotRecovered=initHardError.then(publish).then(attemptWrite)
 .expect(retainedFault and safe and not(done) and not(s.admitted))
 run oldAckCannotDischargeSecondPublication=initTwoEpochs.then(publish).then(deliver)
 .then(nextEpoch).expect(safe and s.epoch==2 and s.ack==1 and s.issuer)
 .then(deliver).expect(done and safe and s.epoch==s.ack)
}

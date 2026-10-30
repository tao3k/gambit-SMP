module abort_quiescence_tests {
 import abort_quiescence_sources.* from "./abort_quiescence_sources"
 action cohort=directInterrupted.then(directRetryFinishes).then(arriveOldCohort)
 run registryKeepsRetryAliveUntilCountCommit=initExistingCovered.then(cohort)
 .then(closeRegistry).then(irqInterrupted).expect(safe and s.reader and s.phase==1)
 .then(irqRetryFinishes).then(publishReducedCount).then(workerClosesFd).expect(done and safe)
 run oldCohortDoesNotCoverExternalC=initUntrackedExternal.then(cohort)
 .then(irqInterrupted).then(irqRetryFinishes).then(closeRegistry)
 .then(publishReducedCount).then(workerClosesFd)
 .expect(not(safe) and s.external==1 and s.closed)
 run scopedExternalPinCompletesCoverage=initPinnedExternal.then(cohort)
 .then(irqInterrupted).then(irqRetryFinishes).then(closeRegistry)
 .then(publishReducedCount).then(externalFinishes).then(workerClosesFd).expect(done and safe)
 run registryLeaseCannotEndAtFirstEintr=initEarlyReaderRelease.then(cohort)
 .then(irqInterrupted).then(closeRegistry).then(publishReducedCount).then(workerClosesFd)
 .expect(not(safe) and s.irq==2 and not(s.reader))
}

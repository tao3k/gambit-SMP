import CohortRetirement
open CohortRetirementAst
def witness : State := joinKnownNext (exitWorkerNext (collectiveDrainNext (closeRosterNext (acquireExternalNext (initial)))))
example : acquireExternalGuard (initial) := by simp [acquireExternalGuard,initial]
example : closeRosterGuard (acquireExternalNext (initial)) := by simp [closeRosterGuard,initial,acquireExternalNext]
example : collectiveDrainGuard (closeRosterNext (acquireExternalNext (initial))) := by simp [collectiveDrainGuard,initial,acquireExternalNext,closeRosterNext]
example : exitWorkerGuard (collectiveDrainNext (closeRosterNext (acquireExternalNext (initial)))) := by simp [exitWorkerGuard,initial,acquireExternalNext,closeRosterNext,collectiveDrainNext]
example : joinKnownGuard (exitWorkerNext (collectiveDrainNext (closeRosterNext (acquireExternalNext (initial))))) := by simp [joinKnownGuard,initial,acquireExternalNext,closeRosterNext,collectiveDrainNext,exitWorkerNext]
example : Safe witness := by simp [Safe,witness,initial,acquireExternalNext,closeRosterNext,collectiveDrainNext,exitWorkerNext,joinKnownNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (retireDomainGuard witness) := by simp [Safe,witness,initial,acquireExternalNext,closeRosterNext,collectiveDrainNext,exitWorkerNext,joinKnownNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : retireDomainGuard witness := by simp [Safe,witness,initial,acquireExternalNext,closeRosterNext,collectiveDrainNext,exitWorkerNext,joinKnownNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]

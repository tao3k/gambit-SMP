import CohortRetirement
open CohortRetirementAst
def witness : State := closeRosterNext (escapeScannerNext (initial))
example : escapeScannerGuard (initial) := by simp [escapeScannerGuard,initial]
example : closeRosterGuard (escapeScannerNext (initial)) := by simp [closeRosterGuard,initial,escapeScannerNext]
example : Safe witness := by simp [Safe,witness,initial,escapeScannerNext,closeRosterNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (collectiveDrainGuard witness) := by simp [Safe,witness,initial,escapeScannerNext,closeRosterNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : collectiveDrainGuard witness := by simp [Safe,witness,initial,escapeScannerNext,closeRosterNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]

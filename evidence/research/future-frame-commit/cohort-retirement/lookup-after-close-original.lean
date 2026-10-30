import CohortRetirement
open CohortRetirementAst
def witness : State := closeRosterNext (enterLookupNext (initial))
example : enterLookupGuard (initial) := by simp [enterLookupGuard,initial]
example : closeRosterGuard (enterLookupNext (initial)) := by simp [closeRosterGuard,initial,enterLookupNext]
example : Safe witness := by simp [Safe,witness,initial,enterLookupNext,closeRosterNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (collectiveDrainGuard witness) := by simp [Safe,witness,initial,enterLookupNext,closeRosterNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]

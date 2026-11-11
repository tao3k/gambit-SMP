import CohortRetirement
open CohortRetirementAst
def witness : State := joinUnknownNext (collectiveDrainNext (closeRosterNext (initial)))
example : closeRosterGuard (initial) := by simp [closeRosterGuard,initial]
example : collectiveDrainGuard (closeRosterNext (initial)) := by simp [collectiveDrainGuard,initial,closeRosterNext]
example : joinUnknownGuard (collectiveDrainNext (closeRosterNext (initial))) := by simp [joinUnknownGuard,initial,closeRosterNext,collectiveDrainNext]
example : Safe witness := by simp [Safe,witness,initial,closeRosterNext,collectiveDrainNext,joinUnknownNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (retireDomainGuard witness) := by simp [Safe,witness,initial,closeRosterNext,collectiveDrainNext,joinUnknownNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]

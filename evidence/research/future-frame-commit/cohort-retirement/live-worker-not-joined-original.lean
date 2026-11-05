import CohortRetirement
open CohortRetirementAst
def witness : State := closeRosterNext (initial)
example : closeRosterGuard (initial) := by simp [closeRosterGuard,initial]
example : Safe witness := by simp [Safe,witness,initial,closeRosterNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
example : ¬ (joinKnownGuard witness) := by simp [Safe,witness,initial,closeRosterNext,enterLookupGuard,exitLookupGuard,acquireExternalGuard,returnExternalGuard,closeRosterGuard,escapeScannerGuard,collectiveDrainGuard,exitWorkerGuard,joinUnknownGuard,joinKnownGuard,retireDomainGuard]
